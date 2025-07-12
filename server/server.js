require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const bodyParser = require('body-parser');
const socketIO = require('socket.io');
const mysql = require('mysql2/promise');
const jwt = require('jsonwebtoken');

// Firebase Admin SDK
const adminFirebase = require('firebase-admin');
const serviceAccount = require('./kkn-simokerto-firebase-adminsdk-fbsvc-db7195739e'); // Path to your Firebase service account json
adminFirebase.initializeApp({
  credential: adminFirebase.credential.cert(serviceAccount),
});
const messaging = adminFirebase.messaging();

// Environment variables
const {
  DB_HOST,
  DB_USER,
  DB_PASS,
  DB_NAME,
  JWT_SECRET,
  PORT = 3000
} = process.env;

// Create Express app
const app = express();
// Allow CORS only for https://simokerto.my.id
app.use(cors({
  origin: 'https://simokerto.my.id',
  credentials: true,
}));
app.use(bodyParser.json());

// Utility function to get current time in UTC+7
function getCurrentTimeUTC7() {
  const now = new Date();
  // Add 7 hours to UTC time (7 * 60 * 60 * 1000 milliseconds)
  return new Date(now.getTime() + (7 * 60 * 60 * 1000));
}

// Utility function to format datetime to UTC+7 string
function formatDateTimeUTC7(date) {
  if (!date) return null;
  const utc7Date = new Date(new Date(date).getTime() + (7 * 60 * 60 * 1000));
  return utc7Date.toISOString().replace('Z', '+07:00');
}

// Utility function to ensure date fields are formatted as strings (assuming they are already in UTC+7 from DB)
function formatDatesInResults(results, dateFields = ['created_at']) {
  return results.map(row => {
    const formattedRow = { ...row };
    dateFields.forEach(field => {
      if (formattedRow[field] instanceof Date) {
        formattedRow[field] = formattedRow[field].toISOString().replace('Z', '+07:00'); // Convert Date object to ISO string with UTC+7
      }
      // If it's already a string, assume it's correctly formatted and pass through
    });
    return formattedRow;
  });
}

// Logging middleware for all requests - update to use UTC+7
app.use((req, res, next) => {
  const now = getCurrentTimeUTC7().toISOString();
  console.log(`[${now}] ${req.method} ${req.url}`);
  next();
});

// Create HTTP server and Socket.IO
const server = http.createServer(app);
// Sederhanakan konfigurasi Socket.IO untuk mengatasi masalah koneksi
const io = new socketIO.Server(server, {
  cors: {
    origin: "https://simokerto.my.id",
    methods: ["GET", "POST"],
    credentials: true
  }
});
const iotNamespace = io.of('/iot');

iotNamespace.on('connection', socket => {
  console.log(`IoT device connected: ${socket.id}`);
});

