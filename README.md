# Interactive-business-form

An interactive Business Model Canvas (نموذج العمل التجاري) for workshops: 20 project rooms, one per team, where students fill the nine canvas blocks together, see each other live, and download their canvas as a PDF.

## Features
- 20 project rooms, each with its own independent data
- The nine canvas blocks in the original layout, filled as sticky notes
- Save and edit, with a confirmation message; teammates' simultaneous saves are merged, not overwritten
- Live presence: who is in the room, named cursors on computers, “… is typing” per block
- Home page shows how many people are in each room
- One-page A4 PDF export of each team's canvas
- Works on phones and computers; designed for 100+ people at once on Supabase's free plan

## Run it
It is a static site: `index.html` and the files next to it, all in one folder.

- **Locally:** open `index.html` in a browser, or run `python3 -m http.server` in this folder and open http://localhost:8000
- **Online:** enable GitHub Pages for this repository (Settings → Pages → Deploy from branch → `main` / root). The site will be at `https://<user>.github.io/Interactive-business-form/`

## Database (Supabase)
The site reads and writes to a Supabase project. Its URL and public (publishable) key are at the top of the script in `index.html`. The publishable key is safe in the browser: Row Level Security only allows reading and updating the 20 project rows.

To use your own Supabase project, run `schema.sql` in the SQL editor, then replace `SUPABASE_URL` and `SUPABASE_KEY` in `index.html`.

## Capacity
Supabase's free plan allows 200 live connections and 100 realtime messages per second. The site stays inside that budget:
- Room counts on the home page come from a database heartbeat, not a shared live channel
- Each room has its own channel; presence carries only name and colour
- Cursor updates adapt to how many computers are online and pause automatically if there are too many (set `REALTIME_BUDGET` to ~400 on the Pro plan for smooth cursors at full load)
- Saving never depends on the live connection

Free Supabase projects pause after about a week without use; open the site a day before a workshop.

## Files
All files sit in the repository root:
- `index.html`: the whole app
- `noto-sans-arabic-*.woff2`: Noto Sans Arabic font (self-hosted)
- `supabase.js`: supabase-js (live presence)
- `html2canvas.min.js`, `jspdf.umd.min.js`: PDF export
- `schema.sql`: database tables, policies and functions
