# HAL-1000 Navbar & Themes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a themed top navbar to all 3 HTML guides and replace `hal-verification.html` with a DOS/BIOS theme.

**Architecture:** Each page gets a `.topnav` fixed bar (40px) inserted right after `<body>`. Existing `.sidebar` shifts down by `--topnav-h`. No JS needed — active state is hardcoded per file. `hal-verification.html` gets a full CSS overhaul; the other two pages only add navbar CSS.

**Tech Stack:** Plain HTML/CSS. No build tools. Verify by opening files in browser.

---

### Task 1: Add topnav to pi-homelab-guide.html

**Files:**
- Modify: `pi-homelab-guide.html`

- [ ] **Step 1: Add `--topnav-h` variable and topnav CSS after the existing `:root` block**

In the `<style>` block, find the line `:root {` and its closing `}`. After the `:root` block ends, insert:

```css
/* ══ TOP NAV ════════════════════════════ */
:root { --topnav-h: 40px; }
.topnav{
  position:fixed;top:0;left:0;right:0;
  height:var(--topnav-h);
  background:var(--bg2);
  border-bottom:1px solid var(--border);
  display:flex;align-items:center;
  padding:0 16px;gap:0;
  z-index:300;
}
.topnav-brand{
  font-family:'Space Mono',monospace;
  font-size:0.62rem;letter-spacing:0.22em;
  color:var(--hal);text-transform:uppercase;
  margin-right:20px;flex-shrink:0;
}
.topnav-links{display:flex;gap:2px;align-items:center}
.topnav-link{
  font-family:'Rajdhani',sans-serif;
  font-size:0.72rem;letter-spacing:0.12em;
  text-transform:uppercase;
  color:var(--text-dim);text-decoration:none;
  padding:4px 12px;border-radius:2px;
  transition:color 0.15s,background 0.15s;
}
.topnav-link:hover{color:var(--text);background:var(--bg3)}
.topnav-link.active{color:var(--hal);background:var(--hal-glow2)}
```

- [ ] **Step 2: Update sidebar top offset**

Find:
```css
.sidebar{
  position:fixed;
  left:0;top:0;bottom:0;
```

Change `top:0` to `top:var(--topnav-h)`:
```css
.sidebar{
  position:fixed;
  left:0;top:var(--topnav-h);bottom:0;
```

- [ ] **Step 3: Push main content down**

Find:
```css
.main{
  margin-left:var(--sidebar-w);
  min-height:100vh;
  padding-bottom:80px;
}
```

Add `padding-top:var(--topnav-h);`:
```css
.main{
  margin-left:var(--sidebar-w);
  min-height:100vh;
  padding-top:var(--topnav-h);
  padding-bottom:80px;
}
```

- [ ] **Step 4: Update mobile bar and main in the responsive block**

Find the responsive section `@media(max-width:768px)` and locate `.mobile-bar` and `.main` inside it. Update:

```css
@media(max-width:768px){
  .sidebar{transform:translateX(-100%)}
  .sidebar.open{transform:translateX(0)}
  .sidebar-overlay.open{display:block}
  .mobile-bar{display:flex;top:var(--topnav-h)}
  .main{margin-left:0;padding-top:calc(var(--topnav-h) + 44px)}
  ...
}
```

(Only the `top` on `.mobile-bar` and `padding-top` on `.main` change — leave all other declarations in this block intact.)

- [ ] **Step 5: Insert topnav HTML right after `<body>`**

Find `<body>` (around line 1040). Insert immediately after:

```html
<!-- ══ TOPNAV ═══════════════════════════ -->
<div class="topnav">
  <span class="topnav-brand">HAL-1000</span>
  <nav class="topnav-links">
    <a href="pi-homelab-guide.html" class="topnav-link active">Pi Setup</a>
    <a href="traefik-guide.html" class="topnav-link">Traefik</a>
    <a href="hal-verification.html" class="topnav-link">Verification</a>
  </nav>
</div>
```

- [ ] **Step 6: Verify**

Open `pi-homelab-guide.html` in browser. Confirm: topnav bar visible at top, "Pi Setup" highlighted, sidebar starts below nav, content not obscured.

