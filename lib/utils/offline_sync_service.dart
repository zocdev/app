import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '/auth/auth_session.dart';
import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/utils/catalog_cache_service.dart';
import '/utils/secure_storage_service.dart';

enum SubmitEntryOutcome {
  sent,
  queued,
  forbidden,
  rejected,
}

class SubmitEntryResult {
  const SubmitEntryResult(this.outcome, {this.errorMessage});

  final SubmitEntryOutcome outcome;
  final String? errorMessage;

  bool get handled =>
      outcome == SubmitEntryOutcome.sent ||
      outcome == SubmitEntryOutcome.queued ||
      outcome == SubmitEntryOutcome.forbidden;
}

class SubmitTimeRequestResult {
  const SubmitTimeRequestResult(
    this.outcome, {
    this.autoApproved = false,
    this.errorMessage,
  });

  final SubmitEntryOutcome outcome;
  final bool autoApproved;
  final String? errorMessage;
}

@immutable
class PendingTimeEntry {
  const PendingTimeEntry({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.tasks,
    required this.remote,
    required this.ignoredPopup,
    required this.notes,
    required this.createdAt,
    this.screenshot,
    this.attempts = 0,
    required this.queuedAtIso,
    this.lastError,
  });

  final String id;
  final String userId;
  final String projectId;
  final List<String> tasks;
  final bool remote;
  final bool ignoredPopup;
  final String notes;
  final String createdAt;
  final String? screenshot;
  final int attempts;
  final String queuedAtIso;
  final String? lastError;

  PendingTimeEntry withRetry({required int attempts, String? lastError}) =>
      PendingTimeEntry(
        id: id,
        userId: userId,
        projectId: projectId,
        tasks: tasks,
        remote: remote,
        ignoredPopup: ignoredPopup,
        notes: notes,
        createdAt: createdAt,
        screenshot: screenshot,
        attempts: attempts,
        queuedAtIso: queuedAtIso,
        lastError: lastError,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'project_id': projectId,
        'tasks': tasks,
        'remote': remote,
        'ignored_popup': ignoredPopup,
        'notes': notes,
        'created_at': createdAt,
        'screenshot': screenshot,
        'attempts': attempts,
        'queued_at': queuedAtIso,
        'last_error': lastError,
      };

  static PendingTimeEntry? tryFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final id = raw['id']?.toString() ?? '';
    final createdAt = raw['created_at']?.toString() ?? '';
    if (id.isEmpty || createdAt.isEmpty) return null;
    final rawTasks = raw['tasks'];
    final tasks = rawTasks is List
        ? rawTasks.map((e) => e.toString()).toList()
        : <String>[];
    return PendingTimeEntry(
      id: id,
      userId: raw['user_id']?.toString() ?? '',
      projectId: raw['project_id']?.toString() ?? '',
      tasks: tasks,
      remote: raw['remote'] == true,
      ignoredPopup: raw['ignored_popup'] == true,
      notes: raw['notes']?.toString() ?? '',
      createdAt: createdAt,
      screenshot: raw['screenshot'] as String?,
      attempts: (raw['attempts'] is num) ? (raw['attempts'] as num).toInt() : 0,
      queuedAtIso: raw['queued_at']?.toString() ?? createdAt,
      lastError: raw['last_error'] as String?,
    );
  }
}

@immutable
class PendingTimeRequest {
  const PendingTimeRequest({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.taskId,
    required this.startedAt,
    required this.endedAt,
    required this.reason,
    required this.remote,
    this.attempts = 0,
    required this.queuedAtIso,
    this.lastError,
  });

  final String id;
  final String userId;
  final String projectId;
  final String taskId;
  final DateTime startedAt;
  final DateTime endedAt;
  final String reason;
  final bool remote;
  final int attempts;
  final String queuedAtIso;
  final String? lastError;

  PendingTimeRequest withRetry({required int attempts, String? lastError}) =>
      PendingTimeRequest(
        id: id,
        userId: userId,
        projectId: projectId,
        taskId: taskId,
        startedAt: startedAt,
        endedAt: endedAt,
        reason: reason,
        remote: remote,
        attempts: attempts,
        queuedAtIso: queuedAtIso,
        lastError: lastError,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'project_id': projectId,
        'task_id': taskId,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt.toUtc().toIso8601String(),
        'reason': reason,
        'remote': remote,
        'attempts': attempts,
        'queued_at': queuedAtIso,
        'last_error': lastError,
      };

