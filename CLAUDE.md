# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter build apk        # Build Android APK
flutter build ios        # Build iOS (requires Xcode)
flutter analyze          # Static analysis
dart format lib/         # Format code
flutter test             # Run tests (minimal placeholder suite)
flutter clean            # Clean build artifacts
```

## Architecture Overview

**Watch Next** is a Flutter app (v2.7.3+46, Dart SDK >=3.3.0) that uses an LLM to generate personalized movie/TV show recommendations, then enriches results via TMDB API and shows streaming availability.

### Core Flow
1. User enters a natural-language prompt in `main_menu_page.dart`
2. `recommendation_loading_page.dart` sends the prompt to OpenAI (or Gemini fallback) using system prompts from `lib/utils/prompts.dart` — response format is `title y:year,, title y:year,,`
3. `http_service.dart` (~1021 lines) looks up each title on TMDB and fetches streaming availability for the user's region
4. Results are displayed as swipeable cards in `recommendation_results_page.dart`
5. Users can save items to their Firestore watchlist, organize them into playlists, or mark them watched

### State Management
No state management framework — the app uses a **service-based architecture** with direct `setState` calls. Services in `lib/services/` handle all business logic and are instantiated directly in pages.

### Storage
- **Firestore**: Watchlist (`users/{userId}/watchlist/`), user actions/analytics (`users/{userId}/actions/`), feedback
- **SQLite** (`sqflite`): Local watched history, streaming service IDs
- **SharedPreferences**: User settings (language, region, selected streaming services, user ID)

### Key Services
| Service | Responsibility |
|---|---|
| `http_service.dart` | All TMDB API calls (search, details, watch providers, trailers, people) |
| `watchlist_service.dart` | Firestore watchlist CRUD with 24h availability cache |
| `watched_service.dart` | Firestore watched history |
| `playlist_service.dart` | User-created playlists of saved items |
| `not_interested_service.dart` | Tracks items the user dismissed so they aren't re-recommended |
| `imdb_import_service.dart` / `letterboxd_import_service.dart` | Bulk-import watched history from IMDB / Letterboxd CSV exports |
| `purchase_service.dart` | In-app purchase to remove ads (`watch_next_remove_ads`); exposes `adsRemovedNotifier` |
| `notification_service.dart` | Local/push notifications |
| `feedback_service.dart` | Submits user feedback to Firestore |
| `user_action_service.dart` | Analytics event logging (disabled in debug mode) |
| `query_cache_service.dart` | Deduplicates LLM queries within 24h |
| `ad_preload_service.dart` / `native_ad_pool.dart` | Preloads + pools AdMob native ads during user input |
| `database_service.dart` | SQLite helpers (schema v4) |

### Key Configuration Files
- `lib/utils/secrets.dart` — All API keys: OpenAI, TMDB, Gemini, AdMob unit IDs
- `lib/utils/prompts.dart` — System prompts for GPT/Gemini recommendation engine
- `lib/utils/constants.dart` — Streaming service logos, privacy policy URL
- `lib/utils/database.dart` — SQLite `DatabaseHelper` singleton

### Navigation
5-tab `BottomNavigationBar` in `home_page.dart`: Watchlist → Watched → **Home** (main_menu) → Discover (browse) → Search.

### Localization
`easy_localization` with 8 languages (EN, IT, DE, FR, ES, PT-BR, JA, HI). Translation JSONs in `assets/translations/`. Language and region settings directly affect both UI language and TMDB watch provider queries.

### Theme
Dark-only theme. Primary background `#0E0E0E`, accent orange `#FFA500`. Colors are centralized in `lib/utils/app_colors.dart`. Custom Raleway font. Portrait orientation locked.

### Analytics & Ads
Firebase Analytics and user action logging are **disabled in debug mode** (`kDebugMode` checks). AdMob native ads are preloaded 200ms before navigating to the loading page to minimize wait time. Ads are suppressed entirely once the user buys the remove-ads IAP (gate on `PurchaseService.adsRemoved`).

### Models
Plain Dart data classes live in `lib/objects/` (e.g. `movie_details.dart`, `series_details.dart`, `watch_providers.dart`, `playlist.dart`) — TMDB response wrappers, not framework models.

### LLM Switching
The app supports switching between OpenAI and Gemini at runtime (settings toggle). Both use the same prompt format and response parsing logic.
