# FCM Troubleshooting - Notifikasi Tidak Muncul Saat App Terbuka

## **Masalah yang Ditemukan:**

### 1. **Deduplication Terlalu Agresif**
- FCM service memblokir notifikasi yang dianggap duplikat dalam 5 detik
- Session ID blocking yang terlalu ketat
- Timestamp expiry 30 detik terlalu pendek

### 2. **Multiple FCM Initialization**
- FCM diinisialisasi di main.dart
- Juga diinisialisasi di notification_permission_handler.dart
- Bisa menyebabkan conflict pada listener

### 3. **Notification State Management**
- Flag `_notificationsEnabled` bisa ter-disable
- Tidak ada logging yang jelas untuk debugging

## **Langkah Debugging:**

### Step 1: Enable Debug Logging
Tambahkan logging lebih detail di FCM service untuk melihat:
- Apakah pesan FCM diterima
- Apakah lolos filter deduplication
- Apakah local notification ditampilkan

### Step 2: Simplify Deduplication
Sementara disable beberapa filter untuk testing:
- Comment out session ID check
- Extend expiry time
- Simplify notification key

### Step 3: Check FCM Token Registration
Pastikan:
- FCM token sudah terdaftar di server
- Topic subscription berhasil
- Permission notification granted

### Step 4: Test FCM Console
Gunakan Firebase Console untuk send test message directly

## **Quick Fix untuk Testing:**

1. **Disable Aggressive Filtering** (temporary)
2. **Add More Logging**
3. **Test with Firebase Console**
4. **Check Permission Status**

## **Rekomendasi Perbaikan:**

### 1. **Simplify FCM Service**
- Single initialization point
- Less aggressive deduplication
- Better error handling

### 2. **Improve Logging**
- Log setiap step FCM processing
- Log permission status
- Log token registration

### 3. **Add FCM Debug Screen**
- Show FCM token
- Show subscription status
- Test notification button
- Show recent notifications log

## **Code Changes Needed:**

1. Update `_shouldShowFcmNotification` method
2. Add debug logging in `_handleForegroundMessage`
3. Create FCM debug widget
4. Simplify initialization flow
