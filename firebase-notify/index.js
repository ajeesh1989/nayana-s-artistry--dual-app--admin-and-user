const express = require('express');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());

// ✅ Load Firebase Service Account
let serviceAccount;
const localPath = path.join(__dirname, 'serviceAccountKey.json');
const renderPath = '/etc/secrets/serviceAccountKey.json';

if (fs.existsSync(localPath)) {
  serviceAccount = require(localPath); // Local dev
} else if (fs.existsSync(renderPath)) {
  serviceAccount = require(renderPath); // Render deployment
} else {
  console.error('❌ Firebase service account key not found!');
  process.exit(1);
}

// ✅ Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// 🔔 Admin notification for new orders
app.post('/send-notification', async (req, res) => {
  const { adminToken, customerName, amount } = req.body;

  if (!adminToken || !customerName || !amount) {
    return res.status(400).send({ success: false, error: 'Missing fields' });
  }

  const message = {
    token: adminToken,
    notification: {
      title: '🛒 New Order Placed',
      body: `${customerName} placed an order worth ₹${amount}`,
    },
    data: {
      screen: 'admin_orders',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
  };

  try {
    const responseFirebase = await admin.messaging().send(message);
    console.log('✅ Order push sent to admin:', responseFirebase);
    res.status(200).send({ success: true, response: responseFirebase });
  } catch (error) {
    console.error('❌ Error sending to admin:', error);
    res.status(500).send({ success: false, error: error.message });
  }
});

// 📣 Broadcast notification to all users via topic
app.post('/send-to-users', async (req, res) => {
  const { topic, title, body, image } = req.body;

  if (!topic || !title || !body) {
    return res.status(400).send({ success: false, error: 'Missing fields' });
  }

  const message = {
    topic,
    notification: {
      title,
      body,
    },
    data: {
      title,
      body,
      image: image || '',
      screen: 'user_notifications',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`📣 Broadcast sent to topic "${topic}"`);

    const usersSnap = await admin.firestore().collection('users').get();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    const savePromises = usersSnap.docs.map((doc) =>
      admin.firestore()
        .collection('users')
        .doc(doc.id)
        .collection('notifications')
        .add({
          title,
          body,
          image: image || '',
          timestamp,
          read: false,
        })
    );

    await Promise.all(savePromises);

    res.status(200).send({ success: true, response });
  } catch (err) {
    console.error('❌ Broadcast error:', err);
    res.status(500).send({ success: false, error: err.message });
  }
});

// ✅ Send order status update to specific user
app.post('/send-user-status-update', async (req, res) => {
  const { userToken, orderId, status, userName, amount } = req.body;

  if (!userToken || !orderId || !status || !userName || !amount) {
    return res.status(400).send({ success: false, error: 'Missing fields' });
  }

  const message = {
    token: userToken,
    notification: {
      title: '📦 Order Status Updated',
      body: `Hi ${userName}, your order of ₹${amount} is now "${status}"`,
    },
    data: {
      screen: 'order_status',
      orderId,
      status,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Status update sent to user:', response);
    res.status(200).send({ success: true, response });
  } catch (error) {
    console.error('❌ Error sending status update to user:', error);
    res.status(500).send({ success: false, error: error.message });
  }
});

// 🚀 Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
