import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/features/auth/auth_provider.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MyScreenContainer(
        child: Center(
          child: CachedNetworkImage(
            imageUrl:
                'https://i.pinimg.com/736x/a6/00/ba/a600ba336702ab75cce59e6d74161ccf.jpg',
          ),
        ),
      ),
    );
  }
}
