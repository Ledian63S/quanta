# Quanta — Position Size Calculator
## Design Brief for Claude Code

---

## App Overview
Quanta is a CFD/Futures position size calculator built specifically for **Quantower** traders.
It calculates how many contracts to trade based on account risk, outputting whole numbers only (no fractional contracts in futures).

**Platform:** Flutter — iOS, Android, Desktop (Windows/macOS/Linux)
**Default values:** $50,000 balance, $300 risk per trade

---

## Design Language

### Aesthetic
- Inspired by **macOS Tahoe Liquid Glass** — clean, modern, premium
- **No header bar** — content breathes from top to bottom
- Light background: `#f4f6fb`
- Cards: white `#ffffff` with subtle border `#e2e8f2`

### Colors
```
Background:   #f4f6fb
Card:         #ffffff
Border:       #e2e8f2
Text:         #0a1020
Muted text:   #8a9cba
Accent cyan:  #00c2e0
Accent blue:  #2563eb
Navy dark:    #06101e
Navy mid:     #0c1e3a
Green:        #00d48a  (actual risk)
Orange:       #f59e0b  (unused risk)
```

### Typography
- UI font: **Manrope** (Google Fonts) — weights 400, 600, 700, 800
- Numbers font: **JetBrains Mono** (Google Fonts) — weights 400, 500, 600

### Active/Selected state
Dark navy gradient: `linear-gradient(135deg, #060e1e, #0b1e3c)`
Cyan border: `rgba(0, 194, 224, 0.3)`
Cyan glow shadow: `0 4px 14px rgba(0, 194, 224, 0.12)`

---

## Navigation
**Floating pill nav bar** — centered at bottom, dark navy background `#0a1428`
4 tabs with SVG icons + text labels:

| Tab | Icon | Label |
|-----|------|-------|
| 0 | Document/list icon | Calculator |
| 1 | Bar chart icon | Levels |
| 2 | Star icon | Instruments |
| 3 | Gear icon | Settings |

Active tab: cyan glow background `rgba(0,194,224,0.1)`, cyan label `#00c2e0`
Inactive tab: 28% opacity icon, muted label

---

## Screen 1 — Calculator (Main)

### Layout (top to bottom):
1. **Logo row** — Quanta logo mark (gradient blue→cyan rounded square) + "Quanta" name + "Calculator" subtitle
2. **Pre-filled chips row** (2 chips side by side):
   - Balance chip: shows `$50,000` (from settings)
   - Risk/Trade chip: shows `$300` (from settings), value in blue `#2563eb`
   - Each chip has a 2px gradient top border (blue→cyan accent line)
3. **"Instrument" label** + **scrollable horizontal row** of favorited instruments
   - Each instrument is a card button: ticker large, subtitle small
   - Selected = dark navy gradient + cyan border
   - Only favorited instruments appear here (default: MNQ only)
4. **"Stop Loss" label** + **large input card**
   - Unfocused: white card, muted label, large placeholder
   - Focused: dark navy gradient background, cyan accent line at bottom, white text
   - Font: JetBrains Mono 36px
   - Unit badge "pts" top right
