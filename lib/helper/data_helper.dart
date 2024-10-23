import 'package:ble_scanner/enum/eddystone_type.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DataHelper {
  String _getHexArray(List<int> bytes) {
    final formattedBytes = bytes
        .map(
          (byte) => byte.toRadixString(16).padLeft(2, '0'),
        )
        .join(', ');

    return '[$formattedBytes]';
  }

  String? getManufactureData(List<List<int>> data) {
    if (data.isEmpty) return null;
    return data.map((val) => _getHexArray(val)).join(', ').toUpperCase();
  }

  String? getServiceData(Map<Guid, List<int>> data) {
    if (data.isEmpty) return null;
    return data.entries
        .map((v) => '${v.key}: ${_getHexArray(v.value)}')
        .join(', ')
        .toUpperCase();
  }

  String? getServiceUuids(List<Guid> serviceUuids) {
    if (serviceUuids.isEmpty) return null;
    return serviceUuids.join(', ').toUpperCase();
  }

  String? getUUIDFromManufactureData(String? manufactureData) {
    if (manufactureData == null || manufactureData.isEmpty) return null;
    final hexList =
        manufactureData.split(', ').map((hex) => hex.trim()).toList();
    if (hexList.length < 20) {
      return null;
    }
    final uuid = hexList.sublist(4, 20).join().toUpperCase();
    return '${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-${uuid.substring(12, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20)}';
  }

  EddystoneType? identifyEddystoneFrame({
    required Map<Guid, List<int>> serviceData,
  }) {
    if (serviceData.isEmpty) return null;
    if (serviceData.entries.isEmpty) return null;
    final bytes = serviceData.entries.first.value;

    if (bytes.length < 3) return null;

    if (bytes[0] == 16 &&
        bytes[1] == 238 &&
        [0, 1, 2, 3].contains(bytes[2]) &&
        bytes.length > 3) {
      return EddystoneType.url;
    }

    if (bytes[0] == 0 && bytes[1] == 238 && bytes.length >= 18) {
      return EddystoneType.uid;
    }

    if (bytes[0] == 48 && bytes[1] == 238 && bytes.length >= 10) {
      return EddystoneType.eid;
    }

    return null;
  }

  String convertBytesToUrl(List<int> bytes) {
    try {
      if (bytes.length < 3) return "";
      String prefix = "";
      if (bytes[2] == 0) prefix = 'http://www.';
      if (bytes[2] == 1) prefix = 'https://www.';
      if (bytes[2] == 2) prefix = 'http://';
      if (bytes[2] == 3) prefix = 'https://';

      List<int> urlBytes = bytes.sublist(3);
      String url = String.fromCharCodes(
        urlBytes.where(
          (byte) => byte >= 32,
        ),
      );

      return '$prefix$url';
    } catch (e) {
      return "";
    }
  }

  String convertBytesToUID(List<int> bytes) {
    String namespace = bytes
        .sublist(2, 12)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join('');

    String instance = bytes
        .sublist(12, 18)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join('');

    return '${namespace.toLowerCase()}:${instance.toLowerCase()}';
  }

  String convertBytesToEID(List<int> eidBytes) {
    String eid = eidBytes
        .sublist(2, 10)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join('');

    return eid;
  }
}
