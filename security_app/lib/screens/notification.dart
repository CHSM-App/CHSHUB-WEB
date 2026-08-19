import 'package:flutter/material.dart';
import 'package:security_app/domain/models/notification.dart';



// Notification Page with StatefulWidget
class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Dummy notification data
  List<SendNotification> notifications = [
    SendNotification(
      id: '1',
      title: 'New Message',
      description: 'You have received a new message from John Doe',
      time: '2m ago',
      route: '/messages',
    ),
    SendNotification(
      id: '2',
      title: 'Order Delivered',
      description: 'Your order #12345 has been delivered successfully to your address',
      time: '1h ago',
      route: '/orders',
    ),
    SendNotification(
      id: '3',
      title: 'Payment Successful',
      description: 'Your payment of \$99.99 was processed successfully',
      time: '3h ago',
      route: '/payments',
    ),
    SendNotification(
      id: '4',
      title: 'System Update Available',
      description: 'A new version 2.5.0 of the app is available for download',
      time: '5h ago',
      route: '/settings',
    ),
    SendNotification(
      id: '5',
      title: 'Friend Request',
      description: 'Sarah Williams wants to connect with you on the platform',
      time: '1d ago',
      route: '/friends',
    ),
    SendNotification(
      id: '6',
      title: 'Sale Alert',
      description: 'Flash sale! Get 50% off on all items for the next 24 hours',
      time: '1d ago',
      route: '/sales',
    ),
    SendNotification(
      id: '7',
      title: 'New Comment',
      description: 'Mike Johnson commented on your post: "Great content!"',
      time: '2d ago',
      route: '/posts',
    ),
    SendNotification(
      id: '8',
      title: 'Reminder',
      description: 'Don\'t forget your appointment tomorrow at 3:00 PM',
      time: '2d ago',
      route: '/calendar',
    ),
    SendNotification(
      id: '9',
      title: 'Subscription Renewal',
      description: 'Your premium subscription will renew in 3 days',
      time: '3d ago',
      route: '/subscription',
    ),
    SendNotification(
      id: '10',
      title: 'Welcome!',
      description: 'Thank you for joining our community. Explore all features',
      time: '1w ago',
      route: '/welcome',
    ),
  ];

  void removeNotification(String id) {
    setState(() {
      notifications.removeWhere((notification) => notification.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                setState(() {
                  notifications.clear();
                });
              },
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationCard(
                  notification: notification,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPage(
                          title: notification.title?? 'No Title',
                          route: notification.route?? 'No route',
                        ),
                      ),
                    );
                  },
                  onDismiss: () {
                    removeNotification(notification.id?? '');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${notification.title} dismissed'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// Notification Card Widget
class NotificationCard extends StatelessWidget {
  final SendNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Content (Left Side)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title?? 'No Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.description?? 'No Description',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Time (Right Side)
                Text(
                  notification.time?? 'No Time',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Detail Page to navigate to
class DetailPage extends StatelessWidget {
  final String title;
  final String route;

  const DetailPage({
    Key? key,
    required this.title,
    required this.route,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Navigated to: $title',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Route: $route',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Notifications'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Main App


