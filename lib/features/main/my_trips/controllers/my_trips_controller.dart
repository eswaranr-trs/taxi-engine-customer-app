import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/enquiry_api/enquiry_repository.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/models/trip_details_model.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';

enum TripStatus { completed, scheduled, cancelled }

enum TripPeriod { all, today, week, month, threeMonths }

extension TripPeriodLabel on TripPeriod {
  String get label {
    switch (this) {
      case TripPeriod.all:
        return 'All';
      case TripPeriod.today:
        return 'Today';
      case TripPeriod.week:
        return 'This Week';
      case TripPeriod.month:
        return 'This Month';
      case TripPeriod.threeMonths:
        return 'Last 3 Months';
    }
  }
}

enum LiveTripStatus { searching, accepted, driverArrived, otpVerified, inProgress, completed, cancelled }

class MyTripsController extends GetxController {
  var selectedTab = TripStatus.scheduled.obs;
  var isLoading = false.obs;
  final TripsRepository _tripsRepository = TripsRepository();
  final RxList<Map<String, dynamic>> trips = <Map<String, dynamic>>[].obs;

  final selectedPeriod = TripPeriod.all.obs;
  final selectedFilterPlace = ''.obs;

  DateTime? selectedDate;

  void setPeriod(TripPeriod period) => selectedPeriod.value = period;

  void applyFilters(String place) {
    selectedFilterPlace.value = place.trim();
  }

  void clearFilters() {
    selectedPeriod.value = TripPeriod.all;
    selectedFilterPlace.value = '';
  }

  @override
  void onInit() {
    super.onInit();
    fetchTrips(selectedTab.value);

    if (Get.isRegistered<ConnectivityService>()) {
      ever(Get.find<ConnectivityService>().isReachable, (bool reachable) {
        if (reachable) fetchTrips(selectedTab.value);
      });
    }
  }

  void setTab(TripStatus status) {
    selectedTab.value = status;
    fetchTrips(status);
  }