5. **Result hero card** (appears when stop loss > 0, hidden otherwise):
   - Dark navy gradient background
   - Instrument name small text top
   - HUGE contract number (JetBrains Mono 56px white)
   - "contracts" label next to it
   - Bottom row: 3 cells — Max Risk (white/50%), Actual Risk (green #00d48a), Unused (orange #f59e0b)

### Key Logic:
```dart
// ALWAYS floor — no fractional contracts in futures
int contracts = (riskAmount / (stopLossPoints * pointValue)).floor();
double actualRisk = contracts * stopLossPoints * pointValue;
double unused = riskAmount - actualRisk;
```

---

## Screen 2 — Levels

### Layout:
1. Logo row (same as Calculator, subtitle "Levels")
2. **Summary card** — dark navy gradient, shows: instrument, contracts, stop loss, actual risk
3. **"Nearby Stop Levels" label**
4. **Table header** — POINTS | CONTRACTS | ACTUAL RISK
5. **Scrollable table** of nearby stop levels:
   - Range: current SL ± 3 points, in 0.5pt increments
   - Selected row (current SL): dark navy gradient highlight
   - Contracts column: bold, larger on highlighted row
   - Actual Risk column: green on highlighted row

---

## Screen 3 — Instruments

### Layout:
1. Logo row (subtitle "Instruments")
2. Two groups separated by section headers:

**Full Size** group:
| Ticker | Name | Point Value |
|--------|------|-------------|
| ES | E-mini S&P 500 | $50/pt |
| NQ | E-mini Nasdaq | $20/pt |
| GC | Gold Futures | $10/pt |
| 6E | Euro FX | $12.5/pt |
| 6B | British Pound | $6.25/pt |

**Micro** group:
| Ticker | Name | Point Value |
|--------|------|-------------|
| MES | Micro S&P 500 | $5/pt |
| MNQ | Micro Nasdaq | $2/pt |
| MGC | Micro Gold | $1/pt |

### Each instrument row:
- White card, rounded 16px
- Left: ticker (bold, 15px) + name + point value (cyan blue, JetBrains Mono)
- Right: star button (☆/★) — taps to toggle favorite
- Favorited rows: amber border tint `rgba(245,158,11,0.2)`
- Cannot unfavorite if it's the only favorite

### Default favorites: MNQ only

---

## Screen 4 — Settings

### Layout:
1. Logo row (subtitle "Settings")
2. **Account section:**
   - Account Balance (number input, default 50000)
   - Currency (shows "USD >", tappable for future)
3. **Risk section:**
   - Risk per Trade (number input, default 300, prefixed with $)
   - Note: Risk is always in USD (no % toggle needed)
4. **Preferences section:**
   - Remember Balance (toggle, default ON)
   - Remember Risk (toggle, default ON)
   - Remember Instrument (toggle, default ON)
5. **About section:**
   - Version: 1.0.0
   - "Built for Quantower" with cyan star

### Important: Settings changes update the Calculator screen chips instantly.

---

## Flutter Project Structure
```
lib/
  main.dart                    — app entry, theme setup
  theme/
    app_theme.dart             — colors, text styles, theme data
  models/
    instrument.dart            — Instrument model (ticker, name, pointValue)
    calculator_state.dart      — state model
  screens/
    calculator_screen.dart     — Screen 1
    levels_screen.dart         — Screen 2
    instruments_screen.dart    — Screen 3
    settings_screen.dart       — Screen 4
  widgets/
    floating_nav_bar.dart      — the pill nav bar
    info_chip.dart             — balance/risk chips
    instrument_button.dart     — instrument selector button
    stop_loss_input.dart       — the large input card
    result_hero.dart           — contracts result card
    levels_table.dart          — nearby levels table
    instrument_row.dart        — instrument list item with star
```

---

## State Management
Use **Provider** package.

```dart
class QuantaState extends ChangeNotifier {
  double accountBalance = 50000;
  double riskAmount = 300;       // Always USD
  String selectedInstrument = 'MNQ';
  double stopLossPoints = 0;
  Set<String> favorites = {'MNQ'};

  // Derived
  int get contracts => stopLossPoints > 0
    ? (riskAmount / (stopLossPoints * currentInstrument.pointValue)).floor()
    : 0;

  double get actualRisk => contracts * stopLossPoints * currentInstrument.pointValue;
  double get unusedRisk => riskAmount - actualRisk;
}
```

---

## pubspec.yaml dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1
  provider: ^6.1.1
  shared_preferences: ^2.2.2
```

---

## Key Design Rules for Claude Code
1. **Never show decimal contracts** — always `floor()`, never `round()`
2. **Results appear live** as stop loss is typed — no calculate button
3. **Only favorited instruments** appear in the Calculator instrument row
4. **Settings changes reflect immediately** in Calculator chips
5. **Floating pill nav** uses `SafeArea` + `Positioned` with `bottom: 16` — NEVER `position: fixed` or outside safe area. Wrap in `Padding(horizontal: 24)` so it never overflows on any screen size.
6. **JetBrains Mono** for ALL numbers — balance, risk, contracts, stop loss
7. **Active instrument card** uses dark navy gradient (not just a border change)
8. **Stop loss input card** transforms to dark navy when focused
9. The app has **no top app bar / no header** — just the logo row
10. Support both **light and dark mode** (dark mode: flip bg to `#0e1018`, cards to `#131a2e`)
11. **Content padding bottom = 100px** on all scrollable screens so pill nav never covers content
