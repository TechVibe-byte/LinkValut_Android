import 'package:hive/hive.dart';

part 'resource_model.g.dart';

@HiveType(typeId: 0)
class ResourceModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String url;

  @HiveField(3)
  String platformType; // 'YouTube Video', 'YouTube Playlist', 'Instagram Reel', 'Website', 'Blog', 'Documentation', 'PDF', 'Custom'

  @HiveField(4)
  List<String> tags;

  @HiveField(5)
  String notes;

  @HiveField(6)
  bool isFavorite;

  @HiveField(7)
  bool isRead;

  @HiveField(8)
  double progressPercentage; // 0.0 to 100.0

  @HiveField(9)
  DateTime dateAdded;

  @HiveField(10)
  DateTime lastUpdated;

  @HiveField(11)
  String learningStatus; // 'Not Started', 'In Progress', 'Completed'

  @HiveField(12)
  bool isArchived;

  @HiveField(13)
  int queueIndex;

  ResourceModel({
    required this.id,
    required this.title,
    required this.url,
    required this.platformType,
    required this.tags,
    required this.notes,
    this.isFavorite = false,
    this.isRead = false,
    this.progressPercentage = 0.0,
    required this.dateAdded,
    required this.lastUpdated,
    this.learningStatus = 'Not Started',
    this.isArchived = false,
    this.queueIndex = 0,
  });

  ResourceModel copyWith({
    String? title,
    String? url,
    String? platformType,
    List<String>? tags,
    String? notes,
    bool? isFavorite,
    bool? isRead,
    double? progressPercentage,
    DateTime? lastUpdated,
    String? learningStatus,
    bool? isArchived,
    int? queueIndex,
  }) {
    return ResourceModel(
      id: id,
      title: title ?? this.title,
      url: url ?? this.url,
      platformType: platformType ?? this.platformType,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      isRead: isRead ?? this.isRead,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      dateAdded: dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      learningStatus: learningStatus ?? this.learningStatus,
      isArchived: isArchived ?? this.isArchived,
      queueIndex: queueIndex ?? this.queueIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'platformType': platformType,
      'tags': tags,
      'notes': notes,
      'isFavorite': isFavorite,
      'isRead': isRead,
      'progressPercentage': progressPercentage,
      'dateAdded': dateAdded.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'learningStatus': learningStatus,
      'isArchived': isArchived,
      'queueIndex': queueIndex,
    };
  }

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      platformType: json['platformType'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      notes: json['notes'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      learningStatus: json['learningStatus'] as String? ?? 'Not Started',
      isArchived: json['isArchived'] as bool? ?? false,
      queueIndex: json['queueIndex'] as int? ?? 0,
    );
  }
}
