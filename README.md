<p align="center">
  <img src="assets/icon/icon.png" width="120" alt="Vndex logo">
</p>

<h1 align="center">Vndex</h1>

<p align="center">
  A personal visual novel tracker and backlog manager for Android, powered by <a href="https://vndb.org">VNDB</a>.
</p>

<p align="center">
  <a href="../../releases/latest"><b>⬇ Download the latest APK</b></a>
</p>

---

## About

Vndex keeps track of the visual novels you're playing, want to play, have finished, or dropped. It looks everything up on VNDB (titles, covers, descriptions, tags, screenshots, characters and staff), while **your lists, ratings and reviews stay on your device**. No account needed.

## Features

**Your library**
- Four lists: **Playing**, **To Play**, **Finished**, **Dropped**, plus an **All** tab with a colored badge showing which list each VN is in
- **Collections**: your own groups like "Favorites" or "Recommend to friends", each with its own tab
- **5-star ratings** with half stars, and written **reviews** with a spoiler toggle
- Started and finished dates recorded automatically
- Search your lists, and **filter / sort / display** options: compact, comfortable or cover-only grids, or a list
- **Undo** when you remove a VN by mistake
- Works offline for VNs in your lists

**Decide what's next**
- **Backlog roulette**: "What should I play next?" picks a random VN from To Play or a collection, filtered by length
- **Home screen widget** showing what you're currently playing

**Discover**
- **Browse** VNDB with **Popular** and **Latest** presets
- A full **filter sheet**: sort, original language, platform, length, development status, release year, minimum rating, **available in English**, and tags you can **include or exclude**
- **Saved searches**
- Tap a tag, a **studio** or a **staff member** to see more of their VNs, or use **Find similar**

**VN pages**
- Cover, release date, developers, length, VNDB rating, and whether there's an **official or fan English release**
- Description with spoilers removed
- **Related VNs** (prequels, sequels, fandiscs…), **staff**, **screenshots**, **characters** and **memorable quotes**, with spoilers hidden
- A link to the VN's **discussion board** on VNDB

**Settings**
- Light / dark / system themes: **Vndex**, **Dusk** and **Catppuccin**, plus a pure black mode
- **18+ options**: blur sensitive covers and images, and show or hide sexual content tags
- **Backup and restore** to a single file, to keep your library safe or move it between devices

## Screenshots

| Library | Browse |
|:---:|:---:|
| <img src="docs/screenshots/library.png" width="260"> | <img src="docs/screenshots/browse.png" width="260"> |

| Filter | VN page |
|:---:|:---:|
| <img src="docs/screenshots/filter.png" width="260"> | <img src="docs/screenshots/detail.png" width="260"> |

## Install

1. Download the APK from the [latest release](../../releases/latest).
2. Open it on your Android phone. If asked, allow installing apps from your browser or files app.
3. Requires Android 5.0 or newer.

## Build it yourself

You'll need the [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.29 or newer) and the Android SDK.

```bash
git clone https://github.com/BrylleJacobGeslaga-UCM/Vndex.git
cd Vndex
flutter pub get
flutter run                 # on a connected phone or emulator
flutter run -d chrome       # in the browser, for quick testing
flutter build apk --release # build an installable APK
```

Release builds are signed with a key that isn't in this repo. Without your own `android/key.properties`, build a debug APK instead (`flutter build apk --debug`).

## Tech stack

| | |
|---|---|
| Framework | Flutter (Dart) |
| State management | Riverpod |
| Local storage | sembast (works on Android and web) |
| Data source | VNDB API v2 (Kana) |
| Images | cached_network_image |
| Home screen widget | home_widget |

## Project structure

```
lib/
├── core/          theme, constants, helpers, shared widgets
├── data/
│   ├── remote/    VNDB API calls
│   ├── local/     local database, settings and backups
│   └── repository/  the single place screens get data from
├── models/        VN, entries, filters, collections, settings
├── providers/     Riverpod providers
├── services/      home screen widget updates
└── screens/       home, browse, detail, roulette, settings
```

## Credits

- VN data, covers, screenshots, character, staff and quote information come from [VNDB.org](https://vndb.org), the community visual novel database, through its public API.
- Vndex is an unofficial personal project and is not affiliated with or endorsed by VNDB.

## License

No license has been chosen yet, so all rights are reserved by the author.