---

### Task 2: Add topnav to traefik-guide.html

**Files:**
- Modify: `traefik-guide.html`

- [ ] **Step 1: Add topnav CSS after the `:root` block**

```css
/* ══ TOP NAV ════════════════════════════ */
:root { --topnav-h: 40px; }
.topnav{
  position:fixed;top:0;left:0;right:0;
  height:var(--topnav-h);
  background:linear-gradient(180deg,var(--metal-top) 0%,var(--metal-bot) 100%);
  border-bottom:1px solid #9898a8;
  box-shadow:0 1px 3px rgba(0,0,0,0.12),inset 0 1px 0 rgba(255,255,255,0.5);
  display:flex;align-items:center;
  padding:0 16px;gap:0;
  z-index:300;
}
.topnav-brand{
  font-family:'Inter',sans-serif;
  font-size:0.72rem;font-weight:700;
  color:var(--metal-text);letter-spacing:0.05em;
  margin-right:20px;flex-shrink:0;
}
.topnav-links{display:flex;gap:2px}
.topnav-link{
  font-family:'Inter',sans-serif;
  font-size:0.72rem;font-weight:500;
  color:var(--text-dim);text-decoration:none;
  padding:3px 10px;border-radius:4px;
  transition:color 0.15s,background 0.15s;
}
.topnav-link:hover{color:var(--text);background:rgba(0,0,0,0.07)}
.topnav-link.active{
  color:var(--accent);background:var(--accent-glow);
  font-weight:600;
}
```

- [ ] **Step 2: Update sidebar top offset**

Find:
```css
.sidebar{
  position:fixed;
  left:0;top:0;bottom:0;
```

Change to:
```css
.sidebar{
  position:fixed;
  left:0;top:var(--topnav-h);bottom:0;
```

- [ ] **Step 3: Push main content down**

Find:
```css
.main{
  margin-left:var(--sidebar-w);
  min-height:100vh;
  padding-bottom:80px;
}
```

Add `padding-top:var(--topnav-h);`:
```css
.main{
  margin-left:var(--sidebar-w);
  min-height:100vh;
  padding-top:var(--topnav-h);
  padding-bottom:80px;
}
```

- [ ] **Step 4: Update mobile bar in responsive block**

Inside `@media(max-width:768px)`, update `.mobile-bar` and `.main`:
```css
  .mobile-bar{display:flex;top:var(--topnav-h)}
  .main{margin-left:0;padding-top:calc(var(--topnav-h) + 44px)}
```

- [ ] **Step 5: Insert topnav HTML right after `<body>`**

```html
<!-- ══ TOPNAV ═══════════════════════════ -->
<div class="topnav">
  <span class="topnav-brand">HAL-1000</span>
  <nav class="topnav-links">
    <a href="pi-homelab-guide.html" class="topnav-link">Pi Setup</a>
    <a href="traefik-guide.html" class="topnav-link active">Traefik</a>
    <a href="hal-verification.html" class="topnav-link">Verification</a>
  </nav>
</div>
```

- [ ] **Step 6: Remove the old back-link**

Find and remove this line from the sidebar HTML:
```html
    <a href="pi-homelab-guide.html" class="hal-back-link">HAL-1000 Pi-hole Guide</a>
```

(The topnav replaces this.)

- [ ] **Step 7: Verify**

Open `traefik-guide.html` in browser. Confirm: brushed-metal topnav visible, "Traefik" highlighted in blue, sidebar/content correctly offset.

---

### Task 3: Restyle hal-verification.html to DOS/BIOS theme + add topnav

**Files:**
- Modify: `hal-verification.html`

- [ ] **Step 1: Replace the entire `<style>` block**

Replace everything between `<style>` and `</style>` with the following. This preserves all class/ID names and structure but applies the DOS/BIOS visual theme:

