# Project Structure - Shinning Pools

## Overview

Shinning Pools is a Flutter-based SaaS application for pool maintenance companies. The project follows Clean Architecture principles with a feature-based structure and uses Firebase as the backend service.

## Technology Stack

### Frontend
- **Framework**: Flutter (Dart)
- **Architecture**: Clean Architecture
- **State Management**: Provider
- **UI Framework**: Custom Material Design system
- **Platforms**: Web, Android, iOS, Desktop

### Backend & Services
- **Authentication**: Firebase Authentication
- **Database**: Firestore (NoSQL)
- **Hosting**: Firebase Hosting
- **Functions**: Firebase Functions
- **Storage**: Firebase Storage

## Project Structure

```
shinning_pools_flutter/
├── android/                    # Android platform-specific code
├── ios/                       # iOS platform-specific code
├── web/                       # Web platform-specific code
├── windows/                   # Windows platform-specific code
├── macos/                     # macOS platform-specific code
├── linux/                     # Linux platform-specific code
├── assets/                    # Static assets (images, fonts, etc.)
│   ├── img/                   # Image assets
│   └── temp/                  # Temporary assets
├── docs/                      # Project documentation
│   ├── database_structure.json # Database schema documentation
│   ├── sample_data.json       # Sample data examples
│   ├── project_progress.md    # Development progress tracking
│   ├── development_plan.md    # Development roadmap
│   ├── development_chat.md    # Development discussion history
│   ├── project_screens.md     # Screen structure documentation
│   ├── project_rules.mdc      # Project rules and guidelines
│   └── project_structure.md   # This file
├── functions/                 # Firebase Cloud Functions
│   ├── index.js              # Functions entry point
│   ├── package.json          # Functions dependencies
│   └── package-lock.json     # Functions lock file
├── lib/                       # Main application code
│   ├── core/                  # Core application components
│   │   ├── app.dart          # Main application entry point
│   │   ├── auth_wrapper.dart # Authentication wrapper
│   │   ├── constants/        # Application constants
│   │   ├── services/         # Core services
│   │   │   ├── account_deletion_service.dart
│   │   │   ├── auth_repository.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── customer_repository.dart
│   │   │   ├── firebase_auth_repository.dart
│   │   │   ├── firestore_service.dart
│   │   │   ├── navigation_service.dart
│   │   │   ├── pool_repository.dart
│   │   │   ├── role.dart
│   │   │   ├── route_repository.dart
│   │   │   └── user.dart
│   │   └── utils/            # Utility functions
│   ├── features/             # Feature modules
│   │   ├── auth/             # Authentication feature
│   │   │   ├── screens/      # Authentication screens
│   │   │   │   ├── email_verification_screen.dart
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   └── splash_screen.dart
│   │   │   └── viewmodels/   # Authentication view models
│   │   ├── companies/        # Company management feature
│   │   │   ├── models/       # Company models
│   │   │   │   └── company.dart
│   │   │   └── screens/      # Company screens
│   │   │       ├── companies_list_screen.dart
│   │   │       ├── company_edit_screen.dart
│   │   │       ├── company_management_screen.dart
│   │   │       ├── company_registration_screen.dart
│   │   │       └── create_company_screen.dart
│   │   │   └── services/     # Company services
│   │   │       └── company_service.dart
│   │   ├── customers/        # Customer management feature
│   │   │   ├── screens/      # Customer screens
│   │   │   │   ├── customer_form_screen.dart
│   │   │   │   └── customers_list_screen.dart
│   │   │   └── viewmodels/   # Customer view models
│   │   ├── dashboard/        # Dashboard feature
│   │   │   ├── screens/      # Dashboard screens
│   │   │   │   ├── associated_dashboard.dart
│   │   │   │   ├── company_dashboard.dart
│   │   │   │   ├── customer_dashboard.dart
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   └── root_dashboard.dart
│   │   │   └── viewmodels/   # Dashboard view models
│   │   ├── pools/            # Pool management feature
│   │   │   ├── screens/      # Pool screens
│   │   │   │   ├── maintenance_form_screen.dart
│   │   │   │   ├── pool_details_screen.dart
│   │   │   │   ├── pool_form_screen.dart
│   │   │   │   └── pools_list_screen.dart
│   │   │   ├── services/     # Pool services
│   │   │   │   └── pool_service.dart
│   │   │   └── viewmodels/   # Pool view models
│   │   ├── reports/          # Reports feature
│   │   │   ├── screens/      # Report screens
│   │   │   │   ├── report_details_screen.dart
│   │   │   │   └── reports_list_screen.dart
│   │   │   └── viewmodels/   # Report view models
│   │   ├── routes/           # Route management feature
│   │   │   ├── screens/      # Route screens
│   │   │   │   ├── route_details_screen.dart
│   │   │   │   └── routes_list_screen.dart
│   │   │   └── viewmodels/   # Route view models
│   │   └── users/            # User management feature
│   │       ├── screens/      # User screens
│   │       │   ├── associated_form_screen.dart
│   │       │   ├── associated_list_screen.dart
│   │       │   └── profile_screen.dart
│   │       └── viewmodels/   # User view models
│   ├── firebase_options.dart # Firebase configuration
│   ├── l10n/                 # Localization
│   │   └── l10n.dart
│   ├── main.dart             # Application entry point
│   └── shared/               # Shared components
│       └── ui/               # Shared UI components
│           ├── theme/        # Theme configuration
│           │   ├── app_theme.dart
│           │   ├── colors.dart
│           │   └── text_styles.dart
│           └── widgets/      # Reusable widgets
│               ├── app_background.dart
│               ├── app_button.dart
│               ├── app_card.dart
│               └── app_text_field.dart
├── test/                     # Test files
│   ├── mock.dart
│   ├── widget_test.dart
│   └── widget_test.mocks.dart
├── firebase.json             # Firebase configuration
├── firestore.rules           # Firestore security rules
├── pubspec.lock              # Dependencies lock file
├── pubspec.yaml              # Dependencies configuration
└── README.md                 # Project readme
```

