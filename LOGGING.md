# Logging Guidelines

## Overview
The application uses a centralized logging system that automatically disables verbose logging in production builds.

## Usage

### Basic Logging
```dart
import 'package:anigmaa/core/utils/app_logger.dart';

final logger = AppLogger();

// Different log levels
logger.debug('Debug information');
logger.info('General information');
logger.warning('Warning message');
logger.error('Error occurred', error, stackTrace);
```

### Network Logging
Network requests are automatically logged using the `NetworkLogger`:
- `→ GET /api/posts` - Request initiated
- `← 200 /api/posts (143ms)` - Successful response
- `✗ 404 /api/users: Not found` - Error response

## Log Levels

- **DEBUG**: Development information (only visible in debug mode)
- **INFO**: General application events
- **WARNING**: Potential issues that don't stop execution
- **ERROR**: Errors that need attention
- **WTF**: Critical failures

## Configuration

Logging is configured in `main.dart`:
```dart
AppLogger().init();
```

By default:
- ✅ Logs are **enabled** in debug mode
- ❌ Logs are **disabled** in release builds
- 🎨 No emojis (professional output)
- 📊 Clean, minimal format

## Best Practices

1. **Use appropriate log levels**
   - Don't use `debug()` for critical errors
   - Don't use `error()` for normal flow

2. **Be concise**
   - ✅ `logger.info('User logged in: ${user.email}')`
   - ❌ `logger.info('The user with the email ${user.email} has successfully logged into the system')`

3. **Don't log sensitive data**
   - ❌ Passwords, tokens, or PII in logs
   - ✅ Use generic identifiers

4. **Network logs are automatic**
   - No need to manually log HTTP requests
   - The interceptor handles it

## What Changed

Before:
```
╔══════════════════════════════════════════════════════════════
║ REQUEST
╠══════════════════════════════════════════════════════════════
║ METHOD: GET
║ URL: http://10.0.2.2:8081/api/v1/posts/feed?limit=20&offset=0
║ HEADERS: {Authorization: Bearer ..., Content-Type: application/json}
╚══════════════════════════════════════════════════════════════
```

After:
```
→ GET /posts/feed
← 200 /posts/feed (156ms)
```

Much cleaner! 🎉
