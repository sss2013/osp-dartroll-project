import 'package:flutter/material.dart';

class MainTestPage extends StatefulWidget {
  const MainTestPage({super.key});

  @override
  State<MainTestPage> createState() => _MainTestPageState();
}

class _MainTestPageState extends State<MainTestPage> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
            child: Container(
                height: screenHeight,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(children: [
                  const Spacer(flex: 3),

                  // 로고
                  Center(
                    child: Image.asset(
                      'assets/images/logos/Culture.png',
                      width: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ]))));
  }
}
