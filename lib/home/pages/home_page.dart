import 'dart:io';

import 'package:ble_scanner/enum/eddystone_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../helper/data_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ScanResult> devices = [];
  bool _isScanning = false;
  bool _bluetoothEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    if (_isScanning) return;

    final permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      return _showPermissionDeniedMessage();
    }

    await _checkBluetooth();
    if (_bluetoothEnabled) {
      _startScan();
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    }
    return await _requestiOSPermissions();
  }

  Future<bool> _requestAndroidPermissions() async {
    // TODO: Implement Android permissions request.
    return true;
  }

  Future<bool> _requestiOSPermissions() async {
    // TODO: Implement iOS permissions request.
    return true;
  }

  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Permissions not granted. Cannot scan for devices.',
        ),
      ),
    );
  }

  Future<void> _checkBluetooth() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    final isBluetoothEnabled = adapterState == BluetoothAdapterState.on;
    if (!isBluetoothEnabled) {
      return _showBluetoothDisabledMessage();
    }
    setState(() {
      _bluetoothEnabled = isBluetoothEnabled;
    });
  }

  void _showBluetoothDisabledMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Bluetooth is required to scan for devices.',
        ),
      ),
    );
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      devices.clear();
    });

    const timeout = Duration(seconds: 20);
    await FlutterBluePlus.startScan(
      timeout: timeout,
      withNames: [],
      withServiceData: [],
      withMsd: [],
    );
    FlutterBluePlus.scanResults.listen(_filterBeacons);
  }

  Future<void> _filterBeacons(List<ScanResult> results) async {
    final newDevices = results.toSet().difference(devices.toSet()).toList();
    setState(() {
      _isScanning = false;
      devices.addAll(newDevices);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _initializeBluetooth(),
          ),
        ],
      ),
      body: _buildListWidget(),
    );
  }

  Widget _buildListWidget() {
    if (_isScanning) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final listItems = List<Widget>.from(
      devices
          .map((device) => _buildListItemsWidget(device))
          .where((item) => item != null),
    );
    if (listItems.isEmpty) {
      return const Center(
        child: Text('No devices found.'),
      );
    }

    return ListView(
      children: listItems,
    );
  }

  Widget? _buildListItemsWidget(ScanResult device) {
    final dataHelper = DataHelper();
    String? url;
    String? namespace;
    String? instanceId;
    String? eid;

    final advertisementData = device.advertisementData;
    final serviceData = advertisementData.serviceData;
    final isEddystoneFrame = dataHelper.identifyEddystoneFrame(
      serviceData: advertisementData.serviceData,
    );
    if (isEddystoneFrame == EddystoneType.url) {
      url = dataHelper.convertBytesToUrl(
        serviceData.entries.first.value,
      );
    }
    if (isEddystoneFrame == EddystoneType.uid) {
      final uid = dataHelper
          .convertBytesToUID(
            serviceData.entries.first.value,
          )
          .split(':');
      namespace = uid[0];
      instanceId = uid[1];
    }
    if (isEddystoneFrame == EddystoneType.eid) {
      eid = dataHelper.convertBytesToEID(
        serviceData.entries.first.value,
      );
    }
    final manufacturerData = dataHelper.getManufactureData(
      advertisementData.msd,
    );
    final uuid = dataHelper.getUUIDFromManufactureData(manufacturerData);
    final data = uuid ?? namespace ?? url ?? eid ?? "";
    if (data.isEmpty) return null;

    return ListTile(
      title: Text(
        data,
        style: const TextStyle(
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          instanceId != null
              ? Text(
                  "Instance ID: $instanceId",
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                )
              : const SizedBox.shrink(),
          Text(
            "Remote ID: ${device.device.remoteId.toString()}",
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: Text('RSSI: ${device.rssi}'),
    );
  }
}
