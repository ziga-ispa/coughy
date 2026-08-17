# Coughy — Claude Code Context

## Build

```bash
xcodegen generate   # regenerates Coughy.xcodeproj from project.yml
```

Open `Coughy.xcodeproj` in Xcode after generating. Run on a **real device** for full audio classification support.

## Architecture (MVVM + Services)

| Layer | Path | Purpose |
|-------|------|---------|
| App entry | `Sources/Phone/App/CoughyPhoneApp.swift` | @main, injects ViewModel as EnvironmentObject |
| Data model | `Sources/Phone/Models/CoughDataModel.swift` | CoughEvent, CoughSession, CoughType |
| Service protocol | `Sources/Phone/Services/CoughDetectionServiceProtocol.swift` | Protocol + delegate for testability |
| Audio engine | `Sources/Phone/Services/CoughMonitorEngine.swift` | Audio pipeline, ML inference, cough grouping |
| Feature extraction | `Sources/Phone/Utilities/LogMelProcessor.swift` | Log-mel spectrogram for CoughCNN |
| ViewModel | `Sources/Phone/ViewModels/CoughMonitorViewModel.swift` | State, formatting logic, session control |
| Main view | `Sources/Phone/Views/CoughMonitorView.swift` | Root UI |
| Stats bar | `Sources/Phone/Views/Components/StatsBarView.swift` | Session statistics display |
| Event row | `Sources/Phone/Views/Components/EventRowView.swift` | Single cough event row |
| Empty state | `Sources/Phone/Views/Components/EmptyStateView.swift` | Empty list placeholder |
| ML model | `Models/CoughCNN.mlpackage` | Dry/wet cough classifier |

## Key Design Decisions

- `CoughDetectionServiceProtocol` makes the engine swappable for testing
- Formatting helpers (dBFS, loudness label, duration) live in `CoughMonitorViewModel`, not in Views
- Background audio monitoring requires `UIBackgroundModes: [audio]` in Info.plist (set in project.yml)
- CoughCNN loaded dynamically at runtime — no Xcode-generated class needed
- Apple SoundAnalysis (`SNClassifySoundRequest`) gates the CNN to reduce false positives and battery drain
