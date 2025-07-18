# Environment Setup Guide

## 🚀 Quick Setup for Environment Variables

Since you mentioned the `GOOGLE_MAPS_API_KEY` is in a `.env` file, I've created a flexible system that can work with your existing setup.

## 📋 Setup Options

### Option 1: Use the Setup Page (Easiest)
1. Open `web/setup-api-key.html` in your browser
2. Paste your Google Maps API key
3. Click "Save API Key"
4. Refresh your Flutter app

### Option 2: Manual Setup
1. Copy your API key from your `.env` file
2. Open browser console in your Flutter app
3. Run: `window.setEnv("GOOGLE_MAPS_API_KEY", "your_api_key_here")`
4. Refresh the page

### Option 3: Direct Configuration
1. Edit `web/config.js`
2. Replace `'YOUR_RESTRICTED_WEB_KEY'` with your actual API key
3. Save and refresh

## 🔧 How It Works

The new system loads environment variables in this order:
1. **Environment variables** (if available)
2. **Local storage** (for development)
3. **Manual configuration** (fallback)

## 📁 Files Created

- `web/env.js` - Environment variable loader
- `web/config.js` - Configuration management
- `web/setup-api-key.html` - Setup helper page
- `web/config.template.js` - Template for reference

## 🛡️ Security

- ✅ `web/config.js` and `web/env.js` are in `.gitignore`
- ✅ API keys are stored locally only
- ✅ No sensitive data in version control
- ✅ Template files for documentation

## 🚨 Troubleshooting

### "InvalidKey" Error
1. Check if API key is set: `window.getEnv("GOOGLE_MAPS_API_KEY")`
2. Use setup page: `web/setup-api-key.html`
3. Verify key in Google Cloud Console

### "API key not found" Warning
1. Set the key: `window.setEnv("GOOGLE_MAPS_API_KEY", "your_key")`
2. Or use the setup page
3. Refresh the app

## 🔄 Integration with Your .env File

If you want to integrate with your existing `.env` file:

1. **For development**: Use the setup page or manual setup
2. **For production**: Use build-time environment variables
3. **For CI/CD**: Set environment variables in your deployment pipeline

## 📞 Quick Commands

```javascript
// Check if API key is set
window.getEnv("GOOGLE_MAPS_API_KEY")

// Set API key
window.setEnv("GOOGLE_MAPS_API_KEY", "your_key_here")

// Check configuration
window.APP_CONFIG.GOOGLE_MAPS_API_KEY
```

---

**🎯 Next Step**: Open `web/setup-api-key.html` in your browser and configure your API key! 