import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/invoice_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/models/trip_details_model.dart';
import 'package:orange_taxi_customer_app/features/main/my_trips/controllers/my_trips_controller.dart';
import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';
import 'package:intl/intl.dart';

class TripDetailsController extends GetxController {
  final TripStateService _tripStateService = Get.find<TripStateService>();
  final TripsRepository _tripsRepo = TripsRepository();

  String _userName = '';
  String _userPhone = '';

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _refreshFromServer();
    ever(_tripStateService.activeTrips, (_) {
      update();
    });

    if (Get.isRegistered<ConnectivityService>()) {
      ever(Get.find<ConnectivityService>().isReachable, (bool reachable) {
        if (reachable) _refreshFromServer();
      });
    }
  }

  Future<void> _refreshFromServer() async {
    final id = _tripStateService.selectedBookingId.value.isNotEmpty
        ? _tripStateService.selectedBookingId.value
        : (_tripStateService.selectedTrip?.bookingId ?? '');
    if (id.isEmpty) return;

    final trip = await _tripsRepo.getTripById(id);
    if (trip == null) return;

    double d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    final Map fare = Get.isRegistered<MyTripsController>()
        ? Get.find<MyTripsController>().fareBreakdown(trip)
        : const {};
    final dynamic vehicle = trip['vehicle'];
    final String vehicleType =
        (trip['vehicleType'] ?? (vehicle is Map ? (vehicle['type'] ?? vehicle['vehicle_type']) : vehicle) ?? 'unknown')
            .toString();
    final String? vehicleModel = (trip['vehicleName'] ?? (vehicle is Map ? vehicle['modelName'] : null))?.toString();

    _tripStateService.updateTripDetails(
      TripDetailsModel(
        bookingId: id,
        dropDateTime: DateTime.tryParse((trip['expectCompletedAt'] ?? '').toString()),
        pickupLocation: trip['pickupAddress']?.toString(),
        destinationLocation: trip['dropoffAddress']?.toString(),
        status: trip['status']?.toString(),
        paymentStatus: trip['paymentStatus']?.toString(),
        paymentMethod: trip['paymentMethod']?.toString(),
        vehicleType: vehicleType,
        vehicleModel: vehicleModel,
        plateNumber: vehicle is Map ? vehicle['number']?.toString() : null,
        finalAmount: d(trip['finalAmount']),
        customerFinalAmount: fare['customerFinalAmount'] != null
            ? d(fare['customerFinalAmount'])
            : (trip['customerFinalAmount'] != null ? d(trip['customerFinalAmount']) : d(trip['finalAmount'])),
        totalFare: d(trip['finalAmount']),
        tripCompletedFinalAmount: trip['tripCompletedFinalAmount'] != null ? d(trip['tripCompletedFinalAmount']) : null,
        estimatedFare: d(fare['estimatedFare']),
        serviceTax: d(fare['serviceTax']),
        tollAmount: d(fare['tollAmount']),
        permitCharges: d(fare['permitCharges']),
        discountAmount: d(fare['discountAmount']),
        driverAllowance: d(fare['driverAllowance']),
        totalDriverCharges: d(fare['totalDriverCharges']),
        totalExtraCharges: d(fare['totalExtraCharges']),
        advanceAmount: fare['advanceAmount'] != null
            ? d(fare['advanceAmount'])
            : d(trip['advancePaymentAmount'] ?? trip['advanceAmount']),
        distanceInKm: trip['tripCompletedDistance'] != null ? d(trip['tripCompletedDistance']) : null,
        stops: TripDetailsModel.stopsFrom(trip['stops'] ?? trip['enquiryData']?['stops']),
      ),
      bookingId: id,
    );
    update();
  }

  Future<void> _loadUser() async {
    final user = await LocalStorageService.getUser();
    if (user != null) {
      _userName = (user['name'] ?? user['fullName'] ?? '').toString();
      _userPhone = (user['phone'] ?? user['phoneNumber'] ?? '').toString();
      update();
    }
  }

  String _orFallback(String? value, String fallback) {
    final v = value?.trim() ?? '';
    return v.isNotEmpty ? v : fallback;
  }

  List<Map<String, dynamic>> get stops => _tripStateService.selectedTrip?.stops ?? const [];
  bool get hasStops => stops.isNotEmpty;
  String stopLabel(int index) => TripDetailsModel.stopLabel(stops[index], index);

  String get pickupLocation => _tripStateService.selectedTrip?.pickupLocation ?? 'unknown';
  String get destination => _tripStateService.selectedTrip?.destinationLocation ?? 'unknown';
  String get distance => '${_tripStateService.selectedTrip?.distanceInKm ?? 0.00} km';
  String get vehicleType => _tripStateService.selectedTrip?.vehicleType ?? 'unknown';
  String get vehicleModel => _tripStateService.selectedTrip?.vehicleModel ?? 'unknown';

  String get pickupDate {
    final date = _tripStateService.selectedTrip?.pickupDateTime;
    if (date == null) return 'unknown';
    return DateFormat('MMM dd, HH:mm').format(date.toLocal());
  }

  bool get isRoundTrip =>
      _tripStateService.selectedTrip?.isRoundTrip ?? (_tripStateService.selectedTrip?.dropDateTime != null);
  String get dropDate {
    final date = _tripStateService.selectedTrip?.dropDateTime;
    if (date == null) return '';
    return DateFormat('MMM dd, HH:mm').format(date.toLocal());
  }

  String get pickupDateOnly {
    final date = _tripStateService.selectedTrip?.pickupDateTime;
    if (date == null) return '--';
    return DateFormat('dd MMM yyyy').format(date.toLocal());
  }

  String get pickupTimeOnly {
    final date = _tripStateService.selectedTrip?.pickupDateTime;
    if (date == null) return '--';
    return DateFormat('hh:mm a').format(date.toLocal());
  }

  String get durationText {
    final d = _tripStateService.selectedTrip?.duration?.trim() ?? '';
    return d.isEmpty ? '--' : d;
  }

  String get plateNumber {
    final p = _tripStateService.selectedTrip?.plateNumber?.trim() ?? '';
    return (p.isEmpty || p == '0' || p == '_') ? '--' : p;
  }

  String get paymentMethodRaw => (_tripStateService.selectedTrip?.paymentMethod ?? '').trim();
  String get paymentMethodLabel =>
      TripStateService.paymentMethodLabel(_tripStateService.selectedTrip?.paymentMethod) ?? 'Cash';

  String get paidViaText {
    final raw = paymentMethodRaw;
    return raw.isEmpty ? 'Paid via $paymentMethodLabel' : 'Paid via ${raw.toUpperCase()}';
  }

  String? get paymentDateText {
    if (_tripStateService.lastPaymentBookingId != bookingId) return null;
    final date = _tripStateService.lastPaymentDate;
    if (date == null) return null;
    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  String get pickupETA {
    final active = _tripStateService.selectedTrip;
    if (active?.duration != null) {
      if (active!.duration!.contains('min')) {
        return 'In ${active.duration}';
      }
      return 'In ${active.duration} minutes';
    }
    return 'In 45 minutes';
  }

  String get passengerName =>
      _orFallback(_tripStateService.selectedTrip?.passengerName, _orFallback(_userName, 'No Name'));
  String get passengerPhone =>
      _orFallback(_tripStateService.selectedTrip?.passengerPhone, _orFallback(_userPhone, 'No Phone'));

  String get status => _tripStateService.selectedTrip?.status ?? 'unknown';
  bool get isCancelled => status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'canceled';
  String get cancellationReason {
    final r = _tripStateService.selectedTrip?.cancellationReason?.trim() ?? '';
    return r.isNotEmpty ? r : 'No reason provided.';
  }

  String get totalFare => '₹${_amt(_finalVal)}';
  String get paymentMethod => _tripStateService.selectedTrip?.paymentMethod ?? 'Cash';
  double get _estimatedFareVal => _tripStateService.selectedTrip?.estimatedFare ?? 0.0;
  double get _serviceTaxVal => _tripStateService.selectedTrip?.serviceTax ?? 0.0;
  double get _tollVal => _tripStateService.selectedTrip?.tollAmount ?? 0.0;
  double get _permitVal => _tripStateService.selectedTrip?.permitCharges ?? 0.0;
  double get _tipsVal => _tripStateService.selectedTrip?.tipsAmount ?? 0.0;
  double get _discountVal => _tripStateService.selectedTrip?.discountAmount ?? 0.0;
  double get _driverAllowanceVal => _tripStateService.selectedTrip?.driverAllowance ?? 0.0;
  double get _driverChargesVal => _tripStateService.selectedTrip?.totalDriverCharges ?? 0.0;
  double get _extraChargesVal => _tripStateService.selectedTrip?.totalExtraCharges ?? 0.0;
  double get _advanceVal => _tripStateService.selectedTrip?.advanceAmount ?? 0.0;
  double get _distanceKmVal => _tripStateService.selectedTrip?.distanceInKm ?? 0.0;
  double get _pricePerKmVal => _tripStateService.selectedTrip?.pricePerKm ?? 0.0;

  double get _finalVal =>
      _tripStateService.selectedTrip?.customerFinalAmount ??
      _tripStateService.selectedTrip?.tripCompletedFinalAmount ??
      _tripStateService.selectedTrip?.finalAmount ??
      _tripStateService.selectedTrip?.totalFare ??
      0.0;

  String _amt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  String get estimatedFare => '₹${_amt(_estimatedFareVal)}';
  String get serviceTax => '₹${_amt(_serviceTaxVal)}';
  String get tollAmount => '₹${_amt(_tollVal)}';
  String get permitCharges => '₹${_amt(_permitVal)}';
  String get tipsAmount => '₹${_amt(_tipsVal)}';
  String get discountAmount => '-₹${_amt(_discountVal)}';
  String get driverAllowance => '₹${_amt(_driverAllowanceVal)}';
  String get driverCharges => '₹${_amt(_driverChargesVal)}';
  String get extraCharges => '₹${_amt(_extraChargesVal)}';
  String get advanceAmount => '-₹${_amt(_advanceVal)}';
  String get balanceDue => '₹${_amt((_finalVal - _advanceVal).clamp(0, double.infinity).toDouble())}';

  bool get hasEstimated => _estimatedFareVal > 0;
  bool get hasServiceTax => _serviceTaxVal > 0;
  bool get hasDiscount => _discountVal > 0;
  bool get hasToll => _tollVal > 0;
  bool get hasPermitCharges => _permitVal > 0;
  bool get hasTips => _tipsVal > 0;
  bool get hasDriverAllowance => _driverAllowanceVal > 0;
  bool get hasDriverCharges => _driverChargesVal > 0;
  bool get hasExtraCharges => _extraChargesVal > 0;
  bool get hasAdvance => _advanceVal > 0;
  bool get hasDistance => _distanceKmVal > 0;
  bool get hasPricePerKm => _pricePerKmVal > 0;
  String get pricePerKm => '₹${_amt(_pricePerKmVal)}';

  String get bookingId => _tripStateService.selectedTrip?.bookingId ?? _tripStateService.selectedBookingId.value;
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPaid => TripStateService.isPaidStatus(_tripStateService.selectedTrip?.paymentStatus);
  final RxBool isDownloadingInvoice = false.obs;

  Future<void> downloadInvoice() async {
    final id = bookingId;
    if (id.isEmpty) {
      AppSnackbar.error('Invoice', 'Trip not found');
      return;
    }
    if (isDownloadingInvoice.value) return;
    try {
      isDownloadingInvoice.value = true;
      AppSnackbar.info('Invoice', 'Preparing your invoice...');
      await InvoiceService.openInvoice(id);
      // final saved = await InvoiceService.saveInvoice(id);
      // if (saved != null) AppSnackbar.success('Invoice', 'Invoice saved to your device');
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to download invoice';
      AppSnackbar.error('Invoice', msg);
    } finally {
      isDownloadingInvoice.value = false;
    }
  }

  final RxBool isSavingInvoice = false.obs;

  Future<void> saveInvoice() async {
    final id = bookingId;
    if (id.isEmpty) {
      AppSnackbar.error('Invoice', 'Trip not found');
      return;
    }
    if (isSavingInvoice.value) return;
    try {
      isSavingInvoice.value = true;
      final saved = await InvoiceService.saveInvoice(id);
      if (saved != null) AppSnackbar.success('Invoice', 'Invoice saved to your device');
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to download invoice';
      AppSnackbar.error('Invoice', msg);
    } finally {
      isSavingInvoice.value = false;
    }
  }
}
