import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/confirm_dialog/confirm_dialog.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/secure_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/payment_api/payment_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/model/transaction_model.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

enum PaymentMethod { none, upi, creditCard, debitCard, digitalWallet, savedCard }

class WalletController extends GetxController {
  static void Function()? pendingAfterTopUp;

  final ApiService _apiService = ApiService();
  final PaymentRepository _paymentRepository = PaymentRepository();

  final userToken = SecureStorageService.getAuthToken();

  var isLoading = false.obs;
  var transactions = <TransactionModel>[].obs;
  var walletBalance = 0.0.obs;
  final RxBool balanceLoaded = false.obs;
  final RxString selectedFilter = 'All'.obs;

  List<TransactionModel> get filteredTransactions {
    switch (selectedFilter.value) {
      case 'Credits':
        return transactions.where((t) => t.transactionType.toLowerCase() == 'credit').toList();
      case 'Debits':
        return transactions.where((t) => t.transactionType.toLowerCase() == 'debit').toList();
      default:
        return transactions;
    }
  }

  final TextEditingController amountController = TextEditingController();
  var addMoneyAmount = ''.obs;
  var selectedPaymentMethod = PaymentMethod.upi.obs;
  var isAddingMoney = false.obs;

  final AuthRepository _authRepository = AuthRepository();
  String? _razorpayKey;
  final Razorpay _razorpay = Razorpay();
  String? _currentTransactionId;

  String? lastTransactionId;
  String? lastOrderId;
  double lastTopUpAmount = 0;
  DateTime? lastTopUpDate;

  String get paymentMethodLabel {
    switch (selectedPaymentMethod.value) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet';
      case PaymentMethod.savedCard:
        return 'Saved Card';
      default:
        return 'Razorpay';
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchCustomerWallet();
    fetchWalletHistory();
    _fetchRazorpayKey();

    if (Get.isRegistered<ConnectivityService>()) {
      ever(Get.find<ConnectivityService>().isReachable, (bool reachable) {
        if (reachable) {
          fetchCustomerWallet();
          fetchWalletHistory();
        }
      });
    }

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    amountController.addListener(() {
      addMoneyAmount.value = amountController.text;
    });
  }

  Future<void> _fetchRazorpayKey() async {
    _razorpayKey = await _authRepository.getConfigValue('razorpayKey');
  }

  Future<void> proceedAddMoney() async {
    final raw = amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(raw) ?? 0;

    if (amount <= 0) {
      AppSnackbar.error('Error', 'Enter a valid amount');
      return;
    }

    try {
      isAddingMoney.value = true;
      final response = await _paymentRepository.createWalletRecharge(amount: amount);

      final data = response['data'] as Map<String, dynamic>;
      _currentTransactionId = data['transactionId']?.toString();
      lastTransactionId = _currentTransactionId;
      lastOrderId = data['orderId']?.toString();
      lastTopUpAmount = ((data['amount'] as num?)?.toDouble() ?? 0) / 100;

      final orderId = data['orderId']?.toString();
      if (orderId == null || orderId.isEmpty) {
        AppSnackbar.error('Error', 'Order ID missing from server');
        return;
      }

      _razorpayKey ??= await _authRepository.getConfigValue('razorpayKey');
      if (_razorpayKey == null || _razorpayKey!.isEmpty) {
        AppSnackbar.error('Error', 'Payment config unavailable');
        return;
      }

      final warning = data['warningMessage']?.toString();
      if (warning != null && warning.isNotEmpty) {
        isAddingMoney.value = false;
        final proceed = await AppConfirmDialog.show(
          title: 'Before you recharge',
          message: warning,
          confirmText: 'Proceed',
          cancelText: 'Cancel',
          icon: Icons.info_outline,
        );
        if (!proceed) return;
        isAddingMoney.value = true;
      }
      final amountPaise = data['amount'];

      final options = {
        'key': _razorpayKey!,
        'order_id': orderId,
        'amount': amountPaise,
        'currency': data['currency']?.toString() ?? 'INR',
        'name': 'Orange Taxi',
        'description': 'Wallet Recharge',
      };

      _lastRazorpayId = orderId;
      _gatewayOpen = true;
      _razorpay.open(options);
      amountController.clear();
    } catch (e) {
      debugPrint('proceedAddMoney error: $e');
      AppSnackbar.error('Error', e is ApiException ? e.message : 'Failed to start recharge');
    } finally {
      if (!_gatewayOpen) isAddingMoney.value = false;
    }
  }