// MySQL pool
const pool = mysql.createPool({
  host: DB_HOST,
  user: DB_USER,
  password: DB_PASS,
  database: DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Token blacklist - in production, use Redis or database
const blacklistedTokens = new Set();

// Middleware: authenticate JWT
async function authenticate(req, res, next) {
  console.log(`Authenticating request to ${req.url}`);
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    console.log('No or invalid Authorization header');
    return res.status(401).json({ error: 'Unauthorized' });
  }
  const token = auth.split(' ')[1];
  
  // Check if token is blacklisted
  if (blacklistedTokens.has(token)) {
    console.log('Token is blacklisted');
    return res.status(401).json({ error: 'Token revoked' });
  }
  
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload;
    req.token = token; // Store token for potential logout
    console.log(`Authenticated user_id: ${payload.user_id}`);
    next();
  } catch (err) {
    console.log('JWT verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// POST /login
app.post('/login', async (req, res) => {
  console.log('POST /login payload:', req.body);
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'username and password required' });
  }
  try {
    // Cek di tabel users
    const [userRows] = await pool.query(
      'SELECT id, password, name FROM users WHERE username = ?',
      [username]
    );
    if (userRows.length > 0) {
      const user = userRows[0];
      const match = (password === user.password);
      if (!match) {
        console.log('Password mismatch (user)');
        return res.status(401).json({ error: 'Username atau Password Salah' });
      }
      // Token untuk user biasa
      const token = jwt.sign({ user_id: user.id, is_admin: false }, JWT_SECRET);
      console.log(`User ${username} logged in, token issued (user)`);
      return res.json({ token, is_admin: false, role: null, name: user.name });
    }

    // Jika tidak ditemukan di users, cek di tabel admin
    const [adminRows] = await pool.query(
      'SELECT id, password, name, role FROM admin WHERE username = ?',
      [username]
    );
    if (adminRows.length === 0) {
      console.log('User not found in users or admin');
      return res.status(401).json({ error: 'Username atau Password Salah' });
    }
    const admin = adminRows[0];
    const match = (password === admin.password);
    if (!match) {
      console.log('Password mismatch (admin)');
      return res.status(401).json({ error: 'Username atau Password Salah' });
    }
    // Token untuk admin
    const token = jwt.sign({ user_id: admin.id, is_admin: true, role: admin.role }, JWT_SECRET);
    console.log(`Admin ${username} logged in, token issued (role: ${admin.role})`);
    // Hanya kembalikan field yang diminta
    return res.json({
      token,
      is_admin: true,
      role: admin.role,
      name: admin.name,
      username: admin.username,
      id: admin.id
    });
  } catch (err) {
    console.error('Error in /login:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /logout - Updated to clear FCM token
app.post('/logout', authenticate, async (req, res) => {
  console.log('POST /logout by user:', req.user.user_id);
  try {
    // Add token to blacklist
    blacklistedTokens.add(req.token);
    
    // Clear FCM token if user is admin
    if (req.user.is_admin) {
      await pool.query('UPDATE admin SET fcm_token = NULL WHERE id = ?', [req.user.user_id]);
    }
    
    console.log(`Token blacklisted for user ${req.user.user_id}`);
    res.json({ message: 'Logged out successfully' });
  } catch (err) {
    console.error('Error in /logout:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /admin/fcm-token - Register FCM token for admin
app.post('/admin/fcm-token', authenticate, async (req, res) => {
  console.log('POST /admin/fcm-token by user:', req.user.user_id);
  const userId = req.user.user_id;
  
  if (!req.user.is_admin) {
    return res.status(403).json({ error: 'Forbidden: Only admins can register FCM tokens' });
  }
  
  const { fcm_token } = req.body;
  if (!fcm_token) {
    return res.status(400).json({ error: 'fcm_token is required' });
  }
  
  try {
    // Generate session ID untuk tracking
    const sessionId = `session_${Date.now()}_${userId}`;
    const sessionStart = getCurrentTimeUTC7();
    
    // Validate FCM token by sending a test message
    try {
      const testMessage = {
        data: { 
          type: 'token_validation',
          message: 'FCM token registered successfully',
          session_id: sessionId,
          session_start: sessionStart.getTime().toString()
        },
        android: {
          priority: 'high',
          ttl: 60000,
          notification: {
            priority: 'default'
          }
        },
        token: fcm_token
      };
      
      await messaging.send(testMessage);
      console.log('FCM token validation successful');
    } catch (validationError) {
      console.error('FCM token validation failed:', validationError.message);
      if (validationError.code === 'messaging/registration-token-not-registered' || 
          validationError.code === 'messaging/invalid-registration-token') {
        return res.status(400).json({ error: 'Invalid FCM token provided' });
      }
    }
    
    // Simpan token dengan session info
    await pool.query(
      'UPDATE admin SET fcm_token = ?, session_id = ?, session_start = ? WHERE id = ?', 
      [fcm_token, sessionId, sessionStart, userId]
    );
    
    console.log(`FCM token registered for admin ${userId} with session ${sessionId}`);
    res.json({ 
      message: 'FCM token registered successfully',
      session_id: sessionId,
      session_start: sessionStart.toISOString()
    });
  } catch (err) {
    console.error('Error in /admin/fcm-token:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// NEW: POST /admin/fcm-token/validate - Validate and clean invalid FCM tokens
app.post('/admin/fcm-token/validate', authenticate, async (req, res) => {
  console.log('POST /admin/fcm-token/validate by user:', req.user.user_id);
  
  if (!req.user.is_admin) {
    return res.status(403).json({ error: 'Forbidden: Only admins can validate FCM tokens' });
  }
  
  try {
    const [adminTokens] = await pool.query('SELECT id, fcm_token FROM admin WHERE fcm_token IS NOT NULL');
    
    let validTokens = 0;
    let invalidTokens = 0;
    
    for (const admin of adminTokens) {
      try {
        const testMessage = {
          data: { 
            type: 'token_validation',
            message: 'Token validation check'
          },
          android: {
            priority: 'normal',
            ttl: 30000 // 30 seconds TTL
          },
          token: admin.fcm_token
        };
        
        await messaging.send(testMessage);
        validTokens++;
        console.log(`FCM token valid for admin ${admin.id}`);
      } catch (error) {
        if (error.code === 'messaging/registration-token-not-registered' || 
            error.code === 'messaging/invalid-registration-token') {
          console.log(`Removing invalid FCM token for admin ${admin.id}`);
          await pool.query('UPDATE admin SET fcm_token = NULL WHERE id = ?', [admin.id]);
          invalidTokens++;
        } else {
          console.error(`FCM validation error for admin ${admin.id}:`, error.message);
        }
      }
    }
    
    console.log(`FCM token validation complete: ${validTokens} valid, ${invalidTokens} invalid (removed)`);
    res.json({ 
      message: 'FCM token validation completed',
      valid_tokens: validTokens,
      invalid_tokens_removed: invalidTokens
    });
  } catch (err) {
    console.error('Error in /admin/fcm-token/validate:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /profile - Mendapatkan profil user yang sedang login
app.get('/profile', authenticate, async (req, res) => {
  console.log('GET /profile by user:', req.user.user_id);
  const userId = req.user.user_id;
  const isAdmin = req.user.is_admin;
  try {
    if (isAdmin) {
      // Cari di tabel admin
      const [admins] = await pool.query(
        'SELECT id, username, name, created_at, role FROM admin WHERE id = ?',
        [userId]
      );
      if (admins.length === 0) {
        console.log('Admin not found in database');
        return res.status(404).json({ error: 'Admin not found' });
      }
      const admin = admins[0];
      console.log(`Profile data retrieved for admin ${admin.username}`);
      return res.json({
        id: admin.id,
        username: admin.username,
        name: admin.name,
        created_at: formatDateTimeUTC7(admin.created_at),
        role: admin.role,
        is_admin: true,
        address: '-',
        phone: '-'
      });
    } else {
      // Cari di tabel users
      const [users] = await pool.query(
        'SELECT id, username, name, address, phone, created_at FROM users WHERE id = ?',
        [userId]
      );
      if (users.length === 0) {
        console.log('User not found in database');
        return res.status(404).json({ error: 'User not found' });
      }
      const user = users[0];
      console.log(`Profile data retrieved for user ${user.username}`);
      return res.json({
        ...user,
        created_at: formatDateTimeUTC7(user.created_at)
      });
    }
  } catch (err) {
    console.error('Error in GET /profile:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /report - Enhanced with FCM notifications
app.post('/report', authenticate, async (req, res) => {
  console.log('POST /report by user:', req.user.user_id, 'with body:', req.body);
  const userId = req.user.user_id;
  const isAdmin = req.user.is_admin;
  const { jenis_laporan, use_account_data, isSirine = 0 } = req.body;
  let { address } = req.body;
  const phone = req.body.phone || '-';

  if (!jenis_laporan) {
    return res.status(400).json({ error: 'jenis_laporan is required' });
  }

  try {
    let name;
    let reporter_type = isAdmin ? 'admin' : 'user';
    let reportUserId = userId; // Selalu ID asli

    if (isAdmin) {
      // Ambil nama admin
      const [admins] = await pool.query('SELECT name FROM admin WHERE id = ?', [userId]);
      if (admins.length === 0) {
        return res.status(404).json({ error: 'Admin not found' });
      }
      name = admins[0].name;
      if (!address) {
        return res.status(400).json({ error: 'address is required for admin reports' });
      }
      // reportUserId tetap userId (ID admin)
    } else {
      // Handle report from a regular user
      const [users] = await pool.query('SELECT name, address FROM users WHERE id = ?', [userId]);
      if (users.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      name = users[0].name;

      if (use_account_data) {
        address = users[0].address;
        console.log(`Using address from user account: ${address}`);
      }
    }

    if (!address) {
      return res.status(400).json({ error: 'address is required' });
    }

    // Insert report dengan user_id = ID asli (admin/user)
    const currentTimeUTC7 = getCurrentTimeUTC7();
    const [result] = await pool.query(
      'INSERT INTO reports (user_id, address, phone, jenis_laporan, reporter_type, isSirine, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [reportUserId, address, phone, jenis_laporan, reporter_type, isSirine, currentTimeUTC7]
    );
    const reportId = result.insertId;
    const report = { 
      id: reportId, 
      name, 
      address, 
      phone, 
      jenis_laporan,
      isSirine: Boolean(isSirine),
      created_at: currentTimeUTC7,
      status: 'pending'
    };
    console.log('New report inserted:', report);
    
    // Emit event to IoT devices
    iotNamespace.emit('new_report', report);
    console.log('Emitted new_report event');

    // Send FCM push notifications dengan session validation
    try {
      const fcmStartTime = Date.now();
      const reportTimestamp = Date.now();
      console.log(`[FCM] Starting notification process at ${new Date(fcmStartTime).toISOString()}`);
      
      const [adminTokens] = await pool.query('SELECT id, fcm_token, session_id, session_start FROM admin WHERE fcm_token IS NOT NULL');
      const tokensWithIds = adminTokens.map(row => ({ 
        id: row.id, 
        token: row.fcm_token,
        session_id: row.session_id,
        session_start: row.session_start
      })).filter(item => !!item.token);
      
      if (tokensWithIds.length > 0) {
        console.log(`[FCM] Found ${tokensWithIds.length} admin tokens to notify`);
        
        // Send notifications dengan session validation dan TTL pendek
        const notificationPromises = tokensWithIds.map(async (item) => {
          const tokenStartTime = Date.now();
          try {
            const message = {
              notification: {
                title: 'Laporan Baru',
                body: `${jenis_laporan} - ${address}\nDilaporkan oleh: ${name}${isSirine ? '\n🚨 SIRINE AKTIF' : ''}`
              },
              data: { 
                reportId: report.id.toString(),
                type: 'new_report',
                address: address,
                jenis_laporan: jenis_laporan,
                reporter_name: name,
                isSirine: isSirine.toString(),
                timestamp: reportTimestamp.toString(),
                report_created_at: currentTimeUTC7.getTime().toString(),
                session_id: item.session_id || 'unknown',
                expires_at: (Date.now() + 30000).toString() // 30 detik dari sekarang
              },
              android: {
                priority: 'high',
                ttl: 15000, // Sangat pendek: 15 detik
                directBootOk: false, // Tidak kirim jika app tidak aktif
                notification: {
                  priority: 'high',
                  defaultSound: true,
                  defaultVibrateTimings: true,
                  sticky: false,
                  localOnly: true, // Hanya lokal, tidak sync ke devices lain
                  notificationPriority: 'PRIORITY_HIGH'
                }
              },
              token: item.token
            };
            
            console.log(`[FCM] Sending to admin ${item.id} (session: ${item.session_id}) at ${new Date().toISOString()}`);
            const response = await messaging.send(message);
            const tokenEndTime = Date.now();
            const tokenDuration = tokenEndTime - tokenStartTime;
            
            console.log(`[FCM] Notification sent successfully to admin ${item.id} in ${tokenDuration}ms, response:`, response);
            return { success: true, token: item.token, adminId: item.id, duration: tokenDuration };
          } catch (error) {
            const tokenEndTime = Date.now();
            const tokenDuration = tokenEndTime - tokenStartTime;
            
            console.error(`[FCM] Failed to send notification to admin ${item.id} in ${tokenDuration}ms:`, error.message);
            
            // Check if token is invalid and remove it
            if (error.code === 'messaging/registration-token-not-registered' || 
                error.code === 'messaging/invalid-registration-token') {
              console.log(`[FCM] Removing invalid FCM token for admin ${item.id}`);
              try {
                await pool.query('UPDATE admin SET fcm_token = NULL WHERE id = ?', [item.id]);
                console.log(`[FCM] Invalid FCM token removed for admin ${item.id}`);
              } catch (dbError) {
                console.error('[FCM] Error removing invalid FCM token:', dbError);
              }
            }
            
            return { success: false, token: item.token, adminId: item.id, error: error.message, duration: tokenDuration };
          }
        });
        
        const results = await Promise.allSettled(notificationPromises);
        const fcmEndTime = Date.now();
        const totalFcmDuration = fcmEndTime - fcmStartTime;
        
        const successCount = results.filter(r => r.status === 'fulfilled' && r.value.success).length;
        const failureCount = results.length - successCount;
        
        console.log(`[FCM] Notification process completed in ${totalFcmDuration}ms: ${successCount}/${results.length} successful`);
        
        if (failureCount > 0) {
          const failures = results.filter(r => r.status === 'rejected' || (r.status === 'fulfilled' && !r.value.success));
          console.log('[FCM] Failed sends:', failures.map(f => f.status === 'fulfilled' ? f.value : f.reason));
        }
        
        // Log individual timing
        results.forEach((result, index) => {
          if (result.status === 'fulfilled') {
            console.log(`[FCM] Admin ${tokensWithIds[index].id}: ${result.value.success ? 'SUCCESS' : 'FAILED'} in ${result.value.duration}ms`);
          }
        });
        
      } else {
        console.log('[FCM] No admin FCM tokens available for notifications');
      }
    } catch (fcmError) {
      console.error('[FCM] Notification error:', fcmError);
      // Don't fail the request if FCM fails
    }

    res.json(report);
  } catch (err) {
    console.error('Error in /report:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /reports/count - Update to use UTC+7
app.get('/reports/count', async (req, res) => {
  console.log('GET /reports/count - Request for statistics');
  try {
    // Query untuk total laporan
    const [totalResult] = await pool.query('SELECT COUNT(*) as total FROM reports');
    
    // Query untuk laporan hari ini - using UTC+7
    const today = getCurrentTimeUTC7().toISOString().split('T')[0]; // Format YYYY-MM-DD in UTC+7
    const [todayResult] = await pool.query(
      'SELECT COUNT(*) as today FROM reports WHERE DATE(created_at) = ?',
      [today]
    );
    
    // Query untuk laporan per lokasi
    const [locationStats] = await pool.query(`
      SELECT address, COUNT(*) as count 
      FROM reports 
      GROUP BY address 
      ORDER BY count DESC 
      LIMIT 5
    `);
    
    const stats = {
      total: totalResult[0].total,
      today: todayResult[0].today,
      top_locations: locationStats
    };
    
    console.log('Report statistics:', stats);
    res.json(stats);
  } catch (err) {
    console.error('Error in GET /reports/count:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /reports/total - Get only the total count of all reports
app.get('/reports/total', async (req, res) => {
  console.log('GET /reports/total - Request for total reports count');
  try {
    // Query for total reports
    const [totalResult] = await pool.query('SELECT COUNT(*) as total FROM reports');
    
    const totalCount = {
      total: totalResult[0].total
    };
    
    console.log('Total reports count:', totalCount.total);
    res.json(totalCount);
  } catch (err) {
    console.error('Error in GET /reports/total:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// NEW: GET /reports/user-stats - Mendapatkan statistik laporan untuk user tertentu
app.get('/reports/user-stats', authenticate, async (req, res) => {
  console.log('GET /reports/user-stats for user:', req.user.user_id);
  const userId = req.user.user_id;
  const isAdmin = req.user.is_admin;
  
  try {
    // Query untuk total laporan user
    const [totalResult] = await pool.query(
      'SELECT COUNT(*) as total FROM reports WHERE user_id = ?',
      [userId]
    );
    
    // Query untuk laporan hari ini dari user - using UTC+7
    const today = getCurrentTimeUTC7().toISOString().split('T')[0]; // Format YYYY-MM-DD in UTC+7
    const [todayResult] = await pool.query(
      'SELECT COUNT(*) as today FROM reports WHERE user_id = ? AND DATE(created_at) = ?',
      [userId, today]
    );
    
    // Query untuk laporan terbaru dari user
    const [recentReports] = await pool.query(`
      SELECT id, address, created_at, jenis_laporan, status
      FROM reports 
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT 5
    `, [userId]);
    
    let userInfo;
    if (isAdmin) {
      const [adminInfo] = await pool.query('SELECT name FROM admin WHERE id = ?', [userId]);
      userInfo = {
        name: adminInfo.length > 0 ? adminInfo[0].name : 'Unknown Admin',
        address: '-',
        phone: '-'
      };
    } else {
      const [usersInfo] = await pool.query('SELECT name, address, phone FROM users WHERE id = ?', [userId]);
      userInfo = usersInfo[0] || { name: 'Unknown', address: 'Unknown', phone: null };
    }
    
    const stats = {
      user: userInfo,
      reports: {
        total: totalResult[0].total,
        today: todayResult[0].today,
        recent: formatDatesInResults(recentReports, ['created_at'])
      }
    };
    
    console.log(`User stats for ${userId}:`, stats.reports.total, 'total reports,', stats.reports.today, 'today');
    res.json(stats);
  } catch (err) {
    console.error('Error in GET /reports/user-stats:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /reports/all - Baru: Endpoint untuk admin untuk melihat semua laporan
app.get('/reports/all', authenticate, async (req, res) => {
  console.log('GET /reports/all requested by user:', req.user.user_id);
  try {
    // Query untuk mendapatkan semua laporan dengan informasi pelapor dari tabel users atau admin
    const [rows] = await pool.query(`
      SELECT 
        r.id, 
        r.user_id, 
        r.address, 
        r.created_at, 
        r.jenis_laporan, 
        r.reporter_type,
        r.status,
        CASE 
          WHEN r.reporter_type = 'admin' THEN a.name
          ELSE u.name 
        END as reporter_name,
        CASE 
          WHEN r.reporter_type = 'admin' THEN '-'
          ELSE u.phone 
        END as phone
      FROM reports r
      LEFT JOIN users u ON r.user_id = u.id AND r.reporter_type = 'user'
      LEFT JOIN admin a ON r.user_id = a.id AND r.reporter_type = 'admin'
      ORDER BY r.created_at DESC
      LIMIT 100
    `);
    
    // Pastikan setiap report punya semua key yang dibutuhkan aplikasi
    const reports = rows.map(r => ({
      id: r.id,
      user_id: r.user_id,
      address: r.address || '-',
      created_at: r.created_at, // Removed redundant UTC+7 conversion
      jenis_laporan: r.jenis_laporan || '-',
      reporter_type: r.reporter_type || '-',
      status: r.status || 'pending',
      reporter_name: r.reporter_name || '-',
      phone: r.phone || '-',
      // Tambahkan field lain yang dibutuhkan aplikasi, misal:
      isSirine: typeof r.isSirine !== 'undefined' ? r.isSirine : false
    }));

    res.json(reports);
  } catch (err) {
    console.error('Error in GET /reports/all:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /reports/:id - Mendapatkan detail laporan berdasarkan ID
app.get('/reports/:id', authenticate, async (req, res) => {
  const { id } = req.params;
  console.log(`GET /reports/${id} requested by user:`, req.user.user_id);
  try {
    // Query untuk mendapatkan detail laporan dengan informasi pelapor dari tabel users atau admin
    const [rows] = await pool.query(`
      SELECT
        r.id,
        r.user_id,
        r.address,
        r.created_at,
        r.jenis_laporan,
        r.reporter_type,
        r.status,
        r.phone,
        r.isSirine,
        CASE
          WHEN r.reporter_type = 'admin' THEN a.name
          ELSE u.name
        END as reporter_name,
        CASE
          WHEN r.reporter_type = 'admin' THEN '-'
          ELSE u.phone
        END as reporter_phone_number -- Renamed to avoid conflict with reports.phone
        -- Consider adding other fields if needed for detail screen
      FROM reports r
      LEFT JOIN users u ON r.user_id = u.id AND r.reporter_type = 'user'
      LEFT JOIN admin a ON r.user_id = a.id AND r.reporter_type = 'admin'
      WHERE r.id = ?
    `, [id]);

    if (rows.length === 0) {
      console.log(`Report with ID ${id} not found`);
      return res.status(404).json({ error: 'Report not found' });
    }

    const report = rows[0];

    // created_at is assumed to be already in UTC+7 from DB
    // No need to format again here
    
    // Ensure phone and isSirine fields are present
    if (!report.phone) report.phone = '-';
    if (typeof report.isSirine === 'undefined') report.isSirine = false;
    
    // Use reporter_phone_number for display if available, otherwise use report.phone
    report.phone = report.reporter_phone_number || report.phone;
    delete report.reporter_phone_number; // Clean up the temporary field

    res.json(report);
  } catch (err) {
    console.error(`Error in GET /reports/${id}:`, err);
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /reports/:id/status - Update status laporan berdasarkan ID
app.put('/reports/:id/status', authenticate, async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  const userId = req.user.user_id;
  const isAdmin = req.user.is_admin;
  
  console.log(`PUT /reports/${id}/status by user:`, userId, `with status: ${status}`);
  
  // Validate input
  if (!status) {
    return res.status(400).json({ error: 'Status is required' });
  }
  
  // Only allow valid status values
  const validStatuses = ['pending', 'processing', 'completed', 'rejected'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ 
      error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` 
    });
  }
  
  // Only admin can update status
  if (!isAdmin) {
    console.log(`Unauthorized status update attempt by user ${userId}`);
    return res.status(403).json({ error: 'Only admin can update report status' });
  }
  
  try {
    // Check if report exists
    const [reportCheck] = await pool.query('SELECT id FROM reports WHERE id = ?', [id]);
    if (reportCheck.length === 0) {
      console.log(`Report with ID ${id} not found`);
      return res.status(404).json({ error: 'Report not found' });
    }
    
    // Update report status
    await pool.query('UPDATE reports SET status = ? WHERE id = ?', [status, id]);
    
    console.log(`Updated status of report ${id} to ${status}`);
    
    // Get the updated report
    const [rows] = await pool.query(`
      SELECT 
        r.id, 
        r.user_id, 
        r.address, 
        r.created_at, 
        r.jenis_laporan, 
        r.reporter_type,
        r.status,
        CASE 
          WHEN r.reporter_type = 'admin' THEN a.name
          ELSE u.name 
        END as reporter_name,
        CASE 
          WHEN r.reporter_type = 'admin' THEN '-'
          ELSE u.phone 
        END as phone
      FROM reports r
      LEFT JOIN users u ON r.user_id = u.id AND r.reporter_type = 'user'
      LEFT JOIN admin a ON r.user_id = a.id AND r.reporter_type = 'admin'
      WHERE r.id = ?
    `, [id]);

    // Notify via Socket.IO
    if (rows.length > 0) {
      const updatedReport = rows[0];
      iotNamespace.emit('report_status_update', {
        report_id: id,
        status: status,
        report: updatedReport
      });
      console.log(`Emitted report_status_update event for report ${id}`);
    }
    
    res.json({ 
      id: parseInt(id), 
      status, 
      message: `Report status updated to ${status}` 
    });
  } catch (err) {
    console.error(`Error in PUT /reports/${id}/status:`, err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /user/:username - Mendapatkan info user berdasarkan username
app.get('/user/:username', authenticate, async (req, res) => {
  const username = req.params.username;
  console.log(`GET /user/${username} by user:`, req.user.user_id);
  
  try {
    const [users] = await pool.query(
      'SELECT id, username, name, address, phone, created_at FROM users WHERE username = ?',
      [username]
    );
    
    if (users.length === 0) {
      console.log(`User ${username} not found`);
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = users[0];
    user.created_at = formatDateTimeUTC7(user.created_at);
    
    console.log(`Found user ${username}`);
    res.json(user);
  } catch (err) {
    console.error(`Error in GET /user/${username}:`, err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /reports/by-username/:username - Laporan berdasarkan username
app.get('/reports/by-username/:username', authenticate, async (req, res) => {
  const username = req.params.username;
  console.log(`GET /reports/by-username/${username} by user:`, req.user.user_id);
  
  try {
    // Pertama, dapatkan user_id dari username (hanya dari tabel users)
    const [users] = await pool.query(
      'SELECT id FROM users WHERE username = ?',
      [username]
    );
    
    if (users.length === 0) {
      console.log(`User ${username} not found`);
      return res.status(404).json({ error: 'User not found' });
    }
    
    const targetUserId = users[0].id;
    
    // Kemudian dapatkan laporan untuk user tersebut
    const [reports] = await pool.query(`
      SELECT 
        r.id, 
        r.address, 
        r.created_at, 
        r.jenis_laporan, 
        r.status,
        u.name as reporter_name, 
        u.phone
      FROM reports r
      JOIN users u ON r.user_id = u.id
      WHERE r.user_id = ? AND r.reporter_type = 'user'
      ORDER BY r.created_at DESC
      LIMIT 100
    `, [targetUserId]);
    
    console.log(`Found ${reports.length} reports for user ${username}`);
    res.json(formatDatesInResults(reports, ['created_at']));
  } catch (err) {
    console.error(`Error in GET /reports/by-username/${username}:`, err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /reports/user-stats/:username - Update to use UTC+7
app.get('/reports/user-stats/:username', authenticate, async (req, res) => {
  const username = req.params.username;
  console.log(`GET /reports/user-stats/${username} by user:`, req.user.user_id);
  
  try {
    // Dapatkan user_id dari username
    const [users] = await pool.query(
      'SELECT id, name, address, phone FROM users WHERE username = ?',
      [username]
    );
    
    if (users.length === 0) {
      console.log(`User ${username} not found`);
      return res.status(404).json({ error: 'User not found' });
    }
    
    const targetUserId = users[0].id;
    const userInfo = {
      name: users[0].name,
      address: users[0].address,
      phone: users[0].phone
    };
    
    // Query untuk total laporan user
    const [totalResult] = await pool.query(
      'SELECT COUNT(*) as total FROM reports WHERE user_id = ?',
      [targetUserId]
    );
    
    // Query untuk laporan hari ini dari user - using UTC+7
    const today = getCurrentTimeUTC7().toISOString().split('T')[0]; // Format YYYY-MM-DD in UTC+7
    const [todayResult] = await pool.query(
      'SELECT COUNT(*) as today FROM reports WHERE user_id = ? AND DATE(created_at) = ?',
      [targetUserId, today]
    );
    
    // Query untuk laporan terbaru dari user
    const [recentReports] = await pool.query(`
      SELECT id, address, created_at, jenis_laporan, status
      FROM reports 
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT 5
    `, [targetUserId]);
    
    const stats = {
      user: userInfo,
      reports: {
        total: totalResult[0].total,
        today: todayResult[0].today,
        recent: formatDatesInResults(recentReports, ['created_at'])
      }
    };
    
    console.log(`User stats for ${userId}:`, stats.reports.total, 'total reports,', stats.reports.today, 'today');
    res.json(stats);
  } catch (err) {
    console.error(`Error in GET /reports/user-stats/${username}:`, err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Example GET endpoint (health check) - Update to use UTC+7
app.get('/health', (req, res) => {
  console.log('GET /health');
  res.json({ status: 'OK', timestamp: getCurrentTimeUTC7().toISOString() });
});

// Logging response status for every request - Update to use UTC+7
app.use((req, res, next) => {
  res.on('finish', () => {
    const now = getCurrentTimeUTC7().toISOString();
    console.log(`[${now}] Response for ${req.method} ${req.originalUrl} - Status: ${res.statusCode}`);
  });
  next();
});

// Start server
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});

/*
.env should contain:
DB_HOST=localhost
DB_USER=root
DB_PASS=
DB_NAME=lapor_maling
JWT_SECRET=your_secret_key
PORT=3000
*/

// NEW: POST /admin/fcm-token/test - Test immediate FCM delivery
app.post('/admin/fcm-token/test', authenticate, async (req, res) => {
  console.log('POST /admin/fcm-token/test by user:', req.user.user_id);
  
  if (!req.user.is_admin) {
    return res.status(403).json({ error: 'Forbidden: Only admins can test FCM tokens' });
  }
  
  const { test_message = 'Test notification from server' } = req.body;
  
  try {
    const testStartTime = Date.now();
    console.log(`[FCM-TEST] Starting test at ${new Date(testStartTime).toISOString()}`);
    
    const [adminTokens] = await pool.query('SELECT id, fcm_token FROM admin WHERE fcm_token IS NOT NULL');
    const tokensWithIds = adminTokens.map(row => ({ id: row.id, token: row.fcm_token })).filter(item => !!item.token);
    
    if (tokensWithIds.length === 0) {
      return res.status(404).json({ error: 'No FCM tokens found for testing' });
    }
    
    const testPromises = tokensWithIds.map(async (item) => {
      const tokenStartTime = Date.now();
      try {
        const message = {
          notification: {
            title: 'Test Notification',
            body: test_message
          },
          data: { 
            type: 'test_notification',
            timestamp: Date.now().toString(),
            test_id: `test_${Date.now()}_${item.id}`
          },
          android: {
            priority: 'high',
            ttl: 15000, // 15 seconds for test
            directBootOk: true,
            notification: {
              priority: 'max',
              defaultSound: true,
              sticky: false,
              localOnly: false,
              notificationPriority: 'PRIORITY_MAX'
            }
          },
          token: item.token
        };
        
        const response = await messaging.send(message);
        const tokenEndTime = Date.now();
        const duration = tokenEndTime - tokenStartTime;
        
        console.log(`[FCM-TEST] Test sent to admin ${item.id} in ${duration}ms`);
        return { success: true, adminId: item.id, duration, response };
      } catch (error) {
        const tokenEndTime = Date.now();
        const duration = tokenEndTime - tokenStartTime;
        
        console.error(`[FCM-TEST] Test failed for admin ${item.id} in ${duration}ms:`, error.message);
        return { success: false, adminId: item.id, duration, error: error.message };
      }
    });
    
    const results = await Promise.allSettled(testPromises);
    const testEndTime = Date.now();
    const totalDuration = testEndTime - testStartTime;
    
    const successCount = results.filter(r => r.status === 'fulfilled' && r.value.success).length;
    
    console.log(`[FCM-TEST] Test completed in ${totalDuration}ms: ${successCount}/${results.length} successful`);
    
    res.json({
      message: 'FCM test completed',
      total_duration_ms: totalDuration,
      successful_sends: successCount,
      total_tokens: results.length,
      results: results.map(r => r.status === 'fulfilled' ? r.value : { success: false, error: r.reason })
    });
  } catch (err) {
    console.error('Error in /admin/fcm-token/test:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

/*
.env should contain:
DB_HOST=localhost
DB_USER=root
DB_PASS=
DB_NAME=lapor_maling
JWT_SECRET=your_secret_key
PORT=3000
*/

// NEW: POST /admin/session/validate - Validate current session
app.post('/admin/session/validate', authenticate, async (req, res) => {
  console.log('POST /admin/session/validate by user:', req.user.user_id);
  
  if (!req.user.is_admin) {
    return res.status(403).json({ error: 'Forbidden: Only admins can validate sessions' });
  }
  
  const { session_id } = req.body;
  const userId = req.user.user_id;
  
  try {
    // Get current session from database
    const [adminData] = await pool.query(
      'SELECT session_id, session_start FROM admin WHERE id = ?', 
      [userId]
    );
    
    if (adminData.length === 0) {
      return res.status(404).json({ error: 'Admin not found' });
    }
    
    const currentSession = adminData[0].session_id;
    const sessionStart = adminData[0].session_start;
    
    const isValid = currentSession === session_id;
    
    console.log(`Session validation for admin ${userId}: ${isValid ? 'VALID' : 'INVALID'}`);
    console.log(`Current session: ${currentSession}, Provided: ${session_id}`);
    
    res.json({
      valid: isValid,
      current_session: currentSession,
      session_start: sessionStart ? new Date(sessionStart).toISOString() : null,
      message: isValid ? 'Session is valid' : 'Session is invalid or expired'
    });
  } catch (err) {
    console.error('Error in /admin/session/validate:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// NEW: POST /admin/session/clear - Clear old sessions (cleanup)
app.post('/admin/session/clear', authenticate, async (req, res) => {
  console.log('POST /admin/session/clear by user:', req.user.user_id);
  
  if (!req.user.is_admin) {
    return res.status(403).json({ error: 'Forbidden: Only admins can clear sessions' });
  }
  
  try {
    // Clear sessions older than 1 hour
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    
    const [result] = await pool.query(
      'UPDATE admin SET session_id = NULL, session_start = NULL WHERE session_start < ? OR session_start IS NULL',
      [oneHourAgo]
    );
    
    console.log(`Cleared ${result.affectedRows} old sessions`);
    
    res.json({
      message: 'Old sessions cleared',
      affected_rows: result.affectedRows
    });
  } catch (err) {
    console.error('Error in /admin/session/clear:', err);
    res.status(500).json({ error: 'Server error' });
  }
});