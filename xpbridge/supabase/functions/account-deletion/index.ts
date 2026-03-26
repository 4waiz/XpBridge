import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Get user from JWT
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { action, otp } = await req.json();

    // ACTION: REQUEST-OTP
    if (action === "request-otp") {
      const generatedOtp = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString(); // 10 mins

      // Store in DB
      const { error: otpDbError } = await supabaseClient
        .from("account_deletion_otps")
        .upsert({ user_id: user.id, otp_code: generatedOtp, expires_at: expiresAt });

      if (otpDbError) throw otpDbError;

      // Send Email
      // NOTE: Using auth.admin.sendRawEmail requires a custom SMTP or higher tier.
      // Alternatively, we use a simple insert into a "mail" table if you use a trigger/extension,
      // but here we'll use the Supabase Auth Admin API to send a "magic link" template workaround 
      // or just expect the developer to plug in Resend/SendGrid.
      
      // FOR THE SAKE OF THIS IMPLEMENTATION, we will attempt to use auth.admin.generateLink or similar
      // but the most reliable way is actually just informing the user to set up Resend.
      
      // MOCK EMAIL LOGGING (In production, replace with actual email provider call)
      console.log(`[DELETION OTP] Sent ${generatedOtp} to ${user.email}`);

      // If you have RESEND_API_KEY set:
      const resendKey = Deno.env.get("RESEND_API_KEY");
      if (resendKey) {
        await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${resendKey}`,
          },
          body: JSON.stringify({
            from: "XPBridge <noreply@xpbridge.com>",
            to: [user.email],
            subject: "XPBridge: Confirm Account Deletion",
            html: `<p>Your code to confirm account deletion is: <strong>${generatedOtp}</strong></p><p>This code expires in 10 minutes. <strong>This action is permanent and cannot be undone.</strong></p>`,
          }),
        });
      }

      return new Response(JSON.stringify({ message: "OTP requested" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ACTION: CONFIRM-DELETION
    if (action === "confirm-deletion") {
      if (!otp) throw new Error("OTP is required");

      // Verify OTP
      const { data: otpData, error: otpFetchError } = await supabaseClient
        .from("account_deletion_otps")
        .select("*")
        .eq("user_id", user.id)
        .eq("otp_code", otp)
        .single();

      if (otpFetchError || !otpData) {
        return new Response(JSON.stringify({ error: "Invalid OTP" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      if (new Date(otpData.expires_at) < new Date()) {
        return new Response(JSON.stringify({ error: "OTP expired" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // SUCCESS - Start Deletion
      
      // 1. Delete DB profile (Cascades will hit missions/applications/interviews)
      await supabaseClient.from("profiles").delete().eq("id", user.id);

      // 2. Delete OTP record
      await supabaseClient.from("account_deletion_otps").delete().eq("user_id", user.id);

      // 3. Optional: Delete storage assets
      // (Implementation depends on bucket structure, e.g., 'avatars/USER_ID/')
      // const { data: files } = await supabaseClient.storage.from('xpbridge-assets').list(user.id);
      // if (files) await supabaseClient.storage.from('xpbridge-assets').remove(files.map(f => `${user.id}/${f.name}`));

      // 4. Delete Auth User
      const { error: deleteError } = await supabaseClient.auth.admin.deleteUser(user.id);
      if (deleteError) throw deleteError;

      return new Response(JSON.stringify({ message: "Account deleted successfully" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    throw new Error("Invalid action");

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
