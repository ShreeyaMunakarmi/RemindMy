import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home1.dart';
import 'home32.dart';
import '../khalti/payments.dart';
import 'package:khalti/khalti.dart';
import 'home32.dart';
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
        body: home3(
          onPointsUpdated: (int) {},
        ),
      ),
    );
  }
}

class home3 extends StatefulWidget {
  final Function(int) onPointsUpdated;

  const home3({Key? key, required this.onPointsUpdated}) : super(key: key);

  @override
  _home3State createState() => _home3State();
}

class _home3State extends State<home3> {
  String userStatus = '';
  List<Map<String, dynamic>> tasks = [];
  List<Map<dynamic, dynamic>> notifications = [];
  final storage = FlutterSecureStorage();

  String? selectedValue;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchTasks();
  }

  Future<void> fetchUserData() async {
    final token = await storage.read(key: 'jwt');

    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.get(
      Uri.parse('http://$ip:3000/auth/me'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        userStatus =
            responseData['status'].toString(); // Convert to string if necessary
      });
    } else {
      print('Failed to fetch user data: ${response.body}');
    }
  }

  Future<void> fetchTasks() async {
    final token = await storage.read(key: 'jwt');

    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.get(
      Uri.parse('http://$ip:3000/auth/tasks?status=0'),
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

      // Check if userStatus is not "1" and if tasks length is greater than 2
      if (userStatus != "1" && tasks.length > 2) {
        _showAlertDialog();
      }
    } else {
      print('Failed to fetch tasks: ${response.body}');
    }
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 40,
                color: Color(0xFF5F33E2),
              ),
              SizedBox(width: 10),
              Text(
                'Upgrade to premium',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content:
              const Text('You have to upgrade RemindMy to set up more tasks.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => payments()),
              ),
            ),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(20),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 24.0,
        );
      },
    ).then((value) {
      // Prevent dismissal using back button
      if (value == null) {
        _showAlertDialog();
      }
    });
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

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => home32(
        onPointsUpdated: (int) {},
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
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
                      'Today\'s Tasks',
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
                          'In progress',
                          style: TextStyle(
                            color: Color(0xFF5F33E2),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            Navigator.of(context).push(_createRoute())
                                as Route<Object?>;
                          });
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Icons.schedule_outlined,
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
                    style: const TextStyle(
                      color: Colors.pink,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                markTaskAsCompleted(task['id']);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFDE496E),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
              ),
              child: const Text(
                'Task Completed',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
