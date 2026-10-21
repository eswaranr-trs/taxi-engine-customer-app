import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/data/repositories/legal_api/legal_repository.dart';
import 'package:orange_taxi_customer_app/features/legal/model/legal_document.dart';

class LegalController extends GetxController {
  final LegalRepository _legalRepository = LegalRepository();

  final LegalDocType docType;
  LegalController(this.docType);

  final Rxn<LegalDocument> document = Rxn<LegalDocument>();
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  String get fallbackTitle => docType == LegalDocType.privacyPolicy ? 'Privacy Policy' : 'Terms & Conditions';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      document.value = await _legalRepository.getDocument(docType);
    } catch (e) {
      error.value = e is ApiException ? e.message : 'Failed to load document';
    } finally {
      isLoading.value = false;
    }
  }
}
