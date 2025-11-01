import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

exports.createUserWithRole = functions.https.onCall(
  async (
    data: {email?: string; password?: string; role?: string},
    context: functions.https.CallableContext
  ) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const callerUid = context.auth.uid;
    const {email, password, role} = data;

    const callerDoc = await admin
      .firestore()
      .collection("users")
      .doc(callerUid)
      .get();

    const callerData = callerDoc.data();

    if (!callerDoc.exists || !callerData || callerData.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can create new user accounts."
      );
    }

    if (!email || !password || !role) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with email, password, and role."
      );
    }

    const validRoles = ["admin", "mid_level", "low_level"];
    if (!validRoles.includes(role)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid role specified."
      );
    }

    try {
      const userRecord = await admin.auth().createUser({
        email,
        password,
        emailVerified: false,
        disabled: false,
      });

      await admin.firestore().collection("users").doc(userRecord.uid).set({
        email,
        role,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        uid: userRecord.uid,
        email,
        role,
        success: true,
      };
    } catch (error: unknown) {
      if (
        typeof error === "object" &&
        error !== null &&
        "code" in error &&
        (error as {code?: string}).code === "auth/email-already-in-use"
      ) {
        throw new functions.https.HttpsError(
          "already-exists",
          "The email address is already in use by another account."
        );
      }

      console.error("Error creating user:", error);
      throw new functions.https.HttpsError(
        "internal",
        "An error occurred while creating the user.",
        (error as {message?: string}).message
      );
    }
  }
);
