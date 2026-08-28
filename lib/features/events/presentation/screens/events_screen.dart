import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/events_providers.dart';
import '../widgets/event_card.dart';
import 'create_event_screen.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() =>
      _EventsScreenState();
}

class _EventsScreenState
    extends ConsumerState<EventsScreen> {
  bool _showCompleted = false;

  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'High',
    'Quiz',
    'Assignment',
    'Exam',
  ];

  @override
  Widget build(BuildContext context) {
    final eventsAsync =
        ref.watch(allEventsProvider);

    return Scaffold(
      body: SafeArea(
        child: eventsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Text(
              'Unable to load events',
            ),
          ),
          data: (events) {
            final filtered =
                _filterEvents(events);

            final groups =
                _groupEvents(filtered);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),

                if (groups.isEmpty)
                  const SliverFillRemaining(
                    child: _EmptyEvents(),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      110,
                    ),
                    sliver: SliverList(
                      delegate:
                          SliverChildBuilderDelegate(
                        (context, index) {
                          final group =
                              groups[index];

                          return _EventGroup(
                            title: group.title,
                            events: group.events,
                            onCompletedChanged:
                                _markCompleted,
                          );
                        },
                        childCount: groups.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          
          context.push(
            '/events/create',
          );
        },
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'New Event',
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        10,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Events',
                      style: theme
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Stay ahead of what matters.',
                      style: theme
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Filters',
                onPressed:
                    _showFilterSheet,
                icon: const Icon(
                  Icons.tune_rounded,
                ),
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
        scrollDirection:
            Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected =
              filter == _selectedFilter;

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

  List<_EventGroup> _groupEvents(
    List events,
  ) {
    final overdue = [];
    final today = [];
    final tomorrow = [];
    final thisWeek = [];
    final later = [];

    final now = DateTime.now();

    final todayDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final tomorrowDate =
        todayDate.add(
      const Duration(days: 1),
    );

    for (final event in events) {
      if (event.isCompleted &&
          !_showCompleted) {
        continue;
      }

      final eventDate = DateTime(
        event.dueDate.year,
        event.dueDate.month,
        event.dueDate.day,
      );

      if (!event.isCompleted &&
          eventDate.isBefore(todayDate)) {
        overdue.add(event);
      } else if (eventDate ==
          todayDate) {
        today.add(event);
      } else if (eventDate ==
          tomorrowDate) {
        tomorrow.add(event);
      } else if (eventDate.isBefore(
        todayDate.add(
          const Duration(days: 7),
        ),
      )) {
        thisWeek.add(event);
      } else {
        later.add(event);
      }
    }

    return [
      if (overdue.isNotEmpty)
        _EventGroup(
          title: 'Overdue',
          events: overdue,
        ),
      if (today.isNotEmpty)
        _EventGroup(
          title: 'Today',
          events: today,
        ),
      if (tomorrow.isNotEmpty)
        _EventGroup(
          title: 'Tomorrow',
          events: tomorrow,
        ),
      if (thisWeek.isNotEmpty)
        _EventGroup(
          title: 'This Week',
          events: thisWeek,
        ),
      if (later.isNotEmpty)
        _EventGroup(
          title: 'Later',
          events: later,
        ),
    ];
  }

  List _filterEvents(List events) {
    return events.where((event) {
      if (!_showCompleted &&
          event.isCompleted) {
        return false;
      }

      switch (_selectedFilter) {
        case 'High':
          return event.priority
                  .toLowerCase() ==
              'high';

        case 'Quiz':
          return event.type
                  .toLowerCase() ==
              'quiz';

        case 'Assignment':
          return event.type
                  .toLowerCase() ==
              'assignment';

        case 'Exam':
          return event.type
                  .toLowerCase() ==
              'exam';

        default:
          return true;
      }
    }).toList();
  }

  Future<void> _markCompleted(
    dynamic event,
    bool completed,
  ) async {
    await ref
        .read(eventsRepositoryProvider)
        .markCompleted(
          event.id,
          completed,
        );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setSheetState) {
            return Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                32,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event view',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SwitchListTile.adaptive(
                    contentPadding:
                        EdgeInsets.zero,
                    title: const Text(
                      'Show completed',
                    ),
                    subtitle: const Text(
                      'Include finished events',
                    ),
                    value: _showCompleted,
                    onChanged: (value) {
                      setState(() {
                        _showCompleted =
                            value;
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
  final Future<void> Function(
    dynamic,
    bool,
  )? onCompletedChanged;

  const _EventGroup({
    required this.title,
    required this.events,
    this.onCompletedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(
              left: 2,
              bottom: 10,
            ),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: theme
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 1.2,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration:
                      BoxDecoration(
                    color: theme
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    '${events.length}',
                    style:
                        const TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ...events.map(
            (event) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: EventCard(
                event: event,
                onCompletedChanged:
                    onCompletedChanged ==
                            null
                        ? null
                        : (value) =>
                            onCompletedChanged!(
                              event,
                              value,
                            ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEvents
    extends StatelessWidget {
  const _EmptyEvents();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration:
                  BoxDecoration(
                color: theme
                    .colorScheme
                    .surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .event_available_rounded,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nothing here',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your upcoming work will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}