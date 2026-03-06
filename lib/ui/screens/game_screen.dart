import 'package:flutter/material.dart';
import '../../core/constants/layout_constants.dart';
import 'game_view_desktop.dart';
import 'game_view_rts.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompact = LayoutConstants.isPhone(context);
    return isCompact ? const RtsGameView() : const DesktopGameView();
  }
}
