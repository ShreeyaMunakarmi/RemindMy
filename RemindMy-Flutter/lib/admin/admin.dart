import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../authentication/login.dart';
import 'admin1.dart';
import 'admin2.dart';
import 'package:remindmy/address.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Admin(),
    );
  }
}

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  int totalUsers = 0;
  int totalTasks = 0;
  int totalDoneTasks = 0;
  double taskCompletionPercentage = 0.0;
  int totalRevenue = 0;
  String userName = '';
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchTotalUsers();
    fetchTotalTasks();
    fetchTotalDoneTasks();
    fetchTaskCompletionPercentage();
    fetchTotalRevenue();
    fetchUserData();
  }

  Future<void> fetchTotalUsers() async {
    final response =
        await http.get(Uri.parse('http://$ip:3000/auth/users/total'));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        totalUsers = responseData['totalUsers'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to fetch total users: ${response.body}')),
      );
    }
  }

  Future<void> fetchTotalTasks() async {
    final response =
        await http.get(Uri.parse('http://$ip:3000/auth/tasks/total'));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        totalTasks = responseData['totalTasks'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to fetch total tasks: ${response.body}')),
      );
    }
  }

  Future<void> fetchTotalDoneTasks() async {
    final response =
        await http.get(Uri.parse('http://$ip:3000/auth/tasks/done'));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        totalDoneTasks = responseData['totalDoneTasks'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to fetch total done tasks: ${response.body}')),
      );
    }
  }

  Future<void> fetchTaskCompletionPercentage() async {
    final response = await http
        .get(Uri.parse('http://$ip:3000/auth/tasks/completion-percentage'));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        taskCompletionPercentage = responseData['completionPercentage'] / 100.0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to fetch task completion percentage: ${response.body}')),
      );
    }
  }

  Future<void> fetchTotalRevenue() async {
    final response =
        await http.get(Uri.parse('http://$ip:3000/auth/revenue/total'));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        totalRevenue = responseData['totalRevenue'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to fetch total revenue: ${response.body}')),
      );
    }
  }

  Future<void> fetchUserData() async {
    final token = await storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('http://$ip:3000/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        userName = responseData['name'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user data: ${response.body}')),
      );
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (Route<dynamic> route) => false,
    );
  }

  Route _createRoute1() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => admin1(),
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

  Route _createRoute2() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => admin2(),
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
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage('assets/logo.png'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFFDEB171),
                            size: 36,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5F33E2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$totalUsers',
                                    style: const TextStyle(
                                      color: Color(0xFFEDE8FF),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Users',
                                    style: TextStyle(
                                      color: Color(0xFFEDE8FF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Icon(
                                Icons.group,
                                color: Color(0xFFEDE8FF),
                                size: 40,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5F33E2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$totalTasks',
                                    style: const TextStyle(
                                      color: Color(0xFFEDE8FF),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Tasks',
                                    style: TextStyle(
                                      color: Color(0xFFEDE8FF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Icon(
                                Icons.list_alt_outlined,
                                color: Color(0xFFEDE8FF),
                                size: 40,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5F33E2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$totalDoneTasks',
                                    style: const TextStyle(
                                      color: Color(0xFFEDE8FF),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Done',
                                    style: TextStyle(
                                      color: Color(0xFFEDE8FF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Icon(
                                Icons.fact_check_outlined,
                                color: Color(0xFFEDE8FF),
                                size: 40,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5F33E2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Revenue Generated:',
                              style: TextStyle(
                                color: Color(0xFFEDE8FF),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$totalRevenue',
                              style: const TextStyle(
                                color: Color(0xFFEDE8FF),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'In NPR',
                              style: TextStyle(
                                color: Color(0xFFEDE8FF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Icon(
                          Icons.account_balance_outlined,
                          color: Color(0xFFEDE8FF),
                          size: 50,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5F33E2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'User Task Completion %:',
                          style: TextStyle(
                            color: Color(0xFFEDE8FF),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        CircularPercentIndicator(
                          radius: 42.0,
                          lineWidth: 5.0,
                          animation: true,
                          percent: taskCompletionPercentage,
                          center: Text(
                            "${(taskCompletionPercentage * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Color(0xFFEDE8FF),
                            ),
                          ),
                          circularStrokeCap: CircularStrokeCap.round,
                          progressColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: logout,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF5F33E2),
                    backgroundColor: const Color(0xFFEDE8FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                        color: Color(0xFF5F33E2),
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        child: SizedBox(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: const Icon(
                  Icons.folder_shared,
                  size: 25,
                ),
                onPressed: () {
                  setState(() {
                    Navigator.of(context).push(_createRoute1())
                        as Route<Object?>;
                  });
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.chat,
                  size: 25,
                ),
                onPressed: () {
                  setState(() {
                    Navigator.of(context).push(_createRoute2())
                        as Route<Object?>;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
