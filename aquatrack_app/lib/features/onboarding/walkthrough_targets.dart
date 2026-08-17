import 'package:flutter/widgets.dart';

/// GlobalKeys that the first-run walkthrough spotlights.
///
/// They live in their own file rather than on either widget so the nav shell
/// and the home screen can each attach one without importing the other, and so
/// adding a step never means touching a 40KB screen file twice.
class WalkthroughTargets {
  const WalkthroughTargets._();

  static final water = GlobalKey(debugLabel: 'walkthrough.water');
  static final coach = GlobalKey(debugLabel: 'walkthrough.coach');
  static final missions = GlobalKey(debugLabel: 'walkthrough.missions');
  static final friends = GlobalKey(debugLabel: 'walkthrough.friends');
  static final profile = GlobalKey(debugLabel: 'walkthrough.profile');
  static final more = GlobalKey(debugLabel: 'walkthrough.more');
  static final smartScan = GlobalKey(debugLabel: 'walkthrough.smartScan');
}