  static PendingTimeRequest? tryFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final id = raw['id']?.toString() ?? '';
    final started = DateTime.tryParse('${raw['started_at']}');
    final ended = DateTime.tryParse('${raw['ended_at']}');
    if (id.isEmpty || started == null || ended == null) return null;
    return PendingTimeRequest(
      id: id,
      userId: raw['user_id']?.toString() ?? '',
      projectId: raw['project_id']?.toString() ?? '',
      taskId: raw['task_id']?.toString() ?? '',
      startedAt: started,
      endedAt: ended,
      reason: raw['reason']?.toString() ?? '',
      remote: raw['remote'] == true,
      attempts: (raw['attempts'] is num) ? (raw['attempts'] as num).toInt() : 0,
      queuedAtIso:
          raw['queued_at']?.toString() ?? started.toUtc().toIso8601String(),
      lastError: raw['last_error'] as String?,
    );
  }
}

/// Queues time entries & manual time requests locally when offline/unstable
/// and flushes them in chronological FIFO order once connectivity returns.
class OfflineSyncService extends ChangeNotifier {
  OfflineSyncService._();

  static OfflineSyncService instance = OfflineSyncService._();

  static const String _kEntriesKey = 'ff_pending_time_entries_v1';
  static const String _kRequestsKey = 'ff_pending_time_requests_v1';

  final List<PendingTimeEntry> _entries = [];
  final List<PendingTimeRequest> _requests = [];
  int _seq = 0;
  Future<int>? _flushInFlight;
  DateTime? _lastSyncAt;
  String? _lastError;

  bool get isSyncing => _flushInFlight != null;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get lastError => _lastError;

  static bool _belongsToUser(String itemUserId, String currentUserId) {
    if (currentUserId.isEmpty || itemUserId.isEmpty) return true;
    return itemUserId == currentUserId;
  }

  List<PendingTimeEntry> get pendingEntries {
    final userId = CatalogCacheService.resolveUserId();
    return _entries
        .where((e) => _belongsToUser(e.userId, userId))
        .toList(growable: false);
  }

  List<PendingTimeRequest> get pendingRequests {
    final userId = CatalogCacheService.resolveUserId();
    return _requests
        .where((r) => _belongsToUser(r.userId, userId))
        .toList(growable: false);
  }

  int get pendingCount => pendingEntries.length + pendingRequests.length;

  String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-${++_seq}';

