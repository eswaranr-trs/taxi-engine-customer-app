import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/features/legal/controller/legal_controller.dart';

class LegalScreen extends GetView<LegalController> {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        surfaceTintColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Obx(
          () => CustomText(
            text: controller.document.value?.title ?? controller.fallbackTitle,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final error = controller.error.value;
          if (error != null) return _buildError(error);

          final doc = controller.document.value;
          if (doc == null || doc.content.trim().isEmpty) {
            return _buildError('This document is not available right now.');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                8.height,
                Html(
                  data: doc.content,
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontFamily: 'Poppins',
                      fontSize: FontSize(14),
                      color: AppColors.slate500,
                      lineHeight: LineHeight.number(1.6),
                    ),
                    'h1': Style(fontSize: FontSize(20), color: AppColors.darkSlate),
                    'h2': Style(fontSize: FontSize(17), color: AppColors.darkSlate),
                    'h3': Style(fontSize: FontSize(15), color: AppColors.darkSlate),
                    'strong': Style(color: AppColors.darkSlate),
                    'a': Style(color: AppColors.primary),
                  },
                ),
                10.height,
                if (doc.lastUpdatedAt != null)
                  CustomText(
                    text: 'Last updated ${DateFormat('MMM dd, yyyy').format(doc.lastUpdatedAt!)}',
                    fontSize: 10,
                    color: AppColors.grey600,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.grey400, size: 48),
            16.height,
            CustomText(text: message, fontSize: 14, color: AppColors.grey600, textAlign: TextAlign.center, maxLines: 4),
            24.height,
            CustomButton(
              text: 'Retry',
              color: AppColors.primary,
              textColor: AppColors.white,
              onPressed: controller.load,
            ),
          ],
        ),
      ),
    );
  }
}
