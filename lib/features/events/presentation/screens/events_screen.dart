import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/events_providers.dart';
import '../widgets/event_card.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  List<int> _manualOrder = [];
  bool _manualOrderLoaded = false;
  @override
  void initState() {
    super.initState();
    _loadManualOrder();
  }

  Future<void> _loadManualOrder() async {
    debugPrint('📥 Loading manual order...');

    final order = await ref.read(eventOrderStorageProvider).getOrder();

    debugPrint('📥 Loaded manual order = $order');

    if (!mounted) return;

    setState(() {
      _manualOrder = order;
      _manualOrderLoaded = true;
    });

    debugPrint('✅ Manual order ready = $_manualOrder');
  }

  bool _showCompleted = false;

  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'High',
    'Quiz',
    'Assignment',
    'Exam',
  ];
  List<T> _applyManualOrder<T>(List<T> events, int Function(T) getId) {
    debugPrint(
      '🔀 APPLY ORDER | manualOrder=$_manualOrder | '
      'eventIds=${events.map(getId).toList()}',
    );

    final manualIndex = <int, int>{
      for (var i = 0; i < _manualOrder.length; i++) _manualOrder[i]: i,
    };

    final ordered = List<T>.from(events);

    ordered.sort((a, b) {
      final aId = getId(a);
      final bId = getId(b);

      final aIndex = manualIndex[aId];
      final bIndex = manualIndex[bId];

      if (aIndex != null && bIndex != null) {
        return aIndex.compareTo(bIndex);
      }

      if (aIndex != null) {
        return -1;
      }

      if (bIndex != null) {
        return 1;
      }

      return 0;
    });

    debugPrint('🔀 APPLY RESULT = ${ordered.map(getId).toList()}');

    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(allEventsProvider);

    return Scaffold(
      body: SafeArea(
        child: eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Unable to load events')),
          data: (events) {
            final filtered = _filterEvents(events);

            final groups = _groupEvents(filtered);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),

                if (groups.isEmpty)
                  const SliverFillRemaining(child: _EmptyEvents())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final group = groups[index];

                        return _EventGroup(
                          title: group.title,
                          events: group.events,
                          onCompletedChanged: _markCompleted,
                          onManualReorder: _manualOrderLoaded
                              ? _handleManualReorder
                              : null,
                        );
                      }, childCount: groups.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/events/create');
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Event'),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Events',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Stay ahead of what matters.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Filters',
                onPressed: _showFilterSheet,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildFilterBar(),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = filter == _selectedFilter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          );
        },
      ),
    );
  }

  List<_EventGroup> _groupEvents(List events) {
    final overdue = <dynamic>[];
    final today = <dynamic>[];
    final tomorrow = <dynamic>[];
    final thisWeek = <dynamic>[];
    final later = <dynamic>[];

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final tomorrowDate = todayDate.add(const Duration(days: 1));
    final weekEnd = todayDate.add(const Duration(days: 7));

    for (final event in events) {
      if (event.isCompleted && !_showCompleted) {
        continue;
      }

      final eventDate = DateTime(
        event.dueDate.year,
        event.dueDate.month,
        event.dueDate.day,
      );

      if (!event.isCompleted && eventDate.isBefore(todayDate)) {
        overdue.add(event);
      } else if (eventDate == todayDate) {
        today.add(event);
      } else if (eventDate == tomorrowDate) {
        tomorrow.add(event);
      } else if (eventDate.isBefore(weekEnd)) {
        thisWeek.add(event);
      } else {
        later.add(event);
      }
    }

    return [
      if (overdue.isNotEmpty)
        _EventGroup(
          title: 'Overdue',
          events: _applyManualOrder(overdue, (e) => e.id),
          onCompletedChanged: _markCompleted,
          onManualReorder: _handleManualReorder,
        ),

      if (today.isNotEmpty)
        _EventGroup(
          title: 'Today',
          events: _applyManualOrder(today, (e) => e.id),
          onCompletedChanged: _markCompleted,
          onManualReorder: _handleManualReorder,
        ),

      if (tomorrow.isNotEmpty)
        _EventGroup(
          title: 'Tomorrow',
          events: _applyManualOrder(tomorrow, (e) => e.id),
          onCompletedChanged: _markCompleted,
          onManualReorder: _handleManualReorder,
        ),

      if (thisWeek.isNotEmpty)
        _EventGroup(
          title: 'This Week',
          events: _applyManualOrder(thisWeek, (e) => e.id),
          onCompletedChanged: _markCompleted,
          onManualReorder: _handleManualReorder,
        ),

      if (later.isNotEmpty)
        _EventGroup(
          title: 'Later',
          events: _applyManualOrder(later, (e) => e.id),
          onCompletedChanged: _markCompleted,
          onManualReorder: _handleManualReorder,
        ),
    ];
  }

  Future<void> _handleManualReorder(List<dynamic> reorderedGroup) async {
    debugPrint('');
    debugPrint('══════════════════════════════════════');
    debugPrint('🚨 REORDER STARTED');

    final reorderedIds = reorderedGroup
        .map<int>((event) => event.id as int)
        .toList();

    debugPrint('🚨 Reordered group IDs = $reorderedIds');
    debugPrint('🚨 Old manual order     = $_manualOrder');

    final newOrder = <int>[];

    // Add the newly reordered group first.
    newOrder.addAll(reorderedIds);

    // Keep all other existing IDs.
    for (final id in _manualOrder) {
      if (!reorderedIds.contains(id)) {
        newOrder.add(id);
      }
    }

    debugPrint('💾 NEW ORDER TO SAVE = $newOrder');

    // Update UI FIRST.
    setState(() {
      _manualOrder = newOrder;
    });

    debugPrint('🖥️ UI STATE UPDATED = $_manualOrder');

    // Save to storage.
    try {
      await ref.read(eventOrderStorageProvider).saveOrder(newOrder);

      debugPrint('✅ STORAGE SAVE SUCCESS');
    } catch (e, stack) {
      debugPrint('❌ STORAGE SAVE FAILED: $e');
      debugPrint('$stack');
    }

    // Read it back immediately to verify.
    try {
      final verifyOrder = await ref.read(eventOrderStorageProvider).getOrder();

      debugPrint('🔍 STORAGE VERIFY = $verifyOrder');

      if (verifyOrder.toString() != newOrder.toString()) {
        debugPrint('❌❌❌ STORAGE DID NOT SAVE CORRECTLY');
        debugPrint('Expected = $newOrder');
        debugPrint('Actual   = $verifyOrder');
      } else {
        debugPrint('✅ STORAGE VERIFIED CORRECTLY');
      }
    } catch (e) {
      debugPrint('❌ STORAGE VERIFY FAILED: $e');
    }

    ref.invalidate(manualEventOrderProvider);

    debugPrint('🚨 REORDER FINISHED');
    debugPrint('══════════════════════════════════════');
    debugPrint('');
  }

  List _filterEvents(List events) {
    return events.where((event) {
      if (!_showCompleted && event.isCompleted) {
        return false;
      }

      switch (_selectedFilter) {
        case 'High':
          return event.priority.toLowerCase() == 'high';

        case 'Quiz':
          return event.type.toLowerCase() == 'quiz';

        case 'Assignment':
          return event.type.toLowerCase() == 'assignment';

        case 'Exam':
          return event.type.toLowerCase() == 'exam';

        default:
          return true;
      }
    }).toList();
  }

  Future<void> _markCompleted(dynamic event, bool completed) async {
    await ref.read(eventsRepositoryProvider).markCompleted(event.id, completed);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event view',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 20),

                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show completed'),
                    subtitle: const Text('Include finished events'),
                    value: _showCompleted,
                    onChanged: (value) {
                      setState(() {
                        _showCompleted = value;
                      });

                      setSheetState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EventGroup extends StatelessWidget {
  final String title;
  final List events;
  final Future<void> Function(dynamic, bool)? onCompletedChanged;
  final Future<void> Function(List<dynamic>)? onManualReorder;

  const _EventGroup({
    required this.title,
    required this.events,
    this.onCompletedChanged,
    this.onManualReorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${events.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              debugPrint('');
              debugPrint('🟡 FLUTTER REORDER CALLBACK');
              debugPrint('🟡 oldIndex = $oldIndex');
              debugPrint('🟡 newIndex = $newIndex');
              debugPrint(
                '🟡 current IDs = ${events.map((e) => e.id).toList()}',
              );

              if (onManualReorder == null) {
                debugPrint('❌ onManualReorder is NULL');
                return;
              }

              final reordered = List<dynamic>.from(events);

              if (newIndex > oldIndex) {
                newIndex -= 1;
              }

              final item = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, item);

              debugPrint(
                '🟢 AFTER DRAG = ${reordered.map((e) => e.id).toList()}',
              );

              onManualReorder!(reordered);
            },
            children: [
              for (final event in events)
                Padding(
                  key: ValueKey('event-${event.id}'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReorderableDragStartListener(
                    index: events.indexOf(event),
                    child: EventCard(
                      event: event,
                      onCompletedChanged: onCompletedChanged == null
                          ? null
                          : (value) => onCompletedChanged!(event, value),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_available_rounded, size: 34),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nothing here',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Your upcoming work will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
