/// Konfigurasi aplikasi untuk beta testing dan environment settings
class AppConfig {
  // Beta Testing Configuration
  static const bool isBetaTesting = true; // Set to false for production
  
  // Beta testing feature flags
  static const bool allowOfficerLogin = true; // Petugas bisa login
  static const bool restrictOfficerEditStatus = true; // Batasi edit status untuk petugas
  
  // Admin permissions berdasarkan role
  static bool canEditReportStatus(bool isAdmin, [String? role]) {
    if (isBetaTesting && restrictOfficerEditStatus) {
      // Dalam mode beta testing, hanya admin asli (bukan petugas) yang bisa edit status
      return isAdmin && role != 'petugas';
    }
    // Dalam mode production normal, admin bisa edit status
    return isAdmin && role != 'petugas';
  }
  
  // Check if user can access admin features
  static bool canAccessAdminFeatures(bool isAdmin, [String? role]) {
    if (isBetaTesting) {
      // Dalam beta testing, hanya admin asli yang bisa akses fitur admin
      return isAdmin && role != 'petugas';
    }
    // Dalam production, sesuai dengan role normal
    return isAdmin && role != 'petugas';
  }
  
  // Beta testing info untuk UI
  static String get betaTestingInfo => isBetaTesting 
      ? "Mode Beta Testing - Fitur edit status dibatasi untuk admin saja"
      : "";
      
  // Environment info
  static String get environmentName => isBetaTesting ? "BETA" : "PRODUCTION";
}
