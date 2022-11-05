import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:qr_code/constants/constants.dart';
import 'package:qr_code/model/qr_model.dart';
import 'package:qr_code/provider/qrcode_provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<Session?> getInitialAuthState() async {
  try {
    final initialSession = await SupabaseAuth.instance.initialSession;

    // Redirect users to different screens depending on the initial session
    if (initialSession == null) {
      // No session found, redirect to login
      log('No session found, redirect to login');
      return null;
    } else {
      // Session found, redirect to home
      log('Session found, redirect to home');
      return initialSession;
    }
  } catch (e) {
    // Handle initial auth state fetch error here
    log('Handle initial auth state fetch error here');
    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: projectURL,
    anonKey: apiKey,
  );
  await Hive.initFlutter();
  Hive.registerAdapter(QrResultsAdapter());
  Session? session = await getInitialAuthState();
  Box? box = await Hive.openBox('qrResults');
  runApp(
    ChangeNotifierProvider(
      create: (context) => QrResultsProvider(),
      child: MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: Colors.red,
        ),
        home: MyHome(
          session: session,
          box: box,
        ),
      ),
    ),
  );
}

class MyHome extends StatefulWidget {
  const MyHome({Key? key, this.session, this.box}) : super(key: key);
  final Session? session;
  final Box? box;
  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  late TextEditingController _emailcontroller;
  late TextEditingController _passwordcontroller;
  @override
  void initState() {
    super.initState();

    _emailcontroller = TextEditingController();
    _passwordcontroller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QrResultsProvider>().openBox(widget.box);
    });
  }

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          Session? session = snapshot.data?.session;
          return Scaffold(
            appBar: AppBar(
                centerTitle: true,
                title: const Text('QR Code Scanner App'),
                actions: [
                  IconButton(
                    onPressed: () {
                      context.read<QrResultsProvider>().clearQrResults();
                      setState(() {});
                    },
                    icon: const Icon(Icons.delete),
                  ),
                  Visibility(
                    visible: session != null,
                    child: IconButton(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                      },
                      icon: const Icon(Icons.logout),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(40),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Visibility(
                      visible: session != null,
                      replacement: const Text(
                        'Please authenticate to continue',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      child: Text(
                        session?.user.email ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: session == null
                  ? Form(
                      key: _formKey,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Welcome to QR Code Scanner App'),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _emailcontroller,
                              decoration: const InputDecoration(
                                hintText: 'Email',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _passwordcontroller,
                              decoration: const InputDecoration(
                                hintText: 'Password',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(
                              height: 50,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      if (session == null) {
                                        if (_formKey.currentState!.validate()) {
                                          try {
                                            final AuthResponse res =
                                                await Supabase
                                                    .instance.client.auth
                                                    .signUp(
                                              email: _emailcontroller.text,
                                              password:
                                                  _passwordcontroller.text,
                                            );

                                            final User? user = res.user;
                                            log('user: $user');
                                            Future.delayed(
                                                Duration.zero,
                                                () => ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Welcome ${user!.email}')),
                                                    ));
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Error: ${e.toString()}')),
                                            );
                                          }
                                        } else {
                                          log('invalid form');
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Please enter correct details')),
                                          );
                                        }
                                      } else {
                                        Supabase.instance.client.auth.signOut();
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          'Sign Up',
                                          style: TextStyle(),
                                        ),
                                        Icon(Icons.login_outlined),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      if (session == null) {
                                        if (_formKey.currentState!.validate()) {
                                          try {
                                            final AuthResponse res =
                                                await Supabase
                                                    .instance.client.auth
                                                    .signInWithPassword(
                                              email: _emailcontroller.text,
                                              password:
                                                  _passwordcontroller.text,
                                            );

                                            final User? user = res.user;
                                            log('user: $user');
                                            Future.delayed(
                                                Duration.zero,
                                                () => ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Welcome ${user!.email}')),
                                                    ));
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Error: ${e.toString()}')),
                                            );
                                          }
                                        } else {
                                          log('invalid form');
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Please enter correct details')),
                                          );
                                        }
                                      } else {
                                        Supabase.instance.client.auth.signOut();
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          'Login',
                                        ),
                                        Icon(Icons.login_outlined),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ValueListenableBuilder<Box<dynamic>>(
                      valueListenable: Hive.box('qrResults').listenable(),
                      builder: (context, box, child) {
                        final qrResults = <QrResults>[...box.values.first];

                        if (qrResults.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                        builder: (context) =>
                                            const QRViewExample(),
                                      ));
                                    },
                                    child: const Text('Scan QR Code View',
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text('No QR Code Scanned',
                                    style:
                                        Theme.of(context).textTheme.headline6),
                              ],
                            ),
                          );
                        } else {
                          return SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                        builder: (context) =>
                                            const QRViewExample(),
                                      ));
                                    },
                                    child: const Text(
                                      'Scan QR Code View',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                const SizedBox(height: 20),
                                const Text('Past Results',
                                    style: TextStyle(fontSize: 20)),
                                const SizedBox(height: 20),
                                Table(
                                  defaultColumnWidth:
                                      const FixedColumnWidth(120.0),
                                  columnWidths: const <int, TableColumnWidth>{
                                    0: FixedColumnWidth(40.0),
                                    1: FixedColumnWidth(200.0),
                                    2: FixedColumnWidth(100.0),
                                  },
                                  border: TableBorder.all(
                                      color: Colors.black,
                                      style: BorderStyle.solid,
                                      width: 2),
                                  children: [
                                    const TableRow(children: [
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('No.'),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Center(child: Text('Data')),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Type'),
                                      ),
                                    ]),
                                    for (var i in qrResults)
                                      TableRow(children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                              '${qrResults.indexOf(i) + 1}'),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('${i.code}'),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('${i.format}'),
                                        ),
                                      ]),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                      }),
            ),
          );
        });
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text(
                        'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
                  else
                    const Text('Scan a code'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.toggleFlash();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getFlashStatus(),
                              builder: (context, snapshot) {
                                return Text('Flash: ${snapshot.data}');
                              },
                            )),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.flipCamera();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getCameraInfo(),
                              builder: (context, snapshot) {
                                if (snapshot.data != null) {
                                  return Text(
                                      'Camera facing ${describeEnum(snapshot.data!)}');
                                } else {
                                  return const Text('loading');
                                }
                              },
                            )),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.pauseCamera();
                          },
                          child: const Text('pause',
                              style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.resumeCamera();
                          },
                          child: const Text('resume',
                              style: TextStyle(fontSize: 20)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    final QrResultsProvider provider = context.read<QrResultsProvider>();
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      final qrResults = QrResults.fromJson({
        'code': scanData.code,
        'format': describeEnum(scanData.format),
      }).toJson().toString();

      if (provider.qrResults.isNotEmpty) {
        for (QrResults value in provider.qrResults) {
          if (!(value.code!.contains(scanData.code ?? ''))) {
            provider.addQrResults(QrResults.fromJson({
              'code': scanData.code,
              'format': describeEnum(scanData.format),
            }));

            log(
              qrResults,
              name: 'QrResults',
            );
          } else {
            log(
              qrResults,
              name: 'Already Scanned',
            );
          }
        }
      } else {
        provider.addQrResults(QrResults.fromJson({
          'code': scanData.code,
          'format': describeEnum(scanData.format),
        }));

        log(
          qrResults,
          name: 'QrResults',
        );
      }

      setState(() {
        result = scanData;
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
