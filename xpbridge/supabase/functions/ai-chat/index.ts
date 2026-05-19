// @ts-nocheck — Supabase Edge Functions run on Deno, not Node.js
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "llama-3.3-70b-versatile";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const authHeader = req.headers.get("Authorization") ?? "";

    if (!authHeader.startsWith("Bearer ")) {
      return json({ error: "Unauthorized" }, 401);
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();

    if (authError || !user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const groqKey = Deno.env.get("GROQ_API_KEY");
    if (!groqKey) {
      return json({ error: "AI service is not configured." }, 503);
    }

    const body = await req.json();
    const { contents, tools, generationConfig, systemPrompt } = body;

    if (!contents || !Array.isArray(contents)) {
      return json({ error: "Invalid request: contents array is required." }, 400);
    }

    const messages = [
      ...(systemPrompt ? [{ role: "system", content: systemPrompt }] : []),
      ...geminiContentsToOpenAiMessages(contents),
    ];

    const groqBody: Record<string, unknown> = {
      model: GROQ_MODEL,
      messages,
      temperature: generationConfig?.temperature ?? 0.7,
      max_tokens: generationConfig?.maxOutputTokens ?? 800,
    };

    if (tools && Array.isArray(tools)) {
      groqBody.tools = geminiToolsToOpenAiTools(tools);
      groqBody.tool_choice = "auto";
    }

    const groqRes = await fetch(GROQ_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${groqKey}`,
      },
      body: JSON.stringify(groqBody),
    });

    const groqData = await groqRes.json();

    if (!groqRes.ok) {
      const msg =
        groqData?.error?.message ?? `Groq API error: ${groqRes.status}`;
      return json({ error: msg }, groqRes.status);
    }

    return json(openAiResponseToGeminiShape(groqData), 200);
  } catch (error) {
    return json({ error: (error as Error).message }, 500);
  }
});

// --- Gemini <-> OpenAI translation ---
//
// The Flutter client speaks Gemini's schema. Groq speaks OpenAI's. We translate
// both directions here so the client doesn't need to change.

function geminiContentsToOpenAiMessages(
  contents: Array<Record<string, unknown>>,
): Array<Record<string, unknown>> {
  const messages: Array<Record<string, unknown>> = [];

  for (const entry of contents) {
    const role = entry.role as string;
    const parts = (entry.parts as Array<Record<string, unknown>>) ?? [];

    // functionResponse parts become OpenAI "tool" role messages.
    const functionResponsePart = parts.find((p) => p.functionResponse);
    if (functionResponsePart) {
      const fr = functionResponsePart.functionResponse as Record<string, unknown>;
      messages.push({
        role: "tool",
        tool_call_id: (fr.name as string) ?? "tool_call",
        name: fr.name,
        content: JSON.stringify(fr.response ?? {}),
      });
      continue;
    }

    // functionCall parts (assistant tool calls)
    const functionCallPart = parts.find((p) => p.functionCall);
    if (functionCallPart && role === "model") {
      const fc = functionCallPart.functionCall as Record<string, unknown>;
      messages.push({
        role: "assistant",
        content: null,
        tool_calls: [
          {
            id: (fc.name as string) ?? "tool_call",
            type: "function",
            function: {
              name: fc.name,
              arguments: JSON.stringify(fc.args ?? {}),
            },
          },
        ],
      });
      continue;
    }

    // Plain text parts
    const text = parts
      .map((p) => p.text)
      .filter((t) => typeof t === "string")
      .join("\n");

    if (!text) continue;

    messages.push({
      role: role === "model" ? "assistant" : "user",
      content: text,
    });
  }

  return messages;
}

function geminiToolsToOpenAiTools(
  tools: Array<Record<string, unknown>>,
): Array<Record<string, unknown>> {
  const out: Array<Record<string, unknown>> = [];
  for (const tool of tools) {
    const decls =
      (tool.function_declarations as Array<Record<string, unknown>>) ?? [];
    for (const d of decls) {
      out.push({
        type: "function",
        function: {
          name: d.name,
          description: d.description,
          parameters: d.parameters,
        },
      });
    }
  }
  return out;
}

function openAiResponseToGeminiShape(
  data: Record<string, unknown>,
): Record<string, unknown> {
  const choice = (data.choices as Array<Record<string, unknown>>)?.[0];
  const message = (choice?.message as Record<string, unknown>) ?? {};
  const parts: Array<Record<string, unknown>> = [];

  const toolCalls = message.tool_calls as Array<Record<string, unknown>> | undefined;
  if (toolCalls && toolCalls.length > 0) {
    for (const tc of toolCalls) {
      const fn = tc.function as Record<string, unknown>;
      let args: unknown = {};
      try {
        args = JSON.parse((fn.arguments as string) ?? "{}");
      } catch (_) {
        args = {};
      }
      parts.push({
        functionCall: {
          name: fn.name,
          args,
        },
      });
    }
  } else {
    parts.push({ text: (message.content as string) ?? "" });
  }

  return {
    candidates: [
      {
        content: {
          role: "model",
          parts,
        },
      },
    ],
  };
}

function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
