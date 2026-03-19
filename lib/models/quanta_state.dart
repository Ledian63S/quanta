import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'instrument.dart';

class QuantaState extends ChangeNotifier {
  double accountBalance = 50000;
  double riskAmount = 300;       // persisted setting
  double? _sessionRisk;          // temporary override, not persisted
  double get effectiveRisk => _sessionRisk ?? riskAmount;
  String selectedTicker = 'MNQ';
  double stopLossPoints = 0;
  Set<String> favorites = {'MNQ'};

  // Appearance
  ThemeMode themeMode = ThemeMode.light;

  // Settings toggles
  bool rememberBalance = true;
  bool rememberRisk = true;
  bool rememberInstrument = true;

  Instrument get currentInstrument =>
      kAllInstruments.firstWhere((i) => i.ticker == selectedTicker,
          orElse: () => kAllInstruments.first);

  List<Instrument> get favoriteInstruments =>
      kAllInstruments.where((i) => favorites.contains(i.ticker)).toList();

  // Core calculation — ALWAYS floor, never round
  int get contracts => stopLossPoints > 0
      ? (effectiveRisk / (stopLossPoints * currentInstrument.pointValue)).floor()
      : 0;

  double get actualRisk =>
      contracts * stopLossPoints * currentInstrument.pointValue;

  double get unusedRisk => effectiveRisk - actualRisk;

  // Nearby levels for Levels screen — ±20 pts in 0.5pt steps
  List<double> get nearbyStopLevels {
    if (stopLossPoints <= 0) return [];
    final sl = stopLossPoints;
    final levels = <double>[];
    for (double step = -20.0; step <= 20.0; step += 0.5) {
      final val = double.parse((sl + step).toStringAsFixed(1));
      if (val > 0) levels.add(val);
    }
    return levels;
  }

  int contractsForStop(double sl) =>
      sl > 0 ? (riskAmount / (sl * currentInstrument.pointValue)).floor() : 0;

  double actualRiskForStop(double sl) =>
      contractsForStop(sl) * sl * currentInstrument.pointValue;

  void setBalance(double value) {
    accountBalance = value;
    notifyListeners();
    _save();
  }

  void setRisk(double value) {
    riskAmount = value;
    notifyListeners();
    _save();
  }

  void setSessionRisk(double value) {
    _sessionRisk = value;
    notifyListeners();
  }

  void setInstrument(String ticker) {
    selectedTicker = ticker;
    notifyListeners();
    _save();
  }

  void setStopLoss(double value) {
    stopLossPoints = value;
    notifyListeners();
  }

  void toggleFavorite(String ticker) {
    if (favorites.contains(ticker)) {
      if (favorites.length == 1) return; // keep at least one
      favorites.remove(ticker);
      if (selectedTicker == ticker) {
        selectedTicker = favorites.first;
      }
    } else {
      favorites.add(ticker);
    }
    notifyListeners();
    _save();
  }

  void setRememberBalance(bool v) { rememberBalance = v; notifyListeners(); _save(); }
  void setRememberRisk(bool v)    { rememberRisk = v;    notifyListeners(); _save(); }
  void setRememberInstrument(bool v) { rememberInstrument = v; notifyListeners(); _save(); }
  void setThemeMode(ThemeMode mode) { themeMode = mode; notifyListeners(); _save(); }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    rememberBalance   = prefs.getBool('rememberBalance')   ?? true;
    rememberRisk      = prefs.getBool('rememberRisk')      ?? true;
    rememberInstrument= prefs.getBool('rememberInstrument')   ?? true;
    if (rememberBalance)    accountBalance = prefs.getDouble('balance')    ?? 50000;
    if (rememberRisk)       riskAmount     = prefs.getDouble('risk')       ?? 300;
    if (rememberInstrument) selectedTicker = prefs.getString('instrument') ?? 'MNQ';
    final favList = prefs.getStringList('favorites') ?? ['MNQ'];
    favorites = Set<String>.from(favList);
    if (!favorites.contains(selectedTicker)) {
      selectedTicker = favorites.first;
    }
    final themeModeStr = prefs.getString('themeMode') ?? 'light';
    themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == themeModeStr, orElse: () => ThemeMode.light);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('rememberBalance',    rememberBalance);
    prefs.setBool('rememberRisk',       rememberRisk);
    prefs.setBool('rememberInstrument', rememberInstrument);
    if (rememberBalance)    prefs.setDouble('balance',    accountBalance);
    if (rememberRisk)       prefs.setDouble('risk',       riskAmount);
    if (rememberInstrument) prefs.setString('instrument', selectedTicker);
    prefs.setStringList('favorites', favorites.toList());
    prefs.setString('themeMode', themeMode.name);
  }
}
