# Watch Next

Never waste time browsing your streaming catalogues again!

Nowadays where I, like most people, am subscribed to multiple streaming services it has become increasingly difficult to pick something to watch. I decided to create Watch Next to solve my own problem and hopefully other people's too.

Watch Next uses ChatGPT and TMDB APIs to give suggestions of movies and shows available on your streaming services in your country. Simply write a text prompt with a genre, or a mood, or anything that inspires you, and you'll get different suggestions.

Sounds useful? Check the app out on [Google Play](https://play.google.com/store/apps/details?id=com.filippefrulli.watch_next&hl=en&gl=US) and the [App Store](https://apps.apple.com/us/app/watch-next-ai-movie-tv-tips/id6450368827)!

## How to set up the project
If you would like to build your own App based on Watch Next, follow these steps:

* [Install Flutter and Dart](https://docs.flutter.dev/get-started/install)
* Clone the repository
* [Get a TMDB API key](https://developer.themoviedb.org/reference/intro/getting-started)
* [Get a ChatGPT API key](https://platform.openai.com/docs/quickstart?context=python)
* Within the project, navigate to lib/utils and create a secrets.dart file. It should looke like this:
    * const String openApiKey = your_openapi_key
    * const String tmdbApiKey = your_tmdb_key

* The secrets file will not be checked in because of the .gitignore rule. (Please note that this is not a 100% secure solution, and API keys can be retrieved by malicious actors through the apk. While TMDB is free of cost, openai is not. Make sure you set a maximum expenditure limit to protect your expenses.)

* The App containes ads, either remove them from the recommandation_results_page, or enable test ads by commenting in line 45 and commenting out line 44 in the same file.
* If you are at a point where you can enable ads add the IDs to the secrets file mentioned above.
* Enjoy :)


## About Flutter

Want to learn how to code a Flutter app? Check out these examples:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
