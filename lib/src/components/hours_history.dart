import 'package:flutter/material.dart';
import 'dart:async';
import '../services/hours_service.dart';
import '../models/hours_entry.dart';
import '../models/hours_entry_adapter.dart';
import '../components/log_display.dart';
import '../components/hours_entry.dart';

class HoursHistory extends StatefulWidget {
  final String organizationId;

  const HoursHistory({
    super.key,
    required this.organizationId,
  });

  @override
  State<HoursHistory> createState() => _HoursHistoryState();
}

class _HoursHistoryState extends State<HoursHistory> {
  final _hoursService = HoursService();
  List<HoursEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void didUpdateWidget(HoursHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      _loadEntries();
    }
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _hoursService.getHoursEntries(widget.organizationId);
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      // AppLogger.error('Error loading hours entries', e); // Assuming AppLogger is defined elsewhere
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LogDisplay<HoursEntryAdapter>(
      entries: _entries.map((entry) => HoursEntryAdapter(entry, hasEditPermission: true, hasDeletePermission: true)).toList(),
      emptyMessage: 'No hours entries found',
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onEdit: (adapter) async {
        final updated = await showDialog<HoursEntry>(
          context: context,
          builder: (context) => HoursEntryForm(
            organizationId: widget.organizationId,
          ),
        );
        if (updated != null) _loadEntries();
      },
      onDelete: (adapter) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Entry'),
            content: const Text('Are you sure you want to delete this entry?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        );
        if (confirm == true) {
          await _hoursService.deleteHoursEntry(
            widget.organizationId,
            adapter.entry.id,
          );
          _loadEntries();
        }
      },
    );
  }
} 