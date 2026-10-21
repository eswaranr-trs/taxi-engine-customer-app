import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/data/repositories/saved_address_api/saved_address_repository.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/model/saved_address_model.dart';

class SavedAddressesController extends GetxController {
  final SavedAddressRepository _repository = SavedAddressRepository();

  var addresses = <AddressModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedAddresses();

    if (Get.isRegistered<ConnectivityService>()) {
      ever(Get.find<ConnectivityService>().isReachable, (bool reachable) {
        if (reachable) loadSavedAddresses();
      });
    }
  }

  List<AddressModel> get _defaultSlots => [
    AddressModel(id: '', nickname: 'Home', fullAddress: '', type: 'home', order: 0),
    AddressModel(id: '', nickname: 'Work', fullAddress: '', type: 'work', order: 1),
  ];

  String _msg(Object e, String fallback) => e is ApiException ? e.message : fallback;
  Future<void> loadSavedAddresses() async {
    try {
      isLoading.value = true;
      final raw = await _repository.getAddresses();
      final list = raw.map(AddressModel.fromJson).toList();

      if (!list.any((a) => a.type == 'home')) list.insert(0, _defaultSlots[0]);
      if (!list.any((a) => a.type == 'work')) {
        list.insert(list.indexWhere((a) => a.type == 'home') + 1, _defaultSlots[1]);
      }

      addresses.assignAll(list);
    } catch (e) {
      addresses.assignAll(_defaultSlots);
      AppSnackbar.error('Error', _msg(e, 'Failed to load addresses'));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addAddress(AddressModel address) async {
    final customCount = addresses.where((e) => e.type == 'custom').length;
    if (customCount >= 10) {
      AppSnackbar.warning('Limit Reached', 'You can only add up to 10 custom places');
      return;
    }
    try {
      isLoading.value = true;
      await _repository.createAddress(address.toApiBody());
      await loadSavedAddresses();
      AppSnackbar.success('Success', 'Address added successfully');
    } catch (e) {
      AppSnackbar.error('Error', _msg(e, 'Failed to add address'));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAddress(AddressModel address) async {
    try {
      isLoading.value = true;
      if (!address.isPersisted) {
        await _repository.createAddress(address.toApiBody());
      } else {
        await _repository.updateAddress(address.id, address.toApiBody());
      }
      await loadSavedAddresses();
      AppSnackbar.success('Success', 'Address updated successfully');
    } catch (e) {
      AppSnackbar.error('Error', _msg(e, 'Failed to update address'));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      isLoading.value = true;
      await _repository.deleteAddress(id);
      await loadSavedAddresses();
      AppSnackbar.success('Success', 'Address deleted successfully');
    } catch (e) {
      AppSnackbar.error('Error', _msg(e, 'Failed to delete address'));
    } finally {
      isLoading.value = false;
    }
  }
}
