# Solusi Notifikasi Terlambat - FCM Timestamp Checking

## 🔍 Masalah Yang Ditemukan

Ketika aplikasi di-force stop saat notifikasi dikirim, kemudian aplikasi dibuka kembali dan ada notifikasi baru, notifikasi lama yang tertunda akan muncul bersamaan dengan notifikasi baru dengan jeda ~5 detik.

## ✅ Solusi Yang Diimplementasikan

### 1. Client Side (Flutter) - SUDAH SELESAI ✅

File: `lib/services/fcm_service.dart`

**Perubahan:**
- Menambahkan timestamp checking untuk memfilter notifikasi terlambat
- Notifikasi yang lebih dari 2 menit akan diabaikan
- Enhanced logging untuk debugging

**Fitur baru:**
```dart
// Konstanta untuk expiry time
static const Duration _notificationExpiryTime = Duration(minutes: 2);
static const String _timestampKey = 'sent_at';

// Method yang diupdate dengan timestamp checking
bool _shouldShowFcmNotification(String notificationKey, Map<String, dynamic> messageData)
```

### 2. Server Side (Node.js) - PERLU DIUPDATE ⚠️

**Yang perlu ditambahkan di server Node.js:**

```javascript
// Contoh untuk mengirim FCM dengan timestamp
const admin = require('firebase-admin');

async function sendNotificationWithTimestamp(fcmToken, title, body, data = {}) {
  // Tambahkan timestamp saat notifikasi dibuat
  const notificationData = {
    ...data,
    sent_at: new Date().toISOString(), // Format: 2025-07-11T10:30:45.123Z
    type: data.type || 'general'
  };

  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body
    },
    data: notificationData,
    // Optional: Tambahkan TTL (Time To Live) untuk mencegah notifikasi terlalu lama
    android: {
      ttl: 300000, // 5 menit dalam milliseconds
      priority: 'high'
    },
    apns: {
      headers: {
        'apns-expiration': Math.floor(Date.now() / 1000) + 300 // 5 menit
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Notification sent successfully:', response);
    return response;
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
}

// Contoh penggunaan untuk laporan baru
async function sendNewReportNotification(fcmToken, reportId, reportTitle) {
  await sendNotificationWithTimestamp(
    fcmToken,
    'Laporan Baru',
    `Laporan "${reportTitle}" telah dibuat`,
    {
      type: 'new_report',
      reportId: reportId.toString(),
      action: 'view_report'
    }
  );
}

// Contoh penggunaan untuk update status
async function sendStatusUpdateNotification(fcmToken, reportId, status, reportTitle) {
  await sendNotificationWithTimestamp(
    fcmToken,
    'Status Laporan Diupdate',
    `Laporan "${reportTitle}" statusnya menjadi ${status}`,
    {
      type: 'status_update',
      reportId: reportId.toString(),
      status: status,
      action: 'view_report'
    }
  );
}
```

## 🎯 Hasil Yang Diharapkan

1. **Notifikasi lama tidak akan muncul** jika sudah lebih dari 2 menit
2. **Logging yang lebih detail** untuk debugging masalah notifikasi
3. **TTL (Time To Live)** pada server akan mencegah notifikasi tersimpan terlalu lama di FCM queue

## 🔧 Testing

### Test Case 1: Normal Flow
1. Buat laporan baru → notifikasi muncul normal
2. Update status → notifikasi muncul normal

### Test Case 2: Force Stop Scenario
1. Buat laporan 1 → force stop aplikasi sebelum notifikasi terkirim
2. Tunggu > 2 menit
3. Buka aplikasi dan buat laporan 2
4. **Expected**: Hanya notifikasi laporan 2 yang muncul
5. **Jika notifikasi laporan 1 masih muncul**: Cek timestamp di data notifikasi

### Test Case 3: Quick Succession
1. Buat laporan 1
2. Segera buat laporan 2 (< 2 menit)
3. **Expected**: Kedua notifikasi muncul karena masih dalam batas waktu

## 📊 Monitoring & Debugging

Periksa log Flutter untuk melihat:
```
Notification age: XX seconds for fcm_new_report_123
Notification too old (XX minutes), blocking: fcm_new_report_123
```

## 🚀 Implementasi Server

1. Update endpoint pembuatan laporan untuk menambahkan `sent_at` timestamp
2. Update endpoint status update untuk menambahkan `sent_at` timestamp  
3. Tambahkan TTL pada konfigurasi FCM message
4. Test dengan scenario force stop

## 💡 Alternatif Solusi

Jika masalah masih terjadi, bisa pertimbangkan:
1. Mengurangi expiry time dari 2 menit ke 1 menit
2. Menambahkan sequence number pada notifikasi
3. Menggunakan server-side check untuk mencegah pengiriman notifikasi lama
