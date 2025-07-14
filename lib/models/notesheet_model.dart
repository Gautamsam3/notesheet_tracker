enum NotesheetStatus {
  pending,
  approved,
  rejected,
  completed,
}

enum ReviewStatus {
  pending,
  approved,
  rejected,
  waiting,
}

class Reviewer {
  final String uid;
  final String name;
  final ReviewStatus status;
  final DateTime? actionDate;
  final String? comments;

  Reviewer({
    required this.uid,
    required this.name,
    this.status = ReviewStatus.pending,
    this.actionDate,
    this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'status': status.name,
      'action_date': actionDate?.toIso8601String(),
      'comments': comments,
    };
  }

  factory Reviewer.fromJson(Map<String, dynamic> json) {
    return Reviewer(
      uid: json['uid'] as String,
      name: json['name'] as String,
      status: ReviewStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReviewStatus.pending,
      ),
      actionDate: json['action_date'] != null
          ? DateTime.parse(json['action_date'] as String)
          : null,
      comments: json['comments'] as String?,
    );
  }

  Reviewer copyWith({
    String? uid,
    String? name,
    ReviewStatus? status,
    DateTime? actionDate,
    String? comments,
  }) {
    return Reviewer(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      status: status ?? this.status,
      actionDate: actionDate ?? this.actionDate,
      comments: comments ?? this.comments,
    );
  }
}

class Notesheet {
  final String id;
  final String title;
  final String description;
  final String creatorUid;
  final String creatorName;
  final List<Reviewer> reviewFlow;
  final String? currentReviewerUid;
  final NotesheetStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deadline;
  final bool isEdited;
  // Helper field to make queries easier in Firestore security rules
  final List<String> reviewerUids;
  // PDF attachment URL from Supabase
  final String? pdfUrl;
  final String? pdfFileName;

  Notesheet({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorUid,
    required this.creatorName,
    required this.reviewFlow,
    this.currentReviewerUid,
    this.status = NotesheetStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.deadline,
    this.isEdited = false,
    this.pdfUrl,
    this.pdfFileName,
  }) : reviewerUids = reviewFlow.map((r) => r.uid).toList();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creator_uid': creatorUid,
      'creator_name': creatorName,
      'review_flow': reviewFlow.map((r) => r.toJson()).toList(),
      'reviewer_uids': reviewerUids,
      'current_reviewer_uid': currentReviewerUid,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'is_edited': isEdited,
      'pdf_url': pdfUrl,
      'pdf_file_name': pdfFileName,
    };
  }

  factory Notesheet.fromJson(Map<String, dynamic> json) {
    return Notesheet(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      creatorUid: json['creator_uid'] as String,
      creatorName: json['creator_name'] as String,
      reviewFlow: (json['review_flow'] as List<dynamic>)
          .map((r) => Reviewer.fromJson(r as Map<String, dynamic>))
          .toList(),
      currentReviewerUid: json['current_reviewer_uid'] as String?,
      status: NotesheetStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NotesheetStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
      pdfUrl: json['pdf_url'] as String?,
      pdfFileName: json['pdf_file_name'] as String?,
    );
  }

  Notesheet copyWith({
    String? id,
    String? title,
    String? description,
    String? creatorUid,
    String? creatorName,
    List<Reviewer>? reviewFlow,
    String? currentReviewerUid,
    NotesheetStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deadline,
    bool? isEdited,
    String? pdfUrl,
    String? pdfFileName,
  }) {
    return Notesheet(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorUid: creatorUid ?? this.creatorUid,
      creatorName: creatorName ?? this.creatorName,
      reviewFlow: reviewFlow ?? this.reviewFlow,
      currentReviewerUid: currentReviewerUid ?? this.currentReviewerUid,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deadline: deadline ?? this.deadline,
      isEdited: isEdited ?? this.isEdited,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfFileName: pdfFileName ?? this.pdfFileName,
    );
  }

  List<Reviewer> get approvedReviewers {
    return reviewFlow.where((r) => r.status == ReviewStatus.approved).toList();
  }

  int get currentReviewerIndex {
    if (currentReviewerUid == null) return -1;
    return reviewFlow.indexWhere((r) => r.uid == currentReviewerUid);
  }

  bool get isCompleted {
    return status == NotesheetStatus.completed ||
        (reviewFlow.isNotEmpty &&
            reviewFlow.every((r) => r.status == ReviewStatus.approved));
  }

  bool get isRejected {
    return status == NotesheetStatus.rejected ||
        reviewFlow.any((r) => r.status == ReviewStatus.rejected);
  }
}
