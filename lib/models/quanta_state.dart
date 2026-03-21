import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'instrument.dart';
import '../theme/app_theme.dart';

class QuantaState extends ChangeNotifier with WidgetsBindingObserver {
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

  @override
  void didChangePlatformBrightness() {
    _syncIsDark();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _saveSync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncIsDark() {
    final platformDark = WidgetsBinding
        .instance.platformDispatcher.platformBrightness == Brightness.dark;
    AppColors.isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformDark);
  }

  static Future<File> _prefsFile() async {
    final dir = Platform.isMacOS
        ? Directory('${Platform.environment['HOME']}/Documents')
        : await getApplicationDocumentsDirectory();
    return File('${dir.path}/quanta_prefs.json');
  }

  Future<void> load() async {
    try {
      final file = await _prefsFile();
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        rememberBalance = data['rememberBalance'] as bool? ?? true;
        rememberRisk = data['rememberRisk'] as bool? ?? true;
        rememberInstrument = data['rememberInstrument'] as bool? ?? true;
        if (rememberBalance) accountBalance = (data['balance'] as num?)?.toDouble() ?? 50000;
        if (rememberRisk) riskAmount = (data['risk'] as num?)?.toDouble() ?? 300;
        if (rememberInstrument) selectedTicker = data['instrument'] as String? ?? 'MNQ';
        final favList = (data['favorites'] as List?)?.cast<String>() ?? ['MNQ'];
        favorites = List<String>.from(favList.isNotEmpty ? favList : ['MNQ']);
        riskIsPercent = data['riskIsPercent'] as bool? ?? false;
        if (!favorites.contains(selectedTicker)) selectedTicker = favorites.first;
        final themeModeStr = data['themeMode'] as String? ?? 'system';
        themeMode = ThemeMode.values.firstWhere((m) => m.name == themeModeStr,
            orElse: () => ThemeMode.system);
      }
    } catch (_) {
      // Use defaults on any error
    }
    WidgetsBinding.instance.addObserver(this);
    _syncIsDark();
    notifyListeners();
  }

  Map<String, dynamic> _buildSaveData() => {
        'rememberBalance': rememberBalance,
        'rememberRisk': rememberRisk,
        'rememberInstrument': rememberInstrument,
        if (rememberBalance) 'balance': accountBalance,
        if (rememberRisk) 'risk': riskAmount,
        if (rememberInstrument) 'instrument': selectedTicker,
        'favorites': favorites,
        'riskIsPercent': riskIsPercent,
        'themeMode': themeMode.name,
      };

  Future<void> _save() async {
    try {
      final file = await _prefsFile();
      await file.writeAsString(jsonEncode(_buildSaveData()));
    } catch (_) {
      // Ignore save errors
    }
  }

  void _saveSync() {
    _save(); // lifecycle save — async is fine, OS gives the app time on background
  }
}
