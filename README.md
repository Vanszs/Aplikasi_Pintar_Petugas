# Simokerto PINTAR - Aplikasi Petugas

<div align="center">
  <img src="assets/logo.png" alt="Simokerto PINTAR Logo" width="120" height="120">
  
  <h3>Pelayanan Informasi Terpadu dan Responsif untuk Petugas Simokerto</h3>
  
  ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
  ![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
  
  **Versi:** 2.1.0+3
</div>

## 📋 Deskripsi

Simokerto PINTAR adalah aplikasi mobile untuk petugas yang memungkinkan pengelolaan laporan masyarakat secara real-time. Aplikasi ini dilengkapi dengan sistem notifikasi push, manajemen laporan, dan dashboard monitoring yang komprehensif.

## ✨ Fitur Utama

### 🔐 Autentikasi & Keamanan
- Login dengan username dan password
- Sistem token JWT untuk keamanan
- Auto-switching antara mode real dan demo
- Session management dengan refresh token

### 📊 Dashboard & Monitoring
- Overview statistik laporan real-time
- Grafik dan analitik laporan
- Status tracking laporan (Pending, Processing, Completed, Rejected)
- User statistics dan leaderboard

### 📱 Manajemen Laporan
- Daftar laporan dengan filtering dan sorting
- Detail laporan dengan informasi lengkap
- Update status laporan
- Form laporan untuk petugas
- Real-time updates via WebSocket

### 🔔 Notifikasi Real-time
- Push notifications via Firebase Cloud Messaging (FCM)
- Socket.IO untuk updates real-time
- Background notifications
- Auto-refresh data saat app kembali aktif

### 👥 Manajemen User
- Profile petugas
- Detail informasi user/pelapor
- Statistik kontribusi user
- Contact management

### 🎨 User Interface
- Material Design 3
- Adaptive dark/light theme
- Smooth animations dan transitions
- Responsive design
- Glassmorphism effects

## 🛠 Tech Stack

### Frontend
- **Flutter** 3.0+ - Cross-platform mobile framework
- **Dart** 3.0+ - Programming language
- **Riverpod** - State management
- **Go Router** - Navigation dan routing

### Backend Integration
- **Socket.IO** - Real-time communication
- **HTTP** - REST API calls
- **Firebase** - Push notifications dan analytics

### Storage & Persistence
- **SharedPreferences** - Local data storage
- **Cached Network Image** - Image caching

### UI/UX Libraries
- **Google Fonts** - Typography
- **Lottie** - Animations
- **Shimmer** - Loading states
- **Flutter Animate** - UI animations
- **Glassmorphism** - Modern UI effects

### Development Tools
- **Flutter Lints** - Code quality
- **Flutter Launcher Icons** - Icon generation

## 📦 Instalasi

### Prerequisites
- Flutter SDK 3.0.0 atau lebih baru
- Dart SDK 3.0.0 atau lebih baru
- Android Studio / VS Code
- Android SDK (untuk Android development)
- Xcode (untuk iOS development - macOS only)

### Langkah Instalasi

1. **Clone repository**
   ```bash
   git clone [repository-url]
   cd petugas_pintar
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   - Buat project Firebase baru
   - Download `google-services.json` untuk Android
   - Download `GoogleService-Info.plist` untuk iOS
   - Tempatkan file konfigurasi di direktori yang sesuai

4. **Generate launcher icons**
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

5. **Run aplikasi**
   ```bash
   # Development mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

## 🚀 Penggunaan

### Mode Autentikasi

**Mode Demo:**
- Username: `test`
- Password: `test`
- Menggunakan data dummy untuk testing

**Mode Production:**
- Username dan password sesuai dengan akun petugas
- Terhubung ke server real dengan data aktual

### Konfigurasi Server

Edit konfigurasi server di `lib/main.dart`:

```dart
const serverIp = '185.197.195.155'; 
const serverPort = '3000';
const serverUrl = 'http://$serverIp:$serverPort';
```

### Firebase Configuration

Pastikan file konfigurasi Firebase sudah ditempatkan dengan benar:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## 📱 Screenshots

<!-- Tambahkan screenshots aplikasi di sini -->

## 🏗 Arsitektur

```
lib/
├── main.dart                 # Entry point aplikasi
├── routes.dart              # Konfigurasi routing
├── models/                  # Data models
│   ├── user.dart
│   └── report.dart
├── providers/               # State management
│   ├── auth_provider.dart
│   └── report_provider.dart
├── screens/                 # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── reports_screen.dart
│   └── ...
├── services/               # Business logic
│   ├── api.dart
│   ├── socket_service.dart
│   ├── fcm_service.dart
│   └── ...
└── widgets/               # Reusable components
```

## 🔧 Environment Variables

Aplikasi menggunakan konfigurasi berikut:

```dart
// Server Configuration
const serverIp = '185.197.195.155';
const serverPort = '3000';

// Firebase Configuration
// Dikonfigurasi melalui google-services.json dan GoogleService-Info.plist
```

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📋 Build Release

### Android
```bash
flutter build apk --release
# atau
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork project ini
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 👥 Tim Pengembang

- **Frontend Developer** - Flutter Development
- **Backend Developer** - API & Socket.IO Integration
- **UI/UX Designer** - Interface Design

## 📞 Support

Untuk bantuan dan pertanyaan:
- Email: support@simokerto-pintar.id
- WhatsApp: +62 xxx-xxxx-xxxx

## 🔄 Changelog

### v2.1.0+3 (Current)
- ✅ Implementasi Firebase Cloud Messaging
- ✅ Auto-switching mode (Real/Demo)
- ✅ Enhanced real-time notifications
- ✅ Improved UI/UX dengan Material Design 3
- ✅ Background service optimization
- ✅ Better error handling dan connectivity

### v2.0.0
- ✅ Socket.IO integration
- ✅ Real-time report updates
- ✅ User management features
- ✅ Enhanced dashboard

### v1.0.0
- ✅ Basic authentication
- ✅ Report management
- ✅ Initial UI implementation

---

<div align="center">
  <strong>Simokerto PINTAR - Melayani dengan Inovasi Digital</strong>
</div>
