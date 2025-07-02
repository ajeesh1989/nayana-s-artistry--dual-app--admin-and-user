const express = require('express');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');
const cors = require('cors');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// 🔔 Send push to a specific admin device token
app.post('/send-notification', async (req, res) => {
  const { adminToken, customerName, amount } = req.body;

  const message = {
    token: adminToken,
    data: {
      title: '🛒 New Order Placed',
      body: `${customerName} placed an order worth ₹${amount}`,
      screen: 'admin_orders',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
  };

  try {
    const responseFirebase = await admin.messaging().send(message);
    console.log('✅ Order push sent:', responseFirebase);
    res.status(200).send({ success: true, response: responseFirebase });
  } catch (error) {
    console.error('❌ Error sending to admin:', error);
    res.status(500).send({ success: false, error: error.message });
  }
});

// 📣 Broadcast push to all users via topic
// 📣 Broadcast push to all users via topic
app.post('/send-to-users', async (req, res) => {
  const { topic, title, body, image } = req.body;

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
    console.log(`📣 Broadcast sent to "${topic}"`);

    const usersSnap = await admin.firestore().collection('users').get();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    const savePromises = usersSnap.docs.map((doc) =>
      admin
        .firestore()
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


app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
