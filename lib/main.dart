import 'dart:async';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          if (!devices.contains(device)) {
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
          content: const Text(
              'This app needs location permission to scan for BLE devices.'),
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
                MaterialPageRoute(
                    builder: (context) =>
                        HomePage(deviceId: devices[index].id)),
              );
            },
          );
        },
      ),
    );
  }
}

class DynamicLineChart extends StatefulWidget {
  DynamicLineChart({Key? key}) : super(key: key);

  final _DynamicLineChartState _dynamicLineChartState =
      _DynamicLineChartState();

  _DynamicLineChartState createState() => _dynamicLineChartState;

  void addValue(double value) => _dynamicLineChartState.addValue(value);
}

class _DynamicLineChartState extends State<DynamicLineChart> {
  List<double> yValues = [
    -1245181,
    -917503,
    -1114112,
    -1114111,
    -917503,
    -1245182,
    -983037,
    -1179646,
    -1179646,
    -983037,
    -1245182,
    -1048575,
    -1114109,
    -1310717,
    -917504,
    -1310717,
    -1048575,
  ];

  void addValue(double yValue) {
    setState(() {
      if (yValues.length == 120) {
        yValues.clear();
      }
      yValues.add(yValue);
    });
  }

  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
          lineBarsData: [
            LineChartBarData(
                show: true,
                barWidth: 3,
                spots: yValues.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value);
                }).toList(),
                color: Colors.red,
                dotData: FlDotData(show: false)),
          ],
          minY: -1570000,
          maxY: -327000,
          titlesData: const FlTitlesData(
            show: false,
          ),
          gridData: const FlGridData(
              show: true, drawVerticalLine: false, drawHorizontalLine: true),
          borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: Colors.black,
                width: 2,
              )),
          backgroundColor: const Color.fromARGB(255, 214, 214, 214),
          lineTouchData: LineTouchData(enabled: false)),
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
  final DynamicLineChart dynamicLineChart = DynamicLineChart();

  String xData = 'Loading...';
  String yData = 'Loading...';
  String zData = 'Loading...';
  String tempData = 'Loading...';
  String spoData = 'Loading...';
  double ecgData = 0;

  final flutterReactiveBle = FlutterReactiveBle();

  final gyroServiceUuid = Uuid.parse('082b91ae-e83c-11e8-9f32-f2801f1b9fd1');
  final tempServiceUuid = Uuid.parse('00001809-0000-1000-8000-00805F9B34FB');
  final spoServiceUuid = Uuid.parse('00001822-0000-1000-8000-00805F9B34FB');
  final ecgServiceUuid = Uuid.parse('123e4567-e89b-12d3-a456-426614174000');

  final xCharacteristicUuid =
      Uuid.parse('082b9438-e83c-11e8-9f32-f2801f1b9fd1');
  final yCharacteristicUuid =
      Uuid.parse('082b9622-e83c-11e8-9f32-f2801f1b9fd1');
  final zCharacteristicUuid =
      Uuid.parse('082b976c-e83c-11e8-9f32-f2801f1b9fd1');
  final tempCharacteristicUuid =
      Uuid.parse('00002A1C-0000-1000-8000-00805F9B34FB');
  final spoCharacteristicUuid =
      Uuid.parse('00002A5F-0000-1000-8000-00805F9B34FB');
  final ecgCharacteristicUuid =
      Uuid.parse('123e4567-e89b-12d3-a456-426614174001');

  void connectAndSubscribe() {
    flutterReactiveBle.connectToDevice(
        id: widget.deviceId,
        /* servicesWithCharacteristicsToDiscover: {
          Uuid.parse('123e4567-e89b-12d3-a456-426614174000'): [ // ECG Service
            Uuid.parse('123e4567-e89b-12d3-a456-426614174001') // ECG Characteristic
          ],
          Uuid.parse('00001809-0000-1000-8000-00805F9B34FB'): [ // Temperature Service
            Uuid.parse('00002A1C-0000-1000-8000-00805F9B34FB')
          ],
          Uuid.parse('082b91ae-e83c-11e8-9f32-f2801f1b9fd1'): [ // Gyro Service
            Uuid.parse('082b9438-e83c-11e8-9f32-f2801f1b9fd1'), // X Characteristic
            Uuid.parse('082b9622-e83c-11e8-9f32-f2801f1b9fd1'), // Y Characteristic
            Uuid.parse('082b976c-e83c-11e8-9f32-f2801f1b9fd1') // Z Characteristic
          ]
        }, */
        connectionTimeout: const Duration(seconds: 10),
        ).listen((connectionState) {
          if(connectionState.toString() == "connected") {
            subscribeToCharacteristic();
          } else if (connectionState.toString() == "disconnected") {
            // TODO
          }
        }, onError: (Object error) {
          // TODO
        });
  }

  void subscribeToCharacteristic() {
    // final xCharacteristic = QualifiedCharacteristic(
    //     characteristicId: xCharacteristicUuid,
    //     serviceId: tempServiceUuid,
    //     deviceId: widget.deviceId);
    // final yCharacteristic = QualifiedCharacteristic(
    //     characteristicId: yCharacteristicUuid,
    //     serviceId: tempServiceUuid,
    //     deviceId: widget.deviceId);
    // final zCharacteristic = QualifiedCharacteristic(
    //     characteristicId: zCharacteristicUuid,
    //     serviceId: tempServiceUuid,
    //     deviceId: widget.deviceId);
    final tempCharacteristic = QualifiedCharacteristic(
        characteristicId: tempCharacteristicUuid,
        serviceId: tempServiceUuid,
        deviceId: widget.deviceId);
    final ecgCharacteristic = QualifiedCharacteristic(
        characteristicId: ecgCharacteristicUuid,
        serviceId: ecgServiceUuid,
        deviceId: widget.deviceId);
    /*final spoCharacteristic = QualifiedCharacteristic(
        characteristicId: spoCharacteristicUuid,
        serviceId: spoServiceUuid,
        deviceId: widget.deviceId);*/

    
    // flutterReactiveBle
    //     .subscribeToCharacteristic(xCharacteristic)
    //     .listen((data) {
    //   setState(() {
    //     xData = _bytesToFloat(data).toString();
    //   });
    // });
    // flutterReactiveBle
    //     .subscribeToCharacteristic(yCharacteristic)
    //     .listen((data) {
    //   setState(() {
    //     yData = _bytesToFloat(data).toString();
    //   });
    // });
    // flutterReactiveBle
    //     .subscribeToCharacteristic(zCharacteristic)
    //     .listen((data) {
    //   setState(() {
    //     zData = _bytesToFloat(data).toString();
    //   });
    // });
    flutterReactiveBle
        .subscribeToCharacteristic(tempCharacteristic)
        .listen((data) {
      setState(() {
        tempData = _bytesToFloat(data).toString();
      });
    });
    flutterReactiveBle
        .subscribeToCharacteristic(ecgCharacteristic)
        .listen((data) {
      setState(() {
        dynamicLineChart.addValue(_bytesToFloat(data));
        spoData = _bytesToFloat(data).toString();
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
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Card(
              //   child: ListTile(
              //     title: Text('X: $xData'),
              //   ),
              // ),
              // Card(
              //   child: ListTile(
              //     title: Text('Y: $yData'),
              //   ),
              // ),
              // Card(
              //   child: ListTile(
              //     title: Text('Z: $zData'),
              //   ),
              // ),
              Card(
                child: ListTile(
                  title: Text('Temp: $tempData'),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text('ECG: $spoData'),
                ),
              ),
              SizedBox(
                height: 300,
                width: 400,
                child: dynamicLineChart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
