import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';

class TripDetailsModel {
  final String? pickupLocation;
  final String? destinationLocation;
  final DateTime? pickupDateTime;
  final DateTime? dropDateTime;
  final double? distanceInKm;
  final double? tripCompletedDistance;
  final double? pricePerKm;
  final String? vehicleType;
  final String? vehicleModel;
  final String? driverName;
  final String? driverImage;
  final String? plateNumber;
  final String? startOtp;
  final String? passengerName;
  final String? passengerPhone;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final String? bookingId;
  final String? status;
  final String? duration;
  final double? finalAmount;
  final double? customerFinalAmount;
  final double? tripCompletedFinalAmount;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? driverPhone;
  final double? driverRating;
  final String? driverTrips;
  final String? arrivalTime;
  final String? distanceLeft;
  final double? totalFare;
  final double? estimatedFare;
  final double? serviceTax;
  final double? tollAmount;
  final double? tipsAmount;
  final double? permitCharges;
  final double? discountAmount;
  final double? driverAllowance;
  final double? totalDriverCharges;
  final double? totalExtraCharges;
  final double? advanceAmount;
  final String? endOtp;
  final Map<String, dynamic>? extraCharges;
  final String? cancellationReason;
  final List<Map<String, dynamic>>? stops;

  final bool? isRoundTrip;
  final int? currentLeg;
  final String? originalPickupAddress;
  final double? originalPickupLat;
  final double? originalPickupLng;
  final DateTime? haltStartedAt;

  TripDetailsModel({
    this.stops,
    this.isRoundTrip,
    this.currentLeg,
    this.haltStartedAt,
    this.originalPickupAddress,
    this.originalPickupLat,
    this.originalPickupLng,
    this.pickupLocation,
    this.destinationLocation,
    this.pickupDateTime,
    this.dropDateTime,
    this.distanceInKm,
    this.tripCompletedDistance,
    this.pricePerKm,
    this.vehicleType,
    this.vehicleModel,
    this.driverName,
    this.driverImage,
    this.plateNumber,
    this.startOtp,
    this.passengerName,
    this.passengerPhone,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.bookingId,
    this.status,
    this.duration,
    this.finalAmount,
    this.customerFinalAmount,
    this.tripCompletedFinalAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.driverPhone,
    this.driverRating,
    this.driverTrips,
    this.arrivalTime,
    this.distanceLeft,
    this.totalFare,
    this.estimatedFare,
    this.serviceTax,
    this.tollAmount,
    this.tipsAmount,
    this.permitCharges,
    this.discountAmount,
    this.driverAllowance,
    this.totalDriverCharges,
    this.totalExtraCharges,
    this.advanceAmount,
    this.endOtp,
    this.extraCharges,
    this.cancellationReason,
  });

