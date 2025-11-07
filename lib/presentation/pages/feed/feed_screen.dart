import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/post.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../bloc/posts/posts_state.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../widgets/post_card.dart';
import '../create_post/create_post_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PostsBloc>().add(LoadPosts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Anigmaa',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          if (state is PostsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PostsBloc>().add(LoadPosts());
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is PostsLoaded) {
            // Get current user ID to filter out their posts
            final userState = context.read<UserBloc>().state;
            String? currentUserId;
            if (userState is UserLoaded && userState.user != null) {
              currentUserId = userState.user!.id;
            }

            // Filter out current user's posts (feed should only show others' posts)
            final feedPosts = currentUserId != null
                ? state.posts.where((post) => post.author.id != currentUserId).toList()
                : state.posts;

            if (feedPosts.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<PostsBloc>().add(RefreshPosts());
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                itemCount: feedPosts.length,
                itemBuilder: (context, index) {
                  return PostCard(post: feedPosts[index]);
                },
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          );

          if (result != null && result is Post) {
            context.read<PostsBloc>().add(CreatePostRequested(result));
          }
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Halo! Selamat datang di Anigmaa 👋',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yuk mulai follow orang atau bikin postingan pertama lo!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              );

              if (result != null && result is Post) {
                context.read<PostsBloc>().add(CreatePostRequested(result));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Bikin Post'),
          ),
        ],
      ),
    );
  }
}
