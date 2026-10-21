import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/enquiry_api/enquiry_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/models/trip_details_model.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/payment/controllers/payment_controller.dart';
import 'package:flutter/material.dart';

class VehicleSelectionController extends GetxController {
  final EnquiryRepository _enquiryRepository = EnquiryRepository();

  var selectedVehicleIndex = 0.obs;
  var isLoading = false.obs;
  final RxBool openingVehicles = false.obs;
  var isPriceLoading = false.obs;
  var selectedDate = DateTime.now().obs;
  var selectedHour = 0.obs;
  var selectedMinute = 0.obs;
  var isAM = true.obs;
  var isScheduled = false.obs;
  var scheduledPickupTime = ''.obs;
  var scheduledDropTime = ''.obs;
  var pickupDate = ''.obs;
  var dropDate = ''.obs;

  final RxnString appliedOfferId = RxnString();
  String? _pendingOfferId;
  final RxBool isApplyingOffer = false.obs;
  final RxnString offerError = RxnString();
  final offerController = TextEditingController();

  bool get hasActiveTrip => Get.find<TripStateService>().selectedStage != RideStage.none;
  final RxInt minScheduleHours = 1.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMinScheduleHours();

    ever(Get.find<TripStateService>().activeStages, (_) {
      final stage = Get.find<TripStateService>().selectedStage;
      if (stage == RideStage.none) {}
    });
  }

  void resetState() {
    selectedVehicleIndex.value = 0;
    isLoading.value = false;
    isPriceLoading.value = false;
    isScheduled.value = false;
    scheduledPickupTime.value = '';
    scheduledDropTime.value = '';
    pickupDate.value = '';
    dropDate.value = '';
    selectedHour.value = 0;
    selectedMinute.value = 0;
    isAM.value = true;
    appliedOfferId.value = null;
    _pendingOfferId = null;
    offerError.value = null;
    offerController.clear();
    vehicles.clear();
    vehicleCounts.clear();
    hasVehicleCounts.value = false;
  }

  @override
  void onClose() {
    offerController.dispose();
    super.onClose();
  }

  Future<void> _loadMinScheduleHours() async {
    try {
      final value = await AuthRepository().getConfigValue('minimumScheduleTimeDifference');
      final parsed = int.tryParse(value ?? '');
      if (parsed != null && parsed > 0) minScheduleHours.value = parsed;
    } catch (_) {}
  }

  RxList<dynamic> vehicles = <dynamic>[].obs;
  RxMap<String, int> vehicleCounts = <String, int>{}.obs;
  final RxBool hasVehicleCounts = false.obs;

  bool isVehicleAvailable(dynamic v) {
    if (!hasVehicleCounts.value) return true;
    for (final key in [v['vehicle_type'], v['name']]) {
      final k = key?.toString().toLowerCase().trim();
      if (k != null && vehicleCounts.containsKey(k)) return (vehicleCounts[k] ?? 0) > 0;
    }
    return false;
  }

  bool isRideLaterOnly(dynamic v) => !isVehicleAvailable(v) && !isScheduled.value;

  bool get selectedNeedsRideLater {
    final int i = selectedVehicleIndex.value;
    if (i < 0 || i >= vehicles.length) return false;
    return isRideLaterOnly(vehicles[i]);
  }

  RxMap<String, dynamic> bookingDetails = <String, dynamic>{}.obs;
  Map<String, dynamic> enquiryPickupdata = {};
  Map<String, dynamic> enquiryDropdata = {};
  double? enquiryDistanceKm;
  int? enquiryDurationMins;
  void setVehicles(List<dynamic> vehicleList) {
    vehicles.value = vehicleList;
  }

  String? _lastEstimationKey;

  String estimationKey({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    required List<Map<String, dynamic>> stops,
    required String serviceTypeId,
  }) {
    final s = stops.map((e) => '${e['lat']},${e['lng']}').join(';');
    return '${pickupLat.toStringAsFixed(5)},${pickupLng.toStringAsFixed(5)}|'
        '${dropLat.toStringAsFixed(5)},${dropLng.toStringAsFixed(5)}|$s|$serviceTypeId';
  }

  bool hasFreshEstimation(String key) => vehicles.isNotEmpty && _lastEstimationKey == key;

  Future<String> _resolveServiceTypeId(String serviceTypeId) async {
    if (serviceTypeId.isNotEmpty) return serviceTypeId;
    if (!Get.isRegistered<TripController>()) return '';
    final trip = Get.find<TripController>();
    return await trip.ensureServiceTypes() ? trip.serviceId : '';
  }

  Future<bool> fetchEstimation({
    required final String pickUp,
    required final String drop,
    required final List<Map<String, dynamic>> stops,
    required final DateTime pickupDateTime,
    final DateTime? dropDateTime,
    required final String serviceTypeId,
    required final double pickupLat,
    required final double pickupLng,
    required final double dropLat,
    required final double dropLng,
    final bool priceOnly = false,
    final bool silent = false,
  }) async {
    void setBusy(bool v) => priceOnly ? isPriceLoading.value = v : isLoading.value = v;
    final String? offerForRequest = _pendingOfferId ?? appliedOfferId.value;
    try {
      setBusy(true);

      final String resolvedServiceTypeId = await _resolveServiceTypeId(serviceTypeId);
      if (resolvedServiceTypeId.isEmpty) {
        setBusy(false);
        await _showNoticeDialog(
          'Service types are still loading. Please check your connection and try again.',
          title: 'Unable to Estimate Fare',
        );
        return false;
      }

      final result = await _enquiryRepository.getEstimation(
        pickUp: pickUp,
        drop: drop,
        stops: stops,
        pickupDate: pickupDateTime.toUtc().toIso8601String(),
        dropDate: dropDate.value.isEmpty ? null : dropDateTime?.toUtc().toIso8601String(),
        serviceTypeId: resolvedServiceTypeId,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropLat: dropLat,
        dropLng: dropLng,
        offerId: offerForRequest,
        isOfferApply: offerForRequest?.isNotEmpty ?? false,
      );

      if (result != null && result['data'] != null && result['data']['vehicles'] != null) {
        final List<dynamic> vehicleList = result['data']['vehicles'];
        final int durationMins = result['data']['duration_mins'] ?? 0;
        final String serviceId = result['data']['service_id'] ?? '';

        for (var vehicle in vehicleList) {
          final DateTime dropDateTime = pickupDateTime.add(Duration(minutes: durationMins));
          final String formattedDropTime = DateFormat('hh:mm a').format(dropDateTime);
          vehicle['dropTime'] = 'Drop at $formattedDropTime';
          vehicle['serviceId'] = serviceId;
        }
        vehicles.assignAll(vehicleList);

        final counts = result['data']['vehicleCounts'];
        vehicleCounts.clear();
        hasVehicleCounts.value = counts is Map;
        if (counts is Map) {
          counts.forEach((k, v) => vehicleCounts[k.toString().toLowerCase().trim()] = int.tryParse('$v') ?? 0);
        }
        vehicles.assignAll([...vehicles.where(isVehicleAvailable), ...vehicles.where((v) => !isVehicleAvailable(v))]);
        final int firstAvailable = vehicles.indexWhere(isVehicleAvailable);
        selectedVehicleIndex.value = firstAvailable >= 0 ? firstAvailable : (vehicles.isEmpty ? -1 : 0);

        enquiryPickupdata = result['data']['pickup'];
        enquiryDropdata = result['data']['dropoff'];

        final double distanceKm = double.tryParse(result['data']['distance_km']?.toString() ?? '') ?? 0.0;
        if (distanceKm > 0) enquiryDistanceKm = distanceKm;
        if (durationMins > 0) enquiryDurationMins = durationMins;

        if (Get.isRegistered<HomeController>()) {
          final home = Get.find<HomeController>();
          if (distanceKm > 0) home.distance.value = '${distanceKm.toStringAsFixed(1)} km';
          if (durationMins > 0) home.duration.value = home.formatDuration(durationMins);

          final double? pLat = double.tryParse(enquiryPickupdata['lat']?.toString() ?? '');
          final double? pLng = double.tryParse(enquiryPickupdata['lng']?.toString() ?? '');
          final double? dLat = double.tryParse(enquiryDropdata['lat']?.toString() ?? '');
          final double? dLng = double.tryParse(enquiryDropdata['lng']?.toString() ?? '');
          if (pLat != null && pLng != null) home.pickupLatLng.value = LatLng(pLat, pLng);
          if (dLat != null && dLng != null) home.destinationLatLng.value = LatLng(dLat, dLng);
        }

        final bool hasWarning = result['warning'] == true;
        final String warningMsg = result['warning_message']?.toString() ?? '';
        if (hasWarning && warningMsg.isNotEmpty) {
          setBusy(false);
          final bool proceed = await _confirmWarning(warningMsg);
          if (!proceed) {
            vehicles.clear();
            _lastEstimationKey = null;
            return false;
          }
        }

        _lastEstimationKey = estimationKey(
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          dropLat: dropLat,
          dropLng: dropLng,
          stops: stops,
          serviceTypeId: resolvedServiceTypeId,
        );
        return result['success'] ?? false;
      }
      return result!['success'];
    } catch (e) {
      if (silent) rethrow;
      vehicles.clear();
      _lastEstimationKey = null;
      if (e is ApiException) {
        setBusy(false);
        final bool isDistance = e.message.toLowerCase().contains('distance');
        await _showNoticeDialog(e.message, title: isDistance ? 'Minimum Distance Required' : 'Unable to Estimate Fare');
      } else {
        AppSnackbar.warning('Unable to estimate', "Couldn't fetch vehicles");
      }
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().clearRouteOverlay();
      }
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> refreshEstimationForSchedule({bool silent = false}) async {
    final home = Get.find<HomeController>();
    final trip = Get.find<TripController>();
    if (vehicles.isEmpty) return false;
    final selectedId = selectedVehicleIndex.value >= 0 ? vehicles[selectedVehicleIndex.value]['id']?.toString() : null;

    final bool ok = await fetchEstimation(
      pickUp: home.pickupAddress.value,
      drop: home.destinationAddress.value,
      stops: home.formattedStops,
      pickupDateTime: DateTime.tryParse(pickupDate.value) ?? DateTime.now(),
      serviceTypeId: trip.serviceId,
      pickupLat: home.pickupLatLng.value.latitude,
      pickupLng: home.pickupLatLng.value.longitude,
      dropLat: home.destinationLatLng.value.latitude,
      dropLng: home.destinationLatLng.value.longitude,
      priceOnly: true,
      silent: silent,
    );

    if (selectedId != null) {
      final idx = vehicles.indexWhere((v) => v['id']?.toString() == selectedId);
      selectedVehicleIndex.value = idx;
    }
    return ok;
  }

  Future<void> applyOffer() async {
    final code = offerController.text.trim().toUpperCase();
    if (code.isEmpty) {
      offerError.value = 'Enter a valid offer code';
      return;
    }
    if (isApplyingOffer.value) return;
    try {
      isApplyingOffer.value = true;
      offerError.value = null;
      _pendingOfferId = code;
      final bool ok = await refreshEstimationForSchedule(silent: true);
      final bool applied = ok && vehicles.any((v) => (num.tryParse('${v['discount_amount'] ?? 0}') ?? 0) > 0);
      if (applied) {
        appliedOfferId.value = code;
        offerController.clear();
      } else {
        offerError.value = 'Code not applicable to this trip';
        _pendingOfferId = null;
        if (ok) await refreshEstimationForSchedule();
      }
    } catch (e) {
      offerError.value = e is ApiException ? e.message : 'Could not apply offer code';
    } finally {
      _pendingOfferId = null;
      isApplyingOffer.value = false;
    }
  }

  String? get activeOfferTitle {
    final int i = selectedVehicleIndex.value;
    if (i < 0 || i >= vehicles.length) return null;
    final v = vehicles[i];
    if ((num.tryParse('${v['discount_amount'] ?? 0}') ?? 0) <= 0) return null;
    final String title = (v['offer_title'] ?? '').toString().trim();
    return title.isEmpty ? null : title;
  }

  Future<void> removeOffer() async {
    appliedOfferId.value = null;
    _pendingOfferId = null;
    offerError.value = null;
    offerController.clear();
    await refreshEstimationForSchedule();
  }

  Future<bool> _confirmWarning(String message) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            CustomText(
              text: 'Minimum Distance Notice',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.darkSlate,
            ),
          ],
        ),
        content: CustomText(text: message, fontSize: 14, color: AppColors.slate500, textAlign: TextAlign.start),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const CustomText(text: 'Cancel', fontSize: 14, color: AppColors.slate500),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const CustomText(
              text: 'Continue',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  Future<void> _showNoticeDialog(String message, {String title = 'Unable to Estimate Fare'}) async {
    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: CustomText(
                text: title,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
        content: CustomText(text: message, fontSize: 14, color: AppColors.slate500, textAlign: TextAlign.start),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const CustomText(text: 'OK', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.black),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  String formatDate(final String date) {
    DateTime dateTime = DateTime.parse(date);
    int day = dateTime.day;
    String suffix = 'th';

    if (day == 1 || day == 21 || day == 31) {
      suffix = 'st';
    } else if (day == 2 || day == 22) {
      suffix = 'nd';
    } else if (day == 3 || day == 23) {
      suffix = 'rd';
    }

    String month = DateFormat('MMMM').format(dateTime);
    return '$day$suffix $month';
  }

  void storeBookingData(
    final Map<String, dynamic> response, {
    final DateTime? pickupDateTime,
    final DateTime? dropDateTime,
    final String? pickup,
    final String? drop,
    final String? distance,
    final String? duration,
    final bool isScheduled = false,
    final Map<String, dynamic>? selectedVehicle,
  }) {
    final outer = response['data'] ?? response ?? {};
    final data = (outer is Map && outer['booking'] is Map) ? outer['booking'] : outer;

    dynamic rawStops =
        (data is Map ? data['stops'] : null) ??
        (data is Map && data['booking'] is Map ? data['booking']['stops'] : null) ??
        response['stops'] ??
        (response['data'] is Map ? response['data']['stops'] : null);
    final List<Map<String, dynamic>>? bookedStops =
        TripDetailsModel.stopsFrom(rawStops) ??
        (Get.find<TripStateService>().lastBookingStops.isEmpty
            ? null
            : List<Map<String, dynamic>>.from(Get.find<TripStateService>().lastBookingStops));
    if (bookedStops != null) {
      Get.find<TripStateService>().lastBookingStops.assignAll(bookedStops);
    }

    double finalDistance = 0.0;
    if (distance != null && distance.isNotEmpty) {
      finalDistance = double.tryParse(distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    } else if (data['distance'] != null) {
      finalDistance = double.tryParse(data['distance'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    } else if (enquiryDistanceKm != null) {
      finalDistance = enquiryDistanceKm!;
    }

    String finalDuration = '0 min';
    if (duration != null && duration.isNotEmpty) {
      finalDuration = duration;
    } else if (data['duration'] != null) {
      finalDuration = data['duration'].toString();
    } else if (enquiryDurationMins != null) {
      finalDuration = Get.find<HomeController>().formatDuration(enquiryDurationMins!);
    }

    String bookingId = (data['bookingId'] ?? data['_id'] ?? data['id'] ?? '').toString();
    if (bookingId.isEmpty) bookingId = 'pending_booking';
    final double finalAmount =
        double.tryParse(data['finalAmount']?.toString() ?? '') ??
        double.tryParse(selectedVehicle?['total_fare']?.toString() ?? '') ??
        double.tryParse(selectedVehicle?['estimated_fare']?.toString() ?? '') ??
        0.0;

    final String vehicleType =
        selectedVehicle?['name']?.toString() ??
        data['vehicleName']?.toString() ??
        selectedVehicle?['vehicle_type']?.toString() ??
        data['vehicleType']?.toString() ??
        '';
    final String? vehicleModel = selectedVehicle?['vehicle_type']?.toString() ?? data['vehicleType']?.toString();

    bookingDetails.value = {
      'passengerName': data['name'] ?? data['otherPassengerName'],
      'passengerPhone': data['phone'] ?? data['otherPassengerPhone'],
      'bookingId': bookingId,
      'status': data['status'],
      'pickup': pickup ?? data['pickup'],
      'drop': drop ?? data['drop'],
      'pickupDateTime': data['pickupDateTime'],
      'serviceType': data['serviceType'],
      'vehicleType': vehicleType,
      'distance': finalDistance,
      'duration': finalDuration,
      'finalAmount': finalAmount,
      'paymentMethod': data['paymentMethod'],
      'paymentStatus': data['paymentStatus'],
      'driverName': data['driverName'],
      'driverPhone': data['driverPhone'],
      'startOtp': data['startOtp'] ?? data['driverOtp'],
      'endOtp': data['endOtp'],
      'advanceAmount': data['advanceAmount'],
      'upPaidAmount': data['upPaidAmount'],
      'days': data['days'],
      'extraCharges': data['extraCharges'],
    };
    final Map fare = data['customerFareBreakDown'] is Map ? data['customerFareBreakDown'] as Map : const {};
    double fareD(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    final double customerFinalAmount = fare['customerFinalAmount'] != null
        ? fareD(fare['customerFinalAmount'])
        : (data['customerFinalAmount'] != null ? fareD(data['customerFinalAmount']) : finalAmount);
    final double estimatedFare = fare['estimatedFare'] != null
        ? fareD(fare['estimatedFare'])
        : fareD(selectedVehicle?['estimated_fare']);
    final double serviceTax = fareD(fare['serviceTax']);
    final double toll = fareD(fare['tollAmount']);
    final double discountAmount = fareD(fare['discountAmount']);
    final double driverAllowance = fare['driverAllowance'] != null
        ? fareD(fare['driverAllowance'])
        : fareD(selectedVehicle?['driver_beta']);

    final double pricePerKm = data['pricePerKm'] != null
        ? fareD(data['pricePerKm'])
        : fareD(selectedVehicle?['price_per_km']);
    final tripStateService = Get.find<TripStateService>();
    tripStateService.setBookingDetails(
      bookingId: bookingId,
      status: data['status']?.toString() ?? 'Finding Driver',
      stops: bookedStops,
      isRoundTrip: Get.find<TripController>().selectedType.value == TripType.roundTrip,
      customerFinalAmount: customerFinalAmount,
      estimatedFare: estimatedFare,
      pricePerKm: pricePerKm,
      serviceTax: serviceTax,
      tollAmount: toll,
      permitCharges: fareD(fare['permitCharges']),
      discountAmount: discountAmount,
      driverAllowance: driverAllowance,
      totalDriverCharges: fareD(fare['totalDriverCharges']),
      totalExtraCharges: fareD(fare['totalExtraCharges']),
      pickup:
          pickup ??
          (data['pickup'] is Map ? data['pickup']['address']?.toString() ?? '' : data['pickup']?.toString() ?? ''),
      drop:
          drop ??
          (data['drop'] is Map
              ? data['drop']['address']?.toString() ?? ''
              : data['drop']?.toString() ?? data['dropoff']?.toString() ?? ''),
      pickupDateTime: pickupDateTime ?? DateTime.tryParse(data['pickupDateTime']?.toString() ?? '') ?? DateTime.now(),
      dropDateTime:
          DateTime.tryParse((data['dropDateTime'] ?? data['drop_time'] ?? data['dropTime'])?.toString() ?? '') ??
          dropDateTime,
      vehicleType: vehicleType,
      vehicleModel: vehicleModel,
      distance: finalDistance,
      duration: finalDuration,
      finalAmount: finalAmount,
      paymentMethod: data['paymentMethod']?.toString() ?? 'Cash',
      paymentStatus: data['paymentStatus']?.toString() ?? 'Unpaid',
      driverName: data['driverName']?.toString(),
      driverPhone: data['driverPhone']?.toString(),
      startOtp: (data['startOtp'] ?? data['driverOtp'])?.toString(),
      advanceAmount: double.tryParse(data['advanceAmount']?.toString() ?? ''),
      endOtp: data['endOtp']?.toString(),
      extraCharges: data['extraCharges'] is Map ? Map<String, dynamic>.from(data['extraCharges']) : null,
      passengerName: data['name']?.toString(),
      passengerPhone: data['phone']?.toString(),
      pickupLat: double.tryParse(enquiryPickupdata['lat']?.toString() ?? ''),
      pickupLng: double.tryParse(enquiryPickupdata['lng']?.toString() ?? ''),
      dropLat: double.tryParse(enquiryDropdata['lat']?.toString() ?? ''),
      dropLng: double.tryParse(enquiryDropdata['lng']?.toString() ?? ''),
      markFindingDriver: false,
    );
  }

  int getDurationInMinutes(String duration) {
    int days = 0;
    int hours = 0;
    int minutes = 0;

    final dayMatch = RegExp(r'(\d+)\s*day').firstMatch(duration);
    final hourMatch = RegExp(r'(\d+)\s*hour').firstMatch(duration);
    final minuteMatch = RegExp(r'(\d+)\s*min').firstMatch(duration);

    if (dayMatch != null) {
      days = int.parse(dayMatch.group(1)!);
    }

    if (hourMatch != null) {
      hours = int.parse(hourMatch.group(1)!);
    }

    if (minuteMatch != null) {
      minutes = int.parse(minuteMatch.group(1)!);
    }

    return (days * 24 * 60) + (hours * 60) + minutes;
  }

  Future<bool> createBooking({
    required final String pickup,
    required final String drop,
    required final String distance,
    required final String duration,
    required final String serviceTypeId,
    required final DateTime pickupDateTime,
    required final List<Map<String, dynamic>> stops,
    DateTime? dropDateTime,
  }) async {
    if (isLoading.value) return false;
    try {
      isLoading.value = true;

      final TripController tripController = Get.find<TripController>();
      final PaymentController paymentController = Get.find<PaymentController>();

      final String resolvedServiceTypeId = await _resolveServiceTypeId(serviceTypeId);
      if (resolvedServiceTypeId.isEmpty) {
        AppSnackbar.error('Unable to create booking', 'Service types are still loading. Please try again.');
        return false;
      }

      if (tripController.selectedType.value == TripType.roundTrip && dropDate.value.isEmpty) {
        AppSnackbar.error('Return Date Required', 'Please select a drop/return date for your round trip');

        return false;
      }

      final Map<String, dynamic> selectedVehicle = vehicles[selectedVehicleIndex.value];

      final user = await LocalStorageService.getUser();
      final String customerName = (user?['name'] ?? '').toString();
      final String customerPhone = (user?['phone'] ?? user?['phoneNumber'] ?? '').toString();

      final bool isScheduled = pickupDateTime.isAfter(DateTime.now().add(const Duration(hours: 1)));

      final String bookingType = isScheduled ? "Scheduled" : "Immediate";

      final Map<String, dynamic> bookingData = {
        "pickup": enquiryPickupdata,
        "dropoff": enquiryDropdata,
        "stops": stops,
        "distance_km": double.tryParse(distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
        "duration_mins": enquiryDurationMins ?? getDurationInMinutes(duration),
        "service_id": resolvedServiceTypeId,
        "service_name": tripController.selectedType.value.name.toLowerCase(),
        "vehicles": [
          {
            "tariff_id": selectedVehicle['tariff_id'],
            "vehicle_type": selectedVehicle['vehicle_type'],
            "name": selectedVehicle['name'],
            "seats": selectedVehicle['seats'],
            "estimated_fare": selectedVehicle['estimated_fare'],
            "driver_beta": selectedVehicle['driver_beta'],
            "final_fare": selectedVehicle['final_fare'],
            "total_fare": selectedVehicle['total_fare'],
            "eta_mins": selectedVehicle['eta_mins'],
            "vehicle_image_url": selectedVehicle['vehicle_image_url'],
          },
        ],

        "tariff_id": selectedVehicle['tariff_id'],
        "selected_tariff_id": selectedVehicle['tariff_id'],
        "estimated_fare": selectedVehicle['estimated_fare'],
        "booking_type": bookingType,
        "payment_method": paymentController.selectedPaymentMethod.value == 'wallet'
            ? 'Wallet'
            : paymentController.selectedPaymentMethod.value == 'cash'
            ? 'Cash'
            : 'upi',
        "booking_for": paymentController.selectedBookingFor.value == 'others' ? 'Others' : 'Myself',
        "name": paymentController.selectedBookingFor.value == 'others'
            ? paymentController.nameController.text
            : customerName,
        "phone": paymentController.selectedBookingFor.value == 'others'
            ? paymentController.phoneNumberController.text
            : customerPhone,
      };

      if (appliedOfferId.value?.isNotEmpty ?? false) {
        bookingData["offerId"] = appliedOfferId.value;
        bookingData["isOfferApply"] = true;
      }

      if (paymentController.selectedBookingFor.value == 'others') {
        bookingData["other_passenger_phone"] = paymentController.phoneNumberController.text;
      }

      if (bookingType == "Scheduled") {
        bookingData["scheduled_time"] = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(pickupDateTime.toUtc());
      }

      if (tripController.selectedType.value == TripType.roundTrip && dropDateTime != null) {
        bookingData["drop_time"] = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(dropDateTime.toUtc());
      }

      Get.find<TripStateService>().lastBookingStops.assignAll(stops.map((s) => Map<String, dynamic>.from(s)).toList());

      final result = await _enquiryRepository.createBooking(bookingData);

      if (result != null && result['success'] == true) {
        Get.find<TripStateService>().entrySource.value = 'booking';
        storeBookingData(
          result,
          pickupDateTime: pickupDateTime,
          dropDateTime: tripController.selectedType.value == TripType.roundTrip ? dropDateTime : null,
          pickup: pickup,
          drop: drop,
          distance: distance,
          duration: duration,
          isScheduled: bookingType == "Scheduled",
          selectedVehicle: selectedVehicle,
        );

        return true;
      }

      return false;
    } catch (e) {
      final String message = e is ApiException ? e.message : e.toString();
      AppSnackbar.error('Unable to create booking', message);

      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