  TripDetailsModel copyWith({
    String? pickupLocation,
    String? destinationLocation,
    DateTime? pickupDateTime,
    DateTime? dropDateTime,
    double? distanceInKm,
    double? tripCompletedDistance,
    double? pricePerKm,
    String? vehicleType,
    String? vehicleModel,
    String? driverName,
    String? driverImage,
    String? plateNumber,
    String? startOtp,
    String? passengerName,
    String? passengerPhone,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    String? bookingId,
    String? status,
    String? duration,
    double? finalAmount,
    double? customerFinalAmount,
    double? tripCompletedFinalAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? driverPhone,
    double? driverRating,
    String? driverTrips,
    String? arrivalTime,
    String? distanceLeft,
    double? totalFare,
    double? estimatedFare,
    double? serviceTax,
    double? tollAmount,
    double? tipsAmount,
    double? permitCharges,
    double? discountAmount,
    double? driverAllowance,
    double? totalDriverCharges,
    double? totalExtraCharges,
    double? advanceAmount,
    String? endOtp,
    Map<String, dynamic>? extraCharges,
    String? cancellationReason,
    List<Map<String, dynamic>>? stops,
    bool? isRoundTrip,
    int? currentLeg,
    DateTime? haltStartedAt,
    bool clearHalt = false,
    bool clearEndOtp = false,
    String? originalPickupAddress,
    double? originalPickupLat,
    double? originalPickupLng,
  }) {
    return TripDetailsModel(
      stops: stops ?? this.stops,
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
      currentLeg: currentLeg ?? this.currentLeg,
      haltStartedAt: clearHalt ? null : (haltStartedAt ?? this.haltStartedAt),
      originalPickupAddress: originalPickupAddress ?? this.originalPickupAddress,
      originalPickupLat: originalPickupLat ?? this.originalPickupLat,
      originalPickupLng: originalPickupLng ?? this.originalPickupLng,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      pickupDateTime: pickupDateTime ?? this.pickupDateTime,
      dropDateTime: dropDateTime ?? this.dropDateTime,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      tripCompletedDistance: tripCompletedDistance ?? this.tripCompletedDistance,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      driverName: driverName ?? this.driverName,
      driverImage: driverImage ?? this.driverImage,
      plateNumber: plateNumber ?? this.plateNumber,
      startOtp: startOtp ?? this.startOtp,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      bookingId: bookingId ?? this.bookingId,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      finalAmount: finalAmount ?? this.finalAmount,
      customerFinalAmount: customerFinalAmount ?? this.customerFinalAmount,
      tripCompletedFinalAmount: tripCompletedFinalAmount ?? this.tripCompletedFinalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      driverPhone: driverPhone ?? this.driverPhone,
      driverRating: driverRating ?? this.driverRating,
      driverTrips: driverTrips ?? this.driverTrips,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      distanceLeft: distanceLeft ?? this.distanceLeft,
      totalFare: totalFare ?? this.totalFare,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      serviceTax: serviceTax ?? this.serviceTax,
      tollAmount: tollAmount ?? this.tollAmount,
      tipsAmount: tipsAmount ?? this.tipsAmount,
      permitCharges: permitCharges ?? this.permitCharges,
      discountAmount: discountAmount ?? this.discountAmount,
      driverAllowance: driverAllowance ?? this.driverAllowance,
      totalDriverCharges: totalDriverCharges ?? this.totalDriverCharges,
      totalExtraCharges: totalExtraCharges ?? this.totalExtraCharges,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      endOtp: clearEndOtp ? null : (endOtp ?? this.endOtp),
      extraCharges: extraCharges ?? this.extraCharges,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  factory TripDetailsModel.empty() {
    return TripDetailsModel();
  }

  factory TripDetailsModel.dummy() {
    return TripDetailsModel(
      pickupLocation: '0',
      destinationLocation: '00',
      pickupDateTime: DateTime.now(),
      dropDateTime: DateTime.now(),
      distanceInKm: 0.0,
      vehicleType: '0',
      vehicleModel: '0',
      driverName: '0',
      driverImage: '',
      plateNumber: '0',
      startOtp: '0',
      passengerName: '0',
      passengerPhone: '0',
      bookingId: '0',
      status: '0',
      duration: '0 m',
      finalAmount: 0,
      paymentMethod: '0',
      paymentStatus: 'Unpaid',
      driverPhone: '+91 1234567890',
      driverRating: 0.0,
      driverTrips: '0 trips',
      arrivalTime: '0 min',
      distanceLeft: '0 km',
      totalFare: 0,
      advanceAmount: 0,
      endOtp: '0',
      extraCharges: {},
    );
  }

  factory TripDetailsModel.fromJson(Map<String, dynamic> json) {
    return TripDetailsModel(
      pickupLocation: json['pickupLocation'],
      destinationLocation: json['destinationLocation'],
      pickupDateTime: json['pickupDateTime'] != null ? DateTime.tryParse(json['pickupDateTime']) : null,
      dropDateTime: json['dropDateTime'] != null ? DateTime.tryParse(json['dropDateTime']) : null,
      distanceInKm: json['distanceInKm']?.toDouble(),
      tripCompletedDistance: json['tripCompletedDistance']?.toDouble(),
      pricePerKm: json['pricePerKm']?.toDouble(),
      vehicleType: json['vehicleType'],
      vehicleModel: json['vehicleModel'],
      driverName: json['driverName'],
      driverImage: json['driverImage'],
      plateNumber: json['plateNumber'],
      startOtp: json['startOtp'],
      passengerName: json['passengerName'],
      passengerPhone: json['passengerPhone'],
      pickupLat: json['pickupLat']?.toDouble(),
      pickupLng: json['pickupLng']?.toDouble(),
      dropLat: json['dropLat']?.toDouble(),
      dropLng: json['dropLng']?.toDouble(),
      bookingId: json['bookingId'],
      status: json['status'],
      duration: json['duration'],
      finalAmount: json['finalAmount']?.toDouble(),
      customerFinalAmount: json['customerFinalAmount']?.toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      driverPhone: json['driverPhone'],
      driverRating: json['driverRating']?.toDouble(),
      driverTrips: json['driverTrips'],
      arrivalTime: json['arrivalTime'],
      distanceLeft: json['distanceLeft'],
      totalFare: json['totalFare']?.toDouble(),
      estimatedFare: json['estimatedFare']?.toDouble(),
      serviceTax: json['serviceTax']?.toDouble(),
      tollAmount: json['tollAmount']?.toDouble(),
      tipsAmount: json['tipsAmount']?.toDouble(),
      permitCharges: json['permitCharges']?.toDouble(),
      discountAmount: json['discountAmount']?.toDouble(),
      driverAllowance: json['driverAllowance']?.toDouble(),
      totalDriverCharges: json['totalDriverCharges']?.toDouble(),
      totalExtraCharges: json['totalExtraCharges']?.toDouble(),
      advanceAmount: json['advanceAmount']?.toDouble(),
      endOtp: json['endOtp'],
      extraCharges: json['extraCharges'],
      cancellationReason: json['cancellationReason'] ?? 'No reason',
      stops: stopsFrom(json['stops']),
      isRoundTrip: json['isRoundTrip'] as bool?,
      currentLeg: legFrom(json['currentLeg']),
      haltStartedAt: json['haltStartedAt'] != null ? DateTime.tryParse(json['haltStartedAt'].toString()) : null,
      originalPickupAddress: json['originalPickupAddress'],
      originalPickupLat: (json['originalPickupLat'] as num?)?.toDouble(),
      originalPickupLng: (json['originalPickupLng'] as num?)?.toDouble(),
    );
  }

  static int? legFrom(dynamic raw) {
    if (raw == null) return null;
    final parsed = int.tryParse(raw.toString());
    if (parsed == null) return null;
    return parsed.clamp(1, 2);
  }

  static bool roundTripFrom(dynamic serviceName, {dynamic flag, dynamic serviceId}) {
    if (flag is bool) return flag;

    final id = serviceId?.toString().trim() ?? '';
    if (id.isNotEmpty && Get.isRegistered<TripController>()) {
      final roundId = Get.find<TripController>().tripData[TripType.roundTrip]?['serviceId']?.toString();
      if (roundId != null && roundId == id) return true;
    }

    final s = (serviceName ?? '').toString().toLowerCase().replaceAll('_', ' ');
    return s.contains('round');
  }

  static List<Map<String, dynamic>>? stopsFrom(dynamic raw) {
    if (raw is! List) return null;
    final list = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return list.isEmpty ? null : list;
  }

  static String stopLabel(Map<String, dynamic> stop, int index) {
    for (final key in ['mainText', 'address', 'secondaryText', 'name', 'location']) {
      final v = stop[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return 'Stop ${index + 1}';
  }

  Map<String, dynamic> toJson() {
    return {
      'pickupLocation': pickupLocation,
      'destinationLocation': destinationLocation,
      'pickupDateTime': pickupDateTime?.toIso8601String(),
      'dropDateTime': dropDateTime?.toIso8601String(),
      'distanceInKm': distanceInKm,
      'tripCompletedDistance': tripCompletedDistance,
      'pricePerKm': pricePerKm,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'driverName': driverName,
      'driverImage': driverImage,
      'plateNumber': plateNumber,
      'startOtp': startOtp,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'bookingId': bookingId,
      'status': status,
      'duration': duration,
      'finalAmount': finalAmount,
      'customerFinalAmount': customerFinalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'driverPhone': driverPhone,
      'driverRating': driverRating,
      'driverTrips': driverTrips,
      'arrivalTime': arrivalTime,
      'distanceLeft': distanceLeft,
      'totalFare': totalFare,
      'estimatedFare': estimatedFare,
      'serviceTax': serviceTax,
      'tollAmount': tollAmount,
      'tipsAmount': tipsAmount,
      'permitCharges': permitCharges,
      'discountAmount': discountAmount,
      'driverAllowance': driverAllowance,
      'totalDriverCharges': totalDriverCharges,
      'totalExtraCharges': totalExtraCharges,
      'advanceAmount': advanceAmount,
      'endOtp': endOtp,
      'extraCharges': extraCharges,
      'cancellationReason': cancellationReason,
      'stops': stops,
      'isRoundTrip': isRoundTrip,
      'currentLeg': currentLeg,
      'haltStartedAt': haltStartedAt?.toIso8601String(),
      'originalPickupAddress': originalPickupAddress,
      'originalPickupLat': originalPickupLat,
      'originalPickupLng': originalPickupLng,
    };
  }
}
