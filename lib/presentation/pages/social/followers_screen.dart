import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_event.dart';
import '../../bloc/user/user_state.dart';
import 'user_profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final String title;
  final bool isFollowers; // true for followers, false for following

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.title,
    this.isFollowers = true,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<User> _users = [];
  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    if (widget.isFollowers) {
      context.read<UserBloc>().add(LoadFollowersEvent(widget.userId));
    } else {
      context.read<UserBloc>().add(LoadFollowingEvent(widget.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FollowersLoading || state is FollowingLoading) {
            return _buildLoadingState();
          }

          if (state is FollowersLoaded) {
            _users = state.followers;
            _filteredUsers = _searchQuery.isEmpty ? _users : _filteredUsers;
          } else if (state is FollowingLoaded) {
            _users = state.following;
            _filteredUsers = _searchQuery.isEmpty ? _users : _filteredUsers;
          }

          return Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _buildUsersList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari ${widget.isFollowers ? 'followers' : 'following'}...',
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
            _filterUsers();
          });
        },
      ),
    );
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = _users;
    } else {
      _filteredUsers = _users.where((user) {
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.bio.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum ada ${widget.isFollowers ? 'followers' : 'following'} nih'
                  : 'Gak ada user yang ditemukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Yuk mulai connect dengan orang lain!'
                  : 'Coba cari yang lain deh',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_filteredUsers[index]);
      },
    );
  }

  Widget _buildUserCard(User user) {
    // Note: In real implementation, isFollowing status should come from API
    // For now, we assume users in following list are being followed
    final isFollowing = !widget.isFollowers;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: user.avatar != null
                ? NetworkImage(user.avatar!)
                : null,
              child: user.avatar == null
                ? Icon(Icons.person, size: 25, color: Colors.grey[400])
                : null,
            ),
            if (user.isVerified)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: user.bio != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                user.bio!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
        trailing: SizedBox(
          width: 80,
          child: ElevatedButton(
            onPressed: () => _toggleFollow(user, isFollowing),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey[200] : Colors.black,
              foregroundColor: isFollowing ? Colors.black87 : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                userId: user.id,
                userName: user.name,
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleFollow(User user, bool currentlyFollowing) {
    if (currentlyFollowing) {
      // Unfollow user via API
      context.read<UserBloc>().add(UnfollowUserEvent(user.id));
    } else {
      // Follow user via API
      context.read<UserBloc>().add(FollowUserEvent(user.id));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}