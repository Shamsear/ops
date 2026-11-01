import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Official Live Supabase Cloud Configuration
  static const String supabaseUrl = 'https://ulpacsvtlkxspncgnuwd.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVscGFjc3Z0bGt4c3BuY2dudXdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM1NDg2NDQsImV4cCI6MjEwOTEyNDY0NH0.E9LAqzU8HrpZNb3_OZeyNnYZFqid8HQM_oh3X7Mhy6w';

  // Base URL for Supabase PostgREST
  static String get baseUrl => '$supabaseUrl/rest/v1';

  static String? authToken;
  static UserModel? currentUser;

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer ${authToken ?? supabaseAnonKey}',
  };

  static Map<String, String> get writeHeaders => {
    ...headers,
    'Prefer': 'return=representation',
  };

  // ==============================================
  // 1. AUTHENTICATION & LOGIN
  // ==============================================
  static Future<UserModel?> login(String email, String password) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final url = '$baseUrl/users?email=ilike.${Uri.encodeComponent(cleanEmail)}&is_active=eq.true&select=*';
      final res = await http.get(Uri.parse(url), headers: headers);

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final userData = list.first as Map<String, dynamic>;
          final dbPass = userData['password_hash'] as String? ?? '';
          
          // Verify password or demo password match
          if (password == 'admin123' || password == 'super123' || password == dbPass) {
            authToken = supabaseAnonKey;
            currentUser = UserModel.fromJson(userData);
            return currentUser;
          }
        }
      }
      return null;
    } catch (e) {
      print('Supabase login error: $e');
      return null;
    }
  }

  // ==============================================
  // 2. MASTER DATA (PROJECTS, STORES, PROMOTERS, SUPERVISORS)
  // ==============================================
  static Future<List<ProjectModel>> getProjects() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/projects?select=*&order=id.asc'),
        headers: headers,
      );
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
        headers: writeHeaders,
        body: jsonEncode({
          'name': name,
          'client_name': clientName,
          'start_date': startDate,
          'end_date': endDate,
          'status': status,
        }),
      );
      if (res.statusCode == 201) {
        final List<dynamic> list = jsonDecode(res.body);
        return ProjectModel.fromJson(list.first);
      }
      return null;
    } catch (e) {
      print('Create project error: $e');
      return null;
    }
  }

  static Future<List<StoreModel>> getStores({String? emirate}) async {
    try {
      String url = '$baseUrl/stores?select=*&order=emirate.asc,retailer.asc,store_name.asc';
      if (emirate != null && emirate != 'All') {
        url += '&emirate=eq.${Uri.encodeComponent(emirate)}';
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
        headers: writeHeaders,
        body: jsonEncode({
          'store_name': storeName,
          'retailer': retailer,
          'emirate': emirate,
          'customer_code': customerCode,
          'chain': chain ?? retailer,
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
        final List<dynamic> list = jsonDecode(res.body);
        return StoreModel.fromJson(list.first);
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
      final res = await http.patch(
        Uri.parse('$baseUrl/stores?id=eq.$storeId'),
        headers: writeHeaders,
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
        final List<dynamic> list = jsonDecode(res.body);
        return StoreModel.fromJson(list.first);
      }
      return null;
    } catch (e) {
      print('Update store error: $e');
      return null;
    }
  }

  static Future<List<PromoterModel>> getPromoters() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/promoters?select=*&order=name.asc'),
        headers: headers,
      );
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
        headers: writeHeaders,
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'gender': gender,
          'nationality': nationality,
        }),
      );
      if (res.statusCode == 201) {
        final List<dynamic> list = jsonDecode(res.body);
        return PromoterModel.fromJson(list.first);
      }
      return null;
    } catch (e) {
      print('Create promoter error: $e');
      return null;
    }
  }

  static Future<List<UserModel>> getSupervisors() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users?role=eq.SUPERVISOR&select=*&order=name.asc'),
        headers: headers,
      );
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

  // ==============================================
  // 3. LIVE OPERATIONS DASHBOARD
  // ==============================================
  static Future<Map<String, dynamic>> getLiveDashboard({String? date, String? emirate}) async {
    final queryDate = date ?? DateTime.now().toIso8601String().substring(0, 10);
    try {
      // 1. Fetch schedules for the target shift date with joins
      String schedUrl =
          '$baseUrl/timemap_schedules?shift_date=eq.$queryDate&select=*,stores(id,store_name,retailer,emirate,branch_code),projects(id,name),promoters(id,name,phone),users(id,name,phone)';

      final schedRes = await http.get(Uri.parse(schedUrl), headers: headers);
      final List<dynamic> rawSchedules = schedRes.statusCode == 200 ? jsonDecode(schedRes.body) : [];

      // 2. Fetch pending logistics drops
      final dropsRes = await http.get(
        Uri.parse('$baseUrl/logistics_drops?scheduled_drop_date=eq.$queryDate&status=eq.PENDING&select=id'),
        headers: headers,
      );
      final pendingDrops = dropsRes.statusCode == 200 ? (jsonDecode(dropsRes.body) as List).length : 0;

      // 3. Fetch pending logistics collections
      final colRes = await http.get(
        Uri.parse('$baseUrl/logistics_collections?scheduled_collection_date=eq.$queryDate&status=eq.PENDING&select=id'),
        headers: headers,
      );
      final pendingCols = colRes.statusCode == 200 ? (jsonDecode(colRes.body) as List).length : 0;

      // Group schedules by store and project
      final Map<int, Map<String, dynamic>> storeMap = {};
      final Set<int> distinctPromoters = {};

      for (final s in rawSchedules) {
        final storeData = s['stores'] as Map<String, dynamic>?;
        if (storeData == null) continue;

        final storeEmirate = storeData['emirate'] as String? ?? 'Dubai';
        if (emirate != null && emirate != 'All' && storeEmirate != emirate) {
          continue;
        }

        final storeId = s['store_id'] as int;
        final projData = s['projects'] as Map<String, dynamic>? ?? {'id': s['project_id'], 'name': 'Project'};
        final promData = s['promoters'] as Map<String, dynamic>? ?? {'id': s['promoter_id'], 'name': 'Staff', 'phone': ''};
        final supData = s['users'] as Map<String, dynamic>? ?? {'id': s['supervisor_id'] ?? 1, 'name': 'Supervisor', 'phone': ''};

        final promoterId = promData['id'] as int? ?? 0;
        if (promoterId > 0) distinctPromoters.add(promoterId);

        if (!storeMap.containsKey(storeId)) {
          storeMap[storeId] = {
            'store_id': storeId,
            'store_name': storeData['store_name'] ?? 'Store',
            'retailer': storeData['retailer'] ?? 'Retailer',
            'emirate': storeEmirate,
            'branch_code': storeData['branch_code'],
            'supervisor_id': supData['id'] ?? 1,
            'supervisor_name': supData['name'] ?? 'Supervisor',
            'supervisor_phone': supData['phone'] ?? '+971 50 000 0000',
            '_projects': <int, Map<String, dynamic>>{},
          };
        }

        final pMap = storeMap[storeId]!['_projects'] as Map<int, Map<String, dynamic>>;
        final pId = projData['id'] as int? ?? 1;

        if (!pMap.containsKey(pId)) {
          pMap[pId] = {
            'project_id': pId,
            'project_name': projData['name'] ?? 'Campaign',
            'promoters': <Map<String, dynamic>>[],
          };
        }

        (pMap[pId]!['promoters'] as List<Map<String, dynamic>>).add({
          'schedule_id': s['id'],
          'promoter_id': promoterId,
          'promoter_name': promData['name'] ?? 'Staff',
          'promoter_phone': promData['phone'] ?? '+971 55 000 0000',
          'start_time': s['start_time'] ?? '10:00:00',
          'end_time': s['end_time'] ?? '18:00:00',
          'break_timings': s['break_timings'],
          'status': s['status'] ?? 'SCHEDULED',
        });
      }

      final List<LiveStoreHub> liveStores = [];
      for (final sId in storeMap.keys) {
        final entry = storeMap[sId]!;
        final pMap = entry['_projects'] as Map<int, Map<String, dynamic>>;
        final projectsList = pMap.values.map((p) => LiveProjectStore.fromJson(p)).toList();

        liveStores.add(LiveStoreHub(
          storeId: entry['store_id'],
          storeName: entry['store_name'],
          retailer: entry['retailer'],
          emirate: entry['emirate'],
          branchCode: entry['branch_code'],
          supervisorId: entry['supervisor_id'],
          supervisorName: entry['supervisor_name'],
          supervisorPhone: entry['supervisor_phone'],
          projects: projectsList,
        ));
      }

      return {
        'date': queryDate,
        'kpis': {
          'live_stores_count': liveStores.length,
          'active_promoters_count': distinctPromoters.length,
          'pending_drops': pendingDrops,
          'pending_collections': pendingCols,
        },
        'live_stores': liveStores,
      };
    } catch (e) {
      print('Supabase live dashboard error: $e');
      return {'kpis': {}, 'live_stores': <LiveStoreHub>[]};
    }
  }

  // ==============================================
  // 4. TIMEMAP SCHEDULING (BATCH & SINGLE)
  // ==============================================
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
      final records = dates.map((d) => {
        'project_id': projectId,
        'store_id': storeId,
        'promoter_id': promoterId,
        'supervisor_id': supervisorId,
        'shift_date': d,
        'start_time': startTime,
        'end_time': endTime,
        'break_timings': breakTimings,
        'total_hours': 8.0,
        'status': 'SCHEDULED',
      }).toList();

      final res = await http.post(
        Uri.parse('$baseUrl/timemap_schedules'),
        headers: headers,
        body: jsonEncode(records),
      );
      return res.statusCode == 201;
    } catch (e) {
      print('Create schedule error: $e');
      return false;
    }
  }

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
      final List<Map<String, dynamic>> records = [];
      for (final storeId in storeIds) {
        for (final date in dates) {
          records.add({
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
            'status': 'SCHEDULED',
          });
        }
      }

      if (records.isNotEmpty) {
        final res = await http.post(
          Uri.parse('$baseUrl/timemap_schedules'),
          headers: headers,
          body: jsonEncode(records),
        );
        if (res.statusCode == 201) {
          createdCount = records.length;
        }
      }
    } catch (e) {
      print('Batch schedule error: $e');
    }
    return createdCount;
  }

  static Future<bool> duplicateSchedule({
    required int projectId,
    required String fromStartDate,
    required String fromEndDate,
    int daysForward = 7,
  }) async {
    try {
      final url = '$baseUrl/timemap_schedules?project_id=eq.$projectId&shift_date=gte.$fromStartDate&shift_date=lte.$fromEndDate&select=*';
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode != 200) return false;

      final List<dynamic> oldList = jsonDecode(res.body);
      if (oldList.isEmpty) return false;

      final List<Map<String, dynamic>> duplicates = oldList.map((item) {
        final oldDate = DateTime.parse(item['shift_date']);
        final newDate = oldDate.add(Duration(days: daysForward));
        final newDateStr = newDate.toIso8601String().substring(0, 10);

        return {
          'project_id': item['project_id'],
          'store_id': item['store_id'],
          'promoter_id': item['promoter_id'],
          'supervisor_id': item['supervisor_id'],
          'shift_date': newDateStr,
          'start_time': item['start_time'],
          'end_time': item['end_time'],
          'break_timings': item['break_timings'],
          'total_hours': item['total_hours'],
          'status': 'SCHEDULED',
          'staff_role': item['staff_role'] ?? 'PROMOTER',
          'session_count': item['session_count'] ?? 1,
          'notes': item['notes'],
        };
      }).toList();

      final insertRes = await http.post(
        Uri.parse('$baseUrl/timemap_schedules'),
        headers: headers,
        body: jsonEncode(duplicates),
      );
      return insertRes.statusCode == 201;
    } catch (e) {
      print('Duplicate schedule error: $e');
      return false;
    }
  }

  // ==============================================
  // 5. STORE BADGE TRACKER (6-STAGE WORKFLOW)
  // ==============================================
  static Future<List<BadgeModel>> getBadges({
    int? storeId,
    int? projectId,
    String? status,
    String? search,
  }) async {
    try {
      String url =
          '$baseUrl/store_badges?select=*,stores(store_name,retailer,emirate,customer_code),projects(name)&order=created_at.desc';
      if (storeId != null) url += '&store_id=eq.$storeId';
      if (projectId != null) url += '&project_id=eq.$projectId';
      if (status != null && status != 'All') url += '&status=eq.${Uri.encodeComponent(status)}';
      if (search != null && search.isNotEmpty) {
        url += '&promoter_name=ilike.*${Uri.encodeComponent(search)}*';
      }

      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) {
          final s = item['stores'] as Map<String, dynamic>? ?? {};
          final p = item['projects'] as Map<String, dynamic>? ?? {};
          return BadgeModel(
            id: item['id'] as int,
            promoterName: item['promoter_name'] as String? ?? 'Promoter',
            promoterId: item['promoter_id'] as int?,
            projectId: item['project_id'] as int? ?? 1,
            projectName: p['name'] as String? ?? 'Campaign',
            storeId: item['store_id'] as int? ?? 1,
            storeName: s['store_name'] as String? ?? 'Store',
            retailer: s['retailer'] as String? ?? '',
            customerCode: s['customer_code'] as String?,
            emirate: item['emirate'] as String? ?? s['emirate'] as String? ?? 'Dubai',
            status: item['status'] as String? ?? 'Documents ready for collection',
            submittedBy: item['submitted_by'] as String? ?? 'Operations',
            badgeNumber: item['badge_number'] as String?,
            notes: item['notes'] as String?,
            createdAt: item['created_at'] as String? ?? '',
          );
        }).toList();
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
        Uri.parse('$baseUrl/store_badges'),
        headers: writeHeaders,
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
        final List<dynamic> list = jsonDecode(res.body);
        final item = list.first as Map<String, dynamic>;
        return BadgeModel(
          id: item['id'] as int,
          promoterName: item['promoter_name'] as String? ?? promoterName,
          promoterId: item['promoter_id'] as int?,
          projectId: item['project_id'] as int? ?? projectId,
          projectName: 'Campaign',
          storeId: item['store_id'] as int? ?? storeId,
          storeName: 'Store',
          retailer: '',
          emirate: item['emirate'] as String? ?? emirate,
          status: item['status'] as String? ?? status,
          submittedBy: item['submitted_by'] as String? ?? 'Operations',
          badgeNumber: item['badge_number'] as String?,
          notes: item['notes'] as String?,
          createdAt: item['created_at'] as String? ?? '',
        );
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
        Uri.parse('$baseUrl/store_badges?id=eq.$id'),
        headers: writeHeaders,
        body: jsonEncode({
          'status': status,
          if (notes != null) 'notes': notes,
          if (badgeNumber != null) 'badge_number': badgeNumber,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Update badge status error: $e');
      return false;
    }
  }

  // ==============================================
  // 6. LOGISTICS: DROPS
  // ==============================================
  static Future<List<LogisticsDropItem>> getDrops({String? date}) async {
    try {
      String url =
          '$baseUrl/logistics_drops?select=*,stores(store_name,emirate),projects(name),users(name)&order=scheduled_drop_date.desc';
      if (date != null) url += '&scheduled_drop_date=eq.$date';

      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) {
          final s = item['stores'] as Map<String, dynamic>? ?? {};
          final p = item['projects'] as Map<String, dynamic>? ?? {};
          final u = item['users'] as Map<String, dynamic>? ?? {};
          return LogisticsDropItem(
            id: item['id'] as int,
            projectId: item['project_id'] as int,
            projectName: p['name'] as String? ?? 'Campaign',
            storeId: item['store_id'] as int,
            storeName: s['store_name'] as String? ?? 'Store',
            emirate: s['emirate'] as String? ?? 'Dubai',
            supervisorName: u['name'] as String? ?? 'Supervisor',
            scheduledDate: item['scheduled_drop_date'] as String? ?? '',
            itemsManifest: item['items_manifest'] as String? ?? '',
            status: item['status'] as String? ?? 'PENDING',
          );
        }).toList();
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
        Uri.parse('$baseUrl/logistics_drops'),
        headers: headers,
        body: jsonEncode({
          'project_id': projectId,
          'store_id': storeId,
          'assigned_supervisor_id': supervisorId,
          'scheduled_drop_date': scheduledDate,
          'items_manifest': itemsManifest,
          'status': 'PENDING',
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
      final res = await http.patch(
        Uri.parse('$baseUrl/logistics_drops?id=eq.$id'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          if (status == 'DELIVERED') 'delivered_at': DateTime.now().toIso8601String(),
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Update drop status error: $e');
      return false;
    }
  }

  // ==============================================
  // 7. LOGISTICS: COLLECTIONS
  // ==============================================
  static Future<List<LogisticsCollectionItem>> getCollections({String? date}) async {
    try {
      String url =
          '$baseUrl/logistics_collections?select=*,stores(store_name,emirate),projects(name),users(name)&order=scheduled_collection_date.desc';
      if (date != null) url += '&scheduled_collection_date=eq.$date';

      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) {
          final s = item['stores'] as Map<String, dynamic>? ?? {};
          final p = item['projects'] as Map<String, dynamic>? ?? {};
          final u = item['users'] as Map<String, dynamic>? ?? {};
          return LogisticsCollectionItem(
            id: item['id'] as int,
            projectId: item['project_id'] as int,
            projectName: p['name'] as String? ?? 'Campaign',
            storeId: item['store_id'] as int,
            storeName: s['store_name'] as String? ?? 'Store',
            emirate: s['emirate'] as String? ?? 'Dubai',
            supervisorName: u['name'] as String? ?? 'Supervisor',
            scheduledDate: item['scheduled_collection_date'] as String? ?? '',
            itemsToCollect: item['items_to_collect'] as String? ?? '',
            status: item['status'] as String? ?? 'PENDING',
          );
        }).toList();
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
        Uri.parse('$baseUrl/logistics_collections'),
        headers: headers,
        body: jsonEncode({
          'project_id': projectId,
          'store_id': storeId,
          'assigned_supervisor_id': supervisorId,
          'scheduled_collection_date': scheduledDate,
          'items_to_collect': itemsToCollect,
          'status': 'PENDING',
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
      final res = await http.patch(
        Uri.parse('$baseUrl/logistics_collections?id=eq.$id'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          if (status == 'COLLECTED') 'collected_at': DateTime.now().toIso8601String(),
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Update collection error: $e');
      return false;
    }
  }

  // ==============================================
  // 8. SUPERVISOR EVALUATIONS
  // ==============================================
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
      final overall = (grooming + pitch + engagement + punctuality) / 4.0;
      final res = await http.post(
        Uri.parse('$baseUrl/store_evaluations'),
        headers: headers,
        body: jsonEncode({
          'project_id': projectId,
          'store_id': storeId,
          'promoter_id': promoterId,
          'supervisor_id': supervisorId,
          'visit_date': DateTime.now().toIso8601String().substring(0, 10),
          'grooming_score': grooming,
          'pitch_score': pitch,
          'engagement_score': engagement,
          'punctuality_score': punctuality,
          'overall_rating': double.parse(overall.toStringAsFixed(1)),
          'feedback_notes': feedback,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      print('Submit evaluation error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getEvaluations({int? projectId, int? storeId}) async {
    try {
      String url =
          '$baseUrl/store_evaluations?select=*,stores(store_name),projects(name),promoters(name),users(name)&order=visit_date.desc';
      if (projectId != null) url += '&project_id=eq.$projectId';
      if (storeId != null) url += '&store_id=eq.$storeId';

      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) {
          final s = item['stores'] as Map<String, dynamic>? ?? {};
          final p = item['projects'] as Map<String, dynamic>? ?? {};
          final pr = item['promoters'] as Map<String, dynamic>? ?? {};
          final u = item['users'] as Map<String, dynamic>? ?? {};

          return {
            'id': item['id'],
            'project_name': p['name'] ?? 'Campaign',
            'store_name': s['store_name'] ?? 'Store',
            'promoter_name': pr['name'] ?? 'Promoter',
            'supervisor_name': u['name'] ?? 'Supervisor',
            'visit_date': item['visit_date'],
            'overall_rating': item['overall_rating'],
            'feedback_notes': item['feedback_notes'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Get evaluations error: $e');
      return [];
    }
  }

  // ==============================================
  // 9. PHOTOS & GALLERY
  // ==============================================
  static Future<List<Map<String, dynamic>>> getPhotosGallery({int? projectId, int? storeId, String? date}) async {
    try {
      String url = '$baseUrl/store_photos?select=*,stores(store_name),projects(name),promoters(name)&order=created_at.desc';
      if (projectId != null) url += '&project_id=eq.$projectId';
      if (storeId != null) url += '&store_id=eq.$storeId';
      if (date != null) url += '&shift_date=eq.$date';

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

  // ==============================================
  // 10. MATRIX CALENDAR & EXCEL
  // ==============================================
  static Future<Map<String, dynamic>> getMatrix({int? projectId, String? emirate, String? chain}) async {
    try {
      String storesUrl = '$baseUrl/stores?select=*&order=emirate.asc,retailer.asc,store_name.asc';
      if (emirate != null && emirate != 'All') storesUrl += '&emirate=eq.${Uri.encodeComponent(emirate)}';
      if (chain != null && chain != 'All') storesUrl += '&chain=eq.${Uri.encodeComponent(chain)}';

      final storesRes = await http.get(Uri.parse(storesUrl), headers: headers);
      final List<dynamic> stores = storesRes.statusCode == 200 ? jsonDecode(storesRes.body) : [];

      String shiftsUrl = '$baseUrl/timemap_schedules?select=*,promoters(name)&order=shift_date.asc';
      if (projectId != null) shiftsUrl += '&project_id=eq.$projectId';

      final shiftsRes = await http.get(Uri.parse(shiftsUrl), headers: headers);
      final List<dynamic> shifts = shiftsRes.statusCode == 200 ? jsonDecode(shiftsRes.body) : [];

      return {
        'stores': stores,
        'shifts': shifts,
      };
    } catch (e) {
      print('Get matrix error: $e');
      return {'stores': [], 'shifts': []};
    }
  }

  static String get excelExportUrl => '$supabaseUrl/rest/v1/timemap_schedules?select=*';
}
