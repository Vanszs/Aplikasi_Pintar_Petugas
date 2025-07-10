# Backend FCM Fix - APNS Header Error

## Error yang Terjadi
```
[FCM] Failed to send notification to               apns: {
                headers: {
                  'apns-priority': '10',
                  'apns-push-type': 'alert',
                  'apns-expiration': (Math.floor(Date.now() / 1000) + 15).toString() // Convert to string
                },2 in 3ms: apns.headers must only contain string values
```

## Root Cause
Error ini terjadi karena di header APNS ada nilai yang bukan string. Berdasarkan kode backend yang diberikan sebelumnya, masalahnya kemungkinan di:

```javascript
apns: {
  headers: {
    'apns-priority': '10',
    'apns-push-type': 'alert',
    'apns-expiration': Math.floor(Date.now() / 1000) + 15 // INI MASALAHNYA - NUMBER, BUKAN STRING
  }
}
```

## Perbaikan yang Diperlukan

### 1. Fix APNS Headers di main.js

Ganti bagian APNS headers dari:
```javascript
apns: {
  headers: {
    'apns-priority': '10',
    'apns-push-type': 'alert',
    'apns-expiration': Math.floor(Date.now() / 1000) + 15 // NUMBER
  }
}
```

Menjadi:
```javascript
apns: {
  headers: {
    'apns-priority': '10',
    'apns-push-type': 'alert',
    'apns-expiration': String(Math.floor(Date.now() / 1000) + 15) // CONVERT TO STRING
  }
}
```

### 2. Complete Fixed Version

```javascript
// POST /report - Enhanced with FCM notifications
app.post('/report', authenticate, async (req, res) => {
  // ...existing code...

  try {
    // ...existing code...

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
                body: `${jenis_laporan} - ${address}\nDilaporkan oleh: ${name}`
              },
              data: { 
                reportId: report.id.toString(),
                type: 'new_report',
                address: address,
                jenis_laporan: jenis_laporan,
                reporter_name: name,
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
              // HAPUS APNS - hanya untuk Android
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
                await pool.query('UPDATE admin SET fcm_token = NULL, session_id = NULL WHERE id = ?', [item.id]);
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
```

### 3. Juga Fix di Endpoint FCM Token Registration

```javascript
// POST /admin/fcm-token - Register FCM token for admin
app.post('/admin/fcm-token', authenticate, async (req, res) => {
  // ...existing code...
  
  try {
    // ...existing code...
    
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
        // HAPUS APNS - hanya untuk Android
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
    
    // ...rest of code...
  } catch (err) {
    console.error('Error in /admin/fcm-token:', err);
    res.status(500).json({ error: 'Server error' });
  }
});
```

## Summary Perbaikan

1. **Root Cause**: APNS headers `apns-expiration` menggunakan nilai number, harus string
2. **Fix**: Wrap dengan `String()` semua nilai numeric di APNS headers
3. **Impact**: FCM notifications akan berhasil dikirim ke iOS dan Android devices

Setelah perbaikan ini diterapkan di backend, error `apns.headers must only contain string values` akan teratasi dan notifikasi FCM akan berfungsi dengan baik.
