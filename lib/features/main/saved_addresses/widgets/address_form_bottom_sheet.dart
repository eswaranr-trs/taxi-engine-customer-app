import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/controller/saved_address_controller.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/model/saved_address_model.dart';

class AddressFormBottomSheet extends StatefulWidget {
  final AddressModel? existingAddress;

  const AddressFormBottomSheet({super.key, this.existingAddress});

  @override
  State<AddressFormBottomSheet> createState() => _AddressFormBottomSheetState();
}

class _AddressFormBottomSheetState extends State<AddressFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  String _selectedType = 'custom';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingAddress != null;
    final isHomeOrWork = _selectedType == 'home' || _selectedType == 'work';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              20.height,
              CustomText(
                text: isEdit ? 'Edit Address' : 'Add New Address',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),

              20.height,
              if (!isHomeOrWork) ...[
                _buildTextField(
                  label: 'Nickname',
                  controller: _nicknameController,
                  hint: 'e.g. Gym, Mom\'s House',
                  validator: (v) => v == null || v.isEmpty ? 'Nickname is required' : null,
                ),
                16.height,
              ],

              _buildTextField(
                label: 'Full Address',
                controller: _addressController,
                hint: 'Tap to select address',
                readOnly: true,
                isSearch: true,
                onTap: () async {
                  final result = await Get.toNamed('/locationSearch', arguments: 'SavedAddress');
                  if (result != null && result is Map) {
                    setState(() {
                      _addressController.text = result['mainText'] ?? '';
                      _selectedLat = result['lat'];
                      _selectedLng = result['lng'];
                    });
                  }
                },
                validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
              ),
              // 16.height,  

              // _buildTextField(
              //   label: 'Notes (Optional)',
              //   controller: _notesController,
              //   hint: 'e.g. Near the supermarket, ring bell twice',
              //   maxLines: 2,
              // ),
              24.height,

              CustomButton(
                text: 'Save Address',
                onPressed: _submit,
                gradient: AppColors.gradientButton,
                textColor: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    _selectedType = addr?.type ?? 'custom';
    _nicknameController = TextEditingController(text: addr?.nickname ?? '');
    _addressController = TextEditingController(text: addr?.fullAddress ?? '');
    _notesController = TextEditingController(text: addr?.notes ?? '');
    _selectedLat = addr?.latitude;
    _selectedLng = addr?.longitude;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final controller = Get.find<SavedAddressesController>();

      final isHomeOrWork = _selectedType == 'home' || _selectedType == 'work';
      final finalNickname = isHomeOrWork ? (_selectedType == 'home' ? 'Home' : 'Work') : _nicknameController.text;

      final newAddress = AddressModel(
        id: widget.existingAddress?.id ?? '',
        nickname: finalNickname,
        fullAddress: _addressController.text,
        notes: _notesController.text,
        type: _selectedType,
        order: widget.existingAddress?.order ?? 0,
        latitude: _selectedLat ?? widget.existingAddress?.latitude,
        longitude: _selectedLng ?? widget.existingAddress?.longitude,
      );

      Get.back();

      if (widget.existingAddress != null) {
        controller.updateAddress(newAddress);
      } else {
        controller.addAddress(newAddress);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    bool? isSearch,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(text: label, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText),
        8.height,
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            suffixIcon: isSearch != null && isSearch
                ? GestureDetector(
                    onTap: onTap,
                    child: const Icon(Icons.search, color: AppColors.primary),
                  )
                : null,
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.grey200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.grey200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
