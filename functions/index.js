const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();

// Define the TMDB API key as a secret
const tmdbApiKey = defineSecret("TMDB_API_KEY");

/**
 * Daily scheduled function to check watchlist availability
 * Runs every day at 9 AM UTC
 * Free tier: 3 Cloud Scheduler jobs included
 */
exports.checkWatchlistAvailability = onSchedule(
    {
      schedule: "0 9 * * *",
      timeZone: "UTC",
      secrets: [tmdbApiKey], // Make the secret available to this function
    },
    async (event) => {
  console.log("Starting daily watchlist availability check");

  const db = admin.firestore();
  const messaging = admin.messaging();

  try {
    // Get all users with watchlist items
    const usersSnapshot = await db.collection("users").get();

    let totalNotificationsSent = 0;
    const today = new Date().toISOString().split("T")[0];

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();

      // Skip if no FCM token
      if (!userData.fcmToken) {
        console.log(`User ${userId} has no FCM token, skipping`);
        continue;
      }

      // Check if we already sent a notification today
      if (userData.lastNotificationDate === today) {
        console.log(`Already sent notification to ${userId} today, skipping`);
        continue;
      }

      // Get user's watchlist
      const watchlistSnapshot = await db
          .collection("users")
          .doc(userId)
          .collection("watchlist")
          .get();

      if (watchlistSnapshot.empty || watchlistSnapshot.size < 3) {
        console.log(`User ${userId} has less than 3 items, skipping`);
        continue;
      }

      // Get user's streaming services
      const userServicesDoc = await db
          .collection("users")
          .doc(userId)
          .collection("preferences")
          .doc("streaming_services")
          .get();

      const userServices = userServicesDoc.exists ?
        userServicesDoc.data().services || [] : [];

      if (userServices.length === 0) {
        console.log(`User ${userId} has no streaming services, skipping`);
        continue;
      }

      let hasAvailabilityChanges = false;
      const updates = [];

      // Check each watchlist item
      for (const watchlistDoc of watchlistSnapshot.docs) {
        const item = watchlistDoc.data();
        const mediaId = item.mediaId;
        const isMovie = item.isMovie;

        // Fetch current availability from TMDB
        const availability = await fetchAvailability(
            mediaId,
            isMovie,
            userData.region || "US",
        );

        // Compare with stored availability
        const oldStreamingServices = item.availability?.streaming || [];
        const newStreamingServices = availability.streaming || [];

        // Check if any new streaming services match user's services
        const newlyAvailable = newStreamingServices.filter(
            (serviceId) =>
              userServices.includes(serviceId) &&
            !oldStreamingServices.includes(serviceId),
        );

        if (newlyAvailable.length > 0) {
          hasAvailabilityChanges = true;
          console.log(
              `Found ${newlyAvailable.length} new services for ${item.title}`,
          );
        }

        // Prepare update
        updates.push({
          docId: watchlistDoc.id,
          data: {
            availability: availability,
            lastChecked: admin.firestore.FieldValue.serverTimestamp(),
          },
        });
      }

      // Update all watchlist items with new availability
      const batch = db.batch();
      for (const update of updates) {
        const ref = db
            .collection("users")
            .doc(userId)
            .collection("watchlist")
            .doc(update.docId);
        batch.update(ref, update.data);
      }
      await batch.commit();

      // Send notification if there are changes
      if (hasAvailabilityChanges) {
        try {
          await messaging.send({
            token: userData.fcmToken,
            notification: {
              title: "Your watchlist has updates!",
              body: "Check what's available on your streaming services",
            },
            data: {
              type: "watchlist_update",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                },
              },
            },
            android: {
              priority: "high",
              notification: {
                sound: "default",
                priority: "high",
              },
            },
          });

          // Update last notification date
          await db.collection("users").doc(userId).update({
            lastNotificationDate: today,
          });

          totalNotificationsSent++;
          console.log(`Sent notification to user ${userId}`);
        } catch (error) {
          console.error(`Failed to send notification to ${userId}:`, error);
          // If token is invalid, remove it
          if (error.code === "messaging/invalid-registration-token" ||
              error.code === "messaging/registration-token-not-registered") {
            await db.collection("users").doc(userId).update({
              fcmToken: admin.firestore.FieldValue.delete(),
            });
          }
        }
      } else {
        console.log(`No availability changes for user ${userId}`);
      }
    }

    console.log(`Completed. Sent ${totalNotificationsSent} notifications`);
    return {success: true, notificationsSent: totalNotificationsSent};
  } catch (error) {
    console.error("Error in checkWatchlistAvailability:", error);
    throw error;
  }
});

/**
 * Fetch availability from TMDB API
 * @param {number} mediaId - TMDB media ID
 * @param {boolean} isMovie - true for movie, false for TV show
 * @param {string} region - ISO 3166-1 country code
 * @return {Object} Availability object with streaming, rent, buy arrays
 */
async function fetchAvailability(mediaId, isMovie, region) {
  const apiKey = tmdbApiKey.value();
  if (!apiKey) {
    throw new Error("TMDB_API_KEY not configured");
  }

  const mediaType = isMovie ? "movie" : "tv";
  const url = `https://api.themoviedb.org/3/${mediaType}/${mediaId}/watch/providers?api_key=${apiKey}`;

  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`TMDB API error: ${response.status}`);
    }

    const data = await response.json();
    const regionData = data.results?.[region];

    if (!regionData) {
      return {streaming: [], rent: [], buy: []};
    }

    return {
      streaming: (regionData.flatrate || []).map((p) => p.provider_id),
      rent: (regionData.rent || []).map((p) => p.provider_id),
      buy: (regionData.buy || []).map((p) => p.provider_id),
    };
  } catch (error) {
    console.error(`Error fetching availability for ${mediaId}:`, error);
    return {streaming: [], rent: [], buy: []};
  }
}
