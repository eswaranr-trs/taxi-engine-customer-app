import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/data/repositories/offer_api/offer_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/offers/models/offer_model.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';

class OffersController extends GetxController {
  final OfferRepository _repo = OfferRepository();

  final RxList<OfferModel> offers = <OfferModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final RxString serviceType = ''.obs;

  Future<void> fetchOffers() async {
    try {
      isLoading.value = true;
      error.value = null;
      final st = Get.isRegistered<TripController>() ? Get.find<TripController>().serviceType : '';
      serviceType.value = st;
      offers.assignAll(await _repo.getEligibleOffers(st));
    } catch (e) {
      error.value = e is ApiException ? e.message : 'Could not load offers';
    } finally {
      isLoading.value = false;
    }
  }
}
