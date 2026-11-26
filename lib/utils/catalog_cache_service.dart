import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '/app_state.dart';
import '/auth/auth_session.dart';
import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/utils/secure_storage_service.dart';

/// Result of synchronizing clients, assigned projects, and project tasks.
class CatalogSyncResult {
  const CatalogSyncResult({
    required this.succeeded,
    this.timedOut = false,
    this.usedCache = false,
  });

  final bool succeeded;
  final bool timedOut;
  final bool usedCache;
}

/// Returns true for HTTP/socket failures where keeping cached data or queuing
/// an offline entry is safer than discarding or rejecting permanently.
bool isTransientApiFailure(ApiCallResponse response) {
  if (response.succeeded) return false;
  final code = response.statusCode;
  if (code <= 0) return true;
  if (code == 401 || code == 408 || code == 429) return true;
  if (code >= 500) return true;
  // An HTML 404 from a proxy/captive portal is a network problem, not an API 404.
  if (code == 404 && response.jsonBody is! Map) return true;
  return false;
}

/// Persists clients, assigned projects, and per-project tasks in memory and
/// encrypted Hive storage so the popup works without real-time per-project
/// lookups and survives offline/unstable connectivity.
class CatalogCacheService extends ChangeNotifier {
  CatalogCacheService._();

  static CatalogCacheService instance = CatalogCacheService._();

  static const String _kCatalogKey = 'ff_cached_catalog_v1';
  static const String _kTimeWorkspaceKey = 'ff_cached_time_workspace_v1';
  static const int _taskBatchSize = 4;

  String? _cachedUserId;
  List<OptionStruct> _clients = [];
  List<ProjectOptionStruct> _projects = [];
  Map<String, List<Map<String, dynamic>>> _tasksByProject = {};
  DateTime? _lastSyncSuccessAt;
  bool _lastSyncFailed = false;
  bool _projectsSyncFailed = false;
  Future<CatalogSyncResult>? _syncInFlight;

  Map<String, dynamic>? _timeRequestWorkspace;
  String? _timeRequestWorkspaceUserId;

  bool get isSyncing => _syncInFlight != null;
  bool get lastSyncFailed => _lastSyncFailed;
  bool get projectsSyncFailed => _projectsSyncFailed;
  DateTime? get lastSyncSuccessAt => _lastSyncSuccessAt;

  bool get hasAnyCatalog =>
      _clients.isNotEmpty ||
      _projects.isNotEmpty ||
      _tasksByProject.isNotEmpty;

  bool wasRecentlySynced(Duration window) {
    final at = _lastSyncSuccessAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < window;
  }

  bool hasTasksForProject(String projectId) =>
      _tasksByProject.containsKey(projectId);

  List<Map<String, dynamic>> tasksForProject(String projectId) {
    final tasks = _tasksByProject[projectId];
    if (tasks == null) return const [];
    return [for (final t in tasks) Map<String, dynamic>.from(t)];
  }

