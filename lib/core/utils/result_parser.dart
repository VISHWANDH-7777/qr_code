import '../../models/parsed_result.dart';

class ResultParser {
  static ParsedResult parse(String rawValue) {
    // URL detection
    if (rawValue.startsWith('http://') || rawValue.startsWith('https://')) {
      return ParsedResult(
        type: 'website',
        rawValue: rawValue,
        displayTitle: rawValue,
        action: 'open_url',
      );
    }

    // WiFi detection (WIFI:S:MySSID;T:WPA;P:MyPassW0rd;;)
    if (rawValue.startsWith('WIFI:')) {
      final ssidMatch = RegExp(r'S:(.*?);').firstMatch(rawValue);
      final passMatch = RegExp(r'P:(.*?);').firstMatch(rawValue);
      final typeMatch = RegExp(r'T:(.*?);').firstMatch(rawValue);
      
      final ssid = ssidMatch?.group(1) ?? 'Unknown Network';
      final pass = passMatch?.group(1) ?? '';
      final type = typeMatch?.group(1) ?? 'nopass';

      return ParsedResult(
        type: 'wifi',
        rawValue: rawValue,
        displayTitle: ssid,
        action: 'connect_wifi',
        details: {
          'ssid': ssid,
          'password': pass,
          'security': type,
        },
      );
    }

    // Email detection (mailto:someone@example.com?subject=Hello)
    if (rawValue.toLowerCase().startsWith('mailto:')) {
      final emailUri = Uri.tryParse(rawValue);
      final email = emailUri?.path ?? rawValue.replaceFirst('mailto:', '');
      return ParsedResult(
        type: 'email',
        rawValue: rawValue,
        displayTitle: email,
        action: 'send_email',
        details: {
          'email': email,
          'subject': emailUri?.queryParameters['subject'],
          'body': emailUri?.queryParameters['body'],
        },
      );
    }

    // Phone detection (tel:+123456789)
    if (rawValue.toLowerCase().startsWith('tel:')) {
      final phone = rawValue.substring(4);
      return ParsedResult(
        type: 'phone',
        rawValue: rawValue,
        displayTitle: phone,
        action: 'call_phone',
      );
    }

    // vCard / MeCard detection (Contact)
    if (rawValue.startsWith('BEGIN:VCARD') || rawValue.startsWith('MECARD:')) {
      return ParsedResult(
        type: 'contact',
        rawValue: rawValue,
        displayTitle: 'Contact Card',
        action: 'add_contact',
      );
    }

    // Default to Plain Text
    return ParsedResult(
      type: 'text',
      rawValue: rawValue,
      displayTitle: rawValue.length > 30 ? '${rawValue.substring(0, 30)}...' : rawValue,
      action: 'copy_text',
    );
  }
}