```css
* { margin: 0; padding: 0; box-sizing: border-box; }

:root {
  --bg:          #0000aa;
  --bg2:         #000088;
  --bg3:         #0000cc;
  --bg4:         #1111bb;
  --border:      #4444cc;
  --border2:     #6666ee;
  --text:        #ffffff;
  --text-dim:    #aaaaff;
  --text-faint:  #6666cc;
  --hal:         #ffff55;
  --hal-dim:     #cccc00;
  --hal-glow:    rgba(255,255,85,0.12);
  --amber:       #ff9900;
  --blue-bright: #55ffff;
  --green-ok:    #55ff55;
  --red-err:     #ff5555;
  --topnav-h:    40px;
  --sidebar-w:   250px;
}

html { scroll-behavior: smooth; }

body {
  background: var(--bg);
  color: var(--text);
  font-family: 'Courier New', 'Lucida Console', Courier, monospace;
  font-size: 14px;
  line-height: 1.6;
  min-height: 100vh;
}

/* ===== TOP NAV ===== */
.topnav {
  position: fixed;
  top: 0; left: 0; right: 0;
  height: var(--topnav-h);
  background: #000088;
  border-bottom: 2px solid #aaaaaa;
  display: flex; align-items: center;
  padding: 0 16px; gap: 0;
  z-index: 300;
}
.topnav-brand {
  font-family: 'Courier New', monospace;
  font-size: 13px; font-weight: bold;
  color: #ffff55; letter-spacing: 2px;
  text-transform: uppercase;
  margin-right: 24px; flex-shrink: 0;
}
.topnav-links { display: flex; gap: 0; }
.topnav-link {
  font-family: 'Courier New', monospace;
  font-size: 12px; letter-spacing: 1px;
  text-transform: uppercase;
  color: #aaaaff; text-decoration: none;
  padding: 4px 12px;
  transition: color 0.1s, background 0.1s;
}
.topnav-link:hover { color: #ffffff; background: #0000cc; }
.topnav-link.active { color: #ffff55; background: #0000cc; }

/* ===== LAYOUT ===== */
.container {
  display: flex;
  min-height: 100vh;
  padding-top: var(--topnav-h);
}

/* ===== SIDEBAR ===== */
.sidebar {
  width: var(--sidebar-w);
  background: var(--bg2);
  border-right: 2px solid #aaaaaa;
  padding: 16px;
  position: fixed;
  top: var(--topnav-h);
  height: calc(100vh - var(--topnav-h));
  overflow-y: auto;
  z-index: 100;
}

.sidebar::-webkit-scrollbar { width: 6px; }
.sidebar::-webkit-scrollbar-track { background: var(--bg3); }
.sidebar::-webkit-scrollbar-thumb { background: var(--hal-dim); border-radius: 0; }

.hal-logo {
  display: block;
  margin-bottom: 20px;
  text-decoration: none;
  color: var(--hal);
  font-weight: bold;
  font-size: 13px;
  letter-spacing: 2px;
  text-transform: uppercase;
  padding: 6px 8px;
  background: #000055;
  border: 1px solid #aaaaaa;
}

.nav-section { margin-bottom: 20px; }

.nav-label {
  font-size: 11px;
  color: #000088;
  background: #aaaaaa;
  text-transform: uppercase;
  letter-spacing: 1px;
  padding: 2px 6px;
  font-weight: bold;
  margin-bottom: 6px;
  display: block;
}

.nav-links { display: flex; flex-direction: column; gap: 0; }

.nav-links a {
  padding: 5px 8px;
  color: var(--text-dim);
  text-decoration: none;
  font-size: 12px;
  letter-spacing: 0.5px;
  border-left: 2px solid transparent;
  transition: color 0.1s, background 0.1s;
  display: block;
}

.nav-links a:hover {
  color: var(--hal);
  background: var(--bg3);
  border-left-color: var(--hal);
}

.nav-links a.active {
  color: var(--hal);
  background: var(--bg3);
  border-left-color: var(--hal);
}

.sidebar-footer {
  border-top: 1px solid var(--border);
  padding-top: 14px;
  margin-top: auto;
  font-size: 11px;
  color: var(--text-dim);
  letter-spacing: 0.5px;
}

.sidebar-footer a { color: var(--blue-bright); text-decoration: none; margin-right: 8px; }
.sidebar-footer a:hover { text-decoration: underline; }

/* ===== MAIN CONTENT ===== */
.main {
  margin-left: var(--sidebar-w);
  flex: 1;
  background: var(--bg);
}

.header {
  background: #000088;
  border-bottom: 2px solid #aaaaaa;
  padding: 20px 30px;
  margin-bottom: 30px;
}

.header h1 {
  font-size: 20px;
  margin-bottom: 8px;
  color: var(--hal);
  letter-spacing: 2px;
  text-transform: uppercase;
}

.header p { color: var(--text-dim); font-size: 13px; }

.content {
  max-width: 1000px;
  margin: 0 auto;
  padding: 0 30px 60px;
}

/* ===== SECTIONS ===== */
section {
  margin-bottom: 40px;
  scroll-margin-top: calc(var(--topnav-h) + 20px);
}

section h2 {
  font-size: 13px;
  color: #0000aa;
  background: #aaaaaa;
  padding: 4px 10px;
  font-weight: bold;
  letter-spacing: 2px;
  text-transform: uppercase;
  margin-bottom: 16px;
  border: none;
  display: block;
}

section h3 {
  font-size: 14px;
  color: var(--hal);
  margin-top: 20px;
  margin-bottom: 10px;
  font-weight: bold;
  letter-spacing: 1px;
}

section p { margin-bottom: 12px; color: var(--text); line-height: 1.7; }

section ul, section ol { margin: 12px 0 12px 22px; color: var(--text); }
section li { margin-bottom: 8px; line-height: 1.6; }

/* ===== BLOCKS ===== */
.start-here {
  background: #000055;
  border-left: 4px solid var(--hal);
  padding: 16px;
  margin: 16px 0;
}

.start-here h3 { color: var(--hal); margin-top: 0; }

.verify, .trouble {
  margin: 16px 0;
  border: 1px solid var(--border2);
  overflow: hidden;
}

.verify { border-left: 4px solid var(--green-ok); }
.trouble { border-left: 4px solid var(--amber); }

.verify > summary, .trouble > summary {
  padding: 10px 14px;
  cursor: pointer;
  background: var(--bg2);
  user-select: none;
  font-weight: bold;
  font-size: 13px;
  display: flex; align-items: center; gap: 8px;
  letter-spacing: 0.5px;
}

.verify > summary { color: var(--green-ok); }
.trouble > summary { color: var(--amber); }
.verify > summary::before { content: "[OK]"; font-weight: bold; }
.trouble > summary::before { content: "[!!]"; font-weight: bold; }

.verify > summary::after, .trouble > summary::after {
  content: ""; margin-left: auto;
  width: 0; height: 0;
  border-left: 5px solid transparent;
  border-right: 5px solid transparent;
  border-top: 6px solid currentColor;
  opacity: 0.7;
}

details[open] > summary::after { transform: rotate(180deg); }
details > summary::-webkit-details-marker { display: none; }

.verify > div, .trouble > div {
  padding: 16px;
  border-top: 1px solid var(--border);
  background: var(--bg);
}

.verify > div ul, .trouble > div ul { margin: 0; padding: 0; list-style: none; }

.verify > div li, .trouble > div li {
  padding: 8px 0;
  border-bottom: 1px solid var(--border);
  display: flex; align-items: center; gap: 10px;
  font-size: 13px;
}

.verify > div li:last-child, .trouble > div li:last-child { border-bottom: none; }
.verify > div li::before { content: " OK "; color: #000; background: var(--green-ok); font-weight: bold; min-width: 36px; text-align: center; font-size: 11px; }
.trouble > div li::before { content: "WARN"; color: #000; background: var(--amber); font-weight: bold; min-width: 36px; text-align: center; font-size: 11px; }

/* ===== VARIABLES PANEL ===== */
.variables-panel {
  background: var(--bg2);
  border: 1px solid #aaaaaa;
  padding: 14px;
  margin-bottom: 24px;
}

.variables-panel h4 {
  font-size: 11px;
  color: #000088;
  background: #aaaaaa;
  text-transform: uppercase;
  letter-spacing: 1px;
  padding: 2px 6px;
  margin-bottom: 12px;
  font-weight: bold;
  display: block;
}

.var-inputs { display: flex; gap: 12px; flex-wrap: wrap; }
.var-input { display: flex; align-items: center; gap: 8px; }
.var-input label { font-size: 12px; color: var(--text-dim); font-weight: bold; }

.var-input input {
  background: #000033;
  border: 1px solid #aaaaaa;
  color: var(--hal);
  padding: 4px 8px;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  min-width: 160px;
  letter-spacing: 0.5px;
}

.var-input input:focus {
  outline: none;
  border-color: var(--hal);
  box-shadow: 0 0 0 1px var(--hal);
}

/* ===== CODE BLOCKS ===== */
.code-block {
  background: #000000;
  border: 1px solid #4444cc;
  padding: 14px;
  margin: 12px 0;
  overflow-x: auto;
  position: relative;
  font-family: 'Courier New', Courier, monospace;
  font-size: 13px;
  line-height: 1.5;
}

.code-block code {
  display: block;
  color: var(--hal);
  word-wrap: break-word;
  white-space: pre-wrap;
}

.code-block .cm   { color: #666666; }
.code-block .str  { color: #55ff55; }
.code-block .key  { color: #55ffff; }
.code-block .flag { color: #ff9900; }

.copy-btn {
  position: absolute;
  top: 8px; right: 8px;
  background: #000055;
  color: var(--text-dim);
  border: 1px solid #4444cc;
  padding: 4px 10px;
  cursor: pointer;
  font-size: 11px;
  font-family: 'Courier New', monospace;
  font-weight: bold;
  letter-spacing: 1px;
  transition: all 0.1s;
}

.copy-btn:hover { background: #0000cc; color: var(--hal); border-color: var(--hal); }
.copy-btn.copied { background: #005500; color: var(--green-ok); border-color: var(--green-ok); }

/* ===== TABLES ===== */
table { width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 13px; }

table th {
  background: #aaaaaa;
  color: #0000aa;
  padding: 8px 12px;
  text-align: left;
  font-weight: bold;
  font-size: 11px;
  letter-spacing: 1px;
  text-transform: uppercase;
  border-bottom: 2px solid #888888;
}

table td { padding: 8px 12px; border-bottom: 1px solid var(--border); }
table tr:hover { background: var(--bg2); }

/* ===== TOOLBAR ===== */
.toolbar {
  position: fixed;
  bottom: 24px; right: 24px;
  display: flex; gap: 8px;
  z-index: 99;
}

.toolbar button {
  width: 40px; height: 40px;
  border: 2px solid #aaaaaa;
  background: #000088;
  color: var(--text);
  cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  font-size: 14px;
  font-family: 'Courier New', monospace;
  transition: all 0.1s;
}

.toolbar button:hover { background: #0000cc; border-color: var(--hal); color: var(--hal); }

/* ===== MOBILE ===== */
.mobile-toggle {
  display: none;
  position: fixed;
  top: calc(var(--topnav-h) + 10px);
  left: 10px;
  width: 38px; height: 38px;
  background: #000088;
  border: 2px solid #aaaaaa;
  color: var(--text);
  font-size: 16px;
  cursor: pointer;
  z-index: 101;
  align-items: center; justify-content: center;
}

a { color: var(--blue-bright); }
a:hover { color: var(--hal); }

@media (max-width: 768px) {
  .sidebar {
    position: fixed;
    left: -250px;
    top: var(--topnav-h);
    height: calc(100vh - var(--topnav-h));
    transition: left 0.3s;
    z-index: 102;
  }
  .sidebar.open { left: 0; }
  .main { margin-left: 0; }
  .mobile-toggle { display: flex; }
  .header { padding: 14px 20px; }
  .header h1 { font-size: 16px; }
  .content { padding: 0 16px 60px; }
  .toolbar { bottom: 12px; right: 12px; }
  .var-inputs { flex-direction: column; }
  .var-input { width: 100%; }
  .var-input input { flex: 1; min-width: 0; }
}

::-webkit-scrollbar { width: 8px; }
::-webkit-scrollbar-track { background: var(--bg2); }
::-webkit-scrollbar-thumb { background: #4444cc; border-radius: 0; }
::-webkit-scrollbar-thumb:hover { background: var(--hal-dim); }
```

