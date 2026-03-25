# Bitcoin Quantum Threat Toolkit (Flutter)

Native-style client for the same **scenario modeling** logic as the Streamlit `app.py` in this repository: quantum vs migration curves, risk, presets, sensitivity sweep, and CSV export.

## Run

```bash
cd bitcoin_quantum_threat_app
flutter pub get
flutter run
```

- **Web:** `flutter build web` then serve `build/web` (RSS feeds may hit **CORS** in the browser; mobile/desktop are fine).
- **Android / iOS:** open the folder in Android Studio / Xcode or `flutter run -d <device>`.

## Structure

| Path | Role |
|------|------|
| `lib/engine/risk_engine.dart` | Curves, scenarios, verdicts (ported from Python) |
| `lib/screens/main_shell.dart` | Bottom navigation + 6 destinations |
| `lib/screens/simulator_screen.dart` | Sliders, `fl_chart` charts, compare / sensitivity / summary |
| `lib/screens/quick_check_screen.dart` | Four-question band |
| `lib/screens/news_screen.dart` | RSS via `http` + `webfeed` |
| `lib/theme/app_theme.dart` | Dark / amber styling |

## License

Same as the parent repository unless you specify otherwise.
