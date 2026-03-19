# Mac Setup Guide — Quanta

## 1. Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homebrew/install/HEAD/install.sh)"
```

## 2. Flutter
```bash
brew install flutter
```

## 3. Xcode
Install from the **App Store**, then run:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

## 4. VS Code
Download from [code.visualstudio.com](https://code.visualstudio.com)

Install these extensions inside VS Code:
- **Flutter**
- **Dart**

## 5. CocoaPods
```bash
sudo gem install cocoapods
```

## 6. Verify everything is installed
```bash
flutter doctor
```

---

## 7. Clone & Run the App
```bash
git clone https://github.com/Ledian63S/quanta.git
cd quanta
flutter create . --org io.github.ledian63s --project-name quanta
flutter pub get
code .
```

## 8. Run on iPhone
- Connect your iPhone via USB
- Trust the computer on your iPhone when prompted
- Open `ios/Runner.xcworkspace` in Xcode
- Go to **Signing & Capabilities** → select your Apple ID as the Team
- Back in VS Code terminal:
```bash
flutter run
```
