# Project Screens - Shinning Pools

## Overview

This document outlines the screen structure and user flow for the Shinning Pools application, a multi-tenant SaaS platform for pool maintenance companies. The application supports four distinct user roles: Root (Platform Owner), Admin (Company Administrator), Associated (Worker) and Customer (Company Customer).

## User Roles & Access

### Role 1: Root (Platform Owner)
- **Description**: Platform administrator with full system access
- **Permissions**: All features and data access
- **Primary Functions**: Company management, system administration, global analytics

### Role 2: Admin (Company Administrator)
- **Description**: Company owner or administrator
- **Permissions**: Company-specific data and features
- **Primary Functions**: User management, pool management, route planning, company analytics

### Role 3: Customer (Company Customer)
- **Description**: Pool owner with read-only access to their pools
- **Permissions**: View own pools and maintenance history
- **Primary Functions**: Pool monitoring, service report access, billing information

### Role 4: Associated (Worker)
- **Description**: Field technician or maintenance worker
- **Permissions**: Assigned routes and tasks
- **Primary Functions**: Route execution, maintenance reporting, task completion

## Screen Structure

### Authentication Screens

#### 1. Splash Screen
- **Purpose**: Initial loading screen with app branding
- **Features**: 
  - App logo and branding
  - Loading animation
  - Authentication state check
- **Navigation**: Auto-navigate to appropriate screen based on auth state

#### 2. Login Screen
- **Purpose**: User authentication
- **Features**:
  - Email/password login
  - Google Sign-In integration
  - "Remember me" option
  - Forgot password link
  - Registration link
- **Navigation**: Dashboard (if authenticated) or Register screen

#### 3. Register Screen
- **Purpose**: New user registration
- **Features**:
  - Email/password registration
  - Google Sign-In registration
  - Terms and conditions acceptance
  - Email verification prompt
- **Navigation**: Email verification screen or Dashboard

#### 4. Email Verification Screen
- **Purpose**: Email verification for new accounts
- **Features**:
  - Verification status display
  - Resend verification email
  - Manual verification check
- **Navigation**: Dashboard (if verified) or back to login

### Dashboard Screens

#### 5. Root Dashboard
- **Purpose**: Platform administration interface
- **Features**:
  - Company management (approve, suspend, delete)
  - Global analytics and metrics
  - System settings and configuration
  - User management across all companies
  - Platform-wide reports
- **Navigation**: Company management, user management, system settings

#### 6. Company Dashboard
- **Purpose**: Company-specific management interface
- **Features**:
  - Company overview and metrics
  - User management (workers, customers)
  - Pool management and analytics
  - Route planning and optimization
  - Billing and financial management
- **Navigation**: User management, pool management, route management

#### 7. Customer Dashboard
- **Purpose**: Pool owner interface
- **Features**:
  - Pool overview and status
  - Maintenance history and reports
  - Service scheduling information
  - Billing and payment access
  - Company registration (if not associated)
- **Navigation**: Pool details, service reports, billing

#### 8. Associated Dashboard
- **Purpose**: Field worker interface
- **Features**:
  - Assigned routes and tasks
  - Route navigation and tracking
  - Maintenance form access
  - Task completion reporting
  - Work history and analytics
- **Navigation**: Route details, maintenance forms, work history

### Management Screens

#### 9. User Management Screen
- **Purpose**: Manage company users
- **Features**:
  - User list with search and filters
  - Add new users
  - Edit user profiles
  - Assign roles and permissions
  - User status management
- **Navigation**: User details, add user, edit user

#### 10. Pool Management Screen
- **Purpose**: Manage customer pools
- **Features**:
  - Pool list with search and filters
  - Add new pools
  - Edit pool information
  - Pool status management
  - Maintenance scheduling
- **Navigation**: Pool details, add pool, edit pool

#### 11. Route Management Screen
- **Purpose**: Plan and manage service routes
- **Features**:
- Route creation and optimization
  - Google Maps integration
  - Worker assignment
  - Route scheduling
  - Route analytics
- **Navigation**: Route details, create route, route analytics

#### 12. Company Management Screen (Root Only)
- **Purpose**: Manage platform companies
- **Features**:
  - Company list with status filters
  - Company approval/rejection
  - Company suspension/activation
  - Company analytics
  - Billing management
- **Navigation**: Company details, company analytics

### Detail Screens

#### 13. Pool Details Screen
- **Purpose**: Detailed pool information
- **Features**:
  - Pool specifications and history
  - Maintenance records
  - Water quality metrics
  - Equipment inventory
  - Service scheduling
- **Navigation**: Maintenance history, equipment details

#### 14. Route Details Screen
- **Purpose**: Detailed route information
- **Features**:
  - Route map and directions
  - Stop list and timing
  - Worker assignment
  - Progress tracking
  - Route optimization
- **Navigation**: Google Maps, stop details

