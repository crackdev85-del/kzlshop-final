
import 'package:flutter/material.dart';
import 'package:myapp/screens/user/home_screen.dart';

class HomeTab extends StatelessWidget {
  final PageController pageController;
  const HomeTab({super.key, required this.pageController});

  @override
  Widget build(BuildContext context) {
    return HomeScreen(pageController: pageController);
  }
}

