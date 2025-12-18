import 'package:flutter/material.dart';

class PostContent extends StatelessWidget {
  final String content;

  const PostContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: const TextStyle(
        fontSize: 15,
        height: 1.5,
        color: Color(0xFF1a1a1a),
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
      ),
    );
  }
}
