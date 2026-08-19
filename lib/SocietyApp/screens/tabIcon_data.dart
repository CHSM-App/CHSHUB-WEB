import 'package:flutter/material.dart';

class TabIconData {
  TabIconData({
    this.icon,
    this.selectedIcon,
    this.index = 0,
    this.isSelected = false,
    this.animationController,
  });

  IconData? icon;                // Normal icon
  IconData? selectedIcon;        // Icon when selected
  bool isSelected;
  int index;
  AnimationController? animationController;

  static List<TabIconData> tabIconsList = <TabIconData>[
    TabIconData(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      index: 0,
    ),
    TabIconData(
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
      index: 1,
    ),
    TabIconData(
      icon: Icons.build_outlined,
      selectedIcon: Icons.build,
      index: 2,
    ),

    TabIconData(
      icon: Icons.person_add_alt,
      selectedIcon: Icons.person_add_alt_rounded,
      index: 3,
    ),
  ];
}
