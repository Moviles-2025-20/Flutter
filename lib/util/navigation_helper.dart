import 'package:flutter/material.dart';

void pushWithNav(GlobalKey<NavigatorState> navigatorKey, Widget page) {
  navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => page));
}
