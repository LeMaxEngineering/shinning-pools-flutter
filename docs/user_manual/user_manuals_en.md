# Shinning Pools - User Manual (English)

"The goal of this app is to focus on 'Maintenance', which will ensure it delivers its core value: making pool maintenance easy, traceable, and professional for both businesses and employees."

# Shinning Pools - User Manuals

Welcome! Please select your preferred language for the user manual:

- [English User Manual](user_manuals_en.md)
- [Manual de Usuario en Español](user_manuals_es.md)
- [Manuel d'Utilisateur en Français](user_manuals_fr.md)

> **Note:** All manuals are kept up-to-date with the latest features and troubleshooting information. If you notice any outdated information, please contact the support team.

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
- **User Statistics**: Monitor user activity and roles
- **Role Management**: Assign and modify user roles
- **Account Management**: Handle user account issues

#### **System Configuration**
- **Platform Settings**: Configure system-wide settings
- **Security Rules**: Manage Firestore security policies
- **Performance Monitoring**: Track system performance
- **Backup Management**: Oversee data backup procedures

### Best Practices
- Regular system monitoring
- Proactive security management
- Company approval workflow
- User support and training

---

## Admin User Manual

### Overview
Company administrators manage their company's operations, including customer management, worker assignments, route planning, and service delivery.

### Dashboard Features

#### **Company Overview**
- **Statistics Dashboard**: View key metrics (customers, pools, workers, routes)
- **Recent Activity**: Monitor recent maintenance and route completions
- **Performance Metrics**: Track company performance indicators

#### **Customer Management**
1. **Add New Customer**
   - Navigate to Customers section
   - Click "Add Customer"
   - Enter customer information:
     - Name and contact details
     - Address information
     - Special requirements
   - Upload customer photo (optional)
   - Save customer record

2. **Customer List Management**
   - View all company customers
   - Search and filter customers
   - Edit customer information
   - View customer maintenance history

3. **Customer Linking**
   - When customers register with matching email, they're automatically linked
   - Unlinked customers can be managed separately
   - Link status is clearly indicated in the interface

#### **Pool Management**
1. **Add New Pool**
   - Navigate to Pools section
   - Click "Add Pool"
   - Enter pool details:
     - Pool name/identifier
     - Address and location
     - Pool type and dimensions
     - Monthly maintenance cost
     - Special requirements
   - Upload pool photo (optional)
   - Submit for processing

2. **Pool Dimension System**
The system now supports intelligent pool dimension parsing:

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

3. **Pool Maintenance Tracking**
   - View recent maintenance records (last 20)
   - Filter maintenance by pool, status, and date
   - Access detailed maintenance information
   - Monitor maintenance completion rates

#### **Worker Management**
1. **Invite Workers**
   - Navigate to Workers section
   - Click "Invite Worker"
   - Enter worker's email address
   - Add personal message (optional)
   - Send invitation

2. **Worker Invitation Requirements**
   - Worker must have registered account
   - Worker must have "Customer" role
   - Worker cannot have registered pools
   - Worker must accept invitation

3. **Worker Onboarding Process**
   - Worker receives invitation notification
   - Worker reviews invitation details
   - Worker accepts or rejects invitation
   - Role changes to "Worker" upon acceptance

4. **Worker Management Features**
   - View all company workers
   - Send reminder invitations (24-hour cooldown)
   - Export worker data (CSV/JSON format)
   - Monitor worker performance

#### **Route Management**
1. **Create Routes**
   - Navigate to Routes section
   - Click "Create Route"
   - Select pools for the route
   - Assign worker to route
   - Set route parameters

2. **Route Optimization**
   - Use Google Maps integration for optimal routes
   - Start routes from user location
   - Optimize for time and distance
   - View route visualization on map

3. **Route Monitoring**
   - Track route completion status
   - Monitor worker progress
   - View historical route data
   - Access route performance analytics

#### **Maintenance Management**
1. **Recent Maintenance List**
   - View last 20 maintenance records
   - Filter by pool, status, and date range
   - Access detailed maintenance information
   - Monitor maintenance completion rates

2. **Maintenance Details**
   - View comprehensive maintenance records
   - Chemical usage and water quality data
   - Physical maintenance activities
   - Cost tracking and billing information

3. **Maintenance Reports**
   - Generate maintenance completion reports
   - Track chemical usage and costs
   - Monitor water quality trends
   - Analyze maintenance efficiency

#### **Reports & Analytics**
- **Maintenance Reports**: Generate service reports with pagination (10 records per page)
- **Performance Analytics**: View team and route performance with enhanced filtering
- **Customer Reports**: Analyze customer satisfaction with modern UI
- **Financial Reports**: Track billing and revenue with improved data display
- **Export Functionality**: Download data in CSV/JSON format
- **Enhanced UI**: Modern dropdown filters with better readability and navigation controls
- **Real-time Updates**: Live dashboard counters showing in-progress reports and active issues
- **Error Handling**: Graceful handling of data loading issues with fallback displays

### Best Practices
- Regular customer communication
- Proactive maintenance scheduling
- Team training and supervision
- Quality control and service standards

---

## Customer User Manual

### Overview
Customers manage their pool information, view maintenance reports, and communicate with their service provider.

### Dashboard Features

#### **Company Registration**
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

#### **Today's Work Tab**
1. **View Today's Active Route**
   - Access "Today" tab to see your active route assignment for today
   - View route name and assigned pools
   - See completion status (completed vs pending pools)
   - Check route details and customer information

2. **Today's Overview**
   - **Assigned Pools**: Total number of pools in today's route
   - **Completed**: Number of pools maintained today
   - **Pending**: Number of pools still needing maintenance
   - **Route Status**: Shows "ACTIVE" for current assignments

3. **Today's Schedule**
   - View all pools assigned for today's route
   - See pool names, addresses, and maintenance status
   - Green checkmark for completed pools
   - Orange status for pending pools
   - Click pool to start maintenance or view details

4. **Route Actions**
   - **View Route Map**: Opens interactive map with today's route
   - **Start Route**: Navigate to route management
   - Pool-specific actions for maintenance

5. **No Assignment States**
   - **No Active Route Today**: When no assignments are scheduled
   - **Route Not Found**: When route data is missing
   - **No Pools in Route**: When route exists but has no pools

#### **Recent Maintenance Tracking**
1. **View Recent Maintenance**
   - Access "Recent Maintenance" section in Reports tab
   - View last 20 maintenance records you've performed
   - Filter by pool, status, and date range
   - See pool addresses and customer names clearly displayed

2. **Maintenance Details**
   - Click on any maintenance record for detailed view
   - Review chemical usage and water quality data
   - Check physical maintenance activities performed
   - Access maintenance notes and observations

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

3. **Map Integration**
   - Use interactive maps for route navigation
   - View pool locations with custom markers
   - Access optimized route directions
   - Track your current location

#### **Pool Maintenance**
1. **Service Recording**
   - Select pool from route
   - Record maintenance activities:
     - Chemical levels and usage
     - Equipment work performed
     - Water quality checks
     - General observations
   - Add photos if needed
   - Submit service report

2. **Maintenance Form Features**
   - Comprehensive chemical tracking
   - Physical maintenance checklist
   - Water quality metrics recording
   - Cost calculation and billing
   - Next maintenance scheduling

3. **Issue Reporting**
   - Report equipment problems
   - Note water quality issues
   - Flag customer concerns
   - Request follow-up actions

#### **Communication**
- **Customer Updates**: Inform customers of service completion
- **Team Communication**: Update supervisors on progress
- **Emergency Contacts**: Access emergency contact information
- **Service Notes**: Leave detailed notes for team members

#### **Profile Management**
- **Personal Information**: Update contact details
- **Work Preferences**: Set availability and preferences
- **Performance Tracking**: View your maintenance statistics
- **Training Materials**: Access training resources

### Best Practices
- Complete maintenance records accurately
- Follow safety protocols
- Communicate issues promptly
- Maintain professional appearance
- Update route progress regularly

---

## Troubleshooting

### Common Issues

#### **Authentication Problems**
- **Login Issues**: Verify email and password
- **Email Verification**: Check spam folder for verification emails
- **Password Reset**: Use "Forgot Password" feature
- **Google Sign-In**: Ensure browser allows pop-ups

#### **Data Loading Issues**
- **Slow Loading**: Check internet connection
- **Missing Data**: Refresh page or clear cache
- **Real-time Updates**: Ensure stable connection
- **Filter Problems**: Clear filters and try again

#### **Map and Location Issues**
- **Location Permissions**: Enable location access in browser
- **Map Not Loading**: Check internet connection
- **Custom Markers**: Ensure image assets are available
- **Route Optimization**: Verify Google Maps API key

#### **File Upload Issues**
- **Photo Upload**: Check file size and format
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

### Firestore Index Errors
If you see an error message like "The query requires an index" or "[cloud_firestore/failed-precondition]", it means Firestore needs a composite index for your filters. To fix:
1. Copy the link provided in the error message and open it in your browser.
2. Click "Create" in the Firebase Console.
3. Wait a few minutes for the index to build, then reload the app.
If the link is broken, see the admin guide or contact support for manual index creation steps.

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

*Last Updated: July 22, 2025*
*Version: 1.7.0 - Route Map Maintenance Integration and Today Tab Enhancement*

> **📝 Recent Updates**: 
> - **Route Map Maintenance Status Integration (July 2025)**: Implemented green pinpoints for maintained pools and red pinpoints for non-maintained pools. Maintained pools are automatically excluded from route calculation for optimal routing.
> - **Today Tab Route Assignment Integration (July 2025)**: Redesigned Today tab to display current account's active route assignment for today with route-based pool loading and assignment status tracking.
> - **Maintenance Status System Enhancement (July 2025)**: Implemented efficient batch status checking, cache invalidation, and real-time synchronization between assignments and maintenance status.
> - **Worker Dashboard Recent Maintenance Cards Fix (July 2025)**: Resolved "Unknown address" issue by implementing proper data fetching from Firestore. Enhanced customer name fetching and improved data display.

## Map Features and Pool Selection (2025 Update)

### Route Map with Maintenance Status
- **Green Pinpoints**: Pools that have been maintained today (excluded from route calculation)
- **Red Pinpoints**: Pools that need maintenance (included in route optimization)
- **Route Line**: Only connects red pinpoints for optimal routing
- **Info Windows**: Different content for maintained vs non-maintained pools
- **Real-Time Updates**: Maintenance status checked in real-time using UTC dates

### Custom User Location Marker
- The map now displays your current location with a custom icon (user_marker.png).
- If you do not see your location marker, ensure location permissions are enabled and the image asset exists in assets/img/user_marker.png.

### Pool Markers and Maintenance Status
- **Green Pinpoints**: Pools that have been maintained today
- **Red Pinpoints**: Pools that need maintenance
- **Blue Markers**: General pool locations
- Each marker displays the pool's address. If the address is missing, it will show 'No address'.

### Route Optimization Features
- **Maintained Pool Exclusion**: Pools maintained today are automatically excluded from route calculation
- **Optimal Routing**: Route optimization only considers pools needing maintenance
- **Visual Clarity**: Clear distinction between maintained and non-maintained pools
- **Efficient Workflow**: Focus on pools that actually need attention

### Pool Selection UI
- The 'Pool Selected' section now appears immediately after the search box for easier workflow.
- You can search for pools by name, address, or customer, or select from the map.
- Maintained pools show "(Not Selectable)" in info windows and cannot be selected for new maintenance.

### Distance-Based Pool Filtering
- Maps can show only the 10 closest pools to your current location
- Toggle between "Nearby Pools" and "All Company Pools"
- Smart distance calculation using Haversine formula

## Help Menu (Lateral Drawer)

A new Help menu is available from the main dashboard for all user roles (worker, company admin, customer, root). Open it using the menu icon in the top left. The Help menu provides:

- **About**: App version, last update, company name (Lemax Engineering LLC), and contact info (+1 561 506 9714).
- **Check for Updates**: Check if a new version is available.
- **Welcome**: Welcome message and app overview.
- **User's Manual Links**: Direct links to the user manual (PDF), quick start, and troubleshooting guides.
- **Contact & Support**: Call or email support directly from the app.

## Recent Maintenance Features (July 2025)

### Worker Dashboard Recent Maintenance
- **Pool Address Display**: Pool addresses now display correctly as main titles
- **Customer Names**: Customer names show as subtitles instead of "Unknown address"
- **Date Formatting**: Dates display in "Month DD, YYYY" format
- **Advanced Filtering**: Filter by pool, status, and date range
- **Data Source**: Uses local data fetching for better reliability

### Company Admin Maintenance Tracking
- **Recent Maintenance List**: View last 20 maintenance records in Pools tab
- **Comprehensive Filtering**: Filter by pool, worker, status, and date
- **Maintenance Details**: Access detailed maintenance information
- **Performance Monitoring**: Track maintenance completion rates

## Maintenance System Architecture (July 2025)

### Maintenance Records
- **Comprehensive Tracking**: Chemical usage, physical maintenance, water quality metrics
- **Cost Calculation**: Automatic cost calculation based on materials used
- **Next Maintenance Scheduling**: Automatic scheduling based on service type
- **Photo Documentation**: Upload photos for maintenance records

### Security and Access Control
- **Role-Based Access**: Different permissions for different user roles
- **Company Isolation**: Users can only access their company's data
- **Maintenance Validation**: Prevents duplicate maintenance records per pool per day
- **Audit Trail**: Complete history of all maintenance activities

## Code Quality and Performance Status (July 2025)
- **Static Analysis:** ✅ Clean codebase with 259 total issues (reduced from 288)
- **Test Coverage:** ✅ 78 passing tests, 0 failures (100% pass rate)
- **Compilation:** ✅ 0 errors, stable performance
- **Performance:** ✅ Stable and responsive across all platforms
- **Cross-Platform:** ✅ Full support for Web, Android, iOS, Desktop
- **Data Integration:** ✅ Robust customer data fetching with error handling

**Reminder:** Always check for the latest app and documentation updates to ensure you have the most current information and features.
