class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role; // OPS_ADMIN, SUPERVISOR, PROMOTER

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ProjectModel {
  final int id;
  final String name;
  final String clientName;
  final String status;

  ProjectModel({
    required this.id,
    required this.name,
    required this.clientName,
    required this.status,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as int,
      name: json['name'] as String,
      clientName: json['client_name'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class StoreModel {
  final int id;
  final String storeName;
  final String retailer;
  final String emirate;
  final String? customerCode;
  final String? chain;
  final String? city;
  final String? smnContact;
  final String? merchandiserLead;
  final String? branchCode;
  final String? contactPerson;
  final String? contactPhone;

  StoreModel({
    required this.id,
    required this.storeName,
    required this.retailer,
    required this.emirate,
    this.customerCode,
    this.chain,
    this.city,
    this.smnContact,
    this.merchandiserLead,
    this.branchCode,
    this.contactPerson,
    this.contactPhone,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as int,
      storeName: json['store_name'] as String,
      retailer: json['retailer'] as String,
      emirate: json['emirate'] as String,
      customerCode: json['customer_code'] as String?,
      chain: json['chain'] as String?,
      city: json['city'] as String?,
      smnContact: json['smn_contact'] as String?,
      merchandiserLead: json['merchandiser_lead'] as String?,
      branchCode: json['branch_code'] as String?,
      contactPerson: json['contact_person'] as String?,
      contactPhone: json['contact_phone'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class PromoterModel {
  final int id;
  final String name;
  final String phone;
  final String? nationality;

  PromoterModel({
    required this.id,
    required this.name,
    required this.phone,
    this.nationality,
  });

  factory PromoterModel.fromJson(Map<String, dynamic> json) {
    return PromoterModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      nationality: json['nationality'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromoterModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class LivePromoterShift {
  final int scheduleId;
  final int promoterId;
  final String promoterName;
  final String promoterPhone;
  final String startTime;
  final String endTime;
  final String? breakTimings;
  final String status;

  LivePromoterShift({
    required this.scheduleId,
    required this.promoterId,
    required this.promoterName,
    required this.promoterPhone,
    required this.startTime,
    required this.endTime,
    this.breakTimings,
    required this.status,
  });

  factory LivePromoterShift.fromJson(Map<String, dynamic> json) {
    return LivePromoterShift(
      scheduleId: json['schedule_id'] as int,
      promoterId: json['promoter_id'] as int,
      promoterName: json['promoter_name'] as String,
      promoterPhone: json['promoter_phone'] as String? ?? '',
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      breakTimings: json['break_timings'] as String?,
      status: json['status'] as String? ?? 'SCHEDULED',
    );
  }
}

class LiveProjectStore {
  final int projectId;
  final String projectName;
  final List<LivePromoterShift> promoters;

  LiveProjectStore({
    required this.projectId,
    required this.projectName,
    required this.promoters,
  });

  factory LiveProjectStore.fromJson(Map<String, dynamic> json) {
    return LiveProjectStore(
      projectId: json['project_id'] as int,
      projectName: json['project_name'] as String,
      promoters: (json['promoters'] as List<dynamic>)
          .map((p) => LivePromoterShift.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LiveStoreHub {
  final int storeId;
  final String storeName;
  final String retailer;
  final String emirate;
  final String? branchCode;
  final int supervisorId;
  final String supervisorName;
  final String supervisorPhone;
  final List<LiveProjectStore> projects;

  LiveStoreHub({
    required this.storeId,
    required this.storeName,
    required this.retailer,
    required this.emirate,
    this.branchCode,
    required this.supervisorId,
    required this.supervisorName,
    required this.supervisorPhone,
    required this.projects,
  });

  factory LiveStoreHub.fromJson(Map<String, dynamic> json) {
    return LiveStoreHub(
      storeId: json['store_id'] as int,
      storeName: json['store_name'] as String,
      retailer: json['retailer'] as String,
      emirate: json['emirate'] as String,
      branchCode: json['branch_code'] as String?,
      supervisorId: json['supervisor_id'] as int,
      supervisorName: json['supervisor_name'] as String,
      supervisorPhone: json['supervisor_phone'] as String? ?? '',
      projects: (json['projects'] as List<dynamic>)
          .map((p) => LiveProjectStore.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LogisticsDropItem {
  final int id;
  final int projectId;
  final String projectName;
  final int storeId;
  final String storeName;
  final String emirate;
  final String supervisorName;
  final String scheduledDate;
  final String itemsManifest;
  final String status; // PENDING, DELIVERED

  LogisticsDropItem({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.storeId,
    required this.storeName,
    required this.emirate,
    required this.supervisorName,
    required this.scheduledDate,
    required this.itemsManifest,
    required this.status,
  });

  factory LogisticsDropItem.fromJson(Map<String, dynamic> json) {
    return LogisticsDropItem(
      id: json['id'] as int,
      projectId: json['project_id'] as int,
      projectName: json['project_name'] as String? ?? '',
      storeId: json['store_id'] as int,
      storeName: json['store_name'] as String? ?? '',
      emirate: json['emirate'] as String? ?? '',
      supervisorName: json['supervisor_name'] as String? ?? '',
      scheduledDate: json['scheduled_drop_date'] as String? ?? '',
      itemsManifest: json['items_manifest'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}

class LogisticsCollectionItem {
  final int id;
  final int projectId;
  final String projectName;
  final int storeId;
  final String storeName;
  final String emirate;
  final String supervisorName;
  final String scheduledDate;
  final String itemsToCollect;
  final String status; // PENDING, COLLECTED

  LogisticsCollectionItem({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.storeId,
    required this.storeName,
    required this.emirate,
    required this.supervisorName,
    required this.scheduledDate,
    required this.itemsToCollect,
    required this.status,
  });

  factory LogisticsCollectionItem.fromJson(Map<String, dynamic> json) {
    return LogisticsCollectionItem(
      id: json['id'] as int,
      projectId: json['project_id'] as int,
      projectName: json['project_name'] as String? ?? '',
      storeId: json['store_id'] as int,
      storeName: json['store_name'] as String? ?? '',
      emirate: json['emirate'] as String? ?? '',
      supervisorName: json['supervisor_name'] as String? ?? '',
      scheduledDate: json['scheduled_collection_date'] as String? ?? '',
      itemsToCollect: json['items_to_collect'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}

class BadgeModel {
  final int id;
  final String promoterName;
  final int? promoterId;
  final int projectId;
  final String projectName;
  final int storeId;
  final String storeName;
  final String retailer;
  final String? customerCode;
  final String emirate;
  final String status;
  final String submittedBy;
  final String? badgeNumber;
  final String? notes;
  final String createdAt;

  BadgeModel({
    required this.id,
    required this.promoterName,
    this.promoterId,
    required this.projectId,
    required this.projectName,
    required this.storeId,
    required this.storeName,
    required this.retailer,
    this.customerCode,
    required this.emirate,
    required this.status,
    required this.submittedBy,
    this.badgeNumber,
    this.notes,
    required this.createdAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as int,
      promoterName: json['promoter_name'] as String,
      promoterId: json['promoter_id'] as int?,
      projectId: json['project_id'] as int,
      projectName: json['project_name'] as String? ?? 'Campaign',
      storeId: json['store_id'] as int,
      storeName: json['store_name'] as String? ?? 'Store',
      retailer: json['retailer'] as String? ?? '',
      customerCode: json['customer_code'] as String?,
      emirate: json['emirate'] as String? ?? 'Dubai',
      status: json['status'] as String? ?? 'Documents ready for collection',
      submittedBy: json['submitted_by'] as String? ?? 'Operations',
      badgeNumber: json['badge_number'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

