import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/vehicle_log.dart';

/// Manages the list of VehicleLog entries and coordinates DB operations.
class VehicleLogProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<VehicleLog> _allLogs = [];
  List<VehicleLog> _insideLogs = [];
  List<VehicleLog> _searchResults = [];

  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // ─── Getters ────────────────────────────────────────────────────────────────

  List<VehicleLog> get allLogs => _allLogs;
  List<VehicleLog> get insideLogs => _insideLogs;
  List<VehicleLog> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get insideCount => _insideLogs.length;

  /// Returns the active list (search results if query exists, else inside logs).
  List<VehicleLog> get activeDisplayList =>
      _searchQuery.isEmpty ? _insideLogs : _searchResults;

  // ─── Load ────────────────────────────────────────────────────────────────────

  Future<void> loadAllLogs() async {
    _setLoading(true);
    try {
      _allLogs = await _db.getAllLogs();
      _insideLogs = await _db.getInsideLogs();
      _error = null;
    } catch (e) {
      _error = 'Failed to load logs: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ─── Add ─────────────────────────────────────────────────────────────────────

  Future<bool> addLog(VehicleLog log) async {
    try {
      await _db.insertLog(log);
      await loadAllLogs();
      return true;
    } catch (e) {
      _error = 'Failed to save log: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Checkout ────────────────────────────────────────────────────────────────

  Future<bool> checkOutVehicle(String id) async {
    try {
      await _db.checkOutVehicle(id);
      await loadAllLogs();
      return true;
    } catch (e) {
      _error = 'Failed to check out vehicle: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Delete ──────────────────────────────────────────────────────────────────

  Future<bool> deleteLog(String id) async {
    try {
      await _db.deleteLog(id);
      await loadAllLogs();
      return true;
    } catch (e) {
      _error = 'Failed to delete log: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Search ──────────────────────────────────────────────────────────────────

  Future<void> search(String query) async {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _searchResults = await _db.searchLogs(_searchQuery);
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
