import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Blue Example', style: GoogleFonts.acme()),
        ),
        body: BluetoothScreen(),
      ),
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!devicesList.contains(r.device)) {
          setState(() {
            devicesList.add(r.device);
          });
        }
      }
    });

    flutterBlue.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: devicesList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(devicesList[index].name),
          subtitle: Text(devicesList[index].id.toString()),
          onTap: () async {
            await devicesList[index].connect();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceScreen(device: devicesList[index]),
              ),
            );
          },
        );
      },
    );
  }
}

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  DeviceScreen({required this.device});

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  List<BluetoothService> services = [];
  BluetoothCharacteristic? characteristic;

  @override
  void initState() {
    super.initState();
    discoverServices();
  }

  void discoverServices() async {
    services = await widget.device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.properties.read) {
          setState(() {
            characteristic = c;
          });
        }
      }
    }
  }

  void readData() async {
    if (characteristic != null) {
      var value = await characteristic!.read();
      print('Read value: $value');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: readData,
          child: Text('Read Data'),
        ),
      ),
    );
  }
}