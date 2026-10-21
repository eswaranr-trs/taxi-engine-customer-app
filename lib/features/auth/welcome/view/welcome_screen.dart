import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/features/auth/welcome/controller/welcome_controller.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomeScreen extends GetView<WelcomeController> {
  const WelcomeScreen({super.key});

  List<Map<String, dynamic>> get _slides => [
    {
      'image': 'assets/images/onboarding_taxi.png',
      'title': 'onboarding_title_1'.tr,
      'title2': 'onboarding_title2_1'.tr,
      'subtitle': 'onboarding_subtitle_1'.tr,
    },
    {
      'image': 'assets/images/onboarding_address.png',
      'title': 'onboarding_title_2'.tr,
      'title2': 'onboarding_title2_2'.tr,
      'subtitle': 'onboarding_subtitle_2'.tr,
    },
    {
      'image': 'assets/images/onboarding_payment.png',
      'title': 'onboarding_title_3'.tr,
      'title2': 'onboarding_title2_3'.tr,
      'subtitle': 'onboarding_subtitle_3'.tr,
    },
  ];

  void navigatToSignUp() {
    LocalStorageService.setIsNewUser(false);
    Get.toNamed(AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
            child: GestureDetector(
              onTap: navigatToSignUp,
              child: CustomText(text: 'Skip', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.lightText),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  controller.onPageChanged(index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.32,
                            child: Image.asset(slide['image'], fit: BoxFit.contain),
                          ),
                        ),
                        40.height,
                        Flexible(
                          child: CustomText(
                            text: slide['title'],
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkSlate,
                            textAlign: TextAlign.start,
                            maxLines: 2,
                          ),
                        ),

                        Flexible(
                          child: CustomText(
                            text: slide['title2'],
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            textAlign: TextAlign.start,
                          ),
                        ),

                        16.height,
                        CustomText(
                          text: slide['subtitle'],
                          fontSize: 16,
                          maxLines: 5,
                          color: AppColors.slate500,
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SmoothPageIndicator(
              controller: controller.pageController,
              count: _slides.length,
              effect: ExpandingDotsEffect(
                dotColor: AppColors.grey300,
                activeDotColor: AppColors.primary,
                spacing: 8.0,
                dotWidth: 10.0,
                dotHeight: 10.0,
                paintStyle: PaintingStyle.fill,
              ),
              onDotClicked: (index) {},
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15.0, left: 280.0, bottom: 15.0),
              child: GestureDetector(
                onTap: () {
                  if (controller.currentPage.value == _slides.length - 1) {
                    controller.onNext();
                  } else {
                    controller.nextPage();
                  }
                },
                child: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 40,
                  child: Icon(Icons.keyboard_tab, color: AppColors.white, size: 24),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