- [ ] **Step 2: Replace the Google Fonts link in `<head>`**

Find:
```html
    <link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@400;500;700&family=Space+Mono:wght@400;700&display=swap" rel="stylesheet">
```

Replace with (Space Mono kept for code consistency, Rajdhani dropped):
```html
    <link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&display=swap" rel="stylesheet">
```

(Share Tech Mono gives a slightly cleaner retro terminal feel; if font fails, Courier New fallback kicks in.)

- [ ] **Step 3: Update the page title**

Find:
```html
    <title>HAL-1000 Verification Guide — Health Check & Troubleshooting</title>
```

Replace with:
```html
    <title>HAL-1000 :: DIAGNOSTIC UTILITY v1.0</title>
```

- [ ] **Step 4: Insert topnav HTML**

Find `<body>` (around line 610) and insert immediately after:

```html
<div class="topnav">
  <span class="topnav-brand">HAL-1000</span>
  <nav class="topnav-links">
    <a href="pi-homelab-guide.html" class="topnav-link">Pi Setup</a>
    <a href="traefik-guide.html" class="topnav-link">Traefik</a>
    <a href="hal-verification.html" class="topnav-link active">Verification</a>
  </nav>
</div>
```

- [ ] **Step 5: Update sidebar HAL logo / header**

