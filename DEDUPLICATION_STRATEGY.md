# Solusi: Deduplication Notifications

## Masalah
Saat app aktif dan user login, ada kemungkinan menerima **notifikasi duplikat**:
1. **Socket Event** → NotificationService → Local Notification (real-time)
2. **FCM Message** → FCMService → FCM Notification (dari server)

Kedua notifikasi bisa muncul bersamaan untuk event yang sama.

## Solusi: Deduplication System

### 1. **NotificationService Deduplication**
```dart
class NotificationService {
  final Set<String> _recentNotifications = {};
  static const int _deduplicationWindowMs = 5000; // 5 detik window
  
  bool _shouldShowNotification(String notificationKey) {
    // Cek apakah notifikasi serupa sudah ditampilkan dalam 5 detik terakhir
    // Return false jika duplikat
  }
}
```

**Notification Keys:**
- `new_report_{reportId}` - untuk laporan baru
- `status_update_{reportId}_{status}` - untuk update status

### 2. **FCMService Deduplication**  
```dart
class FCMService {
  final Set<String> _recentFcmNotifications = {};
  static const int _fcmDeduplicationWindowMs = 5000;
  
  bool _shouldShowFcmNotification(String notificationKey) {
    // Similar logic untuk FCM notifications
  }
}
```

**FCM Notification Keys:**
- `fcm_new_report_{reportId}` - untuk FCM laporan baru
- `fcm_status_update_{reportId}_{status}` - untuk FCM update status

### 3. **Time-based Window Deduplication**
- **Window Duration**: 5 detik
- **Key Format**: `{type}_{id}_{timestamp}`
- **Cleanup**: Otomatis hapus keys yang sudah expired

## Alur Kerja Deduplication

### Skenario 1: Socket Event Datang Dulu
```
1. Socket event → NotificationService.showNewReportNotification()
2. Check _shouldShowNotification('new_report_123') → true (belum ada)
3. Add key 'new_report_123_1641234567000' ke _recentNotifications
4. Show notification ✅

5. FCM message datang (1-2 detik kemudian)
6. Check _shouldShowFcmNotification('fcm_new_report_123') → true (berbeda prefix)
7. Show FCM notification (tapi logic berikutnya akan handle ini)
```

### Skenario 2: Cross-Service Deduplication
Untuk deduplication yang lebih baik, perlu **shared deduplication service**:

```dart
class DeduplicationService {
  static final Set<String> _globalRecentNotifications = {};
  
  static bool shouldShowNotification(String baseKey) {
    // Check both 'new_report_123' dan 'fcm_new_report_123'
    // Return false jika ada yang serupa
  }
}
```

## Implementasi Saat Ini

### ✅ **Individual Service Deduplication**
- NotificationService mencegah duplikat dalam service sendiri
- FCMService mencegah duplikat FCM dalam service sendiri

### 🔄 **Cross-Service Protection** (Recommended Enhancement)
```dart
// Di NotificationService
Future<void> showNewReportNotification(Report report) async {
  final baseKey = 'report_${report.id}';
  if (!DeduplicationService.shouldShowNotification(baseKey, 'local')) {
    return;
  }
  // Show notification
}

// Di FCMService  
Future<void> _showLocalNotification(RemoteMessage message) async {
  final baseKey = 'report_${data['reportId']}';
  if (!DeduplicationService.shouldShowNotification(baseKey, 'fcm')) {
    return;
  }
  // Show notification
}
```

## Benefits

### ✅ **Individual Protection**
- Mencegah duplikat dalam service yang sama
- 5 detik window protection
- Automatic cleanup

### ✅ **Performance**
- Lightweight Set-based tracking
- Memory efficient dengan auto cleanup
- Minimal performance impact

### ✅ **User Experience**
- Tidak ada notifikasi spam
- Tetap reliable untuk notifikasi unik
- Konsisten timing

## Enhanced Strategy (Recommended)

### **Priority System:**
1. **Socket First** - Prioritaskan socket untuk speed
2. **FCM Fallback** - FCM sebagai backup jika socket gagal
3. **Global Deduplication** - Shared service untuk cross-protection

### **Smart Window:**
- **High Priority**: 3 detik window
- **Normal Priority**: 5 detik window  
- **Low Priority**: 10 detik window

### **Context-Aware:**
- App foreground: Prioritas socket
- App background: Prioritas FCM
- Network issues: Extended window

---

Dengan sistem ini, user akan melihat **maksimal 1 notifikasi per event** dalam window yang ditentukan! 🎯
