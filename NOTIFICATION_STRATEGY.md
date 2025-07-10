# Strategi Notifikasi Hybrid

## Ringkasan Sistem Notifikasi

Aplikasi Petugas Pintar menggunakan **strategi hybrid** dengan dua sistem notifikasi yang bekerja secara bersamaan:

### 1. **FCM (Firebase Cloud Messaging)** 
- **Fungsi Utama**: Push notifications dari server ke device
- **Kapan Digunakan**: 
  - Ketika app tidak aktif (background/terminated)
  - Notifikasi real-time dari server
  - Cross-platform delivery

### 2. **Local Notifications (Flutter Local Notifications)**
- **Fungsi Utama**: Notifikasi in-app dengan kontrol penuh
- **Kapan Digunakan**:
  - Ketika app aktif (foreground)
  - Socket events real-time
  - Custom styling dan behavior

## Alur Kerja Notifikasi

### Skenario 1: App Aktif (Foreground)
1. **Socket Event** → NotificationService → Local Notification
2. **FCM Message** → FCMService → Custom Local Notification

### Skenario 2: App Background/Terminated  
1. **FCM Message** → System Notification
2. **Tap Notification** → App Launch → Navigation

### Skenario 3: Kombinasi
1. Server mengirim **FCM message** (untuk reliability)
2. Socket juga mengirim **real-time event** (untuk speed)
3. App menangani deduplication

## Keuntungan Strategi Hybrid

### ✅ **Reliability**
- FCM memastikan notifikasi sampai meski app tidak aktif
- Local notifications memberikan kontrol penuh saat app aktif

### ✅ **Performance**  
- Socket real-time untuk response cepat
- FCM fallback untuk reliability

### ✅ **User Experience**
- Konsistensi tampilan dengan local notifications
- Reliable delivery dengan FCM
- Custom channels dan styling

### ✅ **Flexibility**
- Bisa disable salah satu jika perlu
- Berbagai konfigurasi per jenis notifikasi

## Implementasi Saat Ini

### FCM Registration
```dart
// Auto-register FCM token setelah login admin
if (user.isAdmin && !isDummy) {
  _registerFcmTokenAfterLogin(apiService);
}
```

### Notification Channels
- `new_reports` - Laporan baru (High priority)
- `status_updates` - Update status (Medium priority)  
- `fcm_default_channel` - FCM fallback

### Socket Integration
```dart
// Real-time events tetap menggunakan NotificationService
_notificationService.showNewReportNotification(report);
```

## Rekomendasi

### ✅ **Tetap Gunakan Kedua Sistem**
- Local notifications untuk UX yang optimal
- FCM untuk reliability dan background delivery

### ✅ **Channel Unification**  
- FCM dan Local menggunakan channel yang sama
- Konsistensi styling dan behavior

### ✅ **Deduplication Logic**
- Cegah notifikasi duplikat dari socket + FCM
- Gunakan unique ID atau timestamp

### ✅ **Gradual Migration**
- Mulai dengan FCM untuk admin petugas
- Pertahankan local notifications untuk in-app experience
- Monitor performance dan user feedback

## Testing Strategy

1. **Test Socket + Local** (app foreground)
2. **Test FCM** (app background/terminated)  
3. **Test Both** (transition scenarios)
4. **Test Admin vs Regular User** (FCM vs Local only)

---

Dengan strategi ini, Anda mendapatkan yang terbaik dari kedua sistem tanpa mengorbankan reliability atau user experience.
