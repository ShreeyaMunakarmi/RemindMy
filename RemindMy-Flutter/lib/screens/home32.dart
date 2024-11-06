import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home1.dart';
import 'package:khalti/khalti.dart';
import 'package:remindmy/address.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Khalti.init(
    publicKey: 'test_public_key_e46e3008fb0c40be91e630fface04353',
    enabledDebugging: false,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: home32(
          onPointsUpdated: (int) {},
        ),
      ),
    );
  }
}

class home32 extends StatefulWidget {
  final Function(int) onPointsUpdated;

  home32({super.key, required this.onPointsUpdated});

  @override
  _home32State createState() => _home32State();
}

class _home32State extends State<home32> {
  List<Map<String, dynamic>> tasks = [];
  final storage = FlutterSecureStorage();

  String? selectedValue;
  List<Map<dynamic, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final token = await storage.read(key: 'jwt');

    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.get(
      Uri.parse('http://$ip:3000/auth/tasks?status=1'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as List;
      setState(() {
        tasks = responseData.cast<Map<String, dynamic>>();
      });
    } else {
      print('Failed to fetch tasks: ${response.body}');
    }
  }

  Future<void> markTaskAsCompleted(int taskId) async {
    final token = await storage.read(key: 'jwt');

    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.patch(
      Uri.parse('http://$ip:3000/auth/tasks/status'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'taskId': taskId,
        'status': 1,
      }),
    );

    if (response.statusCode == 200) {
      widget.onPointsUpdated(5); // Update points by 5
      fetchTasks(); // Refresh the tasks after marking as completed
    } else {
      print('Failed to update task status: ${response.body}');
    }
  }

  Future<void> _fetchNotifications() async {
    final token = await storage.read(key: 'jwt');

    if (token == null) {
      Fluttertoast.showToast(msg: 'No token found');
      return;
    }

    final response = await http.get(
      Uri.parse('http://$ip:3000/auth/notifications'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      setState(() {
        notifications = responseData.map((notification) {
          return {
            'title': notification['title'],
            'createdAt': notification['createdAt'],
          };
        }).toList();
      });
      _showNotificationsDialog();
    } else {
      Fluttertoast.showToast(
          msg: 'Failed to fetch notifications: ${response.body}');
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Column(
                  children: [
                    ListTile(
                      title: Text(notification['title'] ?? 'No title'),
                      subtitle: Text(notification['createdAt'] ?? 'No date'),
                    ),
                    Divider(
                      color: Colors.grey, // Customize the color
                      thickness: 1, // Customize the thickness
                      indent: 16, // Left spacing
                      endIndent: 16, // Right spacing
                    ), // Divider after each item
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void sortTasksByDate1() {
    tasks.sort((a, b) => b['date'].compareTo(a['date']));
    setState(() {});
  }

  void sortTasksByDate2() {
    tasks.sort((a, b) => a['date'].compareTo(b['date']));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const home1()),
                          );
                        });
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 40,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Completed Tasks',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.black,
                        size: 40,
                      ),
                      onPressed: _fetchNotifications,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF5F33E2),
                          backgroundColor:
                              const Color(0xFFEDE8FF), // text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'In progress',
                          style: TextStyle(
                            color: Color(0xFF5F33E2),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                        width:
                            16), // Adjust as needed for spacing between buttons
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF5F33E2),
                          backgroundColor:
                              const Color(0xFFEDE8FF), // text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            color: Color(0xFF5F33E2),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    sortTasksByDate1();
                  },
                  onDoubleTap: () {
                    sortTasksByDate2();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDE496E),
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Sort Tasks By Date',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.pink.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.swap_vert_circle_outlined,
                            color: Color(0xFFDE496E),
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ..._buildTaskContainers(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTaskContainers() {
    return tasks.map((task) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task['title'],
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.checklist_outlined,
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              task['description'],
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Plus Code: ',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: task['plusCode'],
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Date: ',
                    style: TextStyle(
                      color: Colors.pink,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: task['date'],
                    style: TextStyle(
                      color: Colors.pink,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
