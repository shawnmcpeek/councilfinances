import 'package:flutter/material.dart';
import 'dart:async';
import '../services/hours_service.dart';
import '../models/hours_entry.dart';
import '../models/hours_entry_adapter.dart';
import '../components/log_display.dart';
import 'hours_entry_edit_dialog.dart';

class HoursHistoryList extends StatefulWidget {
  final String organizationId;
  final bool isAssembly;

  const HoursHistoryList({
    super.key,
    required this.organizationId,
    required this.isAssembly,
  });

  @override
  State<HoursHistoryList> createState() => _HoursHistoryListState();
}

class _HoursHistoryListState extends State<HoursHistoryList> {
  final _hoursService = HoursService();
  StreamSubscription<List<HoursEntry>>? _subscription;
  List<HoursEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeToEntries();
  }

  @override
  void didUpdateWidget(HoursHistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId ||
        oldWidget.isAssembly != widget.isAssembly) {
      _subscribeToEntries();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToEntries() {
    _subscription?.cancel();
    
    if (widget.organizationId.isEmpty) {
      setState(() {
        _entries = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      _subscription = _hoursService
          .getHoursEntries(widget.organizationId, widget.isAssembly)
          .listen(
        (entries) {
          if (mounted) {
            setState(() {
              _entries = entries;
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading hours: $error')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading hours: $e')),
        );
      }
    }
  }

  Future<void> _refreshEntries() async {
    _subscribeToEntries();
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
      onRefresh: _refreshEntries,
      onEdit: (adapter) async {
        await showDialog(
          context: context,
          builder: (context) => HoursEntryEditDialog(
            entry: adapter.entry,
            organizationId: widget.organizationId,
            isAssembly: widget.isAssembly,
            onSuccess: _subscribeToEntries,
          ),
        );
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
            widget.isAssembly,
          );
          _subscribeToEntries();
        }
      },
    );
  }
} 