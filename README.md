# Watch Next

Never waste time browsing your streaming catalogues again!

Nowadays where I, like most people, am subscribed to multiple streaming services it has become increasingly difficult to pick something to watch. I decided to create Watch Next to solve my own problem and hopefully other people's too.

Watch Next uses ChatGPT and TMDB APIs to give suggestions of movies and shows available on your streaming services in your country. Simply write a text prompt with a genre, or a mood, or anything that inspires you, and you'll get different suggestions.

## Features

### 🎬 AI-Powered Recommendations
The core feature of Watch Next is its AI-powered recommendation engine. Simply describe what you're in the mood for – a genre, a feeling, a specific theme, or anything that inspires you – and the app uses ChatGPT to understand your request and suggest movies or TV shows that match.

**How it works:**
1. Select whether you want movie or TV show recommendations
2. Type a prompt describing what you want to watch (e.g., "something like Inception but scarier", "a feel-good comedy for date night", "90s action movies")
3. The AI processes your request and returns personalized suggestions
4. Swipe through recommendations with movie posters, descriptions, ratings, and trailers
5. See exactly where each title is available to stream, rent, or buy

### 📺 Streaming Service Integration
Watch Next integrates with TMDB's watch provider data to show you exactly where content is available:

- **Streaming**: Shows which of your subscribed services have the title available
- **Rent**: Options to rent the title digitally
- **Buy**: Options to purchase the title digitally

Configure your streaming services in settings, and the app will highlight titles available on platforms you already subscribe to.

### 📋 Watchlist
Keep track of movies and shows you want to watch later:

- **Add items** from recommendations or search results
- **Automatic availability tracking** – the app fetches and updates streaming availability when you add items
- **Smart caching** – availability data is refreshed automatically every 24 hours in the background
- **Filter options** – filter by movies/TV shows or show only titles available on your services
- **Import from other platforms**:
  - **IMDb** – Import your IMDb watchlist via CSV export
  - **Letterboxd** – Import your Letterboxd watchlist via CSV export

### 🔍 Search
Search for any movie or TV show directly:

- Search by title
- View detailed information including synopsis, ratings, and cast
- Check streaming availability
- Add to your watchlist

### 🌍 Localization
The app supports multiple languages:
- English (US)
- German (DE)
- Spanish (ES)
- French (FR)
- Italian (IT)

Streaming availability is also region-aware, showing providers available in your country.

## Architecture

Watch Next is built with Flutter and follows a service-oriented architecture:

```
lib/
├── main.dart                 # App entry point and theme configuration
├── pages/                    # Screen/page widgets
│   ├── home_page.dart        # Tab navigation (Watchlist, Home, Search)
│   ├── main_menu_page.dart   # AI recommendation input screen
│   ├── recommendation_loading_page.dart
│   ├── recommandation_results_page.dart
│   ├── watchlist_page.dart   # Watchlist management
│   ├── search_media_page.dart
│   ├── media_detail_page.dart
│   ├── settings_page.dart
│   ├── streaming_services_page.dart
│   ├── language_page.dart
│   └── region_page.dart
├── services/                 # Business logic and API integrations
│   ├── http_service.dart     # TMDB API client
│   ├── watchlist_service.dart # Firestore watchlist management
│   ├── database_service.dart # Local preferences/settings
│   ├── imdb_import_service.dart
│   ├── letterboxd_import_service.dart
│   ├── notification_service.dart
│   └── feedback_service.dart
├── widgets/                  # Reusable UI components
├── objects/                  # Data models
└── utils/                    # Utilities and secrets
```

### Key Technologies
- **Flutter** – Cross-platform mobile framework
- **Firebase** – Cloud Firestore for watchlist storage, Analytics, Cloud Messaging for notifications
- **OpenAI API** – ChatGPT for natural language recommendation processing
- **TMDB API** – Movie/TV show metadata, search, and watch provider data
- **SharedPreferences** – Local settings storage
- **EasyLocalization** – Multi-language support

## How to set up the project
If you would like to build your own App based on Watch Next, follow these steps:

### Prerequisites
* [Install Flutter and Dart](https://docs.flutter.dev/get-started/install)

### API Keys
* [Get a TMDB API key](https://developer.themoviedb.org/reference/intro/getting-started)
* [Get a ChatGPT API key](https://platform.openai.com/docs/quickstart?context=