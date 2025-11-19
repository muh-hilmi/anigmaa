import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../feed/modern_feed_screen.dart';
import '../discover/swipeable_events_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChanged;

  const HomeScreen({super.key, this.onTabChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (widget.onTabChanged != null) {
        widget.onTabChanged!(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Anigmaa title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  BlocBuilder<UserBloc, UserState>(
                    builder: (context, state) {
                      String initials = 'U';
                      if (state is UserLoaded) {
                        initials = state.user.name.isNotEmpty ? state.user.name[0].toUpperCase() : 'U';
                      }
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFAF8F5),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFFAF8F5),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF84994F),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Anigmaa',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF000000),
                      letterSpacing: -0.8,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFAF8F5),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: Colors.grey[700],
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF84994F),
                indicatorWeight: 3,
                labelColor: const Color(0xFF84994F),
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
                tabs: const [
                  Tab(text: 'Postingan'),
                  Tab(text: 'Event'),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe between tabs
                children: [
                  const ModernFeedScreen(),
                  const SwipeableEventsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
