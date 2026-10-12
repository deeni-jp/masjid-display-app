/**
 * Create mosque/settings document in Firestore
 *
 * This is a simple script to create the mosque/settings document needed
 * by the cloud functions for automatic prayer time notifications.
 *
 * Usage: node scripts/create-mosque-settings.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin with application default credentials
// This will use the Firebase project configuration from .firebaserc
admin.initializeApp({
  projectId: 'dticc-app'
});

const db = admin.firestore();

async function createMosqueSettings() {
  try {
    console.log('\n=== Creating Mosque Settings Document ===\n');

    // Default settings for Darut Tauhid Masjid
    // TODO: Replace these coordinates with your mosque's actual location
    const settings = {
      // Placeholder coordinates - UPDATE THESE!
      // To find your mosque's coordinates:
      // 1. Go to Google Maps
      // 2. Search for "Darut Tauhid Masjid"
      // 3. Right-click on the location → "What's here?"
      // 4. Copy the latitude and longitude
      latitude: 40.7128,  // Example: New York City latitude
      longitude: -74.0060, // Example: New York City longitude

      // Calculation method
      // 1 = Karachi, 2 = ISNA, 3 = MWL (default), 4 = Makkah, 5 = Egypt
      method: 3,

      // School of jurisprudence
      // 0 = Shafi (default), 1 = Hanafi
      school: 1,

      // Metadata
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),

      // Optional: Add timezone for reference
      timezone: 'America/New_York'
    };

    console.log('Creating document with settings:');
    console.log(JSON.stringify(settings, null, 2));
    console.log('\nIMPORTANT: Update latitude and longitude with your mosque\'s actual coordinates!\n');

    // Create the document
    await db.collection('mosque').doc('settings').set(settings);

    console.log('✓ Successfully created mosque/settings document!\n');
    console.log('Verification URL:');
    console.log('https://console.firebase.google.com/project/dticc-app/firestore/data/mosque/settings\n');

    console.log('Next steps:');
    console.log('1. Go to Firebase Console and update the latitude/longitude');
    console.log('2. Verify the calculation method and school are correct');
    console.log('3. Deploy cloud functions: npx firebase deploy --only functions');
    console.log('4. Test the functions in Firebase Console\n');

    process.exit(0);
  } catch (error) {
    console.error('Error creating mosque/settings:', error);
    process.exit(1);
  }
}

createMosqueSettings();
