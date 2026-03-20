import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'instrument.dart';
import '../theme/app_theme.dart';

class QuantaState extends ChangeNotifier {
  double accountBalance = 50000;
  double riskAmount = 300; // persisted setting
  double? _sessionRisk; // temporary override, not persisted
  double get effectiveRisk => _sessionRisk ?? riskAmount;
  String selectedTicker = 'MNQ';
  double stopLossPoints = 0;
  List<String> favorites = ['MNQ'];

  // Appearance
  ThemeMode themeMode = ThemeMode.system;

  // Settings toggles
  bool rememberBalance = true;
  bool rememberRisk = true;
  bool rememberInstrument = true;
  bool riskIsPercent = false;

  Instrument get currentInstrument =>
      kAllInstruments.firstWhere((i) => i.ticker == selectedTicker,
          orElse: () => kAllInstruments.first);

  // Preserve insertion order from the favorites list
  List<Instrument> get favoriteInstruments => favorites
      .where((t) => kAllInstruments.any((i) => i.ticker == t))
      .map((t) => kAllInstruments.firstWhere((i) => i.ticker == t))
      .toList();

  double get riskPercent =>
      accountBalance > 0 ? riskAmount / accountBalance * 100 : 0;

  // Core calculation — ALWAYS floor, never round
  int get contracts => stopLossPoints > 0
      ? (effectiveRisk / (stopLossPoints * currentInstrument.pointValue))
          .floor()
      : 0;

  double get actualRisk =>
      contracts * stopLossPoints * currentInstrument.pointValue;

  double get unusedRisk => effectiveRisk - actualRisk;

  // Risk ladder for Levels screen — scroll risk amounts at fixed stop loss
  List<double> get nearbyRiskLevels {
    if (stopLossPoints <= 0) return [];
    const step = 25.0;
    final top = (effectiveRisk * 5).clamp(500.0, 5000.0);
    final levels = <double>[];
    for (double r = 25.0; r <= top; r += step) {
      levels.add(r);
    }
    return levels;
  }

  int contractsForRisk(double risk) => stopLossPoints > 0
      ? (risk / (stopLossPoints * currentInstrument.pointValue)).floor() : 0;

  double actualRiskForRisk(double risk) =>
      contractsForRisk(risk) * stopLossPoints * currentInstrument.pointValue;

  // Keep stop-based helpers for any future use
  int contractsForStop(double sl) =>
      sl > 0 ? (effectiveRisk / (sl * currentInstrument.pointValue)).floor() : 0;

  double actualRiskForStop(double sl) =>
      contractsForStop(sl) * sl * currentInstrument.pointValue;

  void setBalance(double value) {
    accountBalance = value.clamp(0.01, 100000000);
    notifyListeners();
    _save();
  }

  void setRisk(double value) {
    riskAmount = value.clamp(0.01, 1000000);
    _sessionRisk = null; // clear session override when persisted risk changes
    notifyListeners();
    _save();
  }

  void setSessionRisk(double value) {
    _sessionRisk = value.clamp(0.01, 1000000);
    notifyListeners();
  }

  void setInstrument(String ticker) {
    selectedTicker = ticker;
    stopLossPoints = 0;
    notifyListeners();
    _save();
  }

  void setStopLoss(double value) {
    stopLossPoints = value.clamp(0, 100000);
    notifyListeners();
  }

  void reorderFavorites(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = favorites.removeAt(oldIndex);
    favorites.insert(newIndex, item);
    notifyListeners();
    _save();
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

  void setRiskIsPercent(bool v) {
    riskIsPercent = v;
    notifyListeners();
    _save();
  }

  void setRememberBalance(bool v) {
    rememberBalance = v;
    notifyListeners();
    _save();
  }

  void setRememberRisk(bool v) {
    rememberRisk = v;
    notifyListeners();
    _save();
  }

  void setRememberInstrument(bool v) {
    rememberInstrument = v;
    notifyListeners();
    _save();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _syncIsDark();
    notifyListeners();
    _save();
  }

  void _syncIsDark() {
    final platformDark = WidgetsBinding
        .instance.platformDispatcher.platformBrightness == Brightness.dark;
    AppColors.isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformDark);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    rememberBalance = prefs.getBool('rememberBalance') ?? true;
    rememberRisk = prefs.getBool('rememberRisk') ?? true;
    rememberInstrument = prefs.getBool('rememberInstrument') ?? true;
    if (rememberBalance) accountBalance = prefs.getDouble('balance') ?? 50000;
    if (rememberRisk) riskAmount = prefs.getDouble('risk') ?? 300;
    if (rememberInstrument) {
      selectedTicker = prefs.getString('instrument') ?? 'MNQ';
    }
    final favList = prefs.getStringList('favorites') ?? ['MNQ'];
    favorites = List<String>.from(favList);
    riskIsPercent = prefs.getBool('riskIsPercent') ?? false;
    if (!favorites.contains(selectedTicker)) {
      selectedTicker = favorites.first;
    }
    final themeModeStr = prefs.getString('themeMode') ?? 'system';
    themeMode = ThemeMode.values.firstWhere((m) => m.name == themeModeStr,
        orElse: () => ThemeMode.system);
    _syncIsDark();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('rememberBalance', rememberBalance);
    prefs.setBool('rememberRisk', rememberRisk);
    prefs.setBool('rememberInstrument', rememberInstrument);
    if (rememberBalance) prefs.setDouble('balance', accountBalance);
    if (rememberRisk) prefs.setDouble('risk', riskAmount);
    if (rememberInstrument) prefs.setString('instrument', selectedTicker);
    prefs.setStringList('favorites', favorites);
    prefs.setBool('riskIsPercent', riskIsPercent);
    prefs.setString('themeMode', themeMode.name);
  }
}
