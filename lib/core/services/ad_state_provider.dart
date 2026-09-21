import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track when the Mobile Ads SDK has finished initialization.
final adInitializationProvider = StateProvider<bool>((ref) => false);
