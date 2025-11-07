import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../event_detail/event_detail_screen.dart';

class ExploreMockupScreen extends StatefulWidget {
  const ExploreMockupScreen({super.key});

  @override
  State<ExploreMockupScreen> createState() => _ExploreMockupScreenState();
}

class _ExploreMockupScreenState extends State<ExploreMockupScreen> {
  EventCategory? _selectedCategory;
  bool _showFreeOnly = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<EventsBloc>().add(LoadEvents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '🔍 Explore',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: BlocBuilder<EventsBloc, EventsState>(
              builder: (context, state) {
                if (state is EventsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is EventsLoaded) {
                  final filteredEvents = _filterEvents(state.events);

                  if (filteredEvents.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildEventsList(filteredEvents);
                } else if (state is EventsError) {
                  return Center(
                    child: Text('Error: ${state.message}'),
                  );
                }
                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search events...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All', null),
                const SizedBox(width: 8),
                ...EventCategory.values.map((category) =>
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(_getCategoryName(category), category),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('Free Events'),
                selected: _showFreeOnly,
                onSelected: (selected) {
                  setState(() {
                    _showFreeOnly = selected;
                  });
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.black,
                labelStyle: TextStyle(
                  color: _showFreeOnly ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, EventCategory? category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  List<Event> _filterEvents(List<Event> events) {
    return events.where((event) {
      final matchesSearch = _searchQuery.isEmpty ||
          event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == null || event.category == _selectedCategory;

      final matchesFree = !_showFreeOnly || event.isFree;

      return matchesSearch && matchesCategory && matchesFree;
    }).toList();
  }

  Widget _buildEventsList(List<Event> events) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  event.imageUrls.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 50),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getCategoryName(event.category),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (event.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (!event.isFree && event.price != null)
                        Text(
                          '\$${event.price!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(event.startTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${event.currentAttendees}/${event.maxAttendees} going',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(EventCategory category) {
    switch (category) {
      case EventCategory.meetup:
        return 'Meetup';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.networking:
        return 'Networking';
      case EventCategory.food:
        return 'Food';
      case EventCategory.creative:
        return 'Creative';
      case EventCategory.outdoor:
        return 'Outdoor';
      case EventCategory.fitness:
        return 'Fitness';
      case EventCategory.learning:
        return 'Learning';
      case EventCategory.social:
        return 'Social';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else {
      return 'Starting soon';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}