  void restoreFromCache() {
    final storage = SecureStorageService.instance;
    if (!storage.isInitialized) return;

    _entries.clear();
    final rawEntries = storage.getString(_kEntriesKey);
    if (rawEntries != null && rawEntries.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawEntries);
        if (decoded is List) {
          for (final item in decoded) {
            final parsed = PendingTimeEntry.tryFromJson(item);
            if (parsed != null) _entries.add(parsed);
          }
        }
      } catch (_) {}
    }

    _requests.clear();
    final rawRequests = storage.getString(_kRequestsKey);
    if (rawRequests != null && rawRequests.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawRequests);
        if (decoded is List) {
          for (final item in decoded) {
            final parsed = PendingTimeRequest.tryFromJson(item);
            if (parsed != null) _requests.add(parsed);
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _persistEntries() async {
    final storage = SecureStorageService.instance;
    if (!storage.isInitialized) return;
    if (_entries.isEmpty) {
      await storage.remove(_kEntriesKey);
    } else {
      await storage.setString(
        _kEntriesKey,
        jsonEncode(_entries.map((e) => e.toJson()).toList()),
      );
    }
  }

  Future<void> _persistRequests() async {
    final storage = SecureStorageService.instance;
    if (!storage.isInitialized) return;
    if (_requests.isEmpty) {
      await storage.remove(_kRequestsKey);
    } else {
      await storage.setString(
        _kRequestsKey,
        jsonEncode(_requests.map((r) => r.toJson()).toList()),
      );
    }
  }

  static String? _extractApiMessage(ApiCallResponse response) {
    final body = response.jsonBody;
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    return null;
  }

  /// Sends a popup entry immediately, or stores it locally if offline/unstable.
  /// If older entries are already queued, appends to preserve FIFO order and flushes.
  Future<SubmitEntryResult> submitOrQueuePopupEntry({
    required String project,
    required bool remote,
    required bool ignoredPopUp,
    List<String>? tasksList,
    String notes = '',
    String? createdAt,
    String? screenshot,
    Duration requestTimeout = const Duration(seconds: 12),
  }) async {
    final userId = CatalogCacheService.resolveUserId();
    final effectiveCreatedAt = createdAt ??
        functions.timeNowTZ() ??
        DateTime.now().toUtc().toIso8601String();
    final entry = PendingTimeEntry(
      id: _nextId(),
      userId: userId,
      projectId: project,
      tasks: List<String>.from(tasksList ?? const []),
      remote: remote,
      ignoredPopup: ignoredPopUp,
      notes: notes,
      createdAt: effectiveCreatedAt,
      screenshot: screenshot,
      queuedAtIso: DateTime.now().toUtc().toIso8601String(),
    );

    // Keep chronological FIFO order when older entries are still pending.
    if (_entries.any((e) => _belongsToUser(e.userId, userId))) {
      _entries.add(entry);
      unawaited(_persistEntries());
      notifyListeners();
      await flush(requestTimeout: requestTimeout);
      final stillPending = _entries.any((e) => e.id == entry.id);
      return SubmitEntryResult(
        stillPending ? SubmitEntryOutcome.queued : SubmitEntryOutcome.sent,
      );
    }

    await AuthSession.refreshIfDue();
    final response = await AddAtivitiesCall.call(
      token: currentAuthenticationToken,
      project: entry.projectId,
      remote: entry.remote,
      ignoredPopUp: entry.ignoredPopup,
      tasksList: entry.tasks,
      notes: entry.notes,
      createdAt: entry.createdAt,
      screenshot: entry.screenshot,
      timeout: requestTimeout,
    );

    if (response.succeeded) {
      return const SubmitEntryResult(SubmitEntryOutcome.sent);
    }
    if (response.statusCode == 403) {
      return const SubmitEntryResult(SubmitEntryOutcome.forbidden);
    }
    if (!isTransientApiFailure(response)) {
      return SubmitEntryResult(
        SubmitEntryOutcome.rejected,
        errorMessage: _extractApiMessage(response),
      );
    }

    _entries.add(entry);
    _lastError = _extractApiMessage(response) ?? 'Sem conexão';
    unawaited(_persistEntries());
    notifyListeners();
    return const SubmitEntryResult(SubmitEntryOutcome.queued);
  }

  /// Sends a manual time request immediately, or stores it locally if offline/unstable.
  Future<SubmitTimeRequestResult> submitOrQueueTimeRequest({
    required String userId,
    required String projectId,
    required String taskId,
    required DateTime startedAt,
    required DateTime endedAt,
    required String reason,
    required bool remote,
    Duration requestTimeout = const Duration(seconds: 12),
  }) async {
    final req = PendingTimeRequest(
      id: _nextId(),
      userId: userId,
      projectId: projectId,
      taskId: taskId,
      startedAt: startedAt,
      endedAt: endedAt,
      reason: reason,
      remote: remote,
      queuedAtIso: DateTime.now().toUtc().toIso8601String(),
    );

    if (_requests.any((r) => _belongsToUser(r.userId, userId))) {
      _requests.add(req);
      await _persistRequests();
      notifyListeners();
      await flush(requestTimeout: requestTimeout);
      final stillPending = _requests.any((r) => r.id == req.id);
      return SubmitTimeRequestResult(
        stillPending ? SubmitEntryOutcome.queued : SubmitEntryOutcome.sent,
      );
    }

    await AuthSession.refreshIfDue();
    final response = await SubmitTimeRequestCall.call(
      token: currentAuthenticationToken,
      userId: userId,
      projectId: projectId,
      taskId: taskId,
      startedAt: startedAt,
      endedAt: endedAt,
      reason: reason,
      remote: remote,
      timeout: requestTimeout,
    );

    if (response.succeeded) {
      final body = response.jsonBody;
      return SubmitTimeRequestResult(
        SubmitEntryOutcome.sent,
        autoApproved: body is Map && body['auto_approved'] == true,
      );
    }
    if (response.statusCode == 403) {
      return SubmitTimeRequestResult(
        SubmitEntryOutcome.forbidden,
        errorMessage: _extractApiMessage(response),
      );
    }
    if (!isTransientApiFailure(response)) {
      return SubmitTimeRequestResult(
        SubmitEntryOutcome.rejected,
        errorMessage: _extractApiMessage(response),
      );
    }

    _requests.add(req);
    _lastError = _extractApiMessage(response) ?? 'Sem conexão';
    await _persistRequests();
    notifyListeners();
    return const SubmitTimeRequestResult(SubmitEntryOutcome.queued);
  }

  /// Flushes all pending entries/requests for the current user in FIFO order.
  /// Returns the number of items synced during this run.
  Future<int> flush({
    Duration requestTimeout = const Duration(seconds: 12),
    Duration? totalTimeout,
  }) {
    if (pendingCount == 0) return Future.value(0);

    _flushInFlight ??= _performFlush(requestTimeout).whenComplete(() {
      _flushInFlight = null;
      notifyListeners();
    });
    notifyListeners();

    final inFlight = _flushInFlight!;
    if (totalTimeout == null) return inFlight;
    return inFlight.timeout(totalTimeout, onTimeout: () => 0);
  }

  Future<int> _performFlush(Duration requestTimeout) async {
    final userId = CatalogCacheService.resolveUserId();
    if (pendingCount == 0) return 0;

    final refreshOutcome = await AuthSession.refreshIfDue();
    if (refreshOutcome == RefreshOutcome.rejected) {
      return 0;
    }

    var synced = 0;

    // 1. Flush popup time entries FIFO.
    while (true) {
      final idx =
          _entries.indexWhere((e) => _belongsToUser(e.userId, userId));
      if (idx == -1) break;
      final item = _entries[idx];

      final resp = await AddAtivitiesCall.call(
        token: currentAuthenticationToken,
        project: item.projectId,
        remote: item.remote,
        ignoredPopUp: item.ignoredPopup,
        tasksList: item.tasks,
        notes: item.notes,
        createdAt: item.createdAt,
        screenshot: item.screenshot,
        timeout: requestTimeout,
      );

      if (resp.succeeded) {
        _entries.removeAt(idx);
        synced++;
        _lastSyncAt = DateTime.now();
        _lastError = null;
        await _persistEntries();
        notifyListeners();
        continue;
      }

      if (resp.statusCode == 403) {
        // Time tracking disabled by admin: discard to prevent infinite retries.
        _entries.removeAt(idx);
        await _persistEntries();
        notifyListeners();
        break;
      }

      if (!isTransientApiFailure(resp)) {
        // Permanent 4xx payload rejection: remove so later valid items can flush.
        _entries.removeAt(idx);
        _lastError = _extractApiMessage(resp);
        await _persistEntries();
        notifyListeners();
        continue;
      }

      _lastError = _extractApiMessage(resp) ?? 'Sem conexão';
      _entries[idx] = item.withRetry(
        attempts: item.attempts + 1,
        lastError: _lastError,
      );
      await _persistEntries();
      notifyListeners();
      break;
    }

    // 2. Flush manual time requests FIFO.
    while (true) {
      final idx =
          _requests.indexWhere((r) => _belongsToUser(r.userId, userId));
      if (idx == -1) break;
      final item = _requests[idx];

      final resp = await SubmitTimeRequestCall.call(
        token: currentAuthenticationToken,
        userId: item.userId,
        projectId: item.projectId,
        taskId: item.taskId,
        startedAt: item.startedAt,
        endedAt: item.endedAt,
        reason: item.reason,
        remote: item.remote,
        timeout: requestTimeout,
      );

      if (resp.succeeded) {
        _requests.removeAt(idx);
        synced++;
        _lastSyncAt = DateTime.now();
        _lastError = null;
        await _persistRequests();
        notifyListeners();
        continue;
      }

      if (resp.statusCode == 403) {
        _requests.removeAt(idx);
        await _persistRequests();
        notifyListeners();
        break;
      }

      if (!isTransientApiFailure(resp)) {
        _requests.removeAt(idx);
        _lastError = _extractApiMessage(resp);
        await _persistRequests();
        notifyListeners();
        continue;
      }

      _lastError = _extractApiMessage(resp) ?? 'Sem conexão';
      _requests[idx] = item.withRetry(
        attempts: item.attempts + 1,
        lastError: _lastError,
      );
      await _persistRequests();
      notifyListeners();
      break;
    }

    return synced;
  }

  @visibleForTesting
  void resetForTest() {
    _flushInFlight = null;
    _entries.clear();
    _requests.clear();
    _seq = 0;
    _lastSyncAt = null;
    _lastError = null;
  }
}
