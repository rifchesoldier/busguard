// lib/utils/home_shell_navigator.dart

import 'package:flutter/material.dart';

/// Interface abstraite partagée entre home_shell.dart et dashboard_screen.dart.
/// Permet à DashboardScreen de naviguer vers un onglet sans dépendance circulaire.
abstract class HomeShellNavigator {
  void navigateTo(int index);
}
// AJOUTEZ CECI : Le conteneur qui va propager l'interface dans l'arbre des widgets
class HomeShellProvider extends InheritedWidget {
  final HomeShellNavigator navigator;

  const HomeShellProvider({
    super.key,
    required this.navigator,
    required super.child,
  });

  static HomeShellNavigator? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeShellProvider>()?.navigator;
  }

  @override
  bool updateShouldNotify(HomeShellProvider oldWidget) => false;
}