# Deployment Guide

## 🚀 **Overview**
This guide covers the deployment process for the Shinning Pools Flutter application, including Cloud Functions, security configurations, and troubleshooting steps.

## 📋 **Prerequisites**

### **Required Tools**
- Flutter SDK (latest stable version)
- Node.js (v18 or higher)
- Firebase CLI (`npm install -g firebase-tools`)
- Git

### **Firebase Project Setup**
- Firebase project: `shinningpools-8049e`
- Authentication enabled
- Firestore database configured
- Cloud Functions enabled

## 🔧 **Cloud Functions Deployment**

### **1. Install Dependencies**
```bash
cd functions
npm install
```

### **2. Login to Firebase**
```bash
firebase login
```

### **3. Deploy Functions**
```bash
# From project root
firebase deploy --only functions
```

### **4. Available Functions**
- `setInitialUserRole` - Automatically assigns roles on user registration
- `changeUserRole` - Secure role management (root only)
- `getUserInfo` - Get user information (root only)
- `listUsers` - List all users (root only)

### **5. Troubleshooting**

#### **Lint Errors**
If deployment fails due to lint errors:
1. Remove the predeploy hook from `firebase.json`:
```json
"functions": [
  {
    "source": "functions",
    "codebase": "default",
    "ignore": [
      "node_modules",
      ".git",
      "firebase-debug.log",
      "firebase-debug.*.log",
      "*.local"
    ]
  }
]
```

#### **Syntax Errors**
- Ensure Node.js compatibility (avoid optional chaining `?.` in older versions)
- Use traditional conditional checks: `user.email ? user.email.toLowerCase() : null`

## 🔒 **Security Configuration**

### **Firestore Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && 
        (request.auth.uid == userId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'root');
      allow write: if request.auth != null && 
        (request.auth.uid == userId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'root');
    }
    
    // Companies collection
    match /companies/{companyId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['root', 'admin']);
    }
    
    // Other collections follow similar patterns
  }
}
```

### **Authentication Configuration**
- Email/Password authentication enabled
- Google Sign-In enabled
- Email verification required for sensitive operations

## 📱 **Flutter App Deployment**

### **1. Build for Production**
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### **2. Test Build**
```bash
# Run tests
flutter test

# Static analysis
flutter analyze
```

### **3. Deploy to Stores**

#### **Android (Google Play Store)**
1. Generate signed APK/Bundle
2. Upload to Google Play Console
3. Configure release notes and metadata

#### **iOS (App Store)**
1. Archive in Xcode
2. Upload to App Store Connect
3. Configure app information and screenshots

## 🔄 **CI/CD Pipeline**

### **GitHub Actions Workflow**
```yaml
name: Deploy to Firebase
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install -g firebase-tools
      - run: firebase deploy --token "${{ secrets.FIREBASE_TOKEN }}"
```

## 📊 **Monitoring & Analytics**

### **Firebase Console**
- [Project Overview](https://console.firebase.google.com/project/shinningpools-8049e/overview)
- [Authentication](https://console.firebase.google.com/project/shinningpools-8049e/authentication)
- [Firestore](https://console.firebase.google.com/project/shinningpools-8049e/firestore)
- [Functions](https://console.firebase.google.com/project/shinningpools-8049e/functions)

### **Key Metrics to Monitor**
- Function execution times
- Authentication success/failure rates
- Database read/write operations
- Error rates and logs

## 🚨 **Emergency Procedures**

### **Rollback Process**
1. Identify the issue in Firebase Console
2. Revert to previous function version if needed
3. Update Flutter app if required
4. Communicate with users

### **Security Incident Response**
1. Immediately disable affected functions
2. Review logs for suspicious activity
3. Update security rules if needed
4. Notify stakeholders

## 📞 **Support & Maintenance**

### **Regular Tasks**
- Monitor function performance
- Review security logs
- Update dependencies
- Backup critical data

### **Contact Information**
- Development Team: [Contact Info]
- Firebase Support: [Firebase Console]
- Emergency Contact: [Emergency Contact]

---

**⚠️ IMPORTANT**: Always test deployments in a staging environment before production. Keep backups of critical configurations and data.

**🔒 Security Note**: Regularly review and update security rules and authentication settings. 