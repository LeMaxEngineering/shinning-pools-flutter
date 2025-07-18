// Development configuration template
// Copy this file to config.dev.js and update with your development API key

window.APP_CONFIG_DEV = {
  // Development Google Maps API Key
  // Get your development key from: https://console.cloud.google.com/apis/credentials
  // Make sure to restrict it to localhost and development domains
  GOOGLE_MAPS_API_KEY: 'YOUR_DEVELOPMENT_API_KEY_HERE',
  
  // Development settings
  DEBUG_MODE: true,
  API_BASE_URL: 'http://localhost:4000',
  
  // Feature flags for development
  FEATURES: {
    MAPS_ENABLED: true,
    ROUTE_OPTIMIZATION: true,
    PHOTO_UPLOAD: true,
    REAL_TIME_UPDATES: true
  }
};

// Auto-load development config if no environment variables are set
if (!window.env || !window.env.GOOGLE_MAPS_API_KEY) {
  console.log('Loading development configuration...');
  window.env = window.env || {};
  window.env.GOOGLE_MAPS_API_KEY = window.APP_CONFIG_DEV.GOOGLE_MAPS_API_KEY;
} 