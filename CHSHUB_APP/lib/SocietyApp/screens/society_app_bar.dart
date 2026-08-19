import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/notification.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';

class SocietyAppBar {
  
  
  PreferredSizeWidget buildAppBar(BuildContext context, WidgetRef ref) {
    
    final residentName =
        ref.watch(basicInfoViewModelProvider).name ?? 'Resident';
    final unit = ref.watch(basicInfoViewModelProvider).unit ?? 'Unknown Unit';

    return AppBar(
      backgroundColor: const Color(0xFF2E3B62),
      elevation: 0,
      toolbarHeight: 70,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $residentName',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: () {
              // Handle unit switching
              _showUnitSwitchDialog(context);
            },
            child: Row(
              children: [
                Text(
                  unit,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationScreen()                       
                  ),
                );
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '2',
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        GestureDetector(
          // onTap: () {
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (context) => HouseholdScreen()),
          //   );
          // },
          child: const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage: AssetImage('assets/images/user.png'),
            ),
          ),
        ),
      ],
    );
  }
  
  void _showUnitSwitchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Switch Unit'),
          content: const Text(
            'Unit switching functionality is not implemented yet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

