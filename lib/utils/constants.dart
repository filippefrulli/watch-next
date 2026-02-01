const List<String> streamingServicesLogos = [
  'assets/streaming_services/netflix.png',
  'assets/streaming_services/prime_video.png',
  'assets/streaming_services/apple_tv.png',
  'assets/streaming_services/disney+.png',
  'assets/streaming_services/hbo_max.png',
  'assets/streaming_services/hulu.png',
  'assets/streaming_services/paramount+.png',
  'assets/streaming_services/peacock.png',
];

const List<String> streamingServicesLogosIos = [
  'assets/streaming_services/netflix.png',
  'assets/streaming_services/prime_video.png',
  'assets/streaming_services/apple_tv.png',
  'assets/streaming_services/hbo_max.png',
  'assets/streaming_services/hulu.png',
  'assets/streaming_services/paramount+.png',
  'assets/streaming_services/peacock.png',
];

const providersMap = {
  8: 'assets/streaming_services/netflix.png',
  9: 'assets/streaming_services/prime_video.png',
  350: 'assets/streaming_services/apple_tv.png',
  337: 'assets/streaming_services/disney+.png',
  384: 'assets/streaming_services/hbo_max.png',
  15: 'assets/streaming_services/hulu.png',
  531: 'assets/streaming_services/paramount+.png',
  530: 'assets/streaming_services/peacock.png',
};

const providersMapIos = {
  8: 'assets/streaming_services/netflix.png',
  9: 'assets/streaming_services/prime_video.png',
  350: 'assets/streaming_services/apple_tv.png',
  384: 'assets/streaming_services/hbo_max.png',
  15: 'assets/streaming_services/hulu.png',
  531: 'assets/streaming_services/paramount+.png',
  530: 'assets/streaming_services/peacock.png',
};

const String privacyPolicy = '''Privacy Policy for Watch Next

Last Updated: February 1, 2026

1. Introduction

This Privacy Policy describes how Watch Next ("we", "our", or "the App") collects, uses, and protects your information when you use our mobile application. By using Watch Next, you agree to the collection and use of information in accordance with this policy.

2. Information We Collect

2.1 User Account Information
- User ID: A unique identifier generated when you first use the App, stored locally on your device and in our secure database.
- Account timestamps: When you first opened the App and your most recent app open.

2.2 Watchlist Data
- Movies and TV shows you add to your watchlist
- Streaming service preferences you select
- Availability status of content on your preferred streaming services
- Timestamps of when content was added or checked

2.3 Device Information
- Firebase Cloud Messaging (FCM) token: A unique device identifier used exclusively to deliver push notifications about content availability changes
- Device platform (iOS/Android) for notification compatibility

2.4 Usage and Behavioral Data
We collect information about how you interact with the App to improve your experience:
- App opens and session timestamps
- Recommendation requests and the search queries you enter
- Content you add to or remove from your watchlist, including where in the App you added it from
- Search queries you perform and results you select
- Playlists and curated collections you view or interact with
- Settings changes including language, region, and streaming service preferences
- General feature usage patterns

2.5 Analytics Data
We use Firebase Analytics to understand app usage patterns:
- Features used within the app
- General device information (model, OS version)
- Crash reports and performance data

2.6 Advertising Data
We use Google Mobile Ads to display advertisements:
- Ad interaction data (views, clicks)
- Device advertising ID (can be reset in your device settings)

3. How We Use Your Information

We use the collected information for the following purposes:
- To maintain and sync your watchlist across sessions
- To check content availability on your selected streaming services
- To send you daily notifications when watchlisted content becomes available on your streaming services (only if you opt-in to notifications)
- To understand how users interact with different features
- To improve our recommendation system and app experience
- To display relevant advertisements
- To analyze app usage and fix technical issues

4. Data Storage and Security

4.1 Cloud Storage
Your watchlist data, user ID, and usage data are stored in Google Firebase Firestore, a secure cloud database platform. Firebase implements industry-standard security measures including encryption in transit and at rest.

4.2 Local Storage
Your user ID, streaming service preferences, and notification settings are stored locally on your device using secure local storage.

4.3 Security Measures
We implement appropriate technical and organizational security measures to protect your information. However, no method of transmission over the internet or electronic storage is 100% secure.

5. Third-Party Services

We use the following third-party services that may collect and process data:

5.1 Firebase Services (Google LLC)
- Firebase Firestore (data storage)
- Firebase Cloud Messaging (push notifications)
- Firebase Analytics (app usage analytics)
Privacy Policy: https://firebase.google.com/support/privacy

5.2 The Movie Database (TMDB)
- Content metadata and availability information
Privacy Policy: https://www.themoviedb.org/privacy-policy

5.3 Google Mobile Ads
- Advertisement display and tracking
Privacy Policy: https://policies.google.com/privacy

5.4 OpenAI
- Processing of recommendation queries to generate personalized suggestions
- Your search queries are sent to OpenAI's API to generate recommendations
Privacy Policy: https://openai.com/privacy

6. Push Notifications

If you grant notification permissions:
- We will send you a maximum of one notification per day
- Notifications are sent only when content on your watchlist becomes available on your selected streaming services
- You can disable notifications at any time in your device settings
- We do not use notifications for marketing purposes

7. Data Retention

- Watchlist data: Retained as long as you use the App
- Usage data: Retained for up to 24 months to analyze long-term usage patterns
- FCM tokens: Automatically expire and are refreshed by Firebase; invalid tokens are removed
- Analytics data: Retained according to Firebase Analytics default retention periods (14 months)
- You can request deletion of all your data by contacting us

8. Your Rights

You have the right to:
- Access your personal data stored in our systems
- Request correction of inaccurate data
- Request deletion of your data
- Opt-out of push notifications at any time
- Reset your advertising ID in your device settings

9. Children's Privacy

Watch Next is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If we discover that a child under 13 has provided us with personal information, we will delete such information immediately.

10. International Data Transfers

Your information may be transferred to and processed in countries other than your country of residence. These countries may have different data protection laws. By using our App, you consent to such transfers.

11. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last Updated" date at the top of this policy. Significant changes will be communicated through an in-app notification. Your continued use of the App after changes constitutes acceptance of the updated policy.

12. Contact Information

If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us at:

Email: [Your Contact Email]

13. Legal Compliance

This Privacy Policy complies with applicable data protection laws including:
- General Data Protection Regulation (GDPR) for users in the European Economic Area
- California Consumer Privacy Act (CCPA) for users in California
- Other applicable regional data protection laws

14. Third-Party Links

Our App may contain links to streaming service websites or other third-party services. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies before providing any personal information.''';
