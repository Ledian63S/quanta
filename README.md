# Quanta — Position Size Calculator

A clean, modern CFD/Futures position size calculator built for **Quantower** traders. Calculate exactly how many contracts to trade based on your account size and risk tolerance — always whole numbers, never fractional.

---

## Screenshots

_Coming soon_

---

## Features

- **Instant calculation** — results update live as you type your stop loss
- **Always floors contracts** — no rounding up, no fractional contracts
- **4 screens** — Calculator, Levels, Instruments, Settings
- **Nearby Levels table** — see contracts and actual risk for stop levels ±3 points
- **Instrument management** — star/unstar instruments, only favorites appear in the calculator
- **Persistent settings** — balance, risk, and selected instrument remembered across sessions
- **Dark mode support**

## Supported Instruments

| Ticker | Name | Point Value |
|--------|------|-------------|
| ES | E-mini S&P 500 | $50/pt |
| NQ | E-mini Nasdaq | $20/pt |
| GC | Gold Futures | $10/pt |
| 6E | Euro FX | $12.50/pt |
| 6B | British Pound | $6.25/pt |
| MES | Micro S&P 500 | $5/pt |
| MNQ | Micro Nasdaq | $2/pt |
| MGC | Micro Gold | $1/pt |

---

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) SDK ≥ 3.0.0
- Android Studio or Xcode (for iOS)

### Run

```bash
git clone https://github.com/Ledian63S/quanta.git
cd quanta
flutter pub get
flutter run
```

---

## Tech Stack

- **Flutter** — iOS & Android
- **Provider** — state management
- **Google Fonts** — Manrope (UI) + JetBrains Mono (numbers)
- **Shared Preferences** — persistent storage

---

## Calculation Logic

```dart
// Always floor — no fractional contracts in futures
int contracts = (riskAmount / (stopLossPoints * pointValue)).floor();
double actualRisk = contracts * stopLossPoints * pointValue;
double unused = riskAmount - actualRisk;
```

---

## License

MIT — see [LICENSE](LICENSE)
