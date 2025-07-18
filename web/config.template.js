// Configuration template file
// Copy this file to config.js and update with your actual values

window.APP_CONFIG = {
  // Google Maps API Key
  // Get your key from: https://console.cloud.google.com/apis/credentials
  // IMPORTANT: Replace with your actual API key and configure restrictions
  GOOGLE_MAPS_API_KEY: 'YOUR_ACTUAL_API_KEY_HERE',
  
  // Google Sign-In Client ID
  // IMPORTANT: Replace with your actual OAuth client ID
  GOOGLE_SIGNIN_CLIENT_ID: 'YOUR_OAUTH_CLIENT_ID_HERE',
  
  // App settings
  APP_NAME: 'Shinning Pools',
  APP_VERSION: '0.9.0-beta',
  
  // Development settings
  DEBUG_MODE: true,
  
  // API endpoints
  API_BASE_URL: 'https://us-central1-shinningpools-8049e.cloudfunctions.net',
  
  // Feature flags
  FEATURES: {
    MAPS_ENABLED: true,
    ROUTE_OPTIMIZATION: true,
    PHOTO_UPLOAD: true,
    REAL_TIME_UPDATES: true
  }
};

// Helper function to get config values
window.getConfig = function(key) {
  return window.APP_CONFIG[key];
};

// Helper function to check if feature is enabled
window.isFeatureEnabled = function(feature) {
  return window.APP_CONFIG.FEATURES[feature] === true;
};

console.log('App configuration template loaded'); 