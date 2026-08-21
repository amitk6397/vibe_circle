import '../constants/api_urls.dart';

class Helpers {
  Helpers._();

  static DateTime parseUTCDate(String value) {
    if (value.isEmpty) return DateTime.now();
    var normalized = value;
    if (!value.endsWith('Z') &&
        !RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value) &&
        !value.contains('+')) {
      normalized = '${value.replaceAll(' ', 'T')}Z';
    }
    try {
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static String formatRelativeDate(String dateStr) {
    if (dateStr.isEmpty) return 'Just now';
    final now = DateTime.now();
    final date = parseUTCDate(dateStr);

    final nowStart = DateTime(now.year, now.month, now.day);
    final dateStart = DateTime(date.year, date.month, date.day);
    
    final diffDays = dateStart.difference(nowStart).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    if (diffDays == -1) return 'Yesterday';

    if (diffDays < 0) {
      final daysAgo = diffDays.abs();
      if (daysAgo < 7) {
        return '$daysAgo day${daysAgo > 1 ? "s" : ""} ago';
      }
      final weeksAgo = daysAgo ~/ 7;
      if (weeksAgo < 4) {
        return '$weeksAgo week${weeksAgo > 1 ? "s" : ""} ago';
      }
      final monthsAgo = daysAgo ~/ 30;
      if (monthsAgo < 12) {
        return '$monthsAgo month${monthsAgo > 1 ? "s" : ""} ago';
      }
      final yearsAgo = daysAgo ~/ 365;
      return '$yearsAgo year${yearsAgo > 1 ? "s" : ""} ago';
    } else {
      if (diffDays < 7) {
        return 'in $diffDays day${diffDays > 1 ? "s" : ""}';
      }
      final weeksIn = diffDays ~/ 7;
      if (weeksIn < 4) {
        return 'in $weeksIn week${weeksIn > 1 ? "s" : ""}';
      }
      final monthsIn = diffDays ~/ 30;
      if (monthsIn < 12) {
        return 'in $monthsIn month${monthsIn > 1 ? "s" : ""}';
      }
      final yearsIn = diffDays ~/ 365;
      return 'in $yearsIn year${yearsIn > 1 ? "s" : ""}';
    }
    return 'Just now';
  }

  static String timeAgo(dynamic dateInput) {
    if (dateInput == null) return 'Just now';
    DateTime date;
    if (dateInput is DateTime) {
      date = dateInput;
    } else if (dateInput is String) {
      if (dateInput.isEmpty) return 'Just now';
      date = parseUTCDate(dateInput);
    } else {
      return 'Just now';
    }

    final diff = DateTime.now().difference(date);
    if (diff.isNegative || diff.inSeconds < 45) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    if (diff.inDays < 30) {
      final weeks = diff.inDays ~/ 7;
      return '${weeks}w ago';
    }
    if (diff.inDays < 365) {
      final months = diff.inDays ~/ 30;
      return '${months}mo ago';
    }
    return '${diff.inDays ~/ 365}y ago';
  }

  static String getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.map((p) => p.isEmpty ? '' : p[0]).take(2).join('').toUpperCase();
    return initials.isNotEmpty ? initials : '?';
  }

  static String? resolveImageUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'None') return null;

    // Detect raw local device paths from Android/iOS/Desktop cache
    if (trimmed.startsWith('/data/') ||
        trimmed.startsWith('/storage/') ||
        trimmed.startsWith('/var/mobile/') ||
        trimmed.startsWith('C:\\') ||
        trimmed.startsWith('D:\\')) {
      return null;
    }

    final base = ApiUrls.baseUrl.split('/api/')[0];

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (trimmed.contains('/uploads/')) {
        try {
          final uri = Uri.parse(trimmed);
          final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
          return trimmed.replaceFirst(origin, base);
        } catch (_) {}
      }
      return trimmed;
    }

    if (trimmed.startsWith('data:') ||
        trimmed.startsWith('file://') ||
        trimmed.startsWith('content://')) {
      return trimmed;
    }

    if (trimmed.startsWith('/uploads/') || trimmed.startsWith('uploads/')) {
      return '$base${trimmed.startsWith('/') ? '' : '/'}$trimmed';
    }

    return '$base${trimmed.startsWith('/') ? '' : '/'}$trimmed';
  }
}
