# BinPal app

Flutter app for iOS and Android. Works offline from a cached area bundle (see `../data/schema/`).

## Structure

```
lib/
  main.dart
  app/            app widget, services, theme (design tokens), tab shell, shared top bar
  data/           local database (drift) and bundle sync from the CDN
  features/
    today/        today's and tomorrow's collections
    search/       offline item search
    item/         one item's category, instructions and source
    settings/     area, reminders, about
  l10n/           English and Japanese strings (ARB); Dart files are generated
```

Each feature owns its screens and, later, its state and data access. Shared code lives in `app/` until a second feature needs it.

Core packages only: `drift` (SQLite with FTS5), `http` and `crypto` (bundle download and checksum), `url_launcher` (official source links), `geolocator`, `flutter_local_notifications` and `intl`. Camera arrives in v2. Text uses the platform's system font, so no Japanese font is bundled.

## Data and sync

`lib/data/database.dart` holds one SQLite database with the bundle's areas, categories, rules, aliases, calendars and exceptions, plus a small settings table. Generated code is in `database.g.dart`; after changing a table, run `dart run build_runner build`.

`lib/data/bundle_sync.dart` keeps the user's municipality in step with the CDN:

1. Fetch `manifest.json` and find the municipality's bundle in a schema version the app can read.
2. If the stored bundle has the same version and SHA-256, stop. Otherwise download only that bundle.
3. Check its size and SHA-256 against the manifest, and that it is the version and municipality the manifest promised.
4. Replace the municipality's data in a single transaction.

Any failure (no network, HTTP error, wrong size or checksum, a bundle that does not import) leaves the stored data exactly as it was.

`SyncController` runs this on launch and when the app returns to the foreground, at most every six hours once data is stored, and never makes a screen wait for it. Until area setup exists, the municipality is Yokohama (`14100`). Settings → Area data shows which bundle is on the device and retries on tap.

The CDN defaults to `https://data.blidir.fun`; override with `--dart-define=CDN_BASE_URL=…`.

## Search

`lib/features/search/item_search.dart` searches the stored bundle with no network:

* Every rule's Japanese name, reading, English name and aliases go into an FTS5 table with the trigram tokenizer (`search_index`), rebuilt in the same transaction as each bundle import.
* Index and query are folded the same way (`lib/data/normalize.dart`): katakana and half-width katakana to hiragana, full-width letters and digits to ASCII, lower case. So カサ, ｶｻ and かさ are the same query, and so are ＵＭＢＲＥＬＬＡ and umbrella. Kanji are not converted: 傘 finds the umbrella because 傘 is one of its aliases in the bundle.
* Words of three or more characters use the full-text index; one- and two-character words (傘, 電池) use `LIKE` on the same table. Space-separated words must all match.
* Results are ranked exact match (a curated alias before a name or reading), then start of a term, then start of a word, then anywhere; ties go to the shorter Japanese name. Only rules valid today in Japan are shown.
* A query that still has no results two seconds after typing stops is counted in `missed_searches`, once per session: the normalised text and a count, kept on the device and never sent. It is there to find missing aliases.

On the full Yokohama bundle (3,413 items), every prefix of seven typical words took a median of 1.1 ms and at most 26 ms on an Android 16 emulator, and 0.6 ms / 17 ms on an iPhone 17 simulator (`integration_test/search_test.dart`).

## Run

```sh
flutter pub get
flutter run                       # debug on a connected device
flutter test
flutter test integration_test/sync_test.dart -d <device-id>   # first-launch sync against the real CDN
flutter test integration_test/search_test.dart -d <device-id> # search speed with the full Yokohama bundle
```

## Integration tests

`integration_test/` drives the real app on a simulator or device, in English and Japanese, and saves screenshots to `build/screenshots/` (named `<platform>_<locale>_<screen>.png`):

```sh
flutter emulators --launch Pixel_9_API_36          # or open the iOS Simulator
flutter devices                                     # find the device id
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart -d <device-id>
```

`flutter test integration_test -d <device-id> --dart-define=SCREENSHOTS=false` runs the same flows without screenshots. They don't run in CI yet (that needs an emulator on the runner).

Strings are in `lib/l10n/app_en.arb` and `app_ja.arb`. `flutter pub get` or any build regenerates `app_localizations*.dart`.

## App icon and logo

Masters live in `../brand/`: `binpal-icon-1024.png` (square, opaque) and `binpal-logo.png` (transparent wordmark, for light backgrounds). After changing either, regenerate everything from the repo root:

```sh
uv run app/tool/generate_icons.py
```

This writes:

* iOS: a single 1024 px `AppIcon`; Xcode derives the other sizes.
* Android: an adaptive icon (background colour taken from the artwork, transparent mascot foreground, monochrome layer for Android 13+ themed icons) plus square icons for Android 7.
* `assets/brand/logo.png` at 1x, 2x and 3x (56 logical px tall), used on the About screen.
* `../brand/previews/icon-masks.png`: the icon under the iOS mask and common Android launcher masks, plus the themed version. Check it after regenerating.

The mascot sits at the same size on both platforms and inside Android's 66 dp safe circle; the script fails if it doesn't.

## Release builds

```sh
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols/android
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/android
flutter build ios --release --obfuscate --split-debug-info=build/symbols/ios
```

Keep `build/symbols/` from every build you ship: it is needed to read obfuscated crash stack traces (`flutter symbolize`).

Android release builds use R8 shrinking and are signed with debug keys until a Play upload key exists. `compileSdk` is 37 because `flutter_local_notifications` 23 requires it; `targetSdk` stays on Flutter's default.

CI (`.github/workflows/app.yml`) checks formatting, analyzes and runs the tests on every PR touching `app/`. It does not build releases or upload artifacts, to stay within the free GitHub Actions quota; build releases locally with the commands above.

## Baseline (skeleton, 11 Nov 2026)

Flutter 3.47.1. Sizes in MB of 1,048,576 bytes; "compressed" is gzip/zip of the build output, an approximation of download size.

| Build | Size | Compressed |
| -- | --: | --: |
| Android APK arm64-v8a | 18.0 MB | 8.3 MB |
| Android APK armeabi-v7a | 15.3 MB | 7.8 MB |
| Android APK x86_64 | 19.4 MB | 8.5 MB |
| iOS Runner.app | 27.6 MB | 10.4 MB |

Most of it is the Flutter engine (Android `libflutter.so` 11.2 MB, iOS `Flutter.framework` 15.5 MB), the compiled app (4.1 MB / 10 MB) and SQLite for drift (1.7 MB / 1.6 MB). Android keeps native libraries uncompressed in the APK so they load without extraction, which is why the APK is much larger than the download.

Cold start, iPhone 16 (iOS 26.6.1), profile build, `flutter run --profile --trace-startup`, median of 3 launches after the first install:

| Metric | Time |
| -- | --: |
| Engine start → framework ready | 31 ms |
| Engine start → first frame built | 51 ms |
| Engine start → first frame on screen | 226 ms |

These start at engine launch, so they leave out the OS's process start. Android cold start still needs a physical device: the arm64 emulator measured 2.8–5.2 s (`am start -W`), which reflects emulator rendering rather than the app.