  /// Resolves the current user id from [FFAppState.UserData] or [authManager].
  static String resolveUserId() {
    final raw = FFAppState().UserData;
    Map? userData;
    if (raw is Map) {
      userData = raw;
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) userData = decoded;
      } catch (_) {}
    }
    final user = userData?['user'];
    if (user is Map) {
      final id = user['id']?.toString().trim() ?? '';
      if (id.isNotEmpty && id != 'null') return id;
    }
    final uid = authManager.uid?.trim() ?? '';
    return uid == 'null' ? '' : uid;
  }

  static List<Map<String, dynamic>> _normalizeListOfMaps(dynamic raw) {
    if (raw is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map) {
        out.add(Map<String, dynamic>.from(item));
      }
    }
    return out;
  }

  static List<OptionStruct> _parseClients(dynamic raw) {
    final maps = _normalizeListOfMaps(raw);
    return maps
        .map(OptionStruct.maybeFromMap)
        .whereType<OptionStruct>()
        .toList();
  }

  static List<ProjectOptionStruct> _parseProjects(dynamic raw) {
    final maps = _normalizeListOfMaps(raw);
    return maps
        .map(ProjectOptionStruct.maybeFromMap)
        .whereType<ProjectOptionStruct>()
        .toList();
  }

  void _applyToAppState() {
    FFAppState().clientsOptions = List<OptionStruct>.from(_clients);
    FFAppState().projectOptions =
        _projects.map((p) => p.toMap()).toList().cast<dynamic>();
  }

  /// Hydrates cached catalog and manual-time workspace from Hive (no network).
  void restoreFromCache() {
    final storage = SecureStorageService.instance;
    if (!storage.isInitialized) return;

    final currentUserId = resolveUserId();

    final rawCatalog = storage.getJson(_kCatalogKey);
    if (rawCatalog is Map) {
      final savedUserId = rawCatalog['user_id']?.toString() ?? '';
      if (currentUserId.isEmpty ||
          savedUserId.isEmpty ||
          savedUserId == currentUserId) {
        _cachedUserId = savedUserId.isNotEmpty ? savedUserId : currentUserId;
        _clients = _parseClients(rawCatalog['clients']);
        _projects = _parseProjects(rawCatalog['projects']);

        final rawTasks = rawCatalog['tasks_by_project'];
        final restoredTasks = <String, List<Map<String, dynamic>>>{};
        if (rawTasks is Map) {
          for (final entry in rawTasks.entries) {
            final key = entry.key.toString();
            restoredTasks[key] = _normalizeListOfMaps(entry.value);
          }
        }
        _tasksByProject = restoredTasks;

        final updatedAtRaw = rawCatalog['updated_at']?.toString();
        _lastSyncSuccessAt =
            updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) : null;
        _applyToAppState();
      }
    }

    final rawWorkspace = storage.getJson(_kTimeWorkspaceKey);
    if (rawWorkspace is Map) {
      final savedUserId = rawWorkspace['user_id']?.toString() ?? '';
      final workspace = rawWorkspace['workspace'];
      if (workspace is Map &&
          (currentUserId.isEmpty ||
              savedUserId.isEmpty ||
              savedUserId == currentUserId)) {
        _timeRequestWorkspaceUserId =
            savedUserId.isNotEmpty ? savedUserId : currentUserId;
        _timeRequestWorkspace = Map<String, dynamic>.from(workspace);
      }
    }
  }

  Future<void> _persistCatalog() async {
    final storage = SecureStorageService.instance;
    if (!storage.isInitialized) return;
    await storage.setJson(_kCatalogKey, {
      'user_id': _cachedUserId ?? resolveUserId(),
      'updated_at': _lastSyncSuccessAt?.toUtc().toIso8601String(),
      'clients': _clients.map((c) => c.toMap()).toList(),
      'projects': _projects.map((p) => p.toMap()).toList(),
      'tasks_by_project': _tasksByProject,
    });
  }

  /// Syncs only if cached data is missing or older than [maxAge].
  Future<CatalogSyncResult> syncIfStale({
    Duration maxAge = const Duration(minutes: 5),
    Duration requestTimeout = const Duration(seconds: 8),
    Duration? totalTimeout,
  }) {
    if (hasAnyCatalog && wasRecentlySynced(maxAge)) {
      return Future.value(
        const CatalogSyncResult(succeeded: true, usedCache: true),
      );
    }
    return sync(
      force: true,
      requestTimeout: requestTimeout,
      totalTimeout: totalTimeout,
    );
  }

  /// Fetches clients, assigned projects, and tasks for all assigned projects.
  /// Concurrent calls coalesce onto the active sync in flight.
  Future<CatalogSyncResult> sync({
    bool force = true,
    Duration requestTimeout = const Duration(seconds: 8),
    Duration? totalTimeout,
  }) {
    if (!force && hasAnyCatalog && wasRecentlySynced(const Duration(minutes: 5))) {
      return Future.value(
        const CatalogSyncResult(succeeded: true, usedCache: true),
      );
    }

    _syncInFlight ??= _performSync(requestTimeout).whenComplete(() {
      _syncInFlight = null;
    });

    final inFlight = _syncInFlight!;
    if (totalTimeout == null) return inFlight;

    return inFlight.timeout(
      totalTimeout,
      onTimeout: () => CatalogSyncResult(
        succeeded: false,
        timedOut: true,
        usedCache: hasAnyCatalog,
      ),
    );
  }

  Future<CatalogSyncResult> _performSync(Duration requestTimeout) async {
    final userId = resolveUserId();
    if (_cachedUserId != null &&
        _cachedUserId!.isNotEmpty &&
        userId.isNotEmpty &&
        _cachedUserId != userId) {
      _clearInMemory();
    }
    if (userId.isNotEmpty) {
      _cachedUserId = userId;
    }

    // Refresh expired/expiring access token before firing parallel requests.
    await AuthSession.refreshIfDue();

    late ApiCallResponse clientsResp;
    late ApiCallResponse projectsResp;

    await Future.wait([
      (() async {
        clientsResp = await GetClientsCall.call(
          token: currentAuthenticationToken,
          timeout: requestTimeout,
        );
      })(),
      (() async {
        projectsResp = await GetProjectsCall.call(
          token: currentAuthenticationToken,
          userid: userId,
          timeout: requestTimeout,
        );
      })(),
    ]);

    var anyFailed = false;

    if (clientsResp.succeeded && clientsResp.jsonBody is List) {
      _clients = _parseClients(clientsResp.jsonBody);
    } else if (!clientsResp.succeeded) {
      anyFailed = true;
    }

    final projectsSucceeded =
        projectsResp.succeeded && projectsResp.jsonBody is List;
    if (projectsSucceeded) {
      _projects = _parseProjects(projectsResp.jsonBody);
    } else if (!projectsResp.succeeded) {
      anyFailed = true;
    }

    // Apply client/project updates immediately (preserving prior cache on failure).
    _applyToAppState();

    // If both endpoints failed with network/transient errors, avoid firing N
    // per-project task requests while offline.
    final bothNetworkDown = isTransientApiFailure(clientsResp) &&
        isTransientApiFailure(projectsResp);

    if (!bothNetworkDown && _projects.isNotEmpty) {
      final projectIds = _projects
          .map((p) => p.id)
          .where((id) => id.isNotEmpty)
          .toList();

      for (var i = 0; i < projectIds.length; i += _taskBatchSize) {
        final batch = projectIds.skip(i).take(_taskBatchSize);
        await Future.wait(batch.map((projectId) async {
          final resp = await GetAtivitiesByProjectCall.call(
            token: currentAuthenticationToken,
            id: projectId,
            timeout: requestTimeout,
          );
          if (resp.succeeded) {
            _tasksByProject[projectId] = _normalizeListOfMaps(resp.jsonBody);
          } else {
            anyFailed = true;
          }
        }));
      }

      if (projectsSucceeded) {
        final validIds = projectIds.toSet();
        _tasksByProject.removeWhere((key, _) => !validIds.contains(key));
      }
    } else if (projectsSucceeded && _projects.isEmpty) {
      _tasksByProject.clear();
    }

    _lastSyncFailed = anyFailed;
    _projectsSyncFailed = !projectsSucceeded;
    if (!anyFailed) {
      _lastSyncSuccessAt = DateTime.now();
    }

    FFAppState().notifyListeners();
    notifyListeners();
    unawaited(_persistCatalog());

    return CatalogSyncResult(
      succeeded: !anyFailed,
      usedCache: hasAnyCatalog,
    );
  }

  /// Fallback single-project task fetch when a project has no cached tasks yet.
  /// Preserves existing cached tasks if the network call fails.
  Future<bool> refreshProjectTasks(
    String projectId, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (projectId.isEmpty) return false;
    await AuthSession.refreshIfDue();
    final resp = await GetAtivitiesByProjectCall.call(
      token: currentAuthenticationToken,
      id: projectId,
      timeout: timeout,
    );
    if (!resp.succeeded) {
      _lastSyncFailed = true;
      notifyListeners();
      return false;
    }
    _tasksByProject[projectId] = _normalizeListOfMaps(resp.jsonBody);
    notifyListeners();
    unawaited(_persistCatalog());
    return true;
  }

  /// Saves the manual time-request workspace (`projects`, `tasks`, `is_admin`, `user_id`).
  Future<void> saveTimeRequestWorkspace(Map<String, dynamic> workspace) async {
    final userId = resolveUserId();
    _timeRequestWorkspaceUserId = userId;
    _timeRequestWorkspace = Map<String, dynamic>.from(workspace);

    final storage = SecureStorageService.instance;
    if (storage.isInitialized) {
      unawaited(storage.setJson(_kTimeWorkspaceKey, {
        'user_id': userId,
        'workspace': _timeRequestWorkspace,
      }));
    }
  }

  /// Returns cached manual time-request workspace for the current user, if any.
  Map<String, dynamic>? cachedTimeRequestWorkspace() {
    final userId = resolveUserId();
    if (_timeRequestWorkspace != null) {
      final savedId = _timeRequestWorkspaceUserId ?? '';
      if (userId.isEmpty || savedId.isEmpty || savedId == userId) {
        return Map<String, dynamic>.from(_timeRequestWorkspace!);
      }
    }
    return null;
  }

  void _clearInMemory() {
    _cachedUserId = null;
    _clients = [];
    _projects = [];
    _tasksByProject = {};
    _lastSyncSuccessAt = null;
    _lastSyncFailed = false;
    _projectsSyncFailed = false;
    _timeRequestWorkspace = null;
    _timeRequestWorkspaceUserId = null;
  }

  /// Clears cached catalog data on logout so another account never inherits it.
  Future<void> clear() async {
    _clearInMemory();
    FFAppState().clientsOptions = [];
    FFAppState().projectOptions = [];
    FFAppState().taskOptions = [];

    final storage = SecureStorageService.instance;
    if (storage.isInitialized) {
      await storage.remove(_kCatalogKey);
      await storage.remove(_kTimeWorkspaceKey);
    }
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    _syncInFlight = null;
    _clearInMemory();
  }
}
