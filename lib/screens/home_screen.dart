import 'package:flutter/material.dart';

import '../widgets/map_section.dart';
import '../widgets/avatar_list.dart';
import '../widgets/card_section.dart';
import '../widgets/bottom_nav.dart';

import 'camera_screen.dart';
import 'friends_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final pages = const [
    _HomeContent(),
    CameraScreen(),
    FriendsScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F9),
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: BottomNavBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: MapSection()),
        SingleChildScrollView(
          child: Column(
            children: const [
              AvatarList(),
              CardSection(),
            ],
          ),
        ),
      ],
    );
  }
}
