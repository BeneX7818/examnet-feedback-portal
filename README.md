# ExamNet Feedback Portal — Password-only Admin

Static website for GitHub Pages. Students submit feedback without an account; the admin dashboard is protected by a password only (no email/Auth account).

## 1. Configure Supabase
1. Create a Supabase project.
2. Open **SQL Editor** and run `supabase-setup.sql`.
3. **Before running it, replace `CHANGE-THIS-PASSWORD-TO-YOUR-OWN-STRONG-PASSWORD` with your own long, unique password** (preferably 16+ characters).
4. Copy Project URL and anon/public key from Project Settings → API.
5. In `index.html`, replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY`. Use the anon/public key only. Never use service-role key in client code.

## 2. Publish with GitHub Pages
1. Create a GitHub repo and upload `index.html`, `README.md`, and `supabase-setup.sql` to its root.
2. Settings → Pages → Deploy from a branch → choose `main` and `/ (root)` → Save.
3. Wait for the published URL and open it.

## How password-only login works
- Student responses are insert-only for public visitors.
- The admin password is stored as a bcrypt-style hash in a private schema in Supabase, not in the website source.
- Admin unlock sends the entered password to a PostgreSQL RPC function. It returns feedback only if the password matches.
- The password is kept in page memory while unlocked. Lock/logout or refreshing clears it.

## Change your password later
In Supabase SQL Editor, rerun the password-setting `INSERT ... ON CONFLICT` statement from the setup SQL after replacing the password text. It updates the stored hash.

**Security note:** This lightweight password-only RPC does not include rate limiting or CAPTCHA. Use a strong, unique password and do not share it. For higher-security use, use a server-side login with throttling.


Troubleshooting: this version explicitly grants the anon role INSERT privileges as well as its RLS policy. Both are required. If you still receive an error, send the exact Supabase error message from the browser console.
