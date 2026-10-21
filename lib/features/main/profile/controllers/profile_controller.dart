import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/secure_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/socket_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/data/repositories/profile_api/profile_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/upload_api/upload_repository.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/active_trips_controller.dart';
import 'package:orange_taxi_customer_app/features/main/my_trips/controllers/my_trips_controller.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/controller/saved_address_controller.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/controllers/trip_state_controller.dart';
import '../models/user_profile_model.dart';

import 'package:smart_auth/smart_auth.dart';

class ProfileController extends GetxController {
  final ProfileRepository _profileRepository = ProfileRepository();
  final UploadRepository _uploadRepository = UploadRepository();
  final ImagePicker _picker = ImagePicker();

  var isLoading = false.obs;
  var isUploadingImage = false.obs;
  var userProfile = Rxn<UserProfile>();
  var savedAddresses = <String, Map<String, dynamic>>{}.obs;
  final token = SecureStorageService.getAuthToken();
  String? appSignature = 'signature';

  @override
  void onInit() {
    super.onInit();
    getDetails();
    logAppSignature();

    if (Get.isRegistered<ConnectivityService>()) {
      ever(Get.find<ConnectivityService>().isReachable, (bool reachable) {
        if (reachable) getDetails();
      });
    }
  }

  Future<void> loadSavedAddresses() async {
    final addresses = await LocalStorageService.getSavedAddresses();
    savedAddresses.assignAll(addresses);
  }

  Future<String?> logAppSignature() async {
    if (!kDebugMode || !GetPlatform.isAndroid) return null;
    final res = await SmartAuth.instance.getAppSignature();
    appSignature = res.data;
    debugPrint('App Signature: $appSignature');
    if (appSignature == null) debugPrint('App Signature failed: ${res.error}');
    return appSignature;
  }

  void logout() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (Get.isRegistered<TripStateService>()) {
      Get.find<TripStateService>().resetToDummy();
    }
    SocketService().disconnect();

    await LocalStorageService.clear();
    await SecureStorageService.clear();
    await Get.offAllNamed('/login');

    await Get.delete<ActiveTripsController>(force: true);
    await Get.delete<MyTripsController>(force: true);
    await Get.delete<SavedAddressesController>(force: true);
    await Get.delete<TripStateController>(force: true);
    await Get.delete<TripController>(force: true);
    await Get.delete<HomeController>(force: true);
    await Get.delete<ProfileController>(force: true);
  }

  Future<void> getDetails() async {
    try {
      isLoading.value = true;
      final data = await _profileRepository.getProfile();
      userProfile.value = UserProfile.fromJson(data);
    } catch (e) {
      if (Get.find<ConnectivityService>().isReachable.value) {
        AppSnackbar.error('Error', 'Failed to load profile');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadProfileImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1080);
      if (picked == null) return;

      isUploadingImage.value = true;
      final url = await _uploadRepository.uploadImage(picked.path, picked.name);
      final data = await _profileRepository.updateProfilePicture(url);

      userProfile.value = data.isNotEmpty ? UserProfile.fromJson(data) : userProfile.value?.copyWith(avatarUrl: url);
      AppSnackbar.success('Success', 'Profile photo updated');
    } catch (e) {
      AppSnackbar.error('Error', e is ApiException ? e.message : 'Failed to update photo');
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> updateProfile({String? name, String? email, String? phone, String? dateOfBirth}) async {
    try {
      isLoading.value = true;

      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body["name"] = name;
      if (email != null && email.isNotEmpty) body["email"] = email;
      if (phone != null && phone.isNotEmpty) body["phone"] = phone;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) body["dateOfBirth"] = dateOfBirth;

      final data = await _profileRepository.updateProfile(body);

      userProfile.value = data.isNotEmpty
          ? UserProfile.fromJson(data)
          : userProfile.value?.copyWith(name: name, email: email, phone: phone, dateOfBirth: dateOfBirth);

      final stored = await LocalStorageService.getUser() ?? <String, dynamic>{};
      if (name != null && name.isNotEmpty) stored['name'] = name;
      if (email != null && email.isNotEmpty) stored['email'] = email;
      if (phone != null && phone.isNotEmpty) stored['phone'] = phone;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) stored['dateOfBirth'] = dateOfBirth;
      await LocalStorageService.saveUser(Map<String, dynamic>.from(stored));

      Get.back();
      AppSnackbar.success('Success', 'Profile updated successfully');
    } catch (e) {
      AppSnackbar.error('Error', 'Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }
}
