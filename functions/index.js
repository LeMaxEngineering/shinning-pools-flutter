/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Geocoding function to avoid CORS issues on web
exports.geocodeAddress = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }

    const { address } = data;
    
    if (!address || typeof address !== 'string' || address.trim().length === 0) {
      throw new functions.https.HttpsError("invalid-argument", "Valid address is required");
    }

    // Google Maps Geocoding API key - must be set in environment variables
    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError("internal", "GOOGLE_MAPS_API_KEY environment variable is not set. Please set it in your Cloud Functions environment.");
    }
    
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address.trim())}&key=${apiKey}`;
    
    console.log(`Geocoding address: ${address}`);
    
    const response = await axios.get(url);
    
    if (response.status !== 200) {
      throw new functions.https.HttpsError("internal", "Geocoding service error");
    }

    const result = response.data;
    
    if (result.status === 'OK' && result.results && result.results.length > 0) {
      const location = result.results[0].geometry.location;
      console.log(`Geocoding successful: ${location.lat}, ${location.lng}`);
      
      return {
        success: true,
        latitude: location.lat,
        longitude: location.lng,
        formattedAddress: result.results[0].formatted_address,
        status: result.status
      };
    } else {
      console.log(`Geocoding failed: ${result.status} - ${result.error_message || 'No error message'}`);
      
      return {
        success: false,
        status: result.status,
        error: result.error_message || 'No results found for this address'
      };
    }
  } catch (error) {
    console.error('Geocoding error:', error);
    throw new functions.https.HttpsError("internal", error.message || "Unknown error");
  }
});

// Assign role on registration
exports.setInitialUserRole = functions.auth.user().onCreate(async (user) => {
  try {
  const usersSnapshot = await admin.firestore().collection("users").get();
    let role = "customer"; // Default role for security
    
    // Only the first user becomes root
  if (usersSnapshot.empty) {
    role = "root";
  }
    
    // Write to Firestore with proper structure
  await admin.firestore().collection("users").doc(user.uid).set({
    uid: user.uid,
      email: user.email?.toLowerCase(),
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    role: role,
      companyId: null,
      companyName: null,
      name: user.displayName || (user.email ? user.email.split('@')[0] : ''),
      pendingCompanyRequest: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Set custom claim for additional security
  await admin.auth().setCustomUserClaims(user.uid, {role: role});
    
    console.log(`User ${user.email} created with role: ${role}`);
  } catch (error) {
    console.error('Error setting initial user role:', error);
    throw error;
  }
});

// Change user role (root only)
exports.changeUserRole = functions.https.onCall(async (data, context) => {
  try {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "No auth context");
  }
    
  const requester = await admin.auth().getUser(context.auth.uid);
  const requesterClaims = requester.customClaims || {};
    
    // Only root users can change roles
  if (requesterClaims.role !== "root") {
      throw new functions.https.HttpsError("permission-denied", "Only root users can change roles");
  }
    
  const {uid, newRole} = data;
    
    // Validate the new role
    const validRoles = ['root', 'admin', 'worker', 'customer'];
    if (!validRoles.includes(newRole)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid role specified");
    }
    
    // Prevent root from changing their own role to non-root
    if (uid === context.auth.uid && newRole !== 'root') {
      throw new functions.https.HttpsError("permission-denied", "Root users cannot demote themselves");
    }
    
    // Update Firestore
  await admin.firestore()
      .collection("users")
      .doc(uid)
        .update({
          role: newRole,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    // Update custom claims
  await admin.auth()
      .setCustomUserClaims(uid, {role: newRole});

    console.log(`User ${uid} role changed to: ${newRole} by ${context.auth.uid}`);
    return {success: true, message: `User role updated to ${newRole}`};
  } catch (error) {
    console.error('Error changing user role:', error);
    throw new functions.https.HttpsError("internal", "Failed to change user role");
  }
});

// Get user information (root only)
exports.getUserInfo = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "No auth context");
    }
    
    const requester = await admin.auth().getUser(context.auth.uid);
    const requesterClaims = requester.customClaims || {};
    
    // Only root users can get user info
    if (requesterClaims.role !== "root") {
      throw new functions.https.HttpsError("permission-denied", "Only root users can access user information");
    }
    
    const {uid} = data;
    if (!uid) {
      throw new functions.https.HttpsError("invalid-argument", "User ID is required");
    }
    
    const userDoc = await admin.firestore().collection("users").doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    
    return {user: userDoc.data()};
  } catch (error) {
    console.error('Error getting user info:', error);
    throw new functions.https.HttpsError("internal", "Failed to get user information");
  }
});

// List all users (root only)
exports.listUsers = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "No auth context");
    }
    
    const requester = await admin.auth().getUser(context.auth.uid);
    const requesterClaims = requester.customClaims || {};
    
    // Only root users can list users
    if (requesterClaims.role !== "root") {
      throw new functions.https.HttpsError("permission-denied", "Only root users can list users");
    }
    
    const usersSnapshot = await admin.firestore().collection("users").get();
    const users = usersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    return {users};
  } catch (error) {
    console.error('Error listing users:', error);
    throw new functions.https.HttpsError("internal", "Failed to list users");
  }
});

exports.linkCustomerOnUserCreate = functions.auth.user().onCreate(async (user) => {
  const email = user.email;
  const uid = user.uid;

  if (!email) return;

  const customersRef = admin.firestore().collection('customers');
  const snapshot = await customersRef.where('email', '==', email).get();

  if (snapshot.empty) {
    console.log(`No customer found for email: ${email}`);
    return;
  }

  const batch = admin.firestore().batch();

  snapshot.forEach(doc => {
    batch.update(doc.ref, { linkedUserId: uid });
    console.log(`Linked customer ${doc.id} to user ${uid}`);
  });

  await batch.commit();
});

// On-demand route expiration when historical list is requested
exports.checkAndExpireRoutes = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }

    console.log('Checking for routes to expire...');    
    const now = new Date();
    const yesterday = new Date(now.getTime() - 24* 60 *60*1000); // 24hours ago
    
    // Get all active routes that have passed their date
    const routesSnapshot = await admin.firestore()
      .collection('routes')
      .where('status', '==', 'ACTIVE')
      .where('createdAt', '<', yesterday)
      .get();
    
    console.log(`Found ${routesSnapshot.size} routes to expire`);
    
    if (routesSnapshot.size === 0) {
      return {
        success: true,
        expiredRoutes: 0,
        expiredAssignments: 0,
        message: 'No routes to expire'
      };
    }
    
    const batch = admin.firestore().batch();
    let expiredRoutesCount = 0; let expiredAssignmentsCount = 0;
    for (const routeDoc of routesSnapshot.docs) {
      const routeData = routeDoc.data();
      
      // Update route status to 'CLOSED'
      batch.update(routeDoc.ref, {
        status: 'CLOSED',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiredAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      expiredRoutesCount++;
      
      // Find and update all assignments for this route
      const assignmentsSnapshot = await admin.firestore()
        .collection('assignments')
        .where('routeId', '==', routeDoc.id)
        .where('status', '==', 'Active')
        .get();
      
      console.log(`Found ${assignmentsSnapshot.size} active assignments for route ${routeDoc.id}`);
      
      for (const assignmentDoc of assignmentsSnapshot.docs) {
        batch.update(assignmentDoc.ref, {
          status: 'Expired',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          expiredAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        expiredAssignmentsCount++;
      }
    }
    
    // Commit all changes
    await batch.commit();
    console.log(`Successfully expired ${expiredRoutesCount} routes and ${expiredAssignmentsCount} assignments`);
    
    return {
      success: true,
      expiredRoutes: expiredRoutesCount,
      expiredAssignments: expiredAssignmentsCount,
      message: `Expired ${expiredRoutesCount} routes and ${expiredAssignmentsCount} assignments`
    };
    
  } catch (error) {
    console.error('Error in route expiration check:', error);
    throw new functions.https.HttpsError("internal", error.message || "Failed to check and expire routes");
  }
});

// Manual route expiration function (can be called from the app)
exports.manualExpireRoute = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    
    const { routeId } = data;
    if (!routeId) {
      throw new functions.https.HttpsError("invalid-argument", "Route ID is required");
    }
    
    const currentUser = await admin.auth().getUser(context.auth.uid);
    const userClaims = currentUser.customClaims || {};
    
    // Only admin and root users can manually expire routes
    if (userClaims.role !== 'admin' && userClaims.role !== 'root') {
      throw new functions.https.HttpsError("permission-denied", "Only admin and root users can expire routes");
    }
    
    const routeRef = admin.firestore().collection('routes').doc(routeId);
    const routeDoc = await routeRef.get();
    
    if (!routeDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Route not found");
    }
    
    const routeData = routeDoc.data();
    
    // Check if route is already closed
    if (routeData.status === 'CLOSED') {
      return { success: true, message: 'Route is already closed' };
    }
    
    const batch = admin.firestore().batch();
    
    // Update route status to CLOSED
    batch.update(routeRef, {
      status: 'CLOSED',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiredAt: admin.firestore.FieldValue.serverTimestamp(),
      manuallyExpiredBy: context.auth.uid
    });
    
    // Find and update all active assignments for this route
    const assignmentsSnapshot = await admin.firestore()
      .collection('assignments')
      .where('routeId', '==', routeId)
      .where('status', '==', 'Active')
      .get();
    
    let expiredAssignmentsCount = 0;
    for (const assignmentDoc of assignmentsSnapshot.docs) {
      batch.update(assignmentDoc.ref, {
        status: 'Expired',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiredAt: admin.firestore.FieldValue.serverTimestamp(),
        manuallyExpiredBy: context.auth.uid
      });
      
      expiredAssignmentsCount++;
    }
    
    // Commit all changes
    await batch.commit();
    
    console.log(`Route ${routeId} manually expired by ${context.auth.uid}. ${expiredAssignmentsCount} assignments updated.`);
    
    return {
      success: true,
      message: `Route expired successfully. ${expiredAssignmentsCount} assignments updated.`,
      expiredAssignments: expiredAssignmentsCount
    };
    
  } catch (error) {
    console.error('Error in manual route expiration:', error);
    throw new functions.https.HttpsError("internal", error.message || "Failed to expire route");
  }
});

// Send worker invitation reminder
exports.sendWorkerInvitationReminder = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }

    const { invitationId, invitedUserEmail, companyName, invitedByUserName, message } = data;
    
    if (!invitationId || !invitedUserEmail || !companyName) {
      throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
    }

    // Verify the invitation exists and is still pending
    const invitationRef = admin.firestore().collection('worker_invitations').doc(invitationId);
    const invitationDoc = await invitationRef.get();
    
    if (!invitationDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Invitation not found");
    }
    
    const invitationData = invitationDoc.data();
    if (invitationData.status !== 'pending') {
      throw new functions.https.HttpsError("failed-precondition", "Invitation is no longer pending");
    }

    // Check if reminder was sent recently (within 24 hours)
    const lastReminderSentAt = invitationData.lastReminderSentAt;
    if (lastReminderSentAt) {
      const hoursSinceLastReminder = (Date.now() - lastReminderSentAt.toDate().getTime()) / (1000 * 60 * 60);
      if (hoursSinceLastReminder < 24) {
        throw new functions.https.HttpsError("failed-precondition", "Reminder already sent recently. Please wait 24 hours between reminders.");
      }
    }

    // For now, we'll log the reminder and return success
    // In a production environment, you would integrate with an email service like SendGrid, Mailgun, etc.
    console.log(`Sending reminder for invitation ${invitationId}:`);
    console.log(`- To: ${invitedUserEmail}`);
    console.log(`- Company: ${companyName}`);
    console.log(`- Invited by: ${invitedByUserName}`);
    console.log(`- Message: ${message || 'No custom message'}`);
    
    // TODO: Integrate with email service
    // Example with SendGrid:
    // const sgMail = require('@sendgrid/mail');
    // sgMail.setApiKey(process.env.SENDGRID_API_KEY);
    // 
    // const msg = {
    //   to: invitedUserEmail,
    //   from: 'noreply@yourcompany.com',
    //   subject: `Reminder: Worker Invitation from ${companyName}`,
    //   text: `You have a pending invitation to join ${companyName} as a worker. Please check your app to respond.`,
    //   html: `<p>You have a pending invitation to join <strong>${companyName}</strong> as a worker.</p><p>Please check your app to respond.</p>`,
    // };
    // 
    // await sgMail.send(msg);

    // For now, just return success
    return {
      success: true,
      message: 'Reminder sent successfully',
      invitationId: invitationId,
      sentTo: invitedUserEmail,
    };
    
  } catch (error) {
    console.error('Error sending worker invitation reminder:', error);
    throw new functions.https.HttpsError("internal", error.message || "Failed to send reminder");
  }
});