  bool _gatewayOpen = false;
  String _lastRazorpayId = '';

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('WALLET RECHARGE SUCCESS ${response.paymentId} txn=$_currentTransactionId');
    _gatewayOpen = false;
    isAddingMoney.value = false;
    lastTopUpDate = DateTime.now();
    refreshWallet();
    Get.offNamed(AppRoutes.addMoneySuccess);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('WALLET RECHARGE ERROR ${response.code} ${response.message}');
    _gatewayOpen = false;
    isAddingMoney.value = false;
    _paymentRepository.failTransaction(_lastRazorpayId);
    _lastRazorpayId = '';
    AppSnackbar.error('Payment Failed', response.message ?? 'Recharge failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('WALLET ${response.walletName}');
    _gatewayOpen = false;
    isAddingMoney.value = false;
  }

  Future<void> refreshWallet() async {
    await fetchCustomerWallet();
    await fetchWalletHistory();
  }

  final RxBool isWithdrawing = false.obs;

  Future<bool> requestWithdrawal({
    required double amount,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
  }) async {
    if (isWithdrawing.value) return false;
    try {
      isWithdrawing.value = true;
      final response = await _paymentRepository.requestWalletWithdrawal(
        amount: amount,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        bankName: bankName,
      );
      Get.back();
      AppSnackbar.success(
        'Withdrawal Requested',
        response['message']?.toString() ?? 'Your withdrawal request has been submitted',
      );

      await refreshWallet();
      return true;
    } catch (e) {
      AppSnackbar.error('Withdrawal Failed', e is ApiException ? e.message : 'Failed to request withdrawal');
      return false;
    } finally {
      isWithdrawing.value = false;
    }
  }

  @override
  void onClose() {
    amountController.clear();
    addMoneyAmount.value = '';
    _razorpay.clear();
    super.onClose();
  }

  Future<void> fetchCustomerWallet() async {
    try {
      final response = await _paymentRepository.getCustomerWallet();
      if (response != null) {
        final balance = response['data']?['balance'];
        walletBalance.value = double.tryParse(balance?.toString() ?? '') ?? 0.0;
      }
    } catch (e) {
      AppSnackbar.error('Error', 'Failed to fetch customer wallet');
    } finally {
      balanceLoaded.value = true;
    }
  }

  Future<void> fetchWalletHistory() async {
    try {
      isLoading.value = true;

      final response = await _apiService.get(AppEndpoints.customerWalletHistory);

      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> dataList = response.data['data'] as List<dynamic>;

        transactions.value = dataList.map((e) {
          return TransactionModel(
            transactionId: e['transactionId']?.toString() ?? '',
            amount: double.tryParse(e['amount']?.toString() ?? '') ?? 0.0,
            transactionType: e['type']?.toString() ?? '',
            type: e['type']?.toString() ?? '',
            date: DateTime.tryParse(e['createdAt']?.toString() ?? '') ?? DateTime.now(),
            reason: e['description']?.toString() ?? '',
            description: e['description']?.toString() ?? '',
            status: e['status']?.toString() ?? '',
          );
        }).toList();
      } else {
        transactions.clear();
      }
    } catch (e) {
      transactions.clear();
      AppSnackbar.error('Error', 'Failed to fetch wallet history');
    } finally {
      isLoading.value = false;
    }
  }
}
