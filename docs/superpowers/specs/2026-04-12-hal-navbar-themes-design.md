# HAL-1000 Cross-Page Navbar & Theme Design

## Problem
Three HTML documentation guides exist for the hal-1000 homelab project. There is no consistent cross-page navigation, making it hard to move between guides. Additionally, `hal-verification.html` shares the same HAL/2001 dark-red theme as `pi-homelab-guide.html`, leaving it without a distinct identity.

## Solution

### 1. Top Navbar (all 3 pages)
A slim fixed bar (40px tall) at the top of every page links all three guides. It sits above the existing left sidebar and main content, styled to match each page's theme. The active page is visually highlighted.

- `pi-homelab-guide.html` → HAL/2001 bar: dark bg2 background, HAL red active state, Space Mono brand
- `traefik-guide.html` → macOS Aqua bar: brushed-metal gradient, Inter font, blue active state
- `hal-verification.html` → DOS/BIOS bar: cobalt blue, yellow active state, Courier New

All three sidebars shift down by `--topnav-h: 40px` to accommodate the new bar.

### 2. hal-verification.html → MS-DOS / Award BIOS Theme
Full CSS replacement. Existing HTML structure stays intact.

| Element | Style |
|---|---|
| Body | `#0000aa` cobalt blue bg, white text, Courier New |
| Section h2 | Grey bar (`#aaaaaa` bg, `#0000aa` text) — BIOS header style |
| Code blocks | Black bg, yellow text (`#ffff55`) |
| Links | Bright cyan (`#55ffff`) |
| OK states | Bright green (`#55ff55`) |
| Error states | Bright red (`#ff5555`) |
| Warning/trouble | Orange (`#ff9900`) |
| Sidebar | Dark blue (`#000088`) with BIOS-style category labels |

## Files Changed
- `pi-homelab-guide.html` — add topnav CSS + HTML, adjust sidebar/main offsets
- `traefik-guide.html` — add topnav CSS + HTML, adjust sidebar/main offsets
- `hal-verification.html` — full theme replacement + topnav CSS + HTML
