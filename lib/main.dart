import 'dart:async';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  return runApp(MaterialApp(
    home: BLEDevicesScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class BLEDevicesScreen extends StatefulWidget {
  @override
  _BLEDevicesScreenState createState() => _BLEDevicesScreenState();
}

class _BLEDevicesScreenState extends State<BLEDevicesScreen> {
  final flutterReactiveBle = FlutterReactiveBle();
  List<DiscoveredDevice> devices = [];
  List<String> deviceIdList = [];

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    _requestPermission().then((_) {
      devices.clear();
      deviceIdList.clear();
      flutterReactiveBle.scanForDevices(withServices: []).listen((device) {
        setState(() {
          if (!deviceIdList.contains(device.id)) {
            devices.add(device);
            deviceIdList.add(device.id);
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
        backgroundColor: const Color(0xFF145DA0),
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: startScan,
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: devices.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.black,
          height: 1,
        ),
        itemBuilder: (context, index) {
          return Container(
            color: const Color(0xFF2E8BC0),
            child: ListTile(
              title: Text(
                  devices[index].name.isEmpty
                      ? 'Unknown name'
                      : devices[index].name,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ID: ${devices[index].id}',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'RSSI: ${devices[index].rssi}',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          HomePage(deviceId: devices[index].id)),
                );
              },
            ),
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
  List<double> yValues = [];

  void addValue(double yValue) {
    setState(() {
      if (yValues.length >= 120) {
        yValues.removeAt(0);
      }
      yValues.add(yValue);
    });
  }

  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF145DA0), width: 3),
        borderRadius: BorderRadius.circular(50),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: LineChart(
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
              minX: 0,
              maxX: 120,
              clipData: const FlClipData.none(),
              titlesData: const FlTitlesData(
                show: false,
              ),
              gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true),
              borderData: FlBorderData(
                  show: false,
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  )),
              backgroundColor: const Color(0xFFB6D7F6),
              lineTouchData: LineTouchData(enabled: false)),
        ),
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
  final DynamicLineChart dynamicLineChart = DynamicLineChart();

  String tempData = 'Loading...';
  String spoData = 'Loading...';
  double ecgData = 0;

  final flutterReactiveBle = FlutterReactiveBle();

  final tempServiceUuid = Uuid.parse('00001809-0000-1000-8000-00805f9b34fb');
  final ecgServiceUuid = Uuid.parse('123e4567-e89b-12d3-a456-426614174000');

  final tempCharacteristicUuid =
      Uuid.parse('00002a1c-0000-1000-8000-00805f9b34fb');
  final ecgCharacteristicUuid =
      Uuid.parse('123e4567-e89b-12d3-a456-426614174001');

  void connectAndSubscribe() {
    flutterReactiveBle
        .connectToDevice(
      id: widget.deviceId,
      connectionTimeout: const Duration(seconds: 35),
    )
        .listen((connectionState) {
      if (connectionState.toString() == "connected") {
        subscribeToCharacteristic();
      } else if (connectionState.toString() == "disconnected") {
        // TODO
      }
    }, onError: (Object error) {
      // TODO
    });
  }

  void subscribeToCharacteristic() {
    final tempCharacteristic = QualifiedCharacteristic(
        characteristicId: tempCharacteristicUuid,
        serviceId: tempServiceUuid,
        deviceId: widget.deviceId);
    final ecgCharacteristic = QualifiedCharacteristic(
        characteristicId: ecgCharacteristicUuid,
        serviceId: ecgServiceUuid,
        deviceId: widget.deviceId);

    flutterReactiveBle
        .subscribeToCharacteristic(tempCharacteristic)
        .listen((data) {
      setState(() {
        tempData = _bytesToFloat(data).toStringAsFixed(2);
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
        title: const Text('Vital parameters'),
        backgroundColor: const Color(0xFF145DA0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[              
              Card(
                color: const Color(0xFF499CE9),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Image.asset('assets/images/thermometer.png'),
                    title: Text(
                      'Temperature: $tempData °C',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
              // Card(
              //   color: const Color(0xFF499CE9),
              //   child: Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: ListTile(
              //       leading: Image.asset('assets/images/heart.png'),
              //       title: Text(
              //         'HR: $hrData BPM',
              //         style: TextStyle(color: Colors.white, fontSize: 16),
              //       ),
              //     ),
              //   ),
              // ),
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
