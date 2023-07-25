import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surf_practice_magic_ball/helpers.dart';
import 'package:surf_practice_magic_ball/widgets/magic_ball.dart';

class MagicBallScreen extends StatelessWidget {
  const MagicBallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 36, 0, 97), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const Spacer(
              flex: 3,
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 600, maxHeight: 600),
                      child: const MagicBall()),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  bottomText(),
                  style: GoogleFonts.rubik(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String bottomText() {
    if (Helpers.isMobile) return "Нажмите на шар или потрясите телефон";
    return "Нажмите на шар";
  }
}
