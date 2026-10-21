import 'package:flutter/cupertino.dart' show CupertinoPicker, CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/app_widgets/app_widgets.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import '../controllers/profile_controller.dart';
import 'package:orange_taxi_customer_app/core/services/support_service/support_service.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  Widget _buildProfileSkeleton() {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            Row(
              children: [
                const SkeletonBox(width: 88, height: 88, radius: 44),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 150, height: 18),
                      SizedBox(height: 10),
                      SkeletonBox(width: 120, height: 13),
                      SizedBox(height: 8),
                      SkeletonBox(width: 180, height: 13),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ...List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: SkeletonBox(width: double.infinity, height: 56, radius: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDob(String dob) {
    return DateFormat('d MMM yyyy').format(DateTime.parse(dob));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        surfaceTintColor: AppColors.backgroundColor,
        centerTitle: true,
        title: CustomText(text: 'Profile', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.normalText),
      ),
      extendBody: true,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return _buildProfileSkeleton();
          }

          final profile = controller.userProfile.value;
          if (profile == null) {
            return const Center(child: CustomText(text: 'No profile data found'));
          }

          return AppRefreshIndicator(
            onRefresh: controller.getDetails,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Row(
                          children: [
                            Semantics(
                              button: true,
                              label: 'Change profile photo',
                              child: GestureDetector(
                                onTap: () => _showImageSourceSheet(context),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: AppShadows.lg,
                                      ),
                                      child: CircleAvatar(
                                        radius: 40,
                                        backgroundColor: AppColors.grey200,
                                        backgroundImage: profile.avatarUrl.isNotEmpty
                                            ? NetworkImage(profile.avatarUrl)
                                            : null,
                                        child: Obx(
                                          () => controller.isUploadingImage.value
                                              ? Container(
                                                  decoration: BoxDecoration(
                                                    color: AppColors.grey.withValues(alpha: 0.5),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Center(
                                                    child: CupertinoActivityIndicator(
                                                      radius: 12,
                                                      color: AppColors.white,
                                                    ),
                                                  ),
                                                )
                                              : profile.avatarUrl.isEmpty
                                              ? const Icon(Icons.person, size: 40, color: AppColors.grey400)
                                              : const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 2,
                                      bottom: 2,
                                      child: Container(
                                        height: 26,
                                        width: 26,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.white, width: 2.5),
                                        ),
                                        child: const Icon(Icons.camera_alt, color: AppColors.white, size: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            16.width,

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomText(
                                        text: profile.name,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkText,
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      GestureDetector(
                                        onTap: () => _showEditProfileSheet(context),
                                        child: Card(
                                          child: Container(
                                            height: 28,
                                            width: 28,
                                            decoration: BoxDecoration(
                                              color: AppColors.grey300,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.edit_outlined, color: AppColors.charcoal, size: 15),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  8.height,
                                  _buildContactRow(Icons.phone_outlined, profile.phone),
                                  if (profile.email.isNotEmpty && profile.email != 'No email') ...[
                                    6.height,
                                    _buildContactRow(Icons.email_outlined, profile.email),
                                  ],
                                  8.height,
                                  if (profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty) ...[
                                    _buildContactRow(Icons.cake_outlined, formatDob(profile.dateOfBirth!)),
                                    6.height,
                                  ],
                                ],
                              ),
                            ),

                            // 8.width,

                            // GestureDetector(
                            //   onTap: () => _showEditProfileSheet(context),
                            //   child: Container(
                            //     height: 28,
                            //     width: 28,
                            //     decoration: BoxDecoration(
                            //       color: AppColors.grey.withValues(alpha: 0.2),
                            //       borderRadius: BorderRadius.circular(10),
                            //     ),
                            //     child: const Icon(Icons.edit_outlined, color: AppColors.grey500, size: 15),
                            //   ),
                            // ),
                          ],
                        ),
                      ),

                      20.height,

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'RIDES',
                              value: profile.ridesCount.toString(),
                              valueColor: AppColors.black,
                            ),
                          ),
                          10.width,
                          Expanded(
                            child: _buildStatCard(
                              title: 'RATING',
                              value: profile.rating.toStringAsFixed(1),
                              valueColor: AppColors.primary,
                            ),
                          ),

                          10.width,
                          Expanded(
                            child: _buildStatCard(
                              title: 'MEMBER SINCE',
                              value: profile.memberYears,
                              valueColor: AppColors.black,
                            ),
                          ),
                        ],
                      ),

                      20.height,

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Column(
                          children: [
                            buildSettingsTile(
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: AppColors.successGreen,
                              iconBgColor: AppColors.successGreenLight,
                              title: 'Wallet',
                              subtitle: 'Balance & transactions',
                              onTap: () => Get.toNamed(AppRoutes.wallet),
                            ),
                            _buildDivider(),
                            buildSettingsTile(
                              icon: Icons.location_on_outlined,
                              iconColor: AppColors.info,
                              iconBgColor: AppColors.blue50,
                              title: 'Saved Addresses',
                              subtitle: 'Home, Work & Other',
                              onTap: () => Get.toNamed(AppRoutes.savedAddresses),
                            ),

                            _buildDivider(),
                            buildSettingsTile(
                              icon: Icons.support_agent_outlined,
                              iconColor: AppColors.teal,
                              iconBgColor: AppColors.tealLight,
                              title: 'Help & Support',
                              subtitle: '24/7 assistance',
                              onTap: SupportService.showSupportOptions,
                            ),
                            _buildDivider(),
                            buildSettingsTile(
                              icon: Icons.settings_outlined,
                              iconColor: AppColors.grey500,
                              iconBgColor: AppColors.grey100,
                              title: 'Settings',
                              subtitle: 'Privacy & App notifications',
                              onTap: () {
                                Get.toNamed(AppRoutes.settings);
                              },
                            ),
                            _buildDivider(),
                            buildSettingsTile(
                              icon: Icons.star_outline,
                              iconColor: AppColors.primary,
                              iconBgColor: AppColors.amber50,
                              title: 'My Ratings',
                              subtitle: 'See your ratings and reviews',
                              onTap: () {
                                Get.toNamed(AppRoutes.ratings);
                              },
                            ),
                            _buildDivider(),
                            buildSettingsTile(
                              icon: Icons.logout_outlined,
                              iconColor: AppColors.red500,
                              iconBgColor: AppColors.red50,
                              title: 'Logout',
                              titleColor: AppColors.red500,
                              showChevron: false,
                              onTap: () {
                                _showLogoutConfirmDialog(context);
                              },
                            ),
                          ],
                        ),
                      ),

                      26.height,

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [AppColors.amber400, AppColors.amber500, AppColors.amber600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber600.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -24,
                                bottom: -24,
                                child: Icon(
                                  Icons.card_giftcard,
                                  size: 130,
                                  color: AppColors.white.withValues(alpha: 0.15),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: const CustomText(
                                        text: 'REFER & EARN',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    12.height,
                                    const CustomText(
                                      text: 'Invite & Earn Rewards',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                      textAlign: TextAlign.left,
                                    ),

                                    CustomText(
                                      text:
                                          'Share your referral code with others. When they complete their first ride, you both earn exciting rewards. ', //${controller.appSignature} ,
                                      fontSize: 12,
                                      color: AppColors.white.withValues(alpha: 0.9),
                                      textAlign: TextAlign.left,
                                    ),
                                    if (profile.referralCode.isNotEmpty) ...[
                                      16.height,
                                      _buildReferralCode(profile.referralCode),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      20.height,
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildReferralCode(String code) {
    void copy() {
      Clipboard.setData(ClipboardData(text: code));
      AppSnackbar.success('Copied', 'Referral code $code copied');
    }

    return GestureDetector(
      onTap: copy,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.confirmation_number_outlined, color: AppColors.white, size: 18),
            10.width,
            Expanded(
              child: CustomText(
                text: code,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
                letterSpacing: 1.5,
                textAlign: TextAlign.left,
              ),
            ),
            const Icon(Icons.copy_rounded, color: AppColors.white, size: 18),
            6.width,
            const CustomText(text: 'Copy', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.grey500),
        6.width,
        Flexible(
          child: CustomText(
            text: text,
            fontSize: 13,
            color: AppColors.grey500,
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color valueColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.md,
        ),
        child: Column(
          children: [
            CustomText(text: title, fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey),
            6.height,
            CustomText(text: value, fontSize: 18, fontWeight: FontWeight.w800, color: valueColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.grey100, indent: 60, endIndent: 20);
  }

  void _showImageSourceSheet(BuildContext context) {
    bool isCamera = true;
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                24.height,
                const CustomText(text: 'Upload', fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.darkText),
                24.height,
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => isCamera = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: isCamera ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.center,
                          child: CustomText(
                            text: 'Take Photo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCamera ? AppColors.white : AppColors.darkText,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => isCamera = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: !isCamera ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.center,
                          child: CustomText(
                            text: 'Browse',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: !isCamera ? AppColors.white : AppColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                24.height,
                GestureDetector(
                  onTap: () {
                    Get.back();
                    controller.uploadProfileImage(isCamera ? ImageSource.camera : ImageSource.gallery);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grey300, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.amber50, shape: BoxShape.circle),
                          child: Icon(
                            isCamera ? Icons.camera_alt_outlined : Icons.folder_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        16.height,
                        CustomText(
                          text: isCamera ? 'Tap to Take photo' : 'Tap to browse',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                        4.height,
                        CustomText(text: 'JPG (Max 5MB)', fontSize: 12, color: AppColors.grey500),
                      ],
                    ),
                  ),
                ),
                32.height,
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: const BoxDecoration(color: AppColors.red50, shape: BoxShape.circle),
                child: const Icon(Icons.logout_outlined, color: AppColors.red500, size: 28),
              ),
              20.height,
              const CustomText(
                text: 'Logout Confirmation',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
              12.height,
              CustomText(
                text: 'Are you sure you want to log out of the Orange Taxi app?',
                fontSize: 14,
                color: AppColors.grey500,
              ),
              24.height,
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: AppColors.grey500),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: CustomText(
                        text: 'Cancel',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                  16.width,
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red500,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Get.back();
                        controller.logout();
                      },
                      child: const CustomText(
                        text: 'Logout',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final profile = controller.userProfile.value;

    if (profile == null) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: profile.name == 'No name' ? '' : profile.name);
    final emailController = TextEditingController(text: profile.email == 'No email' ? '' : profile.email);

    final phoneDigits = profile.phone.replaceAll(RegExp(r'\D'), '');
    final phoneController = TextEditingController(
      text: phoneDigits.length > 10 ? phoneDigits.substring(phoneDigits.length - 10) : phoneDigits,
    );
    final dobController = TextEditingController(text: _formatDob(profile.dateOfBirth));

    DateTime? pickedDob = profile.dateOfBirth != null ? DateTime.tryParse(profile.dateOfBirth!) : null;

    Future<void> pickDob() async {
      final now = DateTime.now();

      const List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const int minYear = 1950;

      final DateTime initial = pickedDob ?? DateTime(now.year - 18, now.month, now.day);
      int day = initial.day;
      int month = initial.month;
      int year = initial.year;

      final FixedExtentScrollController dayController = FixedExtentScrollController(initialItem: day - 1);
      final FixedExtentScrollController monthController = FixedExtentScrollController(initialItem: month - 1);
      final FixedExtentScrollController yearController = FixedExtentScrollController(initialItem: year - minYear);

      void enforceValidDate() {
        const dur = Duration(milliseconds: 250);
        const curve = Curves.easeOut;

        final int maxDay = DateUtils.getDaysInMonth(year, month);
        if (day > maxDay) {
          day = maxDay;
          dayController.animateToItem(day - 1, duration: dur, curve: curve);
        }

        if (DateTime(year, month, day).isAfter(now)) {
          year = now.year;
          month = now.month;
          day = now.day;
          yearController.animateToItem(year - minYear, duration: dur, curve: curve);
          monthController.animateToItem(month - 1, duration: dur, curve: curve);
          dayController.animateToItem(day - 1, duration: dur, curve: curve);
        }
      }

      Widget wheelHeader(String text) {
        return Expanded(
          child: Center(
            child: CustomText(text: text, color: AppColors.grey, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      }

      await Get.bottomSheet(
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(10)),
                ),
              ),

              20.height,
              CustomText(text: 'Date of Birth', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal),
              8.height,

              CustomText(
                text: 'Pick the day, month and year you were born.',
                fontSize: 14,
                color: AppColors.grey,
                textAlign: TextAlign.center,
              ),

              30.height,

              Row(children: [wheelHeader('Day'), wheelHeader('Month'), wheelHeader('Year')]),

              10.height,

              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: dayController,
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          day = index + 1;
                          enforceValidDate();
                        },
                        children: List.generate(
                          31,
                          (index) => Center(
                            child: CustomText(text: '${index + 1}', fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: CupertinoPicker(
                        scrollController: monthController,
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          month = index + 1;
                          enforceValidDate();
                        },
                        children: months
                            .map(
                              (m) => Center(
                                child: CustomText(text: m, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    Expanded(
                      child: CupertinoPicker(
                        scrollController: yearController,
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          year = minYear + index;
                          enforceValidDate();
                        },
                        children: List.generate(
                          now.year - minYear + 1,
                          (index) => Center(
                            child: CustomText(text: '${minYear + index}', fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              30.height,

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Confirm',
                      gradient: AppColors.gradientButton,
                      textColor: AppColors.white,
                      onPressed: () {
                        pickedDob = DateTime(year, month, day);
                        dobController.text = DateFormat('dd MMM yyyy').format(pickedDob!);
                        Get.back();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        isScrollControlled: true,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
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

                const CustomText(
                  text: 'Edit Profile',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
                4.height,
                CustomText(text: 'Update your personal details', fontSize: 12, color: AppColors.grey500),

                20.height,

                _buildTextFieldLabel('Full Name'),
                8.height,
                TextFormField(
                  controller: nameController,
                  decoration: _buildInputDecoration('Enter your name', icon: Icons.badge_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter your name';
                    if (value.trim().length < 3) return 'Name must be at least 3 characters';
                    return null;
                  },
                ),

                14.height,

                _buildTextFieldLabel('Email Address'),
                8.height,
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('Enter your email', icon: Icons.email_outlined),
                  validator: (value) {
                    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+\-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                    if (value == null || value.trim().isEmpty) return null;
                    if (!emailRegex.hasMatch(value.trim())) return 'Please enter a valid email';
                    return null;
                  },
                ),

                14.height,

                _buildTextFieldLabel('Phone Number'),
                8.height,
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'\d')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _buildInputDecoration('Enter your phone', icon: Icons.phone_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter phone number';
                    if (value.trim().length != 10) return 'Must be 10 digits';
                    return null;
                  },
                ),

                14.height,

                _buildTextFieldLabel('Date of Birth'),
                8.height,
                TextFormField(
                  controller: dobController,
                  readOnly: true,
                  onTap: pickDob,
                  decoration: _buildInputDecoration(
                    'Select your date of birth',
                    icon: Icons.cake_outlined,
                    suffix: Icons.calendar_today_outlined,
                  ),
                ),

                24.height,

                Obx(
                  () => CustomButton(
                    text: 'Save Changes',
                    gradient: AppColors.gradientButton,
                    textColor: AppColors.white,
                    loading: controller.isLoading.value,
                    enabled: !controller.isLoading.value,
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        controller.updateProfile(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                          dateOfBirth: pickedDob != null ? DateFormat('yyyy-MM-dd').format(pickedDob!) : null,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      Future.delayed(const Duration(milliseconds: 400), () {
        nameController.dispose();
        emailController.dispose();
        phoneController.dispose();
        dobController.dispose();
      });
    });
  }

  String _formatDob(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    return dt == null ? '' : DateFormat('dd MMM yyyy').format(dt);
  }

  Widget _buildTextFieldLabel(String label) {
    return CustomText(text: label, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText);
  }

  InputDecoration _buildInputDecoration(String hint, {IconData? icon, IconData? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.grey400, size: 20) : null,
      suffixIcon: suffix != null ? Icon(suffix, color: AppColors.primary, size: 18) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }
}
