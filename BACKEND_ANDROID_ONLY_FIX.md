# PERINTAH BACKEND - HAPUS APNS, ANDROID ONLY

## 🔧 URGENT FIX NEEDED - Backend Node.js

### ❌ Problem:
```
[FCM] Failed to send notification to admin 2 in 3ms: apns.headers must only contain string values
```

### ✅ Solution: Hapus APNS, gunakan Android FCM saja

## 📝 CHANGES REQUIRED di main.js:

### 1. Fix FCM Token Registration Test Message

**GANTI dari:**
```javascript
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
  apns: {
    headers: {
      'apns-priority': '5',
      'apns-expiration': Math.floor(Date.now() / 1000) + 60
    }
  },
  token: fcm_token
};
```

**MENJADI:**
```javascript
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
```

### 2. Fix Report Notification Message

**GANTI dari:**
```javascript
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
    expires_at: (Date.now() + 30000).toString()
  },
  android: {
    priority: 'high',
    ttl: 15000,
    directBootOk: false,
    notification: {
      priority: 'high',
      defaultSound: true,
      defaultVibrateTimings: true,
      sticky: false,
      localOnly: true,
      notificationPriority: 'PRIORITY_HIGH'
    }
  },
  apns: {
    headers: {
      'apns-priority': '10',
      'apns-push-type': 'alert',
      'apns-expiration': Math.floor(Date.now() / 1000) + 15
    },
    payload: {
      aps: {
        alert: {
          title: 'Laporan Baru',
          body: `${jenis_laporan} - ${address}\nDilaporkan oleh: ${name}`
        },
        sound: 'default',
        badge: 1,
        'content-available': 1
      }
    }
  },
  token: item.token
};
```

**MENJADI:**
```javascript
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
    expires_at: (Date.now() + 30000).toString()
  },
  android: {
    priority: 'high',
    ttl: 15000,
    directBootOk: false,
    notification: {
      priority: 'high',
      defaultSound: true,
      defaultVibrateTimings: true,
      sticky: false,
      localOnly: true,
      notificationPriority: 'PRIORITY_HIGH'
    }
  },
  // HAPUS APNS - hanya untuk Android
  token: item.token
};
```

## 🎯 BENEFITS:

1. ✅ **Fix Error**: Tidak ada lagi error APNS headers
2. ✅ **Simpler**: Kode lebih sederhana, fokus Android saja
3. ✅ **Faster**: Tidak perlu process iOS headers
4. ✅ **Less Bugs**: Mengurangi kompleksitas multi-platform

## 🚀 DEPLOYMENT:

1. Edit file `main.js` di server
2. Restart Node.js service
3. Test FCM notification

## ✅ EXPECTED RESULT:

```
[FCM] Found 1 admin tokens to notify
[FCM] Sending to admin 2 (session: session_xxx) at 2025-07-11T01:00:00.000Z
[FCM] Notification sent successfully to admin 2 in 50ms, response: projects/xxx/messages/xxx
[FCM] Notification process completed in 55ms: 1/1 successful
```

## 📱 CLIENT IMPACT:

- **Android devices**: Tetap menerima notifikasi normal
- **iOS devices**: Tidak akan menerima notifikasi (jika ada)
- **Flutter app**: Tidak perlu perubahan kode

## 🔍 VERIFY FIX:

Setelah deploy, cek log server untuk:
- Tidak ada error "apns.headers must only contain string values"
- FCM notifications berhasil terkirim
- Admin dapat menerima notifikasi laporan baru
