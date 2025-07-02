const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

// 🔐 Initialize Firebase Admin SDK with service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ✅ Send notification to admin (HTTP v1 compatible)
async function sendOrderNotificationToAdmin(customerName, amount) {
  try {
    const docRef = db.collection("admin").doc("fcmToken");
    const doc = await docRef.get();

    if (!doc.exists) {
      console.log("⚠️ Admin FCM token document doesn't exist");
      return;
    }

    const adminToken = doc.data()?.token;

    if (!adminToken) {
      console.log("⚠️ No admin FCM token found in document");
      return;
    }

    const message = {
      notification: {
        title: "🛒 New Order Placed",
        body: `${customerName} placed an order of ₹${amount}`,
      },
      token: adminToken,
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        screen: "admin_orders",
      },
    };

    const response = await admin.messaging().send(message);
    console.log("✅ Successfully sent message:", response);
  } catch (error) {
    console.error("❌ Error sending message:", error);
  }
}

// 🧪 Example usage
sendOrderNotificationToAdmin("Test User", 999);
