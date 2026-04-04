import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Base class for all screens in the app
/// Provides consistent structure and common functionality
abstract class BaseScreen extends StatelessWidget {
  const BaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(context),
      bottomNavigationBar: buildBottomBar(context),
      floatingActionButton: buildFloatingActionButton(context),
      backgroundColor: getBackgroundColor(context),
    );
  }

  /// Build the app bar for this screen
  /// Return null for screens without app bar
  PreferredSizeWidget? buildAppBar(BuildContext context);

  /// Build the main body of the screen
  Widget buildBody(BuildContext context);

  /// Build the bottom navigation bar
  /// Return null if not needed
  Widget? buildBottomBar(BuildContext context) => null;

  /// Build the floating action button
  /// Return null if not needed
  Widget? buildFloatingActionButton(BuildContext context) => null;

  /// Get the background color for this screen
  /// Override to change background color
  Color getBackgroundColor(BuildContext context) => AppColors.background;
}

/// Base class for stateful screens
abstract class BaseStatefulScreen extends StatefulWidget {
  const BaseStatefulScreen({super.key});

  @override
  BaseStatefulScreenState createState();
}

abstract class BaseStatefulScreenState<T extends BaseStatefulScreen>
    extends State<T> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(context),
      bottomNavigationBar: buildBottomBar(context),
      floatingActionButton: buildFloatingActionButton(context),
      backgroundColor: getBackgroundColor(context),
    );
  }

  /// Build the app bar for this screen
  /// Return null for screens without app bar
  PreferredSizeWidget? buildAppBar(BuildContext context);

  /// Build the main body of the screen
  Widget buildBody(BuildContext context);

  /// Build the bottom navigation bar
  /// Return null if not needed
  Widget? buildBottomBar(BuildContext context) => null;

  /// Build the floating action button
  /// Return null if not needed
  Widget? buildFloatingActionButton(BuildContext context) => null;

  /// Get the background color for this screen
  /// Override to change background color
  Color getBackgroundColor(BuildContext context) => AppColors.background;
}
