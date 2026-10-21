import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/data/repositories/promo_api/promo_code_repository.dart';
import 'package:orange_taxi_customer_app/features/main/offers/models/promo_code_model.dart';

class PromoCodesController extends GetxController {
  final PromoCodeRepository _repo = PromoCodeRepository();

  final RxList<PromoCodeModel> promoCodes = <PromoCodeModel>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> fetchPromoCodes() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      final list = await _repo.getEligiblePromoCodes();
      final DateTime now = DateTime.now();
      list.removeWhere((p) => p.expiryDate != null && p.expiryDate!.toLocal().isBefore(now));
      promoCodes.assignAll(list);
    } catch (_) {
      promoCodes.clear();
    } finally {
      isLoading.value = false;
    }
  }

  List<PromoCodeModel> sortedFor(double fare) {
    final list = promoCodes.toList();
    list.sort((a, b) {
      final bool ae = a.isEligibleFor(fare);
      final bool be = b.isEligibleFor(fare);
      if (ae != be) return ae ? -1 : 1;
      return b.savingsFor(fare).compareTo(a.savingsFor(fare));
    });
    return list;
  }
}
