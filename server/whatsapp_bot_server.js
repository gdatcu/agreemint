const express = require('express');
const cors = require('cors');
const qrcode = require('qrcode-terminal');
const { Client, LocalAuth } = require('whatsapp-web.js');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
let qrCodeData = null;
let isReady = false;

// Initialize WhatsApp Web Client with LocalAuth session storage
const client = new Client({
  authStrategy: new LocalAuth({ clientId: 'qualiadept-bot' }),
  webVersionCache: {
    type: 'remote',
    remotePath: 'https://raw.githubusercontent.com/wppconnect-team/wa-version/main/html/2.2412.54.html',
  },
  puppeteer: {
    headless: 'new',
    executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || undefined,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-accelerated-2d-canvas',
      '--no-first-run',
      '--no-zygote',
      '--disable-gpu',
    ],
  },
});

client.on('qr', (qr) => {
  qrCodeData = qr;
  isReady = false;
  console.log('\n======================================================');
  console.log('🤖 QUALIADEPT BILLING BOT - SCAN THIS QR CODE WITH WHATSAPP:');
  console.log('======================================================\n');
  qrcode.generate(qr, { small: true });
  console.log('\nOr view QR online at: http://localhost:' + PORT + '/qr\n');
});

client.on('ready', () => {
  isReady = true;
  qrCodeData = null;
  console.log('✅ QualiAdept Billing Bot is authenticated & READY!');
});

client.on('authenticated', () => {
  console.log('🔑 WhatsApp Web Session Authenticated successfully!');
});

client.on('auth_failure', (msg) => {
  console.error('❌ WhatsApp Web Authentication failure:', msg);
});

client.on('disconnected', (reason) => {
  isReady = false;
  qrCodeData = null;
  console.log('⚠️ WhatsApp Web Bot Disconnected:', reason);
});

// Clean phone number helper
function formatWhatsAppPhone(phone) {
  let cleaned = phone.replace(/[^\d]/g, '');
  if (cleaned.startsWith('0') && cleaned.length === 10) {
    cleaned = '40' + cleaned.substring(1);
  }
  if (!cleaned.endsWith('@c.us')) {
    cleaned = cleaned + '@c.us';
  }
  return cleaned;
}

// Status & Health Check endpoint
app.get('/status', (req, res) => {
  res.json({
    status: isReady ? 'READY' : 'AUTHENTICATING',
    authenticated: isReady,
    qrAvailable: !!qrCodeData,
  });
});

// View QR Code in browser endpoint
app.get('/qr', (req, res) => {
  if (isReady) {
    return res.send(`
      <html>
        <body style="display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:sans-serif;background:#f5f5f5;height:100vh;">
          <h2>✅ QualiAdept Billing Bot is authenticated and active!</h2>
          <p style="color:#666;">Connected to active WhatsApp account.</p>
          <a href="/logout" style="margin-top:20px;padding:10px 20px;background:#ef4444;color:white;text-decoration:none;border-radius:8px;font-weight:bold;">
            🚪 Disconnect / Logout Account
          </a>
        </body>
      </html>
    `);
  }
  if (!qrCodeData) {
    return res.send('<h2>⏳ Generating QR Code... Please refresh in 5 seconds.</h2>');
  }
  const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(qrCodeData)}`;
  res.send(`
    <html>
      <body style="display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:sans-serif;background:#f5f5f5;height:100vh;">
        <h2>🤖 QualiAdept Billing Bot — Scan QR Code</h2>
        <p>Open WhatsApp on your phone -> Settings -> Linked Devices -> Link a Device</p>
        <img src="${qrImageUrl}" alt="WhatsApp QR Code" style="border: 4px solid #00E676; border-radius: 12px; margin: 16px;" />
        <p><i>Page refreshes automatically every 10 seconds...</i></p>
        <script>setTimeout(() => location.reload(), 10000);</script>
      </body>
    </html>
  `);
});

// Logout & Session Reset endpoint
app.get('/logout', async (req, res) => {
  try {
    isReady = false;
    qrCodeData = null;
    await client.logout();
    await client.destroy();
    console.log('🚪 WhatsApp Bot session logged out.');
  } catch (err) {
    console.log('Logout notice:', err.message);
  } finally {
    setTimeout(() => {
      client.initialize();
    }, 1000);
    res.send(`
      <html>
        <body style="display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:sans-serif;background:#f5f5f5;height:100vh;">
          <h2>🚪 Logged out successfully!</h2>
          <p>Generating new QR code...</p>
          <script>setTimeout(() => location.href = '/qr', 3000);</script>
        </body>
      </html>
    `);
  }
});

// POST /send-reminder endpoint
app.post('/send-reminder', async (req, res) => {
  if (!isReady) {
    return res.status(503).json({
      error: 'WhatsApp Bot is not authenticated yet. Please scan the QR code first.',
      qrUrl: `http://localhost:${PORT}/qr`,
    });
  }

  const { phone, studentName, programName, amount, currency, dueDate } = req.body;

  if (!phone) {
    return res.status(400).json({ error: 'Missing recipient phone number.' });
  }

  const formattedPhone = formatWhatsAppPhone(phone);
  const student = studentName || 'Cursant';
  const program = programName || 'Program Mentorat';
  const amt = amount || '0.00';
  const curr = currency || 'RON';
  const dateStr = dueDate || new Date().toISOString().split('T')[0];

  const messageText =
    `🤖 [Notificare Automată - QualiAdept Billing]\n\n` +
    `Stimate/ă ${student},\n\n` +
    `Vă informăm că pentru înregistrarea la programul ${program}, tranșa în valoare de ${amt} ${curr} a înregistrat termenul de plată pe data de ${dateStr}.\n\n` +
    `Vă rugăm să efectuați transferul bancar conform acordului agreat. Dacă ați efectuat deja plata, vă rugăm să ignorați această notificare automatizată.\n\n` +
    `Sistemul Automat de Facturare QualiAdept.`;

  try {
    await client.sendMessage(formattedPhone, messageText);
    console.log(`✅ Sent QualiAdept Billing Bot reminder to ${student} (${formattedPhone})`);
    return res.json({
      success: true,
      message: `QualiAdept Billing Bot sent reminder to ${student}`,
      recipient: formattedPhone,
    });
  } catch (err) {
    console.error(`❌ Failed to send reminder to ${formattedPhone}:`, err);
    return res.status(500).json({
      error: 'Failed to dispatch WhatsApp message via bot: ' + err.message,
    });
  }
});

// Start Express App & WhatsApp Client
app.listen(PORT, () => {
  console.log(`🚀 QualiAdept Bot Server listening on port ${PORT}`);
  client.initialize();
});
