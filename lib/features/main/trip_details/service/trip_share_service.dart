import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';

class TripShareService {
  static Future<bool> share({required String bookingId, required String pickup, required String dropoff}) async {
    if (bookingId.isEmpty) return false;

    try {
      final response = await Get.find<ApiService>().get(AppEndpoints.globalTrack(bookingId), requiresToken: true);
      if (response.statusCode != 200 || response.data['success'] != true) {
        return false;
      }

      final Map data = response.data['data'] is Map ? response.data['data'] as Map : const {};
      final String url = (data['publicTrackingUrl'] ?? '').toString().trim();
      if (url.isEmpty) {
        return false;
      }

      String text(dynamic v, String fallback) {
        final s = v?.toString().trim() ?? '';
        return s.isEmpty ? fallback : s;
      }

      final Map driver = data['driver'] is Map ? data['driver'] as Map : const {};
      final String from = text(data['pickupAddress'], pickup);
      final String to = text(data['dropoffAddress'], dropoff);
      final String driverName = text(driver['name'], '');
      final String vehicle = [
        text(driver['vehicleName'], ''),
        text(driver['vehicleNumber'], ''),
      ].where((e) => e.isNotEmpty).join(' · ');

      final double? km = double.tryParse(data['distanceKm']?.toString() ?? '');
      final int? mins = double.tryParse(data['durationMin']?.toString() ?? '')?.round();

      final message = StringBuffer()
        ..writeln('Track my Orange Taxi trip 🚕')
        ..writeln()
        ..writeln('From: $from')
        ..writeln('To: $to');

      if (driverName.isNotEmpty) message.writeln('Driver: $driverName${vehicle.isEmpty ? '' : ' ($vehicle)'}');
      if (km != null && km > 0) {
        message.writeln('Distance: ${km.toStringAsFixed(1)} km${mins != null && mins > 0 ? ' · $mins min' : ''}');
      }
      message
        ..writeln()
        ..writeln('Live track: $url');

      await SharePlus.instance.share(ShareParams(text: message.toString(), subject: 'My Orange Taxi trip'));
      return true;
    } catch (e) {
      return false;
    }
  }
}
