# Account Deletion Implementation

This directory contains the implementation for secure, OTP-verified account deletion for XPBridge.

## Features
- **Public Deletion Page**: `#/delete-account` (explained in `lib/screens/legal/delete_account_screen.dart`).
- **In-App OTP Flow**: Authenticated users can request an OTP and verify it with "DELETE" confirmation.
- **Backend Security**: All deletion logic is handled securely in a Supabase Edge Function to protect the Service Role Key.
- **Public Request Table**: A fallback table `account_deletion_requests` for locked-out users.

## Setup Instructions

### 1. Database Migration
Run the SQL in `supabase/account_deletion_migration.sql` in your Supabase SQL Editor. This will create:
- `public.account_deletion_requests`
- `public.account_deletion_otps`
- Appropriate RLS policies.

### 2. Deploy Edge Function
Ensure you have the Supabase CLI installed and logged in. Then run:
```bash
supabase functions deploy account-deletion
```
Note: This function requires `SUPABASE_SERVICE_ROLE_KEY` (which is auto-populated in Edge Functions by default).

### 3. Email Configuration (Optional but Recommended)
The Edge Function is prepared to use **Resend** for sending OTPs. To enable this:
1. Get an API key from [resend.com](https://resend.com/).
2. Set the secret in Supabase:
```bash
supabase secrets set RESEND_API_KEY=re_your_api_key
```
If you don't use Resend, you can modify the Edge Function in `supabase/functions/account-deletion/index.ts` to use your preferred provider.

### 4. Storage Bucket
Ensure your `xpbridge-assets` bucket exists in Supabase Storage and that the Service Role has permission to delete from it.

## Testing the Flow
1. Go to your Profile settings in the app.
2. Tap "Delete account".
3. Tap "Send OTP".
4. Check your email (or the Edge Function logs in Supabase) for the 6-digit code.
5. Enter the code and type "DELETE".
6. Confirm.

All linked records (missions, applications, interviews) will be deleted via `ON DELETE CASCADE` on the `profiles` table.
