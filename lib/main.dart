import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  var ensureInitialized = WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: Ma3akApp(),
    ),
  );
}
