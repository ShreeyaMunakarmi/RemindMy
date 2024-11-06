import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home2.dart';
import 'home3.dart';
import 'home4.dart';
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: home1(),
      ),
    );
  }
}

class home1 extends StatefulWidget {
  const home1({super.key});

  @override
  State<home1> createState() => _home1State();
}

class _home1State extends State<home1> {
  String userName = '';
  String userEmail = '';
  int userPoints = 0;
  int completedTasks = 0;
  List<Map<String, dynamic>> tasks = [];
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchTasks();
    fetchPointsAndCompletedTasks();
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
        userName = responseData['name'];
        userEmail = responseData['email'];
        userPoints = responseData['points'];
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
    } else {
      print('Failed to fetch tasks: ${response.body}');
    }
  }

  Future<void> fetchPointsAndCompletedTasks() async {
    final token = await storage.read(key: 'jwt');

    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.get(
      Uri.parse('http://$ip:3000/auth/points'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        userPoints = responseData['points'];
        completedTasks = responseData['completedTasks'];
      });
    } else {
      print('Failed to fetch points and completed tasks: ${response.body}');
    }
  }

  void updatePoints(int points) {
    setState(() {
      userPoints += points;
    });
  }

  Route _createRoute1() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const home2(),
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
      pageBuilder: (context, animation, secondaryAnimation) => const home2(),
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

  Route _createRoute3() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => home3(
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

  Route _createRoute4() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => home4(),
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
    double percentage = (completedTasks + tasks.length) > 0
        ? completedTasks / (completedTasks + tasks.length)
        : 0.0;

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
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/logo.png'),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello!',
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
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.stars,
                          color: Color(0xFFDEB171),
                          size: 36,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          userPoints.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F33E2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 10, 0, 10),
                              child: Text(
                                percentage > 0.6
                                    ? "Hurray!\nYour today's tasks\nare almost done!"
                                    : "Keep going!\nYou still have tasks\nto complete!",
                                style: const TextStyle(
                                  color: Color(0xFFEDE8FF),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(70, 0, 0, 0),
                            child: CircularPercentIndicator(
                              radius: 40.0,
                              lineWidth: 6.0,
                              animation: true,
                              percent: percentage,
                              center: Text(
                                "${(percentage * 100).toStringAsFixed(0)}%",
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
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            Navigator.of(context).push(_createRoute3())
                                as Route<Object?>;
                          });
                        },
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
                          'View tasks',
                          style: TextStyle(
                              color: Color(0xFF5F33E2),
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'In progress',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 15),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF5F33E2),
                          ),
                        ),
                        Text(
                          tasks.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._buildTaskContainers(),
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
                  Icons.home,
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
                  Icons.pin_drop,
                  size: 25,
                ),
                onPressed: () {
                  setState(() {
                    Navigator.of(context).push(_createRoute2())
                        as Route<Object?>;
                  });
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.task,
                  size: 25,
                ),
                onPressed: () {
                  setState(() {
                    setState(() {
                      Navigator.of(context).push(_createRoute3())
                          as Route<Object?>;
                    });
                  });
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.account_box,
                  size: 25,
                ),
                onPressed: () {
                  setState(() {
                    Navigator.of(context).push(_createRoute4())
                        as Route<Object?>;
                  });
                },
              )
            ],
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
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              value: 0.5,
              backgroundColor: Colors.grey,
              color: Colors.blue,
            ),
          ],
        ),
      );
    }).toList();
  }
}
