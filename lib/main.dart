import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  return runApp(MaterialApp(home: BLEDevicesScreen()));
}

class BLEDevicesScreen extends StatefulWidget {
  @override
  _BLEDevicesScreenState createState() => _BLEDevicesScreenState();
}

class _BLEDevicesScreenState extends State<BLEDevicesScreen> {
  final flutterReactiveBle = FlutterReactiveBle();
  List<DiscoveredDevice> devices = [];

  @override
  void initState() {
    super.initState();
    _requestPermission().then((_) {
      flutterReactiveBle.scanForDevices(withServices: []).listen((device) {
        setState(() {
          if(!devices.contains(device)) {
            devices.add(device);
          }
        });
      });
    });
  }

  Future<void> _requestPermission() async {
    if (await Permission.location.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Location Permission'),
          content: const Text('This app needs location permission to scan for BLE devices.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Devices'),
      ),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(devices[index].name),
            subtitle: Text(devices[index].id),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage(deviceId: devices[index].id)),
              );
            },
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String deviceId;

  const HomePage({Key? key, required this.deviceId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String xData = 'Loading...';
  String yData = 'Loading...';
  String zData = 'Loading...';
  String tempData = 'Loading...';
  String spoData = 'Loading...';

  final flutterReactiveBle = FlutterReactiveBle();

  final serviceUuid = Uuid.parse('082b91ae-e83c-11e8-9f32-f2801f1b9fd1');
  final tempServiceUuid = Uuid.parse('00001809-0000-1000-8000-00805F9B34FB');
  final spoServiceUuid = Uuid.parse('00001822-0000-1000-8000-00805F9B34FB');

  final xCharacteristicUuid =
      Uuid.parse('082b9438-e83c-11e8-9f32-f2801f1b9fd1');
  final yCharacteristicUuid =
      Uuid.parse('082b9622-e83c-11e8-9f32-f2801f1b9fd1');
  final zCharacteristicUuid =
      Uuid.parse('082b976c-e83c-11e8-9f32-f2801f1b9fd1');
  final tempCharacteristicUuid = Uuid.parse('00002A1C-0000-1000-8000-00805F9B34FB');
  final spoCharacteristicUuid = Uuid.parse('00002A5F-0000-1000-8000-00805F9B34FB');

  void subscribeToCharacteristic() {
    final xCharacteristic = QualifiedCharacteristic(
        characteristicId: xCharacteristicUuid,
        serviceId: serviceUuid,
        deviceId: widget.deviceId);
    final yCharacteristic = QualifiedCharacteristic(
        characteristicId: yCharacteristicUuid,
        serviceId: serviceUuid,
        deviceId: widget.deviceId);
    final zCharacteristic = QualifiedCharacteristic(
        characteristicId: zCharacteristicUuid,
        serviceId: serviceUuid,
        deviceId: widget.deviceId);
    final tempCharacteristic = QualifiedCharacteristic(
        characteristicId: tempCharacteristicUuid,
        serviceId: tempServiceUuid,
        deviceId: widget.deviceId);
    /*final spoCharacteristic = QualifiedCharacteristic(
        characteristicId: spoCharacteristicUuid,
        serviceId: spoServiceUuid,
        deviceId: widget.deviceId);*/

    flutterReactiveBle
        .subscribeToCharacteristic(xCharacteristic)
        .listen((data) {
        setState(() {
          xData = _bytesToFloat(data).toString();
        });
    });
    flutterReactiveBle
        .subscribeToCharacteristic(yCharacteristic)
        .listen((data) {
        setState(() {
          yData = _bytesToFloat(data).toString();
        });
    });
    flutterReactiveBle
        .subscribeToCharacteristic(zCharacteristic)
        .listen((data) {
        setState(() {
          zData = _bytesToFloat(data).toString();
        });
    });
    flutterReactiveBle
        .subscribeToCharacteristic(tempCharacteristic)
        .listen((data) {
        setState(() {
          tempData = _bytesToFloat(data).toString();
        });
    });
    /*
    flutterReactiveBle
        .subscribeToCharacteristic(spoCharacteristic)
        .listen((data) {
        setState(() {
          spoData = _bytesToFloat(data).toString();
        });
    });
    */
  }

  double _bytesToFloat(List<int> data) {
    final buffer = ByteData(4);
    for (var i = 0; i < data.length; i++) {
      buffer.setUint8(i, data[i]);
    }
    return buffer.getFloat32(0, Endian.little);
  }

  @override
  void initState() {
    super.initState();
    subscribeToCharacteristic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Characteristics display'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Card(
              child: ListTile(
                title: Text('X: $xData'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Y: $yData'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Z: $zData'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Temp: $tempData'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('SpO2: $spoData'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
