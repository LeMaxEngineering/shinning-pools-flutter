# Shinning Pools - User Manual (English)

"The goal of this app is to focus on 'Maintenance', which will ensure it delivers its core value: making pool maintenance easy, traceable, and professional for both businesses and employees."

# Shinning Pools - User Manuals

Welcome! Please select your preferred language for the user manual:

- [English User Manual](user_manuals_en.md)
- [Manual de Usuario en Español](user_manuals_es.md)

> **Note:** Both manuals are kept up-to-date with the latest features and troubleshooting information. If you notice any outdated information, please contact the support team.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Root User Manual](#root-user-manual)
3. [Admin User Manual](#admin-user-manual)
4. [Customer User Manual](#customer-user-manual)
5. [Associated User Manual](#associated-user-manual)
6. [Troubleshooting](#troubleshooting)

---

## Getting Started

### First Time Setup

1. **Access the Application**
   - Open your web browser and navigate to the Shinning Pools application
   - The application is optimized for Chrome, Firefox, and Safari

2. **Account Creation**
   - Click "Register" on the login screen
   - Enter your email address and create a secure password
   - Complete email verification (check your inbox)
   - Fill in your profile information

3. **Role Assignment**
   - New users start with "Customer" role by default
   - To become a company admin, register your company (see Customer Manual)
   - Root users are pre-configured by system administrators

### Login Process

1. **Regular Login**
   - Enter your email and password
   - Click "Sign In"
   - You'll be redirected to your role-specific dashboard

2. **Google Sign-In**
   - Click "Sign in with Google"
   - Authorize the application
   - Complete profile setup if first time

3. **Password Recovery**
   - Click "Forgot Password?" on login screen
   - Enter your email address
   - Check your inbox for reset instructions

---

## Root User Manual

### Overview
Root users have complete system access and manage the entire platform, including company approvals, user management, and system configuration.

### Dashboard Features

#### **Company Management**
- **View All Companies**: Access the complete list of registered companies
- **Company Statistics**: See overview of pending, approved, and suspended companies
- **Search & Filter**: Find specific companies by name, email, or status

#### **Company Actions**
1. **Approve Company**
   - Navigate to Companies List
   - Find the pending company
   - Click "Approve" button
   - Company owner automatically becomes Admin role

2. **Edit Company Details**
   - Click the three-dot menu (⋮) next to a company
   - Select "Edit"
   - Modify company information
   - Save changes

3. **Suspend/Reactivate Company**
   - Use the actions menu to suspend active companies
   - Provide suspension reason when prompted
   - Reactivate suspended companies as needed

4. **Delete Company**
   - Use the actions menu to delete companies
   - Confirm deletion (this action cannot be undone)
   - Associated users revert to Customer role

#### **User Management**
- **View All Users**: Access complete user directory
- **Role Management**: Change user roles as needed
- **Profile Management**: Edit user profiles and permissions

#### **System Configuration**
- **Billing Plans**: Create and manage billing plans
- **Maintenance Types**: Configure maintenance categories
- **System Settings**: Manage platform-wide configurations

### Best Practices
- Review company registrations promptly
- Maintain clear communication with company owners
- Document all administrative actions
- Regular system monitoring and maintenance

---

## Admin User Manual

### Overview
Admin users manage their company's operations, including customer management, pool assignments, and team coordination.

### Dashboard Features

#### **Company Overview**
- **Company Statistics**: View key metrics and performance indicators
- **Recent Activity**: Monitor recent operations and updates
- **Quick Actions**: Access frequently used features

#### **Customer Management**
1. **Add New Customer**
   - Navigate to Customers section
   - Click "Add Customer"
   - Fill in customer information:
     - **Customer Photo**: Upload a profile photo (optional)
     - **Name**: Customer's full name (required)
     - **Email**: Contact email (optional but recommended)
     - **Phone**: Primary contact number (required)
     - **Address**: Customer's address (required)
     - **Service Type**: Standard or Premium
     - **Status**: Active or Inactive
   - Save customer profile

2. **Customer List Management**
   - View all company customers
   - Search and filter customers
   - Edit customer information
   - Manage customer pool assignments

#### **Pool Management**
1. **Add New Pool**
   - Navigate to Pools section
   - Click "Add Pool"
   - Enter pool details (size, type, location)
   - Assign to customer

2. **Pool Monitoring**
   - View all company pools
   - Track pool status and maintenance history
   - Schedule maintenance tasks
   - Generate pool reports

#### **Pool Dimension Input Guide**

This section details how the pool dimension system works and provides guidance for optimal data entry.

**📏 Understanding Pool Dimensions**

The pool size field accepts flexible text input but intelligently processes and stores numeric values. This hybrid approach gives you maximum convenience while maintaining data accuracy.

**✍️ Input Methods**

You can enter pool dimensions in several formats:

| Input Format | Example | What Happens | Final Result |
|--------------|---------|--------------|--------------|
| **Simple Number** | `40` | Direct parsing | `40.0 m²` |
| **Decimal Number** | `25.5` | Direct parsing | `25.5 m²` |
| **Dimensions (Width x Height)** | `25x15` | **Calculates area** | `375.0 m²` |
| **Dimensions with Units** | `30m x 20m` | Extracts first number | `30.0 m²` |
| **Mixed Format** | `50.5m` | Extracts number | `50.5 m²` |

**🔄 Processing Flow**

```
User Input (String) → Intelligent Parsing → Database Storage (Number) → Display (Formatted)

Examples:
"40"      → Direct parse      → 40.0    → "40.0 m²"
"25x15"   → Calculate area    → 375.0   → "375.0 m²"
"30m x 20m" → Extract number → 30.0    → "30.0 m²"
```

**🎯 Smart Features**

- **Automatic Area Calculation**: When you enter dimensions like `40x30`, the system automatically calculates the area (1,200 m²)
- **Unit Tolerance**: The system ignores units like 'm', 'ft', etc., and extracts the numeric values
- **Decimal Support**: Both whole numbers and decimals are supported (e.g., `25.5`)
- **Error Protection**: Invalid entries default to `0.0` safely

**💡 Best Practices**

1. **For Square/Rectangular Pools**: Use dimension format `LengthxWidth` (e.g., `25x15`)
2. **For Circular Pools**: Enter the area directly (e.g., `450`)
3. **For Irregular Pools**: Enter the total area (e.g., `320.5`)
4. **Include Decimals**: For precise measurements (e.g., `25.75x12.5`)

**⚠️ Important Notes**

- The system stores the final calculated value as a number in the database
- When editing existing pools, the stored number is displayed
- For dimension format (`LxW`), the system calculates and stores the total area
- All measurements are displayed with `m²` units in the interface

**🔧 Technical Details**

The intelligent parsing system follows this priority:
1. **Direct Number**: If input is a valid number, use it directly
2. **Dimension Calculation**: If format contains 'x', calculate width × height
3. **Number Extraction**: Extract first valid number from mixed formats
4. **Fallback**: Default to 0.0 for invalid input

**📊 Visual Processing Flow**

```
┌─────────────────────────────────────────────────────────────┐
│                    User Input Examples                      │
│  • "40" (simple number)                                    │
│  • "25x15" (dimensions)                                    │
│  • "30m x 20m" (with units)                               │
│  • "50.5" (decimal)                                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                _parseSize() Method                          │
│                                                             │
│  Step 1: Try direct number parsing                         │
│          ↓ (if fails)                                      │
│  Step 2: Check for 'x' format → Calculate area            │
│          ↓ (if fails)                                      │
│  Step 3: Extract first number using regex                  │
│          ↓ (if fails)                                      │
│  Step 4: Return 0.0 (fallback)                            │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                Database Storage                             │
│            Double value (e.g., 375.0)                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                   UI Display                               │
│               "375.0 m²" (formatted)                       │
└─────────────────────────────────────────────────────────────┘
```

This ensures maximum flexibility while maintaining data consistency across your pool management system.

#### **Team Management**
1. **Add Associated Users**
   - Navigate to Users section
   - Click "Add Associated"
   - Create accounts for field workers
   - Assign appropriate permissions

2. **Route Assignment**
   - Create maintenance routes
   - Assign workers to routes
   - Monitor route progress
   - Update route status

#### **Reports & Analytics**
- **Maintenance Reports**: Generate service reports
- **Performance Analytics**: View team and route performance
- **Customer Reports**: Analyze customer satisfaction
- **Financial Reports**: Track billing and revenue

### Best Practices
- Regular customer communication
- Proactive maintenance scheduling
- Team training and supervision
- Quality control and service standards

#### **Worker Invitation and Onboarding Process**

This section details the step-by-step process for inviting a registered user to become a worker for your company.

**A. Admin: Sending the Invitation**

1.  **Navigate to Invite Worker**: From your Admin Dashboard, go to "Manage Workers" and select the option to "Invite Worker" or "Add Worker".
2.  **Enter Email**: In the invitation form, enter the email address of the user you wish to invite.
    *   **Requirement 1**: The user must already have a registered account in the Shinning Pools app (i.e., they must exist in the system).
    *   **Requirement 2**: The user must currently have a `Customer` role.
    *   **Requirement 3**: The user cannot have any swimming pools registered to their account.
3.  **Add a Personal Message (Optional)**: You can add a brief message that the user will see with their invitation.
4.  **Send Invitation**: Click the "Send" button. The system will create a pending invitation and the user will be notified the next time they log in.

**B. Invited User: Responding to the Invitation**

1.  **Login and Notification**: When the invited user logs into their account, they will see a notification about a pending company invitation on their Customer Dashboard.
2.  **Review Invitation**: By clicking the notification, the user is taken to a screen where they can see which company has invited them and any personal message from the admin.
3.  **Accept or Reject**: The user has two options:
    *   **Accept**: If the user accepts, their role will be automatically converted from `Customer` to `Worker`. They will be associated with your company, and the next time they log in, they will see the Worker Dashboard instead of the Customer Dashboard.
    *   **Reject**: If the user rejects, the invitation is marked as `rejected`, and no changes are made to their account. They will remain a `Customer`.

This process ensures that a user must give explicit consent to join a company as a worker, providing a secure and transparent onboarding experience.

---

## Customer User Manual

### Overview
Customer users monitor their pools, view maintenance reports, and manage their account information.

### Dashboard Features

#### **Pool Overview**
- **My Pools**: View all your registered pools
- **Pool Status**: Check current pool conditions
- **Maintenance History**: Review past service records
- **Upcoming Services**: See scheduled maintenance

#### **Company Registration** (New Customers)
1. **Register Your Company**
   - Click "Register Company" on dashboard
   - Fill in company information:
     - Company name
     - Address
     - Phone number
     - Description
   - Submit for approval
   - Wait for root user approval

2. **Registration Status**
   - "Pending Approval": Your request is being reviewed
   - "Approved": You can now access admin features
   - "Rejected": Contact support for assistance

#### **Receiving a Worker Invitation**
If a company administrator invites you to become a worker, you will see a notification on your dashboard.
1. **Review**: Click the notification to review the invitation details.
2. **Respond**: You can choose to **Accept** or **Reject** the invitation.
   - **Accepting** will change your role to "Worker" and grant you access to the company's routes and tasks.
   - **Rejecting** will make no changes to your account.

#### **Pool Management**
1. **Add New Pool**
   - Navigate to Pools section
   - Click "Add Pool"
   - Enter pool details:
     - Pool name/identifier
     - Size and type
     - Location details
     - Special requirements
   - Submit for processing

2. **Pool Monitoring**
   - View pool maintenance history
   - Check water quality reports
   - Monitor equipment status
   - Request additional services

#### **Reports & Communication**
- **Service Reports**: View detailed maintenance reports
- **Billing Information**: Check service invoices
- **Communication**: Contact your service provider
- **Feedback**: Provide service ratings and comments

#### **Profile Management**
- **Personal Information**: Update contact details
- **Preferences**: Set notification preferences
- **Security**: Change password and security settings

### Best Practices
- Keep pool information updated
- Review maintenance reports regularly
- Communicate special requirements promptly
- Provide feedback for service improvement

---

## Associated User Manual

### Overview
Associated users (field workers) execute maintenance routes, record service activities, and update pool status.

### Dashboard Features

#### **Route Management**
1. **View Assigned Routes**
   - Check daily route assignments
   - View route details and pool information
   - Access customer contact information
   - Review special instructions

2. **Route Execution**
   - Start route when beginning work
   - Update progress as you complete pools
   - Record any issues or delays
   - Mark route as complete

#### **Pool Maintenance**
1. **Service Recording**
   - Select pool from route
   - Record maintenance activities:
     - Chemical levels
     - Equipment work
     - Water quality checks
     - General observations
   - Add photos if needed
   - Submit service report

2. **Issue Reporting**
   - Report equipment problems
   - Note water quality issues
   - Flag customer concerns
   - Request follow-up actions

#### **Communication**
- **Customer Updates**: Inform customers of service completion
- **Team Communication**: Update supervisors on progress
- **Emergency Contacts**: Access emergency contact information
- **Service Notes**: Leave detailed notes for team members

#### **Mobile Features**
- **Offline Mode**: Work without internet connection
- **Photo Capture**: Document pool conditions
- **GPS Tracking**: Record service locations
- **Time Tracking**: Monitor service duration

### Best Practices
- Follow safety protocols
- Complete all assigned tasks
- Document work thoroughly
- Communicate issues promptly
- Maintain professional appearance

---

## Troubleshooting

### Common Issues

#### **Login Problems**
- **Forgot Password**: Use password recovery feature
- **Account Locked**: Contact your administrator
- **Email Not Verified**: Check spam folder for verification email

#### **Company Registration Issues**
- **Registration Pending**: Wait for approval (usually 24-48 hours)
- **Registration Rejected**: Contact support for clarification
- **Cannot Register**: Ensure you're using a valid email address

#### **Pool Management Issues**
- **Pool Not Showing**: Check if pool is assigned to your account
- **Cannot Edit Pool**: Verify you have appropriate permissions
- **Maintenance History Missing**: Contact your service provider
- **Pool Photo Not Loading in Edit Mode**: 
  - **Issue**: "Failed to detect image file format" error when editing pools with photos
  - **Cause**: Image data corruption during development mode processing
  - **Solution**: Fixed in latest version - photos now load properly in edit mode
  - **Workaround**: If issue persists, try uploading a new photo (system will preserve image quality)
- **Customer Photo Upload Issues**:
  - **Large File Size**: Photos are automatically compressed to optimize storage
  - **Upload Timeout**: In development mode, photos may be stored as data URLs
  - **CORS Errors**: Development mode uses fallback storage method
  - **Supported Formats**: JPG, PNG images up to reasonable file sizes

#### **Technical Issues**
- **Page Not Loading**: Clear browser cache and cookies
- **Slow Performance**: Check internet connection
- **Mobile Issues**: Use desktop version for full functionality

### Getting Help

#### **Support Channels**
- **In-App Help**: Use the help section in your dashboard
- **Email Support**: Contact support@shinningpools.com
- **Phone Support**: Call during business hours
- **Documentation**: Refer to this manual and online resources

#### **Emergency Contacts**
- **Technical Issues**: IT support team
- **Service Emergencies**: Your assigned service provider
- **Billing Questions**: Accounts department

### System Requirements

#### **Web Browser**
- Chrome 90+ (Recommended)
- Firefox 88+
- Safari 14+
- Edge 90+

#### **Mobile Devices**
- iOS 13+ (Safari)
- Android 8+ (Chrome)
- Responsive design for all screen sizes

#### **Internet Connection**
- Minimum 1 Mbps download speed
- Stable connection for real-time features
- Offline mode available for field workers

---

## Quick Reference

### Keyboard Shortcuts
- **Ctrl + S**: Save changes
- **Ctrl + F**: Search current page
- **Ctrl + R**: Refresh page
- **Esc**: Close dialogs

### Status Indicators
- 🟢 **Active**: Normal operation
- 🟡 **Pending**: Awaiting action
- 🔴 **Suspended**: Temporarily disabled
- ⚫ **Inactive**: Not in use

### Common Actions
- **Edit**: Click pencil icon or three-dot menu
- **Delete**: Use trash icon with confirmation
- **View Details**: Click on item name
- **Export**: Use download icon for reports

---

*Last Updated: December 2024*
*Version: 1.1 - Added Pool Dimension Input Guide*

> **📝 Recent Updates**: Added comprehensive Pool Dimension Input Guide in Admin Manual section, detailing the intelligent parsing system for pool size inputs with examples, best practices, and technical implementation details.
