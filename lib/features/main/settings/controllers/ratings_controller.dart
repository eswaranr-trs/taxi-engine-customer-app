import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/data/repositories/rating_api/ratings_repository.dart';
import 'package:orange_taxi_customer_app/features/main/settings/models/rating_model.dart';

class RatingsController extends GetxController {
  final RatingsRepository _repo = RatingsRepository();

  final RxList<RatingModel> items = <RatingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  double get average {
    if (items.isEmpty) return 0;
    final total = items.fold<int>(0, (sum, r) => sum + r.rating);
    return total / items.length;
  }

  int get total => items.length;
  int countFor(int star) => items.where((r) => r.rating == star).length;

  Future<void> fetch() async {
    try {
      isLoading.value = true;
      error.value = null;
      items.assignAll(await _repo.getRatings());
    } catch (e) {
      error.value = e is ApiException ? e.message : 'Could not load ratings';
    } finally {
      isLoading.value = false;
    }
  }
}
