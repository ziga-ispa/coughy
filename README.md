# Coughy

An iPhone app that classifies cough audio using on-device CoreML models.

---

## Overview

Coughy receives audio files and runs them through two ML models to determine whether the sound is a cough. Results are stored and displayed in the app.

**Key capabilities:**
- Dual-model cough classification: Apple's `SNClassifySoundRequest` + custom `best_model_cough.mlmodel`
- Audio file import via Files app (`UIFileSharingEnabled`)

---

## Architecture

| Layer | Responsibility |
|-------|---------------|
| **Models** | Pure data types (`CoughRecording`) |
| **Services** | Hardware access and OS APIs (audio, CoreML) |
| **ViewModels** | Business logic, service orchestration, `@Published` state |
| **Views** | SwiftUI rendering only, no logic |

---

## Prerequisites

- Xcode 15 or later
- iPhone running iOS 16+
- Apple Developer account (for signing)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed (`brew install xcodegen`)

---

## Setup

```bash
# 1. Clone the repo
git clone <repo-url>
cd coughy

# 2. Generate the Xcode project
xcodegen generate

# 3. Open in Xcode
open Coughy.xcodeproj
```

4. Set your **Development Team** on the `CoughyPhone` target.
5. Select your iPhone as the run destination and build.

---

## Project Structure

```
coughy/
├── project.yml                        XcodeGen spec (source of truth for project config)
├── Models/
│   └── best_model_cough.mlmodel       Custom cough classifier (binary asset, not generated)
└── Sources/
    └── Phone/
        ├── App/CoughyPhoneApp.swift
        ├── Models/CoughRecording.swift
        ├── ViewModels/RecordingsViewModel.swift
        ├── Views/RecordingsView.swift
        └── Services/
            └── ClassificationService.swift  CoreML + SoundAnalysis
```

---

## Key Technical Decisions

### Dual-Model Classification
Two classifiers run in parallel on each audio file:
1. **`SNClassifySoundRequest`** — Apple's built-in sound classifier (handles general cough sounds)
2. **`best_model_cough.mlmodel`** — Custom Core ML model trained on a focused cough dataset

Confidence threshold for both: **10% (0.1)**. Validated against real cough samples; higher thresholds miss genuine coughs.

---

## Permissions

| Key | Why |
|-----|-----|
| `NSMicrophoneUsageDescription` | Audio classification |
| `UIFileSharingEnabled` | Allow users to access audio files via Files app |

---

## Testing

**Checking classification:** if recordings appear but show no label, lower the confidence threshold in `ClassificationService` or verify the `.mlmodel` file was included in the target.
