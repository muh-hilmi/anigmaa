import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/posts/posts_bloc.dart';
import '../../../bloc/posts/posts_event.dart';
import '../../../bloc/events/events_bloc.dart';
import '../../../bloc/events/events_event.dart';

class FeedErrorState extends StatelessWidget {
  final String message;

  const FeedErrorState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF6B6B)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Color(0xFF2D3142)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<PostsBloc>().add(LoadPosts());
              context.read<EventsBloc>().add(LoadEvents());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFCFCFC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
