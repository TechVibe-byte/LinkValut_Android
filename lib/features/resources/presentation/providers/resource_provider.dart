import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/resource_model.dart';
import '../../../../core/database/hive_helper.dart';

class ResourceProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<ResourceModel> _resources = [];
  
  String _searchQuery = "";
  String? _selectedPlatform;
  bool? _filterFavorite;
  String? _filterLearningStatus;

  String get searchQuery => _searchQuery;
  String? get selectedPlatform => _selectedPlatform;
  bool? get filterFavorite => _filterFavorite;
  String? get filterLearningStatus => _filterLearningStatus;

  ResourceProvider() {
    _loadResources();
  }

  void _loadResources() {
    final box = HiveHelper.resourceBox;
    _resources = box.values.toList();
    notifyListeners();
  }

  List<ResourceModel> get allResources => _resources;

  List<ResourceModel> get filteredResources {
    return _resources.where((resource) {
      if (resource.isArchived) return false;

      // Search Query filter (matches Title, URL, Tags, Notes)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = resource.title.toLowerCase().contains(query);
        final matchUrl = resource.url.toLowerCase().contains(query);
        final matchNotes = resource.notes.toLowerCase().contains(query);
        final matchTags = resource.tags.any((tag) => tag.toLowerCase().contains(query));
        if (!matchTitle && !matchUrl && !matchNotes && !matchTags) {
          return false;
        }
      }

      // Platform filter
      if (_selectedPlatform != null && resource.platformType != _selectedPlatform) {
        return false;
      }

      // Favorite filter
      if (_filterFavorite != null && _filterFavorite == true && !resource.isFavorite) {
        return false;
      }

      // Learning status filter
      if (_filterLearningStatus != null && resource.learningStatus != _filterLearningStatus) {
        return false;
      }

      return true;
    }).toList();
  }

  List<ResourceModel> get archivedResources {
    return _resources.where((resource) => resource.isArchived).toList();
  }

  List<String> get allTags {
    final tagsSet = <String>{};
    for (var r in _resources) {
      if (!r.isArchived) {
        tagsSet.addAll(r.tags);
      }
    }
    return tagsSet.toList()..sort();
  }

  // Filters Update
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedPlatform(String? platform) {
    _selectedPlatform = platform;
    notifyListeners();
  }

  void setFilterFavorite(bool? favorite) {
    _filterFavorite = favorite;
    notifyListeners();
  }

  void setFilterLearningStatus(String? status) {
    _filterLearningStatus = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = "";
    _selectedPlatform = null;
    _filterFavorite = null;
    _filterLearningStatus = null;
    notifyListeners();
  }

  // Database Actions
  Future<void> addResource({
    required String title,
    required String url,
    required String platformType,
    required List<String> tags,
    required String notes,
    bool isFavorite = false,
  }) async {
    final newResource = ResourceModel(
      id: _uuid.v4(),
      title: title,
      url: url,
      platformType: platformType,
      tags: tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      notes: notes,
      isFavorite: isFavorite,
      dateAdded: DateTime.now(),
      lastUpdated: DateTime.now(),
      queueIndex: _resources.length,
    );

    final box = HiveHelper.resourceBox;
    await box.put(newResource.id, newResource);
    _loadResources();
  }

  Future<void> updateResource(ResourceModel resource) async {
    resource.lastUpdated = DateTime.now();
    await resource.save();
    _loadResources();
  }

  Future<void> deleteResource(String id) async {
    final box = HiveHelper.resourceBox;
    await box.delete(id);
    _loadResources();
  }

  Future<void> toggleFavorite(String id) async {
    final box = HiveHelper.resourceBox;
    final resource = box.get(id);
    if (resource != null) {
      resource.isFavorite = !resource.isFavorite;
      await resource.save();
      _loadResources();
    }
  }

  Future<void> toggleArchived(String id) async {
    final box = HiveHelper.resourceBox;
    final resource = box.get(id);
    if (resource != null) {
      resource.isArchived = !resource.isArchived;
      await resource.save();
      _loadResources();
    }
  }

  Future<void> updateProgress(String id, double progress) async {
    final box = HiveHelper.resourceBox;
    final resource = box.get(id);
    if (resource != null) {
      resource.progressPercentage = progress.clamp(0.0, 100.0);
      resource.isRead = progress >= 100.0;
      if (progress >= 100.0) {
        resource.learningStatus = 'Completed';
      } else if (progress > 0.0) {
        resource.learningStatus = 'In Progress';
      } else {
        resource.learningStatus = 'Not Started';
      }
      await resource.save();
      _loadResources();
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<ResourceModel> learningQueue = _resources
        .where((r) => !r.isArchived && r.learningStatus != 'Completed')
        .toList()
      ..sort((a, b) => a.queueIndex.compareTo(b.queueIndex));

    final item = learningQueue.removeAt(oldIndex);
    learningQueue.insert(newIndex, item);

    for (int i = 0; i < learningQueue.length; i++) {
      learningQueue[i].queueIndex = i;
      learningQueue[i].save();
    }
    _loadResources();
  }

  void refresh() {
    _loadResources();
  }
}
