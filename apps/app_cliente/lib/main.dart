import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PeNaAreiaClienteApp(dependencies: AppDependencies()));
}

