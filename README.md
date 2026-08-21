# MyDownloader — Flutter Mobile App

This is the **Flutter** version of the mobile app (alternative to the
React Native one in `mobile/`). It talks to the same `backend/` (Node.js +
yt-dlp) — you only need to run that backend once.

## Setup

1. **Install Flutter SDK** if you don't have it: https://docs.flutter.dev/get-started/install

2. **Turn this folder into a real Flutter project** (this repo only ships
   the `lib/`, `pubspec.yaml`, and platform config *snippets* — Flutter
   needs to generate the native `android/` and `ios/` scaffolding itself):

   ```bash
   cd mobile-flutter
   flutter create --org com.yourcompany --project-name my_downloader .
   ```

   This will generate the full `android/` and `ios/` folders without
   touching your existing `lib/` and `pubspec.yaml`.

3. **Merge the permission snippets:**
   - Copy the permission lines from `android/app/src/main/AndroidManifest.xml`
     (already provided) into the one `flutter create` generates — they're
     the same path, so just merge the `<uses-permission>` tags and the
     `android:usesCleartextTraffic="true"` attribute.
   - Copy the keys from `ios/Runner/Info-additions.plist` into the real
     `ios/Runner/Info.plist` that gets generated.

4. **Install dependencies:**
   ```bash
   flutter pub get
   ```

5. **Point the app at your backend.** Open
   `lib/services/api_service.dart` and set `baseUrl`:
   - Android emulator → `http://10.0.2.2:4000`
   - iOS simulator → `http://localhost:4000`
   - Physical phone → `http://<your-computer's-local-IP>:4000`

6. **Run it:**
   ```bash
   flutter run
   ```

## Project structure

```
lib/
  main.dart                  # App entry point + routing (go_router) + theme
  models/video_info.dart     # VideoInfo, VideoFormat, HistoryItem data classes
  services/api_service.dart  # Talks to the backend (fetch info, download file)
  services/history_service.dart # Local download history (SharedPreferences)
  screens/home_screen.dart   # Paste link screen
  screens/format_screen.dart # Choose quality + download + save to gallery
  screens/history_screen.dart# List of past downloads
```

## Notes

- Uses `dio` for networking + file download with progress.
- Uses `gallery_saver_plus` + `permission_handler` to save finished videos
  to the phone's gallery (Android/iOS).
- Uses `go_router` for navigation between the 3 screens.
- Same legal/ToS disclaimer is shown on the home screen — keep it if you
  publish this. See the main `README.md` in the project root for full
  legal notes and next steps (trim/compress/watermark tools, background
  downloads, deploying the backend, publishing to the stores via
  `flutter build apk` / `flutter build ipa`).