Find:
```html
        <a href="#" class="hal-logo">
            <svg class="hal-eye" ...>...</svg>
            HAL-1000
        </a>
```

Replace with:
```html
        <a href="#" class="hal-logo">HAL-1000 DIAGNOSTIC UTILITY</a>
```

(Removes the HAL red-eye SVG that belongs to the 2001 theme.)

- [ ] **Step 6: Update the page header**

Find:
```html
        <div class="header">
            <h1>HAL-1000 Verification Guide</h1>
            <p>Health check, troubleshooting, and diagnostic reference for Pi-hole + Traefik stack</p>
        </div>
```

Replace with:
```html
        <div class="header">
            <h1>HAL-1000 DIAGNOSTIC UTILITY v1.0</h1>
            <p>C:\HAL&gt; RUNNING SYSTEM HEALTH CHECK... Press any key to continue_</p>
        </div>
```

- [ ] **Step 7: Wrap content in .container and verify structure**

The current HTML structure is:
```html
<body>
  <button class="mobile-toggle">
  <div class="sidebar">
  <div class="main">
    <div class="header">
    <div class="content">
```

It should be:
```html
<body>
  <div class="topnav">       ← inserted in Step 4
  <button class="mobile-toggle">
  <div class="container">    ← wrap sidebar + main
    <div class="sidebar">
    <div class="main">
      ...
    </div>
  </div>
```

Find `<button class="mobile-toggle"` and add `<div class="container">` immediately before `<div class="sidebar"`. Close it just before `</body>`.

- [ ] **Step 8: Remove the "Related Guides" sidebar section**

The topnav replaces this. Find and remove:
```html
        <div class="nav-section">
            <div class="nav-label">Related Guides</div>
            <div class="nav-links">
                <a href="pi-homelab-guide.html">PI Homelab Setup</a>
                <a href="traefik-guide.html">Traefik v3 Proxy</a>
            </div>
        </div>
```

- [ ] **Step 9: Verify**

Open `hal-verification.html` in browser. Confirm:
- Cobalt blue background throughout
- Yellow section headers (BIOS-style grey bars)
- Black code blocks with yellow text
- DOS topnav with "Verification" highlighted in yellow
- All sections readable and correctly laid out

---

### Task 4: Commit

**Files:**
- All 3 HTML files + spec and plan docs

- [ ] **Step 1: Stage and commit**

```bash
cd /Users/alexandermervar/Projects/hal-1000
git add pi-homelab-guide.html traefik-guide.html hal-verification.html docs/superpowers/
git commit -m "feat: add cross-page topnav and DOS/BIOS theme for verification guide"
```
