import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/report.dart';

class CacheService {
  static const String _reportsKey = 'cached_reports';
  static const String _userStatsKey = 'cached_user_stats';
  static const String _globalStatsKey = 'cached_global_stats';
  static const String _reportDetailsKey = 'cached_report_details';
  static const String _lastUpdateKey = 'cache_last_update';
  
  // Cache duration in hours
  static const int cacheExpiryHours = 24;

  // Save reports to cache
  static Future<void> saveReports(List<Report> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportJsonList = reports.map((report) => report.toJson()).toList();
      await prefs.setString(_reportsKey, json.encode(reportJsonList));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      developer.log('Saved ${reports.length} reports to cache', name: 'CacheService');
    } catch (e) {
      developer.log('Error saving reports to cache: $e', name: 'CacheService');
    }
  }

  // Load reports from cache
  static Future<List<Report>> loadReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getString(_reportsKey);
      
      if (reportsJson == null) {
        developer.log('No cached reports found', name: 'CacheService');
        return [];
      }

      // Check if cache is still valid
      if (!isCacheValid(prefs)) {
        developer.log('Cache expired, returning empty list', name: 'CacheService');
        return [];
      }

      final reportsList = json.decode(reportsJson) as List;
      final reports = reportsList.map((json) => Report.fromJson(json)).toList();
      developer.log('Loaded ${reports.length} reports from cache', name: 'CacheService');
      return reports;
    } catch (e) {
      developer.log('Error loading reports from cache: $e', name: 'CacheService');
      return [];
    }
  }

  // Save user stats to cache
  static Future<void> saveUserStats(Map<String, dynamic> stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userStatsKey, json.encode(stats));
      developer.log('Saved user stats to cache', name: 'CacheService');
    } catch (e) {
      developer.log('Error saving user stats to cache: $e', name: 'CacheService');
    }
  }

  // Load user stats from cache
  static Future<Map<String, dynamic>?> loadUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_userStatsKey);
      
      if (statsJson == null) {
        developer.log('No cached user stats found', name: 'CacheService');
        return null;
      }

      // Check if cache is still valid
      if (!isCacheValid(prefs)) {
        developer.log('User stats cache expired', name: 'CacheService');
        return null;
      }

      final stats = json.decode(statsJson) as Map<String, dynamic>;
      developer.log('Loaded user stats from cache', name: 'CacheService');
      return stats;
    } catch (e) {
      developer.log('Error loading user stats from cache: $e', name: 'CacheService');
      return null;
    }
  }

  // Save global stats to cache
  static Future<void> saveGlobalStats(Map<String, dynamic> stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_globalStatsKey, json.encode(stats));
      developer.log('Saved global stats to cache', name: 'CacheService');
    } catch (e) {
      developer.log('Error saving global stats to cache: $e', name: 'CacheService');
    }
  }

  // Load global stats from cache
  static Future<Map<String, dynamic>?> loadGlobalStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_globalStatsKey);
      
      if (statsJson == null) {
        developer.log('No cached global stats found', name: 'CacheService');
        return null;
      }

      // Check if cache is still valid
      if (!isCacheValid(prefs)) {
        developer.log('Global stats cache expired', name: 'CacheService');
        return null;
      }

      final stats = json.decode(statsJson) as Map<String, dynamic>;
      developer.log('Loaded global stats from cache', name: 'CacheService');
      return stats;
    } catch (e) {
      developer.log('Error loading global stats from cache: $e', name: 'CacheService');
      return null;
    }
  }

  // Save report detail to cache
  static Future<void> saveReportDetail(int reportId, Report report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentDetailsJson = prefs.getString(_reportDetailsKey);
      Map<String, dynamic> reportDetails = {};
      
      if (currentDetailsJson != null) {
        reportDetails = json.decode(currentDetailsJson) as Map<String, dynamic>;
      }
      
      reportDetails[reportId.toString()] = report.toJson();
      await prefs.setString(_reportDetailsKey, json.encode(reportDetails));
      developer.log('Saved report detail for ID $reportId to cache', name: 'CacheService');
    } catch (e) {
      developer.log('Error saving report detail to cache: $e', name: 'CacheService');
    }
  }

  // Load report detail from cache
  static Future<Report?> loadReportDetail(int reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final detailsJson = prefs.getString(_reportDetailsKey);
      
      if (detailsJson == null) {
        developer.log('No cached report details found', name: 'CacheService');
        return null;
      }

      // Check if cache is still valid - for report details, use longer expiry
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      if (lastUpdate != null) {
        final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
        final now = DateTime.now();
        final difference = now.difference(lastUpdateTime);
        
        // Report details cache expires after 7 days (much longer than regular cache)
        if (difference.inDays >= 7) {
          developer.log('Report details cache expired (${difference.inDays} days old)', name: 'CacheService');
          return null;
        }
      }

      final reportDetails = json.decode(detailsJson) as Map<String, dynamic>;
      final reportJson = reportDetails[reportId.toString()];
      
      if (reportJson == null) {
        developer.log('No cached detail found for report ID $reportId', name: 'CacheService');
        return null;
      }

      final report = Report.fromJson(reportJson);
      developer.log('Loaded cached report detail for ID $reportId', name: 'CacheService');
      return report;
    } catch (e) {
      developer.log('Error loading report detail from cache: $e', name: 'CacheService');
      return null;
    }
  }

  // Check if cache is still valid
  static bool isCacheValid(SharedPreferences prefs) {
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    if (lastUpdate == null) return false;
    
    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime);
    
    return difference.inHours < cacheExpiryHours;
  }

  // Clear all cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_reportsKey);
      await prefs.remove(_userStatsKey);
      await prefs.remove(_globalStatsKey);
      await prefs.remove(_reportDetailsKey);
      await prefs.remove(_lastUpdateKey);
      developer.log('All cache cleared', name: 'CacheService');
    } catch (e) {
      developer.log('Error clearing cache: $e', name: 'CacheService');
    }
  }

  // Get cache info for debugging
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      final hasReports = prefs.getString(_reportsKey) != null;
      final hasUserStats = prefs.getString(_userStatsKey) != null;
      final hasGlobalStats = prefs.getString(_globalStatsKey) != null;
      final hasReportDetails = prefs.getString(_reportDetailsKey) != null;
      
      return {
        'lastUpdate': lastUpdate != null 
            ? DateTime.fromMillisecondsSinceEpoch(lastUpdate).toIso8601String()
            : null,
        'isValid': lastUpdate != null ? isCacheValid(prefs) : false,
        'hasReports': hasReports,
        'hasUserStats': hasUserStats,
        'hasGlobalStats': hasGlobalStats,
        'hasReportDetails': hasReportDetails,
      };
    } catch (e) {
      developer.log('Error getting cache info: $e', name: 'CacheService');
      return {};
    }
  }
}
