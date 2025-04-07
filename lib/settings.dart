import 'package:flutter/material.dart';
import 'package:walletway/user_authentication/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'about_app.dart';
import 'app_drawer.dart';
import 'how_to_use.dart';
import 'main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  static const String routeName = '/settings';

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications(); // Initialize Notifications when page opens
   // _sendTestNotification(); // Send a test notification
  }

  void _initializeNotifications() {
    AwesomeNotifications().initialize(
      'resource://drawable/ww', // Your notification icon path
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Notification channel for basic alerts',
          importance: NotificationImportance.High,
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
        ),
      ],
    );

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  // void _sendTestNotification() {
  //   AwesomeNotifications().createNotification(
  //     content: NotificationContent(
  //       id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
  //       channelKey: 'basic_channel',
  //       title: 'Settings Page Opened',
  //       body: 'You are now in the WalletWay Settings.',
  //       notificationLayout: NotificationLayout.Default,
  //     ),
  //   );
  // }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE39C6F),
        title: const Text("Settings"),
        centerTitle: true,
      ),
      drawer: AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SettingsTile(
            title: "Set Alert",
            onTap: () {
              _showSetAlertDialog(context); // Show set alert dialog
            },
          ),
          SettingsTile(
            title: "About App",
            onTap: () {
              Navigator.pushNamed(context, WelcomePage.routeName); // Navigate to About App
            },
          ),
          SettingsTile(
            title: "How to use WalletWay",
            onTap: () {
              Navigator.pushNamed(context, HowToUsePage.routeName); // Navigate to HowToUsePage
            },
          ),
          SettingsTile(
            title: "Delete Account",
            onTap: () {
              _showDeleteAccountDialog(context); // Show delete account dialog
            },
          ),
          SettingsTile(
            title: "Logout",
            onTap: () {
              _showLogoutDialog(context); // Show logout confirmation dialog
            },
          ),
        ],
      ),
    );
  }

  // Set Alert dialog
  void _showSetAlertDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    DateTime? selectedDateTime;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Set Alert"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, // Center align content
              children: [
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: "Reason"),
                  textAlign: TextAlign.center, // Center text inside the field
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE39C6F), // Same as logout button
                  ),
                  onPressed: () async {
                    DateTime? pickedDate = await _pickDate(context);
                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await _pickTime(context);
                      if (pickedTime != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Text(
                    selectedDateTime == null
                        ? "Pick Date & Time"
                        : "Selected: ${selectedDateTime.toString()}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center buttons
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 20), // Space between buttons
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE39C6F), // Same as logout button
                    ),
                    onPressed: () {
                      if (reasonController.text.isNotEmpty &&
                          selectedDateTime != null) {
                        _saveAlertAndScheduleNotification(
                            context, reasonController.text, selectedDateTime!);
                        Navigator.of(ctx).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill in all fields."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Set Alert",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }


  Future<DateTime?> _pickDate(BuildContext context) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
  }

  Future<TimeOfDay?> _pickTime(BuildContext context) async {
    return await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  // Save Alert and Schedule Notification
  void _saveAlertAndScheduleNotification(
      BuildContext context, String reason, DateTime dateTime) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Save alert to Firestore
        await FirebaseFirestore.instance.collection('alerts').add({
          'userId': user.uid,
          'reason': reason,
          'date': dateTime.toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Check if notifications are allowed
        bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
        if (!isAllowed) {
          isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
        }

        if (!isAllowed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Notification permission denied."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Ensure the dateTime is in the future
        if (dateTime.isAfter(DateTime.now())) {
          int notificationId = dateTime.millisecondsSinceEpoch.remainder(100000);

          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: notificationId,
              channelKey: 'basic_channel',
              title: 'Reminder Alert',
              body: 'Reminder: $reason at ${dateTime.toLocal()}',
              notificationLayout: NotificationLayout.Default,
            ),
            schedule: NotificationCalendar(
              year: dateTime.year,
              month: dateTime.month,
              day: dateTime.day,
              hour: dateTime.hour,
              minute: dateTime.minute,
              second: 0,
              preciseAlarm: true, // Ensures precise scheduling
              allowWhileIdle: true, // Allows notifications in low-power mode
            ),
          );

          print("Notification scheduled for $dateTime");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Alert set successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please select a future date and time."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error setting alert: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error setting alert: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // Delete Account confirmation dialog
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "This action is irreversible. All your account data will be permanently deleted. Do you wish to proceed?",
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center buttons
            children: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 20), // Space between buttons
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE39C6F), // Orange background
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showPasswordDialog(context);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white), // Black text
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showPasswordDialog(BuildContext context) {
    final TextEditingController _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Re-authenticate"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _reauthenticateAndDeleteAccount(context, _passwordController.text);
            },
            child: const Text("Re-authenticate & Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _reauthenticateAndDeleteAccount(
      BuildContext context, String password) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);

        await _deleteUserData(user.uid);

        await user.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account deleted successfully."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting account: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUserData(String userId) async {
    try {
      FirebaseFirestore.instance.collection('users').doc(userId).delete();

      await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      FirebaseStorage.instance
          .ref()
          .child('user_data/$userId')
          .listAll()
          .then((result) {
        for (var ref in result.items) {
          ref.delete();
        }
      });
    } catch (e) {
      throw Exception("Error deleting user data: $e");
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center buttons horizontally
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Cancel",
                    //style: TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 20), // Space between buttons
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE39C6F),
                  ),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
          actionsAlignment: MainAxisAlignment.center, // Align buttons to center
        );
      },
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const SettingsTile({Key? key, required this.title, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