  String _getStatusString(TripStatus status) {
    switch (status) {
      case TripStatus.completed:
        return 'completed';
      case TripStatus.scheduled:
        return 'scheduled';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }

  bool _inSelectedPeriod(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    late final DateTime start;
    late final DateTime end;
    switch (selectedPeriod.value) {
      case TripPeriod.all:
        return true;
      case TripPeriod.today:
        start = today;
        end = today.add(const Duration(days: 1));
      case TripPeriod.week:
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 7));
      case TripPeriod.month:
        start = DateTime(now.year, now.month);
        end = DateTime(now.year, now.month + 1);
      case TripPeriod.threeMonths:
        start = DateTime(now.year, now.month - 2);
        end = DateTime(now.year, now.month + 1);
    }
    return !date.isBefore(start) && date.isBefore(end);
  }

  List<Map<String, dynamic>> get filteredTrips {
    Iterable<Map<String, dynamic>> base = trips;
    if (selectedTab.value == TripStatus.scheduled) {
      base = base.where((t) => (t['status']?.toString().toLowerCase() ?? '') != 'cancelled');
    }

    if (selectedPeriod.value == TripPeriod.all && selectedFilterPlace.value.isEmpty) {
      return base.toList();
    }

    return base.where((trip) {
      bool matchesDate = true;
      bool matchesPlace = true;

      if (selectedPeriod.value != TripPeriod.all) {
        final String? dateString = (trip['scheduledAt'] ?? trip['createdAt'])?.toString();
        final tripDate = (dateString != null && dateString.isNotEmpty)
            ? DateTime.tryParse(dateString)?.toLocal()
            : null;

        matchesDate = tripDate != null && _inSelectedPeriod(tripDate);
      }

      if (selectedFilterPlace.value.isNotEmpty) {
        final place = selectedFilterPlace.value.toLowerCase();

        matchesPlace =
            (trip['pickupAddress'] ?? '').toString().toLowerCase().contains(place) ||
            (trip['dropoffAddress'] ?? '').toString().toLowerCase().contains(place);
      }

      return matchesDate && matchesPlace;
    }).toList();
  }

  int _fetchSeq = 0;

  Future<void> fetchTrips(TripStatus status) async {
    final int seq = ++_fetchSeq;
    try {
      isLoading.value = true;
      trips.clear();

      final String statusString = _getStatusString(status);
      final response = await _tripsRepository.getTrips(statusString);

      if (seq != _fetchSeq || status != selectedTab.value) return;

      if (response != null && response['data'] != null) {
        final list = List<Map<String, dynamic>>.from(response['data']);
        trips.assignAll(list);

        if (status == TripStatus.scheduled && Get.isRegistered<TripStateService>()) {
          final tss = Get.find<TripStateService>();
          for (final t in list) {
            tss.muteAutoNav(t['bookingId']?.toString() ?? '');
            tss.muteAutoNav(t['_id']?.toString() ?? '');
          }
        }
      }
    } catch (e) {
      if (seq == _fetchSeq && Get.find<ConnectivityService>().isReachable.value) {
        AppSnackbar.error('Error', 'Failed to load trips: ${e.toString()}');
      }
    } finally {
      if (seq == _fetchSeq) isLoading.value = false;
    }
  }

  Future<void> refreshTrips() async {
    await fetchTrips(selectedTab.value);
  }

  String shortenLocation(String location) {
    return location.replaceAll(RegExp(r'\s*\(.*?\)'), '').replaceAll(RegExp(r',.*'), '').trim();
  }

  Future<void> cancelScheduledTrip(String bookingId) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator(color: AppColors.primary)), barrierDismissible: false);

      final response = await Get.find<EnquiryRepository>().cancelTrip(tripId: bookingId, reason: 'I booked by mistake');

      if (Get.isDialogOpen == true) Get.back();

      if (response != null && response['success'] == true) {
        AppSnackbar.success('Success', response['message'] ?? 'Booking cancelled successfully');
        fetchTrips(selectedTab.value);
      } else {
        AppSnackbar.error('Error', response?['message'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      AppSnackbar.error('Error', e.toString());
    }
  }

  String formatDuration(int totalMinutes) {
    final int days = totalMinutes ~/ (24 * 60);
    final int hours = (totalMinutes % (24 * 60)) ~/ 60;
    final int minutes = totalMinutes % 60;

    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''} $hours hr${hours > 1 ? 's' : ''}';
    }

    if (hours > 0) {
      return '$hours hr${hours > 1 ? 's' : ''} $minutes min${minutes > 1 ? 's' : ''}';
    }

    return '$minutes min${minutes > 1 ? 's' : ''}';
  }

  Map fareBreakdown(Map trip) => _fareBreakdown(trip);
  Map _fareBreakdown(Map trip) {
    final completed = (trip['status']?.toString().toLowerCase() ?? '') == 'completed';
    final primary = completed ? trip['afterTripBreakdowns'] : trip['beforeTripBreakdowns'];
    if (primary is Map && primary['customerFareBreakDown'] is Map) return primary['customerFareBreakDown'] as Map;
    final alt = completed ? trip['beforeTripBreakdowns'] : trip['afterTripBreakdowns'];
    if (alt is Map && alt['customerFareBreakDown'] is Map) return alt['customerFareBreakDown'] as Map;
    if (trip['customerFareBreakDown'] is Map) return trip['customerFareBreakDown'] as Map;
    return const {};
  }

  void resumeTrip(Map<String, dynamic> trip) {
    try {
      final tripStateService = Get.find<TripStateService>();

      final Map<String, dynamic>? driver = trip['driver'];
      final double distance =
          double.tryParse(
            (trip['afterTripBreakdowns']?['fare']?['distance'] ??
                        trip['enquiryData']?['distance_km'] ??
                        trip['distanceKm'] ??
                        trip['distance'] ??
                        trip['distanceInKm'] ??
                        '0')
                    ?.toString()
                    .replaceAll('NaN', '0') ??
                '0',
          ) ??
          0.0;

      final int durationMinutes =
          int.tryParse(
            (trip['tripCompletedDuration'] ??
                        trip['enquiryData']?['duration_mins'] ??
                        trip['durationMinutes'] ??
                        trip['duration'] ??
                        trip['totalDuration'] ??
                        '0')
                    ?.toString() ??
                '0',
          ) ??
          0;

      final dynamic vehicle = trip['vehicle'];
      final String vehicleType =
          (trip['vehicleType'] ??
                  (vehicle is Map ? (vehicle['type'] ?? vehicle['vehicle_type'] ?? vehicle['name']) : vehicle) ??
                  trip['vehicleCategoryId'] ??
                  'Mini')
              .toString();
      final String? vehicleModel = (trip['vehicleName'] ?? (vehicle is Map ? vehicle['modelName'] : null))?.toString();
      final String? plateNumber = vehicle is Map ? vehicle['number']?.toString() : null;

      final Map fare = _fareBreakdown(trip);
      double fareD(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
      final double finalAmount =
          double.tryParse(trip['finalAmount']?.toString() ?? trip['price']?.toString() ?? '0') ?? 0.0;
      final double customerFinalAmount = fare['customerFinalAmount'] != null
          ? fareD(fare['customerFinalAmount'])
          : (trip['customerFinalAmount'] != null ? fareD(trip['customerFinalAmount']) : finalAmount);

      final String tripId = (trip['bookingId'] ?? trip['_id'] ?? '').toString();
      final RideStage knownStage = tripStateService.activeStages[tripId] ?? RideStage.none;

      tripStateService.setBookingDetails(
        bookingId: tripId,
        status: trip['status'] ?? 'scheduled',
        pickup: trip['pickupAddress'] ?? 'Unknown',
        drop: trip['dropoffAddress'] ?? 'Unknown',
        stops: TripDetailsModel.stopsFrom(trip['stops'] ?? trip['enquiryData']?['stops']),
        isRoundTrip: TripDetailsModel.roundTripFrom(
          trip['serviceName'] ?? trip['service_name'] ?? trip['serviceType'],
          flag: trip['isRoundTrip'],
          serviceId: trip['serviceId'] ?? trip['service_id'],
        ),
        pickupDateTime: trip['scheduledAt'] != null ? DateTime.parse(trip['scheduledAt']) : DateTime.now(),
        vehicleType: vehicleType,
        vehicleModel: vehicleModel,
        plateNumber: plateNumber,
        customerFinalAmount: customerFinalAmount,
        tripCompletedFinalAmount: trip['tripCompletedFinalAmount'] != null
            ? fareD(trip['tripCompletedFinalAmount'])
            : null,
        estimatedFare: fareD(fare['estimatedFare']),
        pricePerKm: double.tryParse(trip['pricePerKm']?.toString() ?? ''),
        serviceTax: fareD(fare['serviceTax']),
        tollAmount: fareD(fare['tollAmount']),
        discountAmount: fareD(fare['discountAmount']),
        driverAllowance: fareD(fare['driverAllowance']),
        totalDriverCharges: fareD(fare['totalDriverCharges']),
        totalExtraCharges: fareD(fare['totalExtraCharges']),
        distance: distance,
        duration: formatDuration(durationMinutes),
        finalAmount: finalAmount,
        paymentMethod: trip['paymentMethod'] ?? 'cash',
        paymentStatus: trip['paymentStatus'] ?? 'pending',
        driverName: driver?['name']?.toString(),
        driverPhone: driver?['phone']?.toString(),
        startOtp: trip['driverOtp']?.toString() ?? trip['startOtp']?.toString(),
        endOtp: trip['endOtp']?.toString(),
      );

      final statusStr = (trip['status']?.toString() ?? '').toLowerCase();

      RideStage? listStage;
      if (statusStr == 'booking accepted') {
        listStage = RideStage.findingDriver;
      } else if (statusStr == 'pickup arrived') {
        listStage = RideStage.tripVerification;
      } else if (statusStr == 'started') {
        listStage = RideStage.tripInProgress;
      } else if (statusStr == 'completed') {
        final paymentStatus = (trip['paymentStatus']?.toString() ?? '').toLowerCase();
        listStage = paymentStatus == 'success' ? RideStage.tripCompleted : RideStage.payment;
      } else if (statusStr == 'cancelled') {
        listStage = RideStage.tripCancelled;
      }

      if (listStage != null && tripStateService.stageRank(listStage) >= tripStateService.stageRank(knownStage)) {
        tripStateService.updateRideStage(listStage, bookingId: tripId);
      }

      tripStateService.resumeRideFlow();
    } catch (e) {
      AppSnackbar.error('Error', 'Failed to resume trip: $e');
    }
  }
}
