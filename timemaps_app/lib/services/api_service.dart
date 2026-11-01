import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

import 'dart:io' show Platform;

class ApiService {
  // Uses 10.0.2.2 for Android emulators (official host loopback) or 192.168.10.51 / localhost
  static String get baseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api';
      }
    } catch (_) {}
    return 'http://localhost:5000/api';
  }
  static String? authToken;
  static UserModel? currentUser;

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  // 1. Auth
  static Future<UserModel?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        authToken = data['token'];
        currentUser = UserModel.fromJson(data['user']);
        return currentUser;
      }
      return null;
    } catch (e) {
      print('API login error: $e');
      return null;
    }
  }

  // 2. Master Data
  static Future<List<ProjectModel>> getProjects() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/projects'), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => ProjectModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get projects error: $e');
      return [];
    }
  }

  static Future<List<StoreModel>> getStores({String? emirate}) async {
    try {
      String url = '$baseUrl/stores';
      if (emirate != null && emirate != 'All') {
        url += '?emirate=${Uri.encodeComponent(emirate)}';
      }
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => StoreModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get stores error: $e');
      return [];
    }
  }

  static Future<List<PromoterModel>> getPromoters() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/promoters'), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => PromoterModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get promoters error: $e');
      return [];
    }
  }

  static Future<List<UserModel>> getSupervisors() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/supervisors'), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => UserModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get supervisors error: $e');
      return [];
    }
  }

  // 2b. Master Data Creation
  static Future<ProjectModel?> createProject({
    required String name,
    required String clientName,
    required String startDate,
    required String endDate,
    String status = 'ACTIVE',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/projects'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'client_name': clientName,
          'start_date': startDate,
          'end_date': endDate,
          'status': status,
        }),
      );
      if (res.statusCode == 201) {
        return ProjectModel.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('Create project error: $e');
      return null;
    }
  }

  static Future<StoreModel?> createStore({
    required String storeName,
    required String retailer,
    required String emirate,
    String? customerCode,
    String? chain,
    String? city,
    String? smnContact,
    String? merchandiserLead,
    String? branchCode,
    String? locationAddress,
    String? contactPerson,
    String? contactPhone,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/stores'),
        headers: headers,
        body: jsonEncode({
          'store_name': storeName,
          'retailer': retailer,
          'emirate': emirate,
          'customer_code': customerCode,
          'chain': chain,
          'city': city,
          'smn_contact': smnContact,
          'merchandiser_lead': merchandiserLead,
          'branch_code': branchCode,
          'location_address': locationAddress,
          'contact_person': contactPerson,
          'contact_phone': contactPhone,
        }),
      );
      if (res.statusCode == 201) {
        return StoreModel.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('Create store error: $e');
      return null;
    }
  }

  static Future<StoreModel?> updateStore({
    required int storeId,
    String? storeName,
    String? retailer,
    String? emirate,
    String? customerCode,
    String? chain,
    String? city,
    String? smnContact,
    String? merchandiserLead,
    String? branchCode,
    String? locationAddress,
    String? contactPerson,
    String? contactPhone,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/stores/$storeId'),
        headers: headers,
        body: jsonEncode({
          if (storeName != null) 'store_name': storeName,
          if (retailer != null) 'retailer': retailer,
          if (emirate != null) 'emirate': emirate,
          if (customerCode != null) 'customer_code': customerCode,
          if (chain != null) 'chain': chain,
          if (city != null) 'city': city,
          if (smnContact != null) 'smn_contact': smnContact,
          if (merchandiserLead != null) 'merchandiser_lead': merchandiserLead,
          if (branchCode != null) 'branch_code': branchCode,
          if (locationAddress != null) 'location_address': locationAddress,
          if (contactPerson != null) 'contact_person': contactPerson,
          if (contactPhone != null) 'contact_phone': contactPhone,
        }),
      );
      if (res.statusCode == 200) {
        return StoreModel.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('Update store error: $e');
      return null;
    }
  }

  static Future<PromoterModel?> createPromoter({
    required String name,
    required String phone,
    String? email,
    String gender = 'FEMALE',
    String? nationality,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/promoters'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'gender': gender,
          'nationality': nationality,
        }),
      );
      if (res.statusCode == 201) {
        return PromoterModel.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('Create promoter error: $e');
      return null;
    }
  }

  // 3. Live Dashboard
  static Future<Map<String, dynamic>> getLiveDashboard({String? date, String? emirate}) async {
    try {
      String url = '$baseUrl/dashboard/live?';
      if (date != null) url += 'date=$date&';
      if (emirate != null && emirate != 'All') url += 'emirate=${Uri.encodeComponent(emirate)}&';

      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final stores = (data['live_stores'] as List<dynamic>)
            .map((s) => LiveStoreHub.fromJson(s))
            .toList();

        return {
          'date': data['date'],
          'kpis': data['kpis'] ?? {},
          'live_stores': stores,
        };
      }
      return {'kpis': {}, 'live_stores': <LiveStoreHub>[]};
    } catch (e) {
      print('Live dashboard error: $e');
      return {'kpis': {}, 'live_stores': <LiveStoreHub>[]};
    }
  }

  // 4. In-App Scheduling
  static Future<bool> createSchedule({
    required int projectId,
    required int storeId,
    required int promoterId,
    required int supervisorId,
    required List<String> dates,
    required String startTime,
    required String endTime,
    String? breakTimings,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/timemaps/create'),
        headers: headers,
        body: jsonEncode({
          'project_id': projectId,
          'store_id': storeId,
          'promoter_id': promoterId,
          'supervisor_id': supervisorId,
          'dates': dates,
          'start_time': startTime,
          'end_time': endTime,
          'break_timings': breakTimings,
          'total_hours': 8.0,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      print('Create schedule error: $e');
      return false;
    }
  }

  static Future<bool> duplicateSchedule({
    required int projectId,
    required String fromStartDate,
    required String fromEndDate,
    int daysForward = 7,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/timemaps/duplicate'),
        headers: headers,
        body: jsonEncode({
          'project_id': projectId,
          'from_start_date': fromStartDate,
          'from_end_date': fromEndDate,
          'days_forward': daysForward,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Duplicate schedule error: $e');
      return false;
    }
  }

  // 5. Logistics: Drops
  static Future<List<LogisticsDropItem>> getDrops({String? date}) async {
    try {
      String url = '$baseUrl/logistics/drops';
      if (date != null) url += '?date=$date';
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => LogisticsDropItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get drops error: $e');
      return [];
    }
  }

  static Future<bool> createDrop({
    required int projectId,
    required int storeId,
    required int supervisorId,
    required String scheduledDate,
    required String itemsManifest,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/logistics/drops'),
        headers: headers,
        body: jsonEncode({
          'project_id': projectId,
          'store_id': storeId,
          'assigned_supervisor_id': supervisorId,
          'scheduled_drop_date': scheduledDate,
          'items_manifest': itemsManifest,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      print('Create drop error: $e');
      return false;
    }
  }

  static Future<bool> updateDropStatus(int id, String status) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/logistics/drops/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Update drop error: $e');
      return false;
    }
  }

  // 6. Logistics: Dedicated Collections Option
  static Future<List<LogisticsCollectionItem>> getCollections({String? date}) async {
    try {
      String url = '$baseUrl/logistics/collections';
      if (date != null) url += '?date=$date';
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => LogisticsCollectionItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get collections error: $e');
      return [];
    }
  }

  static Future<bool> createCollection({
    required int projectId,
    required int storeId,
    required int supervisorId,
    required String scheduledDate,
    required String itemsToCollect,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/logistics/collections'),
        headers: headers,
        body: jsonEncode({
          'project_id': projectId,
          'store_id': storeId,
          'assigned_supervisor_id': supervisorId,
          'scheduled_collection_date': scheduledDate,
          'items_to_collect': itemsToCollect,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      print('Create collection error: $e');
      return false;
    }
  }

  static Future<bool> updateCollectionStatus(int id, String status) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/logistics/collections/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Update collection error: $e');
      return false;
    }
  }

  // 7. Supervisor Evaluations
  static Future<bool> submitEvaluation({
    required int projectId,
    required int storeId,
    required int promoterId,
    required int supervisorId,
    required int grooming,
    required int pitch,
    required int engagement,
    required int punctuality,
    String? feedback,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/evaluations'),
        headers: headers,
        body: jsonEncode({
          'project_id': projectId,
          'store_id': storeId,
          'promoter_id': promoterId,
          'supervisor_id': supervisorId,
          'grooming_score': grooming,
          'pitch_score': pitch,
          'engagement_score': engagement,
          'punctuality_score': punctuality,
          'feedback_notes': feedback,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      print('Submit evaluation error: $e');
      return false;
    }
  }

  // 8. Store Badge Tracker
  static Future<List<BadgeModel>> getBadges({int? storeId, int? projectId, String? status, String? search}) async {
    try {
      String url = '$baseUrl/badges?';
      if (storeId != null) url += 'store_id=$storeId&';
      if (projectId != null) url += 'project_id=$projectId&';
      if (status != null && status != 'All') url += 'status=${Uri.encodeComponent(status)}&';
      if (search != null && search.isNotEmpty) url += 'search=${Uri.encodeComponent(search)}&';

      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => BadgeModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get badges error: $e');
      return [];
    }
  }

  static Future<BadgeModel?> createBadge({
    required String promoterName,
    int? promoterId,
    required int projectId,
    required int storeId,
    required String emirate,
    String status = 'Documents ready for collection',
    String? submittedBy,
    String? badgeNumber,
    String? notes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/badges'),
        headers: headers,
        body: jsonEncode({
          'promoter_name': promoterName,
          'promoter_id': promoterId,
          'project_id': projectId,
          'store_id': storeId,
          'emirate': emirate,
          'status': status,
          'submitted_by': submittedBy ?? 'Operations Lead',
          'badge_number': badgeNumber,
          'notes': notes,
        }),
      );
      if (res.statusCode == 201) {
        return BadgeModel.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('Create badge error: $e');
      return null;
    }
  }

  static Future<bool> updateBadgeStatus(int id, String status, {String? notes, String? badgeNumber}) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/badges/$id/status'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          if (notes != null) 'notes': notes,
          if (badgeNumber != null) 'badge_number': badgeNumber,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Update badge status error: $e');
      return false;
    }
  }

  // 9. Batch Shift Scheduler
  static Future<int> createBatchSchedules({
    required int projectId,
    required List<int> storeIds,
    required List<String> dates,
    int? promoterId,
    required String startTime,
    required String endTime,
    String? breakTimings,
    double? totalHours,
    String? staffRole,
    String? notes,
  }) async {
    int createdCount = 0;
    try {
      for (final storeId in storeIds) {
        for (final date in dates) {
          final res = await http.post(
            Uri.parse('$baseUrl/schedules'),
            headers: headers,
            body: jsonEncode({
              'project_id': projectId,
              'store_id': storeId,
              'promoter_id': promoterId,
              'shift_date': date,
              'start_time': startTime,
              'end_time': endTime,
              'break_timings': breakTimings,
              'total_hours': totalHours ?? 8.0,
              'staff_role': staffRole ?? 'PROMOTER',
              'notes': notes,
            }),
          );
          if (res.statusCode == 201) createdCount++;
        }
      }
    } catch (e) {
      print('Batch schedule error: $e');
    }
    return createdCount;
  }

  // 10. Master Dynamic Matrix & Reports
  static Future<Map<String, dynamic>> getMatrix({int? projectId, String? emirate, String? chain}) async {
    try {
      String url = '$baseUrl/timemaps/matrix?';
      if (projectId != null) url += 'project_id=$projectId&';
      if (emirate != null && emirate != 'All') url += 'emirate=${Uri.encodeComponent(emirate)}&';
      if (chain != null && chain != 'All') url += 'chain=${Uri.encodeComponent(chain)}&';
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'stores': [], 'shifts': []};
    } catch (e) {
      print('Get matrix error: $e');
      return {'stores': [], 'shifts': []};
    }
  }

  static Future<List<Map<String, dynamic>>> getEvaluations({int? projectId, int? storeId}) async {
    try {
      String url = '$baseUrl/evaluations?';
      if (projectId != null) url += 'project_id=$projectId&';
      if (storeId != null) url += 'store_id=$storeId&';
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Get evaluations error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPhotosGallery({int? projectId, int? storeId, String? date}) async {
    try {
      String url = '$baseUrl/photos/gallery?';
      if (projectId != null) url += 'project_id=$projectId&';
      if (storeId != null) url += 'store_id=$storeId&';
      if (date != null) url += 'date=$date&';
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Get photos gallery error: $e');
      return [];
    }
  }

  static String get excelExportUrl => '$baseUrl/timemaps/export-excel';
}

