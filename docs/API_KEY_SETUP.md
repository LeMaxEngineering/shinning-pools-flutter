# API Key Setup Guide

## 🚀 Quick Setup for Development

### 1. Google Maps API Key Setup

#### Step 1: Get Your API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Select your project: `shinningpools-8049e`
3. Click "Create Credentials" → "API Key"
4. Copy the generated API key

#### Step 2: Configure the API Key
1. **For Web Development**:
   ```bash
   # Copy the template file
   cp web/config.template.js web/config.js
   
   # Edit config.js and replace YOUR_ACTUAL_API_KEY_HERE with your actual key
   ```

2. **For Android Development**:
   ```bash
   # Create local.properties file (if it doesn't exist)
   echo "GOOGLE_MAPS_API_KEY=your_actual_api_key_here" >> android/local.properties
   ```

#### Step 3: Enable Required APIs
In Google Cloud Console, enable these APIs:
- Maps JavaScript API
- Directions API
- Geocoding API
- Places API (if needed)

### 2. API Key Restrictions (Security)

#### Web Restrictions
1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Click on your API key
3. Under "Application restrictions", select "HTTP referrers (web sites)"
4. Add your domains:
   ```
   http://localhost:*
   https://yourdomain.com/*
   ```

#### Android Restrictions
1. Under "Application restrictions", select "Android apps"
2. Add your package name: `com.example.shinning_pools_flutter`
3. Add your SHA-1 certificate fingerprint

### 3. Billing Setup
1. Go to [Google Cloud Billing](https://console.cloud.google.com/billing)
2. Link a billing account to your project
3. Set up billing alerts to avoid unexpected charges

## 🔧 Configuration Files

### Web Configuration (`web/config.js`)
```javascript
window.APP_CONFIG = {
  GOOGLE_MAPS_API_KEY: 'your_actual_api_key_here',
  // ... other settings
};
```

### Android Configuration (`android/local.properties`)
```properties
GOOGLE_MAPS_API_KEY=your_actual_api_key_here
```

## 🛡️ Security Best Practices

### 1. Never Commit API Keys
- ✅ `web/config.js` is in `.gitignore`
- ✅ `android/local.properties` is in `.gitignore`
- ✅ Use `config.template.js` for documentation

### 2. Use Environment Variables in Production
```bash
# Set environment variables
export GOOGLE_MAPS_API_KEY=your_production_key
export FIREBASE_SERVICE_ACCOUNT_KEY=your_service_account_json
```

### 3. API Key Restrictions
- **HTTP Referrers**: Restrict to your domains
- **Android Apps**: Restrict to your package name
- **API Restrictions**: Only enable required APIs

### 4. Monitoring
- Set up billing alerts
- Monitor API usage
- Review access logs regularly

## 🚨 Troubleshooting

### "InvalidKey" Error
**Cause**: API key not configured or invalid
**Solution**:
1. Check if `web/config.js` exists and has the correct key
2. Verify the key is valid in Google Cloud Console
3. Ensure the key has the required APIs enabled

### "RefererNotAllowedMapError"
**Cause**: Domain not in API key restrictions
**Solution**:
1. Add your domain to HTTP referrers in Google Cloud Console
2. For development, add `http://localhost:*`

### "QuotaExceededError"
**Cause**: API usage limit reached
**Solution**:
1. Check billing account is linked
2. Increase quota limits if needed
3. Monitor usage patterns

### "ApiNotEnabledMapError"
**Cause**: Required API not enabled
**Solution**:
1. Enable Maps JavaScript API
2. Enable Directions API
3. Enable Geocoding API

## 📋 Setup Checklist

### Development Setup
- [ ] Google Maps API key obtained
- [ ] `web/config.js` created with valid key
- [ ] `android/local.properties` configured
- [ ] Required APIs enabled
- [ ] Domain restrictions configured
- [ ] Billing account linked

### Production Setup
- [ ] Production API key created
- [ ] Environment variables configured
- [ ] Domain restrictions set
- [ ] Billing alerts configured
- [ ] Usage monitoring enabled
- [ ] Security rules reviewed

## 🔄 Updating API Keys

### When to Update
- API key compromised
- Domain changes
- Package name changes
- Security requirements change

### Update Process
1. Generate new API key in Google Cloud Console
2. Update configuration files
3. Test functionality
4. Remove old key after verification
5. Update team members

## 📞 Support

- **Google Cloud Console**: [https://console.cloud.google.com](https://console.cloud.google.com)
- **Google Maps Documentation**: [https://developers.google.com/maps](https://developers.google.com/maps)
- **Firebase Console**: [https://console.firebase.google.com](https://console.firebase.google.com)

---

**⚠️ IMPORTANT**: Keep your API keys secure and never commit them to version control. Use the template files and environment variables for proper security. 