## Architecture Overview

### Clean Architecture Layers

1. **Presentation Layer** (`lib/features/*/screens/`)
   - UI components and screens
   - State management with Provider
   - User interactions and navigation

2. **Domain Layer** (`lib/core/services/`)
   - Business logic and entities
   - Repository interfaces
   - Use cases and services

3. **Data Layer** (`lib/core/services/`)
   - Repository implementations
   - Data sources (Firebase)
   - Data models and DTOs

### Feature-Based Structure

Each feature is organized as a module with:
- **Screens**: UI components and pages
- **ViewModels**: Business logic and state management
- **Models**: Data structures and entities
- **Services**: Feature-specific services

### Shared Components

- **Core Services**: Authentication, navigation, data access
- **UI Components**: Reusable widgets and theme system
- **Utilities**: Helper functions and constants

## Key Features

### Authentication System
- Firebase Authentication integration
- Google Sign-In and email/password
- Role-based access control
- Email verification

### Multi-tenant Architecture
- Company-based data isolation
- Role-based permissions
- Secure data boundaries

### Real-time Data
- Firestore real-time synchronization
- Live updates across devices
- Offline data support

### Responsive Design
- Cross-platform compatibility
- Adaptive UI components
- Touch and mouse support

## Development Guidelines

### Code Organization
- Follow Clean Architecture principles
- Maintain feature-based structure
- Keep shared components in appropriate directories
- Document all major components

### State Management
- Use Provider for state management
- Keep state as close to UI as possible
- Implement proper error handling
- Use reactive programming patterns

### Testing Strategy
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows
- Platform-specific testing

### Security
- Implement proper authentication
- Use Firestore security rules
- Validate all user inputs
- Protect sensitive data

## Database Structure

The application uses Firestore with the following collections:
- **users**: User accounts and authentication
- **companies**: Pool maintenance companies
- **customers**: Pool owners and customers
- **pools**: Swimming pools managed by the system
- **routes**: Service routes for maintenance workers
- **reports**: Maintenance service reports

See `docs/database_structure.json` for detailed schema documentation.

## Deployment

### Development
- Local development with Firebase emulators
- Hot reload for rapid development
- Debug mode with comprehensive logging

### Production
- Firebase hosting for web deployment
- Firebase Functions for backend logic
- Automated deployment with CI/CD

## Future Enhancements

### Planned Features
- Route optimization with Google Maps
- Advanced analytics and reporting
- Mobile app development
- Third-party integrations

### Technical Improvements
- Performance optimization
- Advanced caching strategies
- Offline-first architecture
- Multi-language support

## Conclusion

The Shinning Pools project structure follows modern Flutter development practices with a focus on maintainability, scalability, and user experience. The Clean Architecture approach ensures separation of concerns and testability, while the feature-based organization promotes modular development and team collaboration.

---
Last updated: June 2025