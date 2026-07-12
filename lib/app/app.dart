import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class AluInternshipApp extends StatelessWidget {
  const AluInternshipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "ALU Internship",
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
