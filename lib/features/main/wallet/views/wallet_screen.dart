import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_constants.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/model/transaction_model.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/controller/wallet_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class WalletScreen extends GetView<WalletController> {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<WalletController>()) {
      Get.put(WalletController());
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        title: const CustomText(text: 'Wallet', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkSlate),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: AppRefreshIndicator(
          onRefresh: controller.refreshWallet,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: _buildWalletBalanceCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(
                    () => Row(
                      children: [
                        GestureDetector(
                          onTap: () => controller.selectedFilter.value = 'All',
                          child: _buildFilterPill('All', controller.selectedFilter.value == 'All'),
                        ),

                        12.width,

                        GestureDetector(
                          onTap: () => controller.selectedFilter.value = 'Credits',
                          child: _buildFilterPill('Credits', controller.selectedFilter.value == 'Credits'),
                        ),

                        12.width,

                        GestureDetector(
                          onTap: () => controller.selectedFilter.value = 'Debits',
                          child: _buildFilterPill('Debits', controller.selectedFilter.value == 'Debits'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Obx(() {
              if (controller.isLoading.value) {
                return SliverToBoxAdapter(
                  child: Shimmer(child: Column(children: List.generate(7, (_) => const ListRowSkeleton()))),
                );
              }

              final items = controller.filteredTransactions;

              if (items.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CustomText(text: 'No transactions yet', color: AppColors.grey),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 90),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.grey100, height: 32),
                  itemBuilder: (context, index) {
                    return _buildTransactionItem(items[index]);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletBalanceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.amber400, AppColors.primary, AppColors.orangeAccent],
        ),
        boxShadow: AppShadows.lg,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
              ),
            ),
            Positioned(
              bottom: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, color: AppColors.white, size: 13),
                        6.width,
                        const CustomText(
                          text: 'ORANGE WALLET',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),

                  24.height,

                  CustomText(
                    text: 'Available Balance',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white.withValues(alpha: 0.9),
                    textAlign: TextAlign.left,
                  ),

                  8.height,

                  Obx(
                    () => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6, right: 4),
                          child: CustomText(
                            text: '₹',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: CustomText(
                              text: controller.balanceLoaded.value
                                  ? controller.walletBalance.value.toStringAsFixed(2)
                                  : '--',
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!AppConstants.baseUrl.contains("demo"))
                    Obx(() {
                      if (controller.walletBalance.value <= 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.withdraw),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.white.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.account_balance_outlined, color: AppColors.white, size: 15),
                                8.width,
                                const CustomText(
                                  text: 'Withdraw to bank',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                                4.width,
                                const Icon(Icons.chevron_right_rounded, color: AppColors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey300),
      ),
      child: CustomText(
        text: title,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: AppColors.darkSlate,
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final bool isCredit = transaction.transactionType.toLowerCase() == 'credit';
    final bool isPending =
        transaction.status.toLowerCase() == 'pending' || transaction.status.toLowerCase() == 'processing';
    final bool isFailed = transaction.status.toLowerCase() == 'failed';

    // final String typeText = isCredit ? 'Credit' : 'Debit';
    // final Color typeColor = isCredit
    //     ? AppColors.success
    //     : isFailed
    //     ? AppColors.red
    //     : AppColors.warning;

    final String formattedDate = DateFormat('dd MMM yyyy hh:mm a').format(transaction.date.toLocal());

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: transaction.reason,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkSlate,
                maxLines: 2,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
              ),
              4.height,
              CustomText(text: formattedDate, fontSize: 10, color: AppColors.grey400),
            ],
          ),
        ),

        12.width,

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              text: '₹ ${isCredit ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkSlate,
            ),
            4.height,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CustomText(text: typeText, fontSize: 10, fontWeight: FontWeight.w500, color: typeColor),
                // if (isPending) ...[
                //   8.width,
                //   Container(
                //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                //     decoration: BoxDecoration(
                //       color: AppColors.orange.withValues(alpha: 0.15),
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //     child: CustomText(
                //       text: transaction.status,
                //       fontSize: 9,
                //       fontWeight: FontWeight.w600,
                //       color: AppColors.orange,
                //     ),
                //   ),
                // ],
                if (isFailed || isPending) ...[
                  5.width,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPending
                          ? AppColors.orange.withValues(alpha: 0.15)
                          : AppColors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomText(
                      text: transaction.status,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isPending ? AppColors.orange : AppColors.red,
                    ),
                  ),
                  5.width,
                ] else ...[
                  5.width,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomText(
                      text: transaction.status,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.successGreen,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}
