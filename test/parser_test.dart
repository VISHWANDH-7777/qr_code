import 'package:flutter_test/flutter_test.dart';
import 'package:qr_toolkit/core/utils/result_parser.dart';

void main() {
  group('ResultParser Tests', () {
    test('Should parse HTTP URL correctly', () {
      final result = ResultParser.parse('https://example.com');
      expect(result.type, 'website');
      expect(result.action, 'open_url');
      expect(result.displayTitle, 'https://example.com');
    });

    test('Should parse WIFI correctly', () {
      final result = ResultParser.parse('WIFI:S:MyNetwork;T:WPA;P:12345678;;');
      expect(result.type, 'wifi');
      expect(result.action, 'connect_wifi');
      expect(result.displayTitle, 'MyNetwork');
      expect(result.details?['password'], '12345678');
      expect(result.details?['security'], 'WPA');
    });

    test('Should parse Email correctly', () {
      final result = ResultParser.parse('mailto:test@example.com?subject=Hello');
      expect(result.type, 'email');
      expect(result.action, 'send_email');
      expect(result.displayTitle, 'test@example.com');
      expect(result.details?['email'], 'test@example.com');
    });

    test('Should parse Phone correctly', () {
      final result = ResultParser.parse('tel:+1234567890');
      expect(result.type, 'phone');
      expect(result.action, 'call_phone');
      expect(result.displayTitle, '+1234567890');
    });

    test('Should parse SMS correctly', () {
      final result = ResultParser.parse('smsto:+1234567890:Hello there');
      expect(result.type, 'sms');
      expect(result.action, 'send_sms');
      expect(result.displayTitle, '+1234567890');
      expect(result.details?['message'], 'Hello there');
    });

    test('Should parse Geo Location correctly', () {
      final result = ResultParser.parse('geo:40.7128,-74.0060');
      expect(result.type, 'location');
      expect(result.action, 'open_map');
      expect(result.displayTitle, 'Location Coordinates');
    });

    test('Should parse vCard correctly', () {
      final result = ResultParser.parse('BEGIN:VCARD\nVERSION:3.0\nFN:John Doe\nEND:VCARD');
      expect(result.type, 'contact');
      expect(result.action, 'add_contact');
      expect(result.displayTitle, 'Contact Card');
    });

    test('Should parse random text correctly', () {
      final result = ResultParser.parse('Just some random text data');
      expect(result.type, 'text');
      expect(result.action, 'copy_text');
      expect(result.displayTitle, 'Just some random text data');
    });
  });
}
