const functions = require('firebase-functions');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

/**
 * ImageKit authentication endpoint for client-side uploads.
 * Returns signature, token, expire for ImageKit upload API.
 *
 * Set IMAGEKIT_PRIVATE_KEY in Firebase config:
 *   firebase functions:config:set imagekit.private_key="your_private_key"
 */
exports.imagekitAuth = functions.https.onRequest((req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'GET');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const privateKey = functions.config().imagekit?.private_key;
  if (!privateKey) {
    console.error('IMAGEKIT_PRIVATE_KEY not set. Run: firebase functions:config:set imagekit.private_key="YOUR_KEY"');
    res.status(500).json({ error: 'Server misconfiguration' });
    return;
  }

  const token = req.query.token || uuidv4();
  const expire = parseInt(req.query.expire, 10) || Math.floor(Date.now() / 1000) + 2400;

  const signature = crypto
    .createHmac('sha1', privateKey)
    .update(token + expire)
    .digest('hex');

  res.json({ token, expire, signature });
});

/**
 * Verification emails: use EmailJS from the Flutter app (see lib/core/config/emailjs_config.dart).
 * No Firestore trigger / SMTP here — works on Firebase Spark without Blaze or a card.
 */
