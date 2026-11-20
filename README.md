# UoM UIP Student Hub

A student-built academic platform for the **Bachelor of Science Honours in Urban Informatics & Planning (2024/2028)** at the Department of Town & Country Planning, University of Moratuwa.

**Live Site:** https://sasiru807.github.io/uom-uip-hub/

## Features
- **Curriculum & Module Explorer:** Search and filter all 69 handbook modules (`PL1101`–`PL4807`) by level, semester, type, GIS/Tech track, 100% CA, and high-stakes `C+` studio/ISRP pass thresholds.
- **Notes & Past Papers:** Share and browse Google Drive links organized by module code, backed by Supabase.
- **GIS, Remote Sensing & Coding Spine:** Track personal mastery across all 10 informatics & quantitative modules (`PL1106` through `PL4806`), synced per student.
- **Semester GPA & Risk Simulator:** Exact UoM 4.20 scale (`A+` to `F`), automatic NGPA/`N` exclusion, Dean's List (`3.80+`) check, and `C+` studio/ISRP alerts.
- **Handbook Criteria & Charts:** Credit distribution, CA/WE balance, attendance (`80%`), add/drop (`2 weeks`), and Class cutoffs.
- **UoM-Only Access & Admin Panel:** Magic Link sign-in restricted strictly to `@uom.lk` emails, with full Admin moderation privileges for `bandarahmsh.25@uom.lk`.

## Quick Launch Setup
1. **Run the SQL Schema:** In your Supabase dashboard, open **SQL Editor → New Query**, paste `uom_uip_supabase_schema.sql`, and click **Run**.
2. **Set Auth Redirect URL:** Under **Authentication → URL Configuration**, set **Site URL** and **Redirect URLs** to `https://sasiru807.github.io/uom-uip-hub/`.
3. **Add Your Supabase Keys:** Open `index.html`, replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` near the top of the `<script>` tag with your values from **Project Settings → API**.
4. **Upload to GitHub:** Upload `index.html`, `uom_uip_supabase_schema.sql`, and `README.md` to the root of `sasiru807/uom-uip-hub` (`main` branch). GitHub Pages will publish automatically within 1–2 minutes.
