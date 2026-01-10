import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfree/core/theme/app_theme.dart';
import 'package:mindfree/core/utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: MindfreeApp()));
}

class MindfreeApp extends ConsumerWidget {
  const MindfreeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      theme: AppTheme.darkTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg_mesh.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: const Color.fromARGB(183, 0, 0, 0)),
              ),
            ),
            if (child != null) child,
          ],
        );
      },
    );
  }
}
