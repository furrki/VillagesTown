import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/layout_constants.dart';
import 'game_view_desktop.dart';
import 'game_view_rts.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  static bool get usesCharacterCampaign {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = LayoutConstants.isPhone(context);
    return isCompact || usesCharacterCampaign ? const RtsGameView() : const DesktopGameView();
  }
}
