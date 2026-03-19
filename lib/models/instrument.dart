class Instrument {
  final String ticker;
  final String name;
  final double pointValue;
  final String group; // 'Full Size' or 'Micro'

  const Instrument({
    required this.ticker,
    required this.name,
    required this.pointValue,
    required this.group,
  });
}

const List<Instrument> kAllInstruments = [
  // Full Size
  Instrument(ticker: 'ES',  name: 'E-mini S&P 500',   pointValue: 50,   group: 'Full Size'),
  Instrument(ticker: 'NQ',  name: 'E-mini Nasdaq',     pointValue: 20,   group: 'Full Size'),
  Instrument(ticker: 'GC',  name: 'Gold Futures',      pointValue: 10,   group: 'Full Size'),
  Instrument(ticker: '6E',  name: 'Euro FX',           pointValue: 12.5, group: 'Full Size'),
  Instrument(ticker: '6B',  name: 'British Pound',     pointValue: 6.25, group: 'Full Size'),
  // Micro
  Instrument(ticker: 'MES', name: 'Micro S&P 500',    pointValue: 5,    group: 'Micro'),
  Instrument(ticker: 'MNQ', name: 'Micro Nasdaq',     pointValue: 2,    group: 'Micro'),
  Instrument(ticker: 'MGC', name: 'Micro Gold',       pointValue: 1,    group: 'Micro'),
];
