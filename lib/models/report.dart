import 'package:intl/intl.dart';

class Report {
  final int id;
  final int userId;
  final String address;
  final DateTime createdAt;
  final String? userName; // Optional field for displaying user's name
  final String? phone; // Added phone field
  final String? jenisLaporan; // Added jenis_laporan field
  final String? detailLaporan; // Added detail_laporan field

  Report({
    required this.id,
    required this.userId,
    required this.address,
    required this.createdAt,
    this.userName,
    this.phone,
    this.jenisLaporan,
    this.detailLaporan,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] != null ? 
              (json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString())) : 0,
      address: json['address']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at']).toUtc().add(const Duration(hours: 7)),
      userName: json['reporter_name']?.toString() ?? json['name']?.toString(), // Backend menggunakan 'reporter_name' atau 'name'
      phone: json['phone']?.toString(), // Parse phone from API
      jenisLaporan: json['jenis_laporan']?.toString(), // Parse jenis_laporan from API
      detailLaporan: json['detail_laporan']?.toString(), // Parse detail_laporan from API
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'name': userName,
      'phone': phone,
      'jenis_laporan': jenisLaporan,
      'detail_laporan': detailLaporan,
    };
  }

  // Format timestamp for display
  String formattedDate() {
    return DateFormat('dd MMM yyyy, HH:mm').format(createdAt);
  }

  // Type of report with proper formatting
  String getReportType() {
    if (jenisLaporan == null || jenisLaporan!.isEmpty) {
      return "Tidak Diketahui";
    }
    // Capitalize first letter
    return jenisLaporan![0].toUpperCase() + jenisLaporan!.substring(1);
  }

  String get timeAgo {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
    }
  }
}
