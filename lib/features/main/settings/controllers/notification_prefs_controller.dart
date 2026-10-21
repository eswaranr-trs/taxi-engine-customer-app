import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/data/repositories/notification_api/notification_repository.dart';

class NotificationPrefsController extends GetxController {
  final NotificationRepository _repo = NotificationRepository();

  final RxList<String> available = <String>[].obs;
  final RxList<String> allowed = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  bool isOn(String type) => allowed.contains(type);

  Future<void> fetch() async {
    try {
      isLoading.value = true;
      error.value = null;
      final r = await _repo.getPreferences();
      available.assignAll(r.available);
      allowed.assignAll(r.allowed);
    } catch (e) {
      error.value = e is ApiException ? e.message : 'Could not load preferences';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggle(String type, bool on) async {
    final prev = List<String>.from(allowed);
    if (on) {
      if (!allowed.contains(type)) allowed.add(type);
    } else {
      allowed.remove(type);
    }
    try {
      isSaving.value = true;
      await _repo.updatePreferences(enable: on ? [type] : const [], disable: on ? const [] : [type]);
    } catch (e) {
      allowed.assignAll(prev);
      AppSnackbar.error('Error', e is ApiException ? e.message : 'Could not save preference');
    } finally {
      isSaving.value = false;
    }
  }
}
