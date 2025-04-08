import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/hours_service.dart';
import '../models/hours_entry.dart';
import '../theme/app_theme.dart';
import 'dart:async';

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
  final _dateFormat = DateFormat('M/d/yyyy');
  final _timeFormat = DateFormat('h:mm a');
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entries.isEmpty) {
      return const Center(child: Text('No hours entries found'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final startDate = entry.startTime.toDate();
        final endDate = entry.endTime.toDate();
        
        final sameDay = startDate.year == endDate.year && 
                       startDate.month == endDate.month && 
                       startDate.day == endDate.day;
        
        final timeRange = sameDay
            ? '${_dateFormat.format(startDate)} ${_timeFormat.format(startDate)} - ${_timeFormat.format(endDate)}'
            : '${_dateFormat.format(startDate)} ${_timeFormat.format(startDate)} - ${_dateFormat.format(endDate)} ${_timeFormat.format(endDate)}';

        return Card(
          margin: EdgeInsets.only(bottom: AppTheme.spacing),
          child: ListTile(
            title: Text(entry.programName),
            subtitle: Text(
              '$timeRange\n${entry.totalHours} hours',
            ),
          ),
        );
      },
    );
  }
} 