# singleorigingames.com

Studio landing page for [Single Origin Games](https://singleorigingames.com).
Served by GitHub Pages, custom domain via Porkbun DNS, HTTPS via Let's
Encrypt.

## What lives here

| File | Purpose |
|---|---|
| `index.html` | Studio landing page |
| `app-ads.txt` | AdMob publisher verification (RFC IAB Tech Lab spec) |
| `CNAME` | GitHub Pages custom-domain pointer (one line: the domain) |

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

- Required files present (`index.html`, `app-ads.txt`, `CNAME`)
- `app-ads.txt` follows the IAB spec (one bad char = lost AdMob revenue)
- AdMob publisher ID present (`pub-7717083762897022`)
- CNAME is exactly `singleorigingames.com`
- `index.html` has DOCTYPE, charset, viewport, title

Same checks run in GitHub Actions on every push — local lets you catch
errors before they leave your machine.

## CI pipeline

GitHub Actions runs on every push to `main` (and every PR):

| Job | What it checks | Failure mode |
|---|---|---|
| `html-validation` | W3C-style HTML validity | Hard fail — broken HTML breaks the site |
| `app-ads-validation` | IAB spec format on `app-ads.txt` | Hard fail — bad format = AdMob de-verifies |
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

In `index.html`, duplicate the `.game` div block:

```html
<div class="game">
  <h2>NEW GAME NAME</h2>
  <p>One-line description.</p>
  <a href="https://play.google.com/store/apps/details?id=...">Get on Google Play →</a>
</div>
```

### Updating app-ads.txt

⚠️ Each line must follow the IAB spec EXACTLY:

```
ad_network_domain, publisher_id, DIRECT|RESELLER[, cert_id]
```

A single malformed line breaks AdMob's automated verification for ALL
configured ad networks on this domain. Run `./scripts/validate.ps1`
before pushing.
