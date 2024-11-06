import 'package:flutter/material.dart';
import 'package:khalti/khalti.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/home1.dart';
import 'package:remindmy/address.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Khalti.init(
    publicKey: 'test_public_key_e46e3008fb0c40be91e630fface04353',
    enabledDebugging: false,
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: payments(),
      theme: ThemeData(primarySwatch: Colors.deepPurple),
    ),
  );
}

class payments extends StatelessWidget {
  payments({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Khalti Payment Gateway RM'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Wallet Payment'),
              Tab(text: 'EBanking'),
              Tab(text: 'MBanking'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WalletPayment(),
            Banking(paymentType: PaymentType.eBanking),
            Banking(paymentType: PaymentType.mobileCheckout),
          ],
        ),
      ),
    );
  }
}

class WalletPayment extends StatefulWidget {
  const WalletPayment({Key? key}) : super(key: key);

  @override
  State<WalletPayment> createState() => _WalletPaymentState();
}

class _WalletPaymentState extends State<WalletPayment> {
  late final TextEditingController _mobileController, _pinController;
  final GlobalKey<FormState> _formKey = GlobalKey();
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            validator: (v) => (v?.isEmpty ?? true) ? 'Required ' : null,
            decoration: const InputDecoration(
              label: Text('Mobile Number'),
            ),
            controller: _mobileController,
          ),
          TextFormField(
            validator: (v) => (v?.isEmpty ?? true) ? 'Required ' : null,
            decoration: const InputDecoration(
              label: Text('Khalti MPIN'),
            ),
            controller: _pinController,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              final messenger = ScaffoldMessenger.maybeOf(context);
              try {
                final initiationModel = await Khalti.service.initiatePayment(
                  request: PaymentInitiationRequestModel(
                    amount: 1000,
                    mobile: _mobileController.text,
                    productIdentity: 'RemindMy Freemium',
                    productName: 'Subscription',
                    transactionPin: _pinController.text,
                    productUrl: null,
                    additionalData: {
                      'vendor': 'RemindMyINC',
                      'manufacturer': 'RemindMyDev',
                    },
                  ),
                );

                final otpCode = await _showOTPSentDialog();

                if (otpCode != null) {
                  try {
                    final model = await Khalti.service.confirmPayment(
                      request: PaymentConfirmationRequestModel(
                        confirmationCode: otpCode,
                        token: initiationModel.token,
                        transactionPin: _pinController.text,
                      ),
                    );

                    debugPrint(model.toString());
                    _showSuccessDialog('Transaction Successful!');
                  } catch (e) {
                    _showErrorDialog(e.toString());
                    messenger?.showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              } catch (e) {
                _showErrorDialog(e.toString());
              }
            },
            child: const Text('PAY Rs. 1000'),
          ),
          const SizedBox(height: 50),
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/logo.png'),
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: const [
                  TextSpan(
                    text: 'RemindMy',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '™',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showOTPSentDialog() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String? otp;
        return AlertDialog(
          title: const Text('OTP Sent!'),
          content: TextField(
            decoration: const InputDecoration(
              label: Text('OTP Code'),
            ),
            onChanged: (v) => otp = v,
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context, otp),
            )
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline,
                size: 40,
                color: Color(
                  0xFF5F33E2,
                )),
            SizedBox(width: 10),
            Text(
              'Success',
              style: TextStyle(
                fontSize: 30,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () async {
              final date = DateTime.now().toIso8601String();
              setState(() {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const home1()),
                );
              });
              try {
                await PaymentService().storePayment(date);
              } catch (e) {
                // Handle the error, show a message, etc.
                print(e);
              }
            },
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        backgroundColor: Colors.white,
        elevation: 24.0,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dangerous_outlined,
                size: 40,
                color: Color(
                  0xFF5F33E2,
                )),
            SizedBox(width: 10),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 30,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        backgroundColor: Colors.white,
        elevation: 24.0,
      ),
    );
  }
}

class Banking extends StatefulWidget {
  const Banking({Key? key, required this.paymentType}) : super(key: key);

  final PaymentType paymentType;

  @override
  State<Banking> createState() => _BankingState();
}

class _BankingState extends State<Banking> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<BankListModel>(
      future: Khalti.service.getBanks(paymentType: widget.paymentType),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final banks = snapshot.data!.banks;
          return ListView.builder(
            itemCount: banks.length,
            itemBuilder: (context, index) {
              final bank = banks[index];

              return ListTile(
                leading: SizedBox.square(
                  dimension: 40,
                  child: Image.network(bank.logo),
                ),
                title: Text(bank.name),
                subtitle: Text(bank.shortName),
                onTap: () async {
                  final mobile = await showDialog<String>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      String? mobile;
                      return AlertDialog(
                        title: const Text('Enter Mobile Number'),
                        content: TextField(
                          decoration: const InputDecoration(
                            label: Text('Mobile Number'),
                          ),
                          onChanged: (v) => mobile = v,
                        ),
                        actions: [
                          SimpleDialogOption(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context, mobile),
                          )
                        ],
                      );
                    },
                  );

                  if (mobile != null) {
                    final url = Khalti.service.buildBankUrl(
                      bankId: bank.idx,
                      amount: 1000,
                      mobile: mobile,
                      productIdentity: 'RemindMy Freemium',
                      productName: 'Subscription',
                      paymentType: widget.paymentType,
                      returnUrl: 'https://khalti.com',
                    );

                    try {
                      url_launcher.launchUrl(Uri.parse(url));
                      _showSuccessDialog('Transaction Successful!');
                    } catch (e) {
                      _showErrorDialog('Transaction Failed!');
                    }
                  }
                },
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog first
              // Delay navigation to ensure the dialog has been dismissed
              Future.delayed(Duration(milliseconds: 300), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const home1()),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog first
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const home1()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class PaymentService {
  final storage = const FlutterSecureStorage();

  Future<void> storePayment(String date) async {
    final token = await storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.post(
      Uri.parse('http://$ip:3000/auth/payments'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'date': date,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to store payment: ${response.body}');
    }
  }
}
