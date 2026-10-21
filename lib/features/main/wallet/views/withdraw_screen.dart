import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/controller/wallet_controller.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final WalletController controller = Get.find<WalletController>();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _confirmAccountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  static final NumberFormat _money = NumberFormat('#,##,##0.##', 'en_IN');
  static final RegExp _ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bool ok = await controller.requestWithdrawal(
      amount: _amount,
      accountNumber: _accountController.text.trim(),
      ifscCode: _ifscController.text.trim().toUpperCase(),
      bankName: _bankNameController.text.trim(),
    );
    if (ok && mounted) Get.back();
  }

  String? _validateAmount(String? value) {
    final double amount = double.tryParse(value?.trim() ?? '') ?? 0;
    if (amount <= 0) return 'Enter an amount to withdraw';
    if (amount > controller.walletBalance.value) return 'Amount exceeds your wallet balance';
    return null;
  }

  String? _validateAccount(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your account number';
    if (v.length < 9 || v.length > 18) return 'Account number must be 9–18 digits';
    return null;
  }

  String? _validateConfirmAccount(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Re-enter your account number';
    if (v != _accountController.text.trim()) return 'Account numbers do not match';
    return null;
  }

  String? _validateBankName(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your bank name';
    if (v.length < 3) return 'Enter a valid bank name';
    return null;
  }

  String? _validateIfsc(String? value) {
    final String v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'Enter the IFSC code';
    if (!_ifscPattern.hasMatch(v)) return 'Enter a valid 11-character IFSC code';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const CustomText(
          text: 'Withdraw',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.darkSlate,
          textAlign: TextAlign.start,
        ),
        elevation: 0,
        backgroundColor: AppColors.grey50,
        surfaceTintColor: AppColors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountCard(),
                      22.height,
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: CustomText(
                          text: 'BANK ACCOUNT',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey400,
                          letterSpacing: 1.2,
                          textAlign: TextAlign.start,
                        ),
                      ),
                      10.height,
                      _buildBankCard(),
                      14.height,
                      _buildNotice(),
                    ],
                  ),
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))],
  );

  Widget _buildAmountCard() {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.grey500),
                10.width,
                Expanded(
                  child: Obx(
                    () => CustomText(
                      text: controller.balanceLoaded.value
                          ? 'Available  ₹${_money.format(controller.walletBalance.value)}'
                          : 'Available  ––',
                      fontSize: 14,
                      color: AppColors.grey600,
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey100),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  text: 'AMOUNT',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey400,
                  letterSpacing: 1.2,
                  textAlign: TextAlign.start,
                ),
                10.height,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: CustomText(
                        text: '₹',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: _amount > 0 ? AppColors.darkSlate : AppColors.grey300,
                      ),
                    ),
                    8.width,
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: _validateAmount,
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) =>
                                RegExp(r'^\d{0,6}(\.\d{0,2})?$').hasMatch(newValue.text) ? newValue : oldValue,
                          ),
                        ],
                        cursorColor: AppColors.primary,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkSlate,
                          fontFamily: 'Poppins',
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.grey300,
                            fontFamily: 'Poppins',
                          ),
                          errorStyle: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.redAccent),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard() {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        children: [
          _field(
            label: 'Bank name',
            hint: 'e.g. State Bank of India',
            icon: Icons.account_balance_rounded,
            controller: _bankNameController,
            keyboardType: TextInputType.text,
            capitalization: TextCapitalization.words,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .&'-]")),
              LengthLimitingTextInputFormatter(60),
            ],
            validator: _validateBankName,
          ),
          const Divider(height: 1, indent: 66, color: AppColors.grey100),
          _field(
            label: 'Account number',
            hint: 'Enter account number',
            icon: Icons.account_balance_outlined,
            controller: _accountController,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(18)],
            validator: _validateAccount,
          ),
          const Divider(height: 1, indent: 66, color: AppColors.grey100),
          _field(
            label: 'Confirm account number',
            hint: 'Re-enter account number',
            icon: Icons.verified_user_outlined,
            controller: _confirmAccountController,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(18)],
            validator: _validateConfirmAccount,
          ),
          const Divider(height: 1, indent: 66, color: AppColors.grey100),
          _field(
            label: 'IFSC code',
            hint: 'e.g. SBIN0001234',
            icon: Icons.tag_rounded,
            controller: _ifscController,
            keyboardType: TextInputType.text,
            capitalization: TextCapitalization.characters,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(11),
              TextInputFormatter.withFunction(
                (oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase()),
              ),
            ],
            validator: _validateIfsc,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required List<TextInputFormatter> formatters,
    required String? Function(String?) validator,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          14.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(text: label, fontSize: 11, color: AppColors.grey500, textAlign: TextAlign.start),
                4.height,
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textCapitalization: capitalization,
                  inputFormatters: formatters,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: validator,
                  cursorColor: AppColors.primary,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkSlate,
                    letterSpacing: 0.8,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey300,
                      letterSpacing: 0,
                    ),
                    errorStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.redAccent),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return ClipRRect(
      borderRadius: AppRadius.rSm,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.warning),
            Expanded(
              child: Container(
                color: AppColors.white,
                padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(color: AppColors.grey50, shape: BoxShape.circle),
                      child: const Icon(Icons.info, size: 20, color: AppColors.warning),
                    ),
                    12.width,
                    const Expanded(
                      child: CustomText(
                        text:
                            'Money is transferred only to this account and usually arrives within 1–2 working days. Double-check the details — transfers to a wrong account cannot be reversed.',
                        fontSize: 11,
                        color: AppColors.slate500,
                        textAlign: TextAlign.left,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.grey100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            final bool loading = controller.isWithdrawing.value;
            final double amount = _amount;
            final bool hasAmount = amount > 0;

            return CustomButton(
              text: loading ? 'Processing...' : (hasAmount ? 'Withdraw ₹${_money.format(amount)}' : 'Withdraw'),
              loading: loading,
              enabled: hasAmount && !loading,
              onPressed: _submit,
              gradient: hasAmount ? AppColors.gradientButton : null,
              textColor: hasAmount ? AppColors.white : AppColors.grey400,
            );
          }),
          10.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 11, color: AppColors.grey400),
              6.width,
              const CustomText(text: 'Processed securely to your bank account', fontSize: 10, color: AppColors.grey400),
            ],
          ),
        ],
      ),
    );
  }
}
