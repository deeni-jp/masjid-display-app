/**
 * Initialize mosque/settings document in Firestore
 *
 * This script creates the mosque/settings document needed by the cloud functions
 * to automatically schedule prayer time notifications.
 *
 * Usage:
 *   node init-mosque-settings.js
 *
 * You will be prompted to enter:
 *   - Mosque latitude (e.g., 40.7128 for New York)
 *   - Mosque longitude (e.g., -74.0060 for New York)
 *   - Calculation method (default: 3 - Muslim World League)
 *   - School of jurisprudence (default: 1 - Hanafi)
 *
 * To find your mosque's coordinates:
 *   1. Go to https://www.google.com/maps
 *   2. Search for "Darut Tauhid Masjid" or your mosque name
 *   3. Right-click on the mosque location and select "What's here?"
 *   4. Copy the latitude and longitude values
 */

const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Create readline interface for user input
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise((resolve) => {
    rl.question(query, resolve);
  });
}

async function initializeMosqueSettings() {
  console.log('\n=== Initialize Mosque Settings ===\n');
  console.log('This will create the mosque/settings document in Firestore.');
  console.log('The cloud functions need this document to automatically send prayer time notifications.\n');

  try {
    // Get mosque coordinates
    const latitude = parseFloat(await question('Enter mosque latitude (e.g., 40.7128): '));
    const longitude = parseFloat(await question('Enter mosque longitude (e.g., -74.0060): '));

    if (isNaN(latitude) || isNaN(longitude)) {
      console.error('Error: Invalid coordinates. Please enter valid numbers.');
      process.exit(1);
    }

    // Get calculation method
    console.log('\nCalculation Methods:');
    console.log('  1 - University of Islamic Sciences, Karachi');
    console.log('  2 - Islamic Society of North America (ISNA)');
    console.log('  3 - Muslim World League (Default)');
    console.log('  4 - Umm Al-Qura University, Makkah');
    console.log('  5 - Egyptian General Authority of Survey');
    const methodInput = await question('Enter calculation method (default: 3): ');
    const method = methodInput ? parseInt(methodInput) : 3;

    // Get school of jurisprudence
    console.log('\nSchool of Jurisprudence:');
    console.log('  0 - Shafi (Default)');
    console.log('  1 - Hanafi');
    const schoolInput = await question('Enter school (default: 1 for Hanafi): ');
    const school = schoolInput ? parseInt(schoolInput) : 1;

    // Confirm settings
    console.log('\n=== Mosque Settings ===');
    console.log(`Latitude: ${latitude}`);
    console.log(`Longitude: ${longitude}`);
    console.log(`Calculation Method: ${method}`);
    console.log(`School: ${school}`);
    console.log('\nLocation preview: https://www.google.com/maps?q=' + latitude + ',' + longitude);

    const confirm = await question('\nCreate this document in Firestore? (yes/no): ');

    if (confirm.toLowerCase() !== 'yes' && confirm.toLowerCase() !== 'y') {
      console.log('Cancelled.');
      process.exit(0);
    }

    // Create the document
    await db.collection('mosque').doc('settings').set({
      latitude: latitude,
      longitude: longitude,
      method: method,
      school: school,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('\n✓ Successfully created mosque/settings document!');
    console.log('\nNext steps:');
    console.log('  1. Deploy Firestore rules: firebase deploy --only firestore:rules');
    console.log('  2. Deploy cloud functions: firebase deploy --only functions');
    console.log('  3. Test the scheduleDailyPrayerNotifications function in Firebase Console');

  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    rl.close();
    process.exit(0);
  }
}

initializeMosqueSettings();
