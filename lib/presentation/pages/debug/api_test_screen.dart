import 'package:flutter/material.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_config.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final DioClient _dioClient = DioClient();
  String _result = 'Press a button to test API';
  bool _isLoading = false;

  Future<void> _testHealthCheck() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing health endpoint...';
    });

    try {
      final response = await _dioClient.dio.get('\${AppConfig.baseUrl}/health');
      setState(() {
        _result = 'SUCCESS!\n\nStatus: \${response.statusCode}\n\nResponse:\n\${response.data}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'ERROR!\n\n\$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetEvents() async {
    setState(() {
      _isLoading = true;
      _result = 'Getting events...';
    });

    try {
      final response = await _dioClient.get('/events');
      setState(() {
        _result = 'SUCCESS!\n\nStatus: \${response.statusCode}\n\nResponse:\n\${response.data}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'ERROR!\n\n\$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetPosts() async {
    setState(() {
      _isLoading = true;
      _result = 'Getting posts...';
    });

    try {
      final response = await _dioClient.get('/posts');
      setState(() {
        _result = 'SUCCESS!\n\nStatus: \${response.statusCode}\n\nResponse:\n\${response.data}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'ERROR!\n\n\$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppConfig.isDevelopment ? Colors.orange : Colors.green,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Environment: \${AppConfig.isDevelopment ? "DEVELOPMENT" : "PRODUCTION"}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Base URL: \${AppConfig.baseUrl}', style: const TextStyle(color: Colors.white)),
                Text('API URL: \${AppConfig.apiUrl}', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testHealthCheck,
                    icon: const Icon(Icons.favorite),
                    label: const Text('Test Health Check'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testGetEvents,
                    icon: const Icon(Icons.event),
                    label: const Text('GET /events'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testGetPosts,
                    icon: const Icon(Icons.article),
                    label: const Text('GET /posts'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator())),
                  if (!_isLoading)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _result.contains('SUCCESS') ? Colors.green[50] : Colors.grey[100],
                        border: Border.all(color: _result.contains('SUCCESS') ? Colors.green : Colors.grey, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(_result, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
