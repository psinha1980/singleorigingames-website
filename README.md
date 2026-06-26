# singleorigingames.com

Studio site for [Single Origin Games](https://singleorigingames.com).
Static multi-page site served by GitHub Pages, custom domain via Porkbun
DNS, HTTPS via Let's Encrypt.

## What lives here

### Pages

| File | Purpose |
|---|---|
| `index.html` | Studio landing page (game cards link out to `games/`) |
| `about.html` | About the studio |
| `games/tycoon-era.html` | Tycoon Era game page |
| `privacy.html` | Privacy policy (studio-wide) |
| `support.html` | Support / contact |
| `404.html` | Not-found page (served by GitHub Pages) |

### Shared assets & config

| File | Purpose |
|---|---|
| `css/style.css` | Shared stylesheet for every page |
| `img/` | Logos, favicons, Apple touch icon, OG image, game icons |
| `app-ads.txt` | Unity Ads + LevelPlay reseller verification (IAB Tech Lab spec) |
| `CNAME` | GitHub Pages custom-domain pointer (one line: the domain) |
| `scripts/validate.ps1` | Local mirror of the CI validation checks |
| `.github/workflows/validate.yml` | CI validation pipeline |

## Local dev workflow

### One-time setup

1. Install [VS Code](https://code.visualstudio.com/)
2. Install the recommended extensions (VS Code will prompt when you open the folder):
   - **Live Server** — instant local preview with auto-reload
   - **EditorConfig** — enforces the project's whitespace rules
   - **Prettier** — auto-formats HTML on save
3. Copy `.vscode/settings.example.json` → `.vscode/settings.json` (gitignored — your local preferences)

### Daily workflow

```powershell
# Open the folder in VS Code
code .

# Right-click index.html → "Open with Live Server"
# OR: Ctrl+Shift+P → "Live Server: Open with Live Server"
# Browser opens at http://127.0.0.1:5500 with auto-reload on save.

# Edit, preview live, then:
./scripts/validate.ps1     # run the same checks as CI, locally
git add .
git commit -m "..."
git push                   # GitHub Pages redeploys in ~60 seconds
```

### What `validate.ps1` checks

- Required files present (`index.html`, `about.html`, `privacy.html`,
  `support.html`, `404.html`, `css/style.css`, `app-ads.txt`, `CNAME`)
- `app-ads.txt` follows the IAB spec (one bad char = LevelPlay/Unity verification fails)
- Unity Ads org core ID present (`13469858174961`)
- CNAME is exactly `singleorigingames.com`
- Every `.html` page has DOCTYPE, charset, viewport, title, and a
  `meta description` (404 exempt)
- Every internal `href="/..."` link resolves to a real file

Same checks run in GitHub Actions on every push — local lets you catch
errors before they leave your machine.

## CI pipeline

GitHub Actions runs on every push to `main` (and every PR):

| Job | What it checks | Failure mode |
|---|---|---|
| `html-validation` | W3C-style HTML validity | Hard fail — broken HTML breaks the site |
| `app-ads-validation` | IAB spec format on `app-ads.txt` | Hard fail — bad format = LevelPlay/Unity de-verifies |
| `link-check` | Every internal + external link resolves | Soft fail — external sites flake |
| `lighthouse` | Performance/accessibility/SEO score | Advisory only — trends matter more than thresholds |

Workflow: `.github/workflows/validate.yml`

To see results: GitHub repo → **Actions** tab → click the latest run.

## Production setup

| Layer | Service | Notes |
|---|---|---|
| Domain | Porkbun (`singleorigingames.com`) | 4 A records (`185.199.108-111.153`) + CNAME `www → psinha1980.github.io.` |
| Hosting | GitHub Pages | Source: `main` branch / `(root)` |
| SSL | Let's Encrypt via GitHub Pages | Auto-renewed every 90 days |
| Email | Porkbun forwarding | `*@singleorigingames.com` → personal Gmail (if set up) |

## Updating the site

### Just want to fix a typo?

```powershell
code index.html
# ...edit...
./scripts/validate.ps1
git commit -am "fix: typo on tagline"
git push
```

Live in ~60 seconds.

### Adding a new game?

Two steps:

1. **Create the game page.** Copy `games/tycoon-era.html` to
   `games/<your-game>.html` and update the title, `meta description`,
   copy, icon, and store link. It already pulls in `css/style.css`, so
   it matches the rest of the site.

2. **Link it from the homepage.** In `index.html`, duplicate an existing
   `.game-card` inside the `.games` grid and point it at the new page:

   ```html
   <a href="/games/your-game.html" class="game-card">
     <span class="game-card__badge game-card__badge--live">Available now</span>
     <h3>Your Game Name</h3>
     <p class="game-card__desc">One-line description.</p>
     <div class="game-card__meta">
       <span class="game-card__chip">Idle</span>
       <span class="game-card__chip">Free</span>
     </div>
     <span class="btn btn--secondary">Read more →</span>
   </a>
   ```

   For a not-yet-released game, use a non-linking `<div class="game-card">`
   with the `game-card__badge--soon` badge (see the Fleet Magnate card).

Run `./scripts/validate.ps1` before pushing — the internal-link check
will fail if the card points at a page that doesn't exist yet.

### Updating app-ads.txt

⚠️ Each line must follow the IAB spec EXACTLY:

```
ad_network_domain, publisher_id, DIRECT|RESELLER[, cert_id]
```

A single malformed line breaks LevelPlay's / Unity Ads' automated
verification for ALL configured ad networks on this domain. Run
`./scripts/validate.ps1` before pushing.

The bulk RESELLER list is generated by LevelPlay (ironSource) dashboard
→ Account → app-ads.txt manager. Re-fetch monthly to capture new
networks LevelPlay onboards.
