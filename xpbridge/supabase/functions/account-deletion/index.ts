// @ts-nocheck — Supabase Edge Functions run on Deno, not Node.js
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const authHeader = req.headers.get("Authorization") ?? "";

    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
      throw new Error("Missing required Supabase function secrets");
    }

    if (!authHeader.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Get user from JWT
    const { data: { user }, error: authError } = await userClient.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { action } = await req.json();

    // ACTION: DELETE (password-verified — the client re-authenticates before calling)
    if (action === "delete") {
      // 1. Try to call purge_my_user_data() RPC if it exists
      try {
        await adminClient.rpc("purge_my_user_data", { target_user_id: user.id });
      } catch (_) {
        // RPC may not exist — fall back to manual deletion
      }

      // 2. Delete user-owned storage files (best-effort). Covers the three
      //    folder-prefixes the Flutter client actually writes into:
      //    - resumes/<uid>/...
      //    - profiles/<uid>/...
      //    - logos/<uid>/...
      //    We still sweep the legacy `<uid>/...` prefix too, in case any
      //    older build created objects there.
      try {
        const bucket = "xpbridge-assets";
        const prefixes = [
          `resumes/${user.id}`,
          `profiles/${user.id}`,
          `logos/${user.id}`,
          user.id,
        ];
        const pathsToDelete: string[] = [];
        for (const prefix of prefixes) {
          const { data: files } = await adminClient.storage
            .from(bucket)
            .list(prefix);
          if (files && files.length > 0) {
            for (const f of files as { name: string }[]) {
              pathsToDelete.push(`${prefix}/${f.name}`);
            }
          }
        }
        if (pathsToDelete.length > 0) {
          await adminClient.storage.from(bucket).remove(pathsToDelete);
        }
      } catch (_) {
        // Storage cleanup is best-effort
      }

      // 3. Delete DB profile (cascade will handle related records)
      await adminClient.from("profiles").delete().eq("id", user.id);

      // 4. Clean up OTP records if any exist
      try {
        await adminClient.from("account_deletion_otps").delete().eq("user_id", user.id);
      } catch (_) {
        // Table may not exist
      }

      // 5. Delete Auth User
      const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id);
      if (deleteError) throw deleteError;

      return new Response(JSON.stringify({ message: "Account deleted successfully" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    throw new Error("Invalid action");

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Internal server error";
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
