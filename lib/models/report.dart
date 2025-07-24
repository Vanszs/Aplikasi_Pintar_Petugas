import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class Report {
  final int id;
  final int userId;
  final String address;
  final DateTime createdAt;
  final String? userName; // Optional field for displaying user's name
  final String? phone; // Added phone field
  final String? jenisLaporan; // Added jenis_laporan field
  final String status; // Added status field
  final bool? sirenActivated; // Added siren activation status

  Report({
    required this.id,
    required this.userId,
    required this.address,
    required this.createdAt,
    this.userName,
    this.phone,
    this.jenisLaporan,
    this.status = 'pending', // Default status
    this.sirenActivated,
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
      status: json['status']?.toString() ?? 'pending', // Parse status from API
      sirenActivated: json['isSirine'] != null ? 
                     (json['isSirine'] is bool ? json['isSirine'] : 
                      json['isSirine'].toString().toLowerCase() == 'true') : null,
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
      'status': status,
      'isSirine': sirenActivated,
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

  // Get a user-friendly status name
  String getStatusDisplay() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }
  
  // Get status color
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'processing':
        return const Color(0xFF3B82F6); // Blue
      case 'completed':
        return const Color(0xFF10B981); // Green
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B); // Gray
    }
  }

  // Get siren status display
  String getSirenStatusDisplay() {
    if (sirenActivated == null) return 'Tidak Diketahui';
    return sirenActivated! ? 'Diaktifkan' : 'Tidak Diaktifkan';
  }

  // Get siren status color
  Color getSirenStatusColor() {
    if (sirenActivated == null) return const Color(0xFF64748B); // Gray
    return sirenActivated! ? const Color(0xFFEF4444) : const Color(0xFF10B981); // Red for activated, Green for not activated
  }

  // Get siren status icon
  IconData getSirenStatusIcon() {
    if (sirenActivated == null) return Icons.help_outline;
    return sirenActivated! ? Icons.volume_up_rounded : Icons.volume_off_rounded;
  }
}
