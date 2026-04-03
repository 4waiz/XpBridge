// @ts-nocheck — Supabase Edge Functions run on Deno, not Node.js
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta";
const GEMINI_MODEL = "gemini-2.5-flash";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // --- Auth check ---
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

    // --- Gemini API key (stored as Edge Function secret) ---
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiKey) {
      return json({ error: "AI service is not configured." }, 503);
    }

    // --- Parse request ---
    const body = await req.json();
    const { contents, tools, generationConfig } = body;

    if (!contents || !Array.isArray(contents)) {
      return json({ error: "Invalid request: contents array is required." }, 400);
    }

    // --- Proxy to Gemini ---
    const geminiUrl = `${GEMINI_BASE}/models/${GEMINI_MODEL}:generateContent?key=${geminiKey}`;
    const geminiBody: Record<string, unknown> = { contents, generationConfig };
    if (tools) {
      geminiBody.tools = tools;
    }

    const geminiRes = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(geminiBody),
    });

    const geminiData = await geminiRes.json();

    if (!geminiRes.ok) {
      const msg =
        geminiData?.error?.message ?? `Gemini API error: ${geminiRes.status}`;
      return json({ error: msg }, geminiRes.status);
    }

    return json(geminiData, 200);
  } catch (error) {
    return json({ error: (error as Error).message }, 500);
  }
});

function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
