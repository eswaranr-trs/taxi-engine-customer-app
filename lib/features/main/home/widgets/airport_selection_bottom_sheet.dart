import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/services/location_service/location_service.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';
import 'package:orange_taxi_customer_app/data/models/airport_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AirportSelectionBottomSheet extends StatefulWidget {
  const AirportSelectionBottomSheet({super.key});

  @override
  State<AirportSelectionBottomSheet> createState() => _AirportSelectionBottomSheetState();
}

class _AirportSelectionBottomSheetState extends State<AirportSelectionBottomSheet> {
  final HomeController controller = Get.find<HomeController>();
  final TripController tripController = Get.find<TripController>();
  final LocationService _locationService = LocationService();

  AirportModel? expandedAirport;
  String? _resolvingId;

  @override
  void initState() {
    super.initState();
    if (tripController.airportCities.isEmpty) tripController.getTripTypes();
  }

  List<AirportModel> get _airports {
    final cities = tripController.airportCities;
    final list = AirportModel.forCities(cities);
    return list.isNotEmpty ? list : controller.mockAirports;
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height * 0.7;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          12.height,
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          18.height,
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CustomText(
                text: 'Select Airport & Terminal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
                textAlign: TextAlign.start,
              ),
            ),
          ),
          16.height,
          Flexible(
            child: Obx(() {
              tripController.tripData.length;
              final airports = _airports;
              if (airports.isEmpty) return _emptyState();

              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: airports.length,
                separatorBuilder: (_, _) => 12.height,
                itemBuilder: (context, index) {
                  final airport = airports[index];
                  final isExpanded = expandedAirport?.id == airport.id;
                  return _buildAirportCard(airport, isExpanded);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
          Obx(
            () => tripController.isLoading.value
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.local_airport_outlined, size: 34, color: AppColors.grey400),
          ),
          14.height,
          const CustomText(
            text: 'No airport cities available',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkSlate,
          ),
          6.height,
          const CustomText(
            text: 'Airport transfer cities come from the service list. Try again in a moment.',
            fontSize: 12,
            color: AppColors.grey500,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
          16.height,
          GestureDetector(
            onTap: () => tripController.getTripTypes(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const CustomText(
                text: 'Retry',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirportCard(AirportModel airport, bool isExpanded) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpanded ? AppColors.primary : AppColors.grey100, width: 1.5),
        boxShadow: isExpanded
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => expandedAirport = isExpanded ? null : airport),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_airport, color: AppColors.primary, size: 20),
                  ),
                  14.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: airport.name,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkSlate,
                          textAlign: TextAlign.start,
                          maxLines: 2,
                        ),
                        if (airport.city.isNotEmpty) ...[
                          2.height,
                          CustomText(
                            text: airport.city,
                            fontSize: 11,
                            color: AppColors.grey500,
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Column(children: airport.terminals.map(_buildTerminalRow(airport)).toList()),
            ),
        ],
      ),
    );
  }

  Widget Function(TerminalModel) _buildTerminalRow(AirportModel airport) {
    return (TerminalModel terminal) {
      final bool isSelected = controller.selectedTerminal.value?.id == terminal.id;
      final bool isResolving = _resolvingId == terminal.id;
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isResolving ? null : () => _selectTerminal(airport, terminal),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.business_outlined, color: AppColors.grey500, size: 18),
                10.width,
                Expanded(
                  child: CustomText(
                    text: terminal.name,
                    fontSize: 14,
                    color: AppColors.darkSlate,
                    textAlign: TextAlign.start,
                  ),
                ),
                if (isResolving)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                else if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ),
      );
    };
  }

  Future<void> _selectTerminal(AirportModel airport, TerminalModel terminal) async {
    TerminalModel resolved = terminal;

    if (!terminal.hasCoords) {
      setState(() => _resolvingId = terminal.id);
      final coords = await _lookupAirportCoords(airport);
      if (!mounted) return;
      setState(() => _resolvingId = null);

      if (coords == null) {
        AppSnackbar.error('Airport', 'Could not locate ${airport.name}. Pick the address manually.');
        return;
      }
      resolved = terminal.copyWith(lat: coords.latitude, lng: coords.longitude);
    }

    controller.selectedAirport.value = airport;
    controller.selectedTerminal.value = resolved;

    final latLng = LatLng(resolved.lat, resolved.lng);
    final address = '${resolved.name}, ${airport.name}';
    Get.back();
    controller.moveToLocation(latLng, address, isPickup: !controller.isToAirport.value);
  }

  Future<LatLng?> _lookupAirportCoords(AirportModel airport) async {
    try {
      final query = airport.city.isNotEmpty ? '${airport.city} airport' : airport.name;
      final predictions = await _locationService.getPlacePredictions(query);
      if (predictions.isEmpty) return null;

      final details = await _locationService.getPlaceDetails(predictions.first.placeId);
      if (details == null || (details.latitude == 0 && details.longitude == 0)) return null;
      return LatLng(details.latitude, details.longitude);
    } catch (e) {
      print('[airport] coords lookup failed for ${airport.city}: $e');
      return null;
    }
  }
}
