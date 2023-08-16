import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),   debugShowCheckedModeBanner  : false,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String value = "LOW";
  List<ScanResult> _scanResults = [];
  late BluetoothCharacteristic targetCharacteristic;
  final targetCharacteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");


  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    if (_counter % 2 == 0) {
      startBlue();
    } else {
      // stopScan();
    }
  }

  @override
  void initState() {
    // check adapter availability
    startScan();
    super.initState();
  }

  void startScan() async {
    if (await FlutterBluePlus.isAvailable == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    await FlutterBluePlus.adapterState
        .map((s) {
          print(s);
          return s;
        })
        .where((s) => s == BluetoothAdapterState.on)
        .first;

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        print('${r.device.localName} found! rssi: ${r.rssi}');
        if (!_scanResults.any((element) => element.device.id == r.device.id)) {
          setState(() {
            _scanResults.add(r);
          });
        }
      }
    });

    startBlue();
  }

  void startBlue() async {
    FlutterBluePlus.startScan(
        timeout: const Duration(
          seconds: 30,
        ),
        androidUsesFineLocation: true);
  }

  void stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  @override
  void dispose() {
    stopScan();
    super.dispose();
  }

  Future<void> connectToDeviceAndSendData(BluetoothDevice device) async {
    // Connect to the device
    await device.connect();

    // Discover services
    final services = await device.discoverServices();

    // Find the target characteristic
   
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid == targetCharacteristicUuid) {
          targetCharacteristic = characteristic;
          break;
        }
      }
    }
 


    // Write data to the characteristic
    final random = Random();
    String mode = random.nextBool() ? 'HIGH' : 'LOW';
    final data = utf8.encode(mode);
    setState(() {
      value = mode;
    });
    await targetCharacteristic.write(data);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: screenHeight / 2,
              child: ListView.builder(
                itemCount: _scanResults.length,
                itemBuilder: (context, index) {
                  final device = _scanResults[index].device;
                  return ListTile(
                    title: Text(device.name),
                    subtitle: Text(device.id.toString()),
                    onTap: () => connectToDeviceAndSendData(device),
                  );
                },
              ),
            ),
            Flexible(
              child: Center(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
