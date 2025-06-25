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
admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

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
