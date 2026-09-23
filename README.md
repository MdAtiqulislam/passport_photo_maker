# Passport Photo Maker (passport_photo_maker)

Studio-grade passport-photo app — guided wizard, AI photo restoration, outfit fitting and print sheets.

## Features

- Step-by-step photo wizard with camera guide overlay
- Editor: background, crop, adjustments, quality badge
- AI enhance and ONNX/on-device restoration with before-after slider
- Outfit gallery, fitting studio and extractor/renderer
- Templates, print-sheet layouts and export/share
- Project history, onboarding and settings

## Tech Stack

- Flutter (Dart)
- GetX for state management and routing
- On-device ML (ONNX restoration, segmentation)

## Getting Started

```bash
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── app/modules/   # Wizard, camera, editor, restoration, outfit, print, export
├── core/          # Services (AI, image processing, storage), theme, utils
├── data/          # Models and repositories
└── main.dart      # App entry point
```

## Notes

- App label: "Passport Photo Maker" (Android)
- No secrets, keystores or Firebase configs are committed to this repository.
