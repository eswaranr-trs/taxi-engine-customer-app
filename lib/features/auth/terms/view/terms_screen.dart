import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import '../controller/terms_controller.dart';

class TermsScreen extends GetView<TermsController> {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const CustomText(
          text: 'Legal & Consent',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(
                text: 'We value your privacy.',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
              ),
              16.height,
              const CustomText(
                text:
                    'To comply with the DPDP Act 2023, we require your explicit consent to collect and process your data. By proceeding, we will securely log your consent timestamp and IP address for compliance auditing.',
                fontSize: 14,
                color: AppColors.slate500,
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
