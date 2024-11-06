import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'home1.dart';
import 'package:remindmy/address.dart';
import '../khalti/payments.dart';
import 'package:khalti/khalti.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Khalti.init(
    publicKey: 'test_public_key_e46e3008fb0c40be91e630fface04353',
    enabledDebugging: false,
  );

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'RemindMy',
        channelName: 'RemindMy Notification',
        channelDescription: 'Notification for user',
        defaultColor: const Color(0xFF5F33E2),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        criticalAlerts: true,
      ),
    ],
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
      home: home2(),
    );
  }
}

class home2 extends StatefulWidget {
  const home2({super.key});

  @override
  State<home2> createState() => _home2State();
}

class _home2State extends State<home2> {
  String? selectedValue;

  LatLng? mylatlong;
  String address = 'Unknown';
  String addressx = 'Unknown';
  String userStatus = '';
  List<Map<dynamic, dynamic>> userTasks = [];
  List<Map<dynamic, dynamic>> notifications = [];

  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    getUserLocation();
    fetchUserData();
    fetchUserTasks();
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
            responseData['status'].toString(); // Convert to string if needed
      });
    } else {
      print('Failed to fetch user data: ${response.body}');
    }
  }

  Future<void> fetchUserTasks() async {
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
        userTasks = responseData.cast<Map<String, dynamic>>();
      });

      // Ensure that userStatus is updated before checking
      if (userStatus != '1' && userTasks.length > 2) {
        _showUpgradeAlert();
      }
    } else {
      print('Failed to fetch tasks: ${response.body}');
    }
  }

  Future<void> getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);
    LatLng userLatLng = LatLng(position.latitude, position.longitude);
    setMarker(userLatLng);
    _mapController.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 14));
  }

  Future<void> setMarker(LatLng value) async {
    mylatlong = value;

    List<Placemark> result =
        await placemarkFromCoordinates(value.latitude, value.longitude);

    if (result.isNotEmpty) {
      address =
          '${result[0].name}, ${result[0].locality} ${result[0].administrativeArea}';
    }
    addressx = '${result[0].name}';

    setState(() {});
    Fluttertoast.showToast(msg: '📍$address');

    _checkForMatchingTask();
  }

  Future<void> _searchAndNavigate(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        LatLng newLatLng =
            LatLng(locations[0].latitude, locations[0].longitude);
        setMarker(newLatLng);
        _mapController.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 14));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Location not found: $query');
    }
  }

  Future<void> _createTask() async {
    final token = await storage.read(key: 'jwt');
    final title = _titleController.text;
    final description = _descriptionController.text;

    if (token == null) {
      Fluttertoast.showToast(msg: 'No token found');
      return;
    }

    final response = await http.post(
      Uri.parse('http://$ip:3000/auth/tasks'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'plusCode': addressx,
        'title': title,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      Fluttertoast.showToast(msg: 'Task created successfully');
      _titleController.clear();
      _descriptionController.clear();
      fetchUserTasks(); // Fetch the updated list of tasks
    } else {
      Fluttertoast.showToast(msg: 'Failed to create task: ${response.body}');
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

  void _checkForMatchingTask() {
    for (var task in userTasks) {
      if (addressx == task['plusCode']) {
        _saveNotification(task['id'], task['title']!, task['description']!);
        showNotification(task['title']!, task['description']!);
        break;
      }
    }
  }

  Future<void> _saveNotification(
      int taskId, String title, String description) async {
    final token = await storage.read(key: 'jwt');

    if (token == null) {
      Fluttertoast.showToast(msg: 'No token found');
      return;
    }

    final response = await http.post(
      Uri.parse('http://$ip:3000/auth/notifications'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'taskId': taskId,
        'title': title,
        'description': description,
      }),
    );

    if (response.statusCode != 201) {
      Fluttertoast.showToast(
          msg: 'Failed to save notification: ${response.body}');
    }
  }

  void _showUpgradeAlert() {
    showDialog(
      context: context,
      barrierDismissible: true, // Prevents dismissal by tapping outside
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
        _showUpgradeAlert();
      }
    });
  }

  void _showUpgradedAlert() {
    showDialog(
      context: context,
      barrierDismissible: true,
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
                'Premium Unlocked',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: const Text('You have already purchased RemindMy premium.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => home2()),
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
        _showUpgradeAlert();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
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
                    'Set your tasks',
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 25,
                    color: Colors.black,
                  ),
                  hintText: 'Search location',
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none, // Removes the default border
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFF5F33E2), // Outline color when focused
                      width: 5.0, // Outline width when focused
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.black, // Outline color when enabled
                      width: 4, // Outline width when enabled
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onSubmitted: (value) {
                  _searchAndNavigate(value);
                },
              ),
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition:
                    const CameraPosition(target: LatLng(0, 0), zoom: 2),
                markers: mylatlong != null
                    ? {
                        Marker(
                          infoWindow: InfoWindow(title: address),
                          position: mylatlong!,
                          draggable: true,
                          markerId: const MarkerId('1'),
                          onDragEnd: (value) {
                            setMarker(value);
                          },
                        ),
                      }
                    : {},
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  if (mylatlong != null) {
                    _mapController.animateCamera(
                        CameraUpdate.newLatLngZoom(mylatlong!, 14));
                  }
                },
                onTap: (value) {
                  setMarker(value);
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
            SlidingUpPanel(
              minHeight: 120,
              maxHeight: 420.0,
              panel: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Task Setup',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 36,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.edit,
                              color: Colors.black,
                            ),
                            hintText: 'Enter title for your task',
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide.none, // Removes the default border
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(
                                    0xFF5F33E2), // Outline color when focused
                                width: 5.0, // Outline width when focused
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color:
                                    Colors.black, // Outline color when enabled
                                width: 4, // Outline width when enabled
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.edit_document,
                              color: Colors.black,
                            ),
                            hintText: 'Enter description for your task',
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide.none, // Removes the default border
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(
                                    0xFF5F33E2), // Outline color when focused
                                width: 5.0, // Outline width when focused
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color:
                                    Colors.black, // Outline color when enabled
                                width: 4, // Outline width when enabled
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: ElevatedButton(
                          onPressed: _createTask,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF5F33E2),
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0)),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 16.0),
                          ),
                          child: const Text(
                            'Set Task',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: GestureDetector(
                          onTap: () {
                            if (userStatus != '1') {
                              showAlert(context);
                            } else {
                              _showUpgradedAlert();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 16.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDE496E),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Upgrade to Premium',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
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
                                    Icons.payments_outlined,
                                    color: Color(0xFFDE496E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              collapsed: Container(
                decoration: const BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SLIDE UP TO SET TASK',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
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
                                Icons.arrow_upward_outlined,
                                color: Colors.pink,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Address: ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: address,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  // Use your desired color for the address
                                  fontSize: 18,
                                  fontWeight: FontWeight
                                      .bold, // Adjust font weight as needed
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showNotification(String title, String body) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'RemindMy',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}

void showAlert(BuildContext context) {
  AlertDialog alert = AlertDialog(
    title: const Row(
      children: [
        Icon(Icons.payments_outlined,
            size: 40,
            color: Color(
              0xFF5F33E2,
            )),
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
    content: const Text('You have to upgrade RemindMy to set up more tasks.'),
    actions: [
      TextButton(
        child: const Text('OK'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => payments()),
        ),
      ),
      TextButton(
        child: const Text('CANCEL'),
        onPressed: () => Navigator.of(context).pop(),
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

  // Show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
