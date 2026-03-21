# Changelog

## [1.2.3] – 2026-03-21 (build 7)
### Fixed
- Favourites and all settings now persist correctly on iOS — `Platform.environment['HOME']` returns empty on iOS, so saves were silently failing; switched to `getApplicationDocumentsDirectory()` for mobile storage
- Added lifecycle save so state is flushed to disk when the app is backgrounded

## [1.2.3] – 2026-03-18 (build 6)
### Fixed
- Windows ICO format corrected for RC compiler compatibility

## [1.2.2] – 2026-03-17
### Changed
- Updated screenshots for light theme
- Adaptive Android icon
- Navigation CSS cleanup and row height adjustments

## [1.2.1] – 2026-03-13
### Changed
- Normalised hero number styles to `AppText.mono` across all three columns

## [1.2.0] – 2026-03-12
### Changed
- New Q app icon across all platforms
- Uniform 32 px hero numbers and 18 px selected row text on Levels screen

## [1.1.0] – earlier
### Added
- Release workflow covering macOS, Windows, iOS, and Android
- 4-part version string displayed in Settings

### Fixed
- Stop loss value no longer resets when navigating back to the calculator
- Theme colours and smooth theme transition

## [1.0.0] – initial release
### Added
- Position size calculator: `contracts = floor(riskAmount / (stopLossPoints × pointValue))`
- Calculator, Levels, and Markets screens
- Dark / light / system theme
- Persist settings across launches
- macOS, Windows, iOS, Android builds