#### 15. User Details Screen
- **Purpose**: Detailed user information
- **Features**:
  - User profile and contact info
  - Role and permissions
  - Work history and performance
  - Account status
  - Activity logs
- **Navigation**: Edit user, work history

### Form Screens

#### 16. Pool Form Screen
- **Purpose**: Add or edit pool information
- **Features**:
  - Pool specifications form
  - Location and address input
  - Customer association
  - Equipment inventory
  - Service preferences
- **Navigation**: Customer selection, location picker

#### 17. Maintenance Form Screen
- **Purpose**: Report maintenance activities
- **Features**:
- Maintenance type selection
  - Materials and chemicals used
  - Equipment changes
  - Time and cost tracking
  - Photo documentation
- **Navigation**: Material selection, photo capture

#### 18. Company Registration Screen
- **Purpose**: Register new company
- **Features**:
  - Company information form
  - Owner details
  - Service preferences
  - Terms acceptance
  - Submission for approval
- **Navigation**: Terms and conditions, approval status

### Report Screens

#### 19. Reports List Screen
- **Purpose**: View and manage reports
- **Features**:
  - Report list with filters
  - Search functionality
  - Export options
  - Report status tracking
  - Analytics overview
- **Navigation**: Report details, create report

#### 20. Report Details Screen
- **Purpose**: Detailed report view
- **Features**:
  - Complete report information
  - Maintenance details
  - Cost breakdown
  - Photo documentation
  - Customer signature
- **Navigation**: Edit report, export PDF

### Profile & Settings

#### 21. Profile Screen
- **Purpose**: User profile management
- **Features**:
  - Profile information editing
  - Photo upload
  - Password change
  - Account settings
  - Logout functionality
- **Navigation**: Edit profile, change password

## Navigation Matrix

| Screen / Role | Admin | Associated | Customer |
|---------------|-------|------------|----------|
| Dashboard | ✅ | ✅ | ✅ |
| User Management | ✅ | ❌ | ❌ |
| Pool Management | ✅ | ✅ | ❌ |
| Route Management | ✅ | ✅ | ❌ |
| Company Management | ❌ | ❌ | ❌ |
| Reports | ✅ | ✅ | ✅ |
| Profile | ✅ | ✅ | ✅ |

## Screen Flow Diagrams

### Authentication Flow
```
Splash Screen → Login Screen → Dashboard
                ↓
            Register Screen → Email Verification → Dashboard
```

### Customer Flow
```
Customer Dashboard → Pool Details → Service Reports
        ↓
    Company Registration → Approval Status
```

### Admin Flow
```
Company Dashboard → User Management → Pool Management → Route Management
        ↓
    Reports → Analytics → Billing
```

### Worker Flow
```
Associated Dashboard → Route Details → Maintenance Forms → Task Completion
        ↓
    Work History → Performance Analytics
```

## Responsive Design

### Mobile Optimization
- Touch-friendly interface
- Simplified navigation
- Optimized forms
- Offline capability
- GPS integration

### Web Optimization
- Full-featured interface
- Multi-window support
- Advanced analytics
- Export functionality
- Keyboard shortcuts

### Tablet Optimization
- Hybrid mobile/web interface
- Split-screen support
- Enhanced forms
- Touch and mouse support

## Accessibility Features

### Visual Accessibility
- High contrast mode
- Large text options
- Color-blind friendly design
- Screen reader support

### Motor Accessibility
- Voice navigation
- Gesture controls
- Keyboard navigation
- Assistive technology support

### Cognitive Accessibility
- Simple navigation
- Clear instructions
- Error prevention
- Help and guidance

## Performance Considerations

### Loading Optimization
- Lazy loading for lists
- Image optimization
- Caching strategies
- Progressive loading

### Data Management
- Real-time synchronization
- Offline data storage
- Efficient queries
- Background updates

### User Experience
- Smooth animations
- Responsive interactions
- Error handling
- Loading states

## Security Features

### Authentication Security
- Multi-factor authentication
- Session management
- Secure token handling
- Account lockout

### Data Security
- Role-based access control
- Data encryption
- Secure API communication
- Audit logging

### Privacy Protection
- Data minimization
- User consent management
- Privacy controls
- GDPR compliance

## Future Enhancements

### Advanced Features
- AI-powered route optimization
- Predictive maintenance
- Advanced analytics
- Mobile app development

### Integrations
- Third-party payment systems
- Equipment manufacturer APIs
- Weather service integration
- Customer communication tools

### Platform Expansion
- Native mobile applications
- Desktop application
- API for third-party integrations
- Multi-language support

## Conclusion

The screen structure and user flow for Shinning Pools is designed to provide an intuitive and efficient experience for all user roles. The responsive design ensures compatibility across devices while maintaining security and performance standards. The modular approach allows for easy expansion and customization as the application grows. 