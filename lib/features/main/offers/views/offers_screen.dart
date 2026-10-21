import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:orange_taxi_customer_app/features/main/offers/controllers/offers_controller.dart';
import 'package:orange_taxi_customer_app/features/main/offers/controllers/promo_codes_controller.dart';
import 'package:orange_taxi_customer_app/features/main/offers/models/offer_model.dart';
import 'package:orange_taxi_customer_app/features/main/offers/models/promo_code_model.dart';

class OffersScreen extends StatefulWidget {
  final bool showBack;
  final bool showPromoCodes;

  const OffersScreen({super.key, this.showBack = true, this.showPromoCodes = true});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final OffersController controller = Get.isRegistered<OffersController>()
      ? Get.find<OffersController>()
      : Get.put(OffersController());

  final PromoCodesController promoController = Get.isRegistered<PromoCodesController>()
      ? Get.find<PromoCodesController>()
      : Get.put(PromoCodesController());

  static const List<_Palette> _palettes = [
    _Palette(
      gradient: [AppColors.orangeAccent, AppColors.orange],
      tint: AppColors.orange50,
      foreground: AppColors.white,
    ),
    _Palette(gradient: [AppColors.primary, AppColors.primary], tint: AppColors.amber50, foreground: AppColors.black),
    _Palette(
      gradient: [AppColors.successGreen, AppColors.success],
      tint: AppColors.successGreenLight,
      foreground: AppColors.white,
    ),
    _Palette(gradient: [AppColors.info, AppColors.blue500], tint: AppColors.blue50, foreground: AppColors.white),
    _Palette(gradient: [AppColors.amber400, AppColors.amber600], tint: AppColors.amber50, foreground: AppColors.black),
  ];

  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.fetchOffers();
      if (widget.showPromoCodes) promoController.fetchPromoCodes();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([controller.fetchOffers(), if (widget.showPromoCodes) promoController.fetchPromoCodes()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        title: CustomText(
          text: 'Available Deals',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
          textAlign: TextAlign.left,
        ),
        centerTitle: true,
        automaticallyImplyLeading: widget.showBack,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (widget.showPromoCodes)
              Obx(() {
                final bool loading = controller.isLoading.value || promoController.isLoading.value;
                final bool hasAny = promoController.promoCodes.isNotEmpty || controller.offers.isNotEmpty;
                if (loading || !hasAny) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 10), child: _buildTabs());
              }),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value || (widget.showPromoCodes && promoController.isLoading.value)) {
        return _buildLoading();
      }

      final List<PromoCodeModel> promos = widget.showPromoCodes ? promoController.promoCodes : const [];
      final offers = controller.offers;

      if (promos.isEmpty && offers.isEmpty) {
        final String? err = controller.error.value;
        final String st = controller.serviceType.value;
        return _buildEmpty(
          icon: err != null ? Icons.error_outline : Icons.local_offer_outlined,
          message: err ?? 'No offers available${st.isEmpty ? '' : ' for $st'} right now',
        );
      }

      final bool showPromos = promos.isNotEmpty && _tab != 2;
      final bool showOffers = offers.isNotEmpty && _tab != 1;

      final List<Widget> items = [
        if (showPromos) ...[
          if (_tab == 0) ...[
            _sectionHeader(
              icon: Icons.local_fire_department_rounded,
              color: AppColors.orange,
              bg: AppColors.orange50,
              title: promos.length > 1 ? 'Promo Codes' : 'Promo Code',
              subtitle: 'Use these codes to get instant discounts',
              onViewAll: _tab == 0 ? () => setState(() => _tab = 1) : null,
            ),
          ],
          ...promos.asMap().entries.map(
            (e) => _PromoTicket(promo: e.value, palette: _palettes[e.key % _palettes.length], highlight: e.key == 0),
          ),
        ],

        if (showOffers) ...[
          if (_tab == 0) ...[
            _sectionHeader(
              icon: Icons.card_giftcard_rounded,
              color: AppColors.primary,
              bg: AppColors.amber50,
              title: offers.length > 1 ? 'Offer Codes' : 'Offer Code',
              subtitle: 'Special offers for you',
              onViewAll: _tab == 0 && widget.showPromoCodes ? () => setState(() => _tab = 2) : null,
            ),
          ],
          ...offers.asMap().entries.map(
            (e) => _OfferCard(offer: e.value, palette: _palettes[(e.key + 2) % _palettes.length]),
          ),
        ],

        if (!showPromos && !showOffers)
          Padding(
            padding: const EdgeInsets.only(top: 200),
            child: Column(
              children: [
                Icon(Icons.local_offer_outlined, size: 44, color: AppColors.grey300),
                12.height,
                CustomText(
                  text: _tab == 1 ? 'No promo codes available right now' : 'No offer codes available right now',
                  fontSize: 13,
                  color: AppColors.grey400,
                ),
              ],
            ),
          ),
      ];

      return AppRefreshIndicator(
        onRefresh: _refresh,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, widget.showBack ? 20 : 96),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => 9.height,
              itemBuilder: (_, i) => items[i],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTabs() {
    const List<(String, IconData)> tabs = [
      ('All Deals', Icons.local_offer_outlined),
      ('Promo Codes', Icons.confirmation_num_outlined),
      ('Offer Codes', Icons.card_giftcard_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _tab == i ? AppColors.amber50 : AppColors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tabs[i].$2, size: 15, color: _tab == i ? AppColors.primary : AppColors.grey500),
                      5.width,
                      Flexible(
                        child: CustomText(
                          text: tabs[i].$1,
                          fontSize: 12,
                          fontWeight: _tab == i ? FontWeight.bold : FontWeight.w600,
                          color: _tab == i ? AppColors.darkText : AppColors.grey500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required Color color,
    required Color bg,
    required String title,
    required String subtitle,
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                  textAlign: TextAlign.left,
                ),
                2.height,
                CustomText(
                  text: subtitle,
                  fontSize: 11,
                  color: AppColors.slate500,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // if (onViewAll != null)
          //   GestureDetector(
          //     behavior: HitTestBehavior.opaque,
          //     onTap: onViewAll,
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         CustomText(text: 'View All', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          //         2.width,
          //         const Icon(Icons.chevron_right_rounded, size: 17, color: AppColors.primary),
          //       ],
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SkeletonBox(width: 130, height: 60),
          20.height,
          SkeletonBox(width: 130, height: 15),
          11.height,
          SkeletonBox(width: double.infinity, height: 76, radius: 15),
          9.height,
          SkeletonBox(width: double.infinity, height: 76, radius: 15),
          20.height,
          SkeletonBox(width: 90, height: 15),
          11.height,
          SkeletonBox(width: double.infinity, height: 84, radius: 15),
        ],
      ),
    );
  }

  Widget _buildEmpty({required IconData icon, required String message}) {
    return AppRefreshIndicator(
      onRefresh: _refresh,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 52, color: AppColors.grey300),
                14.height,
                CustomText(text: message, fontSize: 13, color: AppColors.grey400, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Palette {
  final List<Color> gradient;
  final Color tint;
  final Color foreground;

  const _Palette({required this.gradient, required this.tint, required this.foreground});

  Color get accent => gradient.first;
  LinearGradient get linear => LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient);
}

class _PromoTicket extends StatefulWidget {
  final PromoCodeModel promo;
  final _Palette palette;
  final bool highlight;
  const _PromoTicket({required this.promo, required this.palette, this.highlight = false});

  @override
  State<_PromoTicket> createState() => _PromoTicketState();
}

class _PromoTicketState extends State<_PromoTicket> {
  static final NumberFormat _inr = NumberFormat.decimalPattern('en_IN');
  static const double _stubWidth = 92;
  static const double _notchSize = 12;

  bool _copied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.promo.code));
    _copyTimer?.cancel();
    setState(() => _copied = true);
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promo;
    final DateTime? expiry = promo.expiryDate;
    final String value = promo.isPercentage
        ? '${promo.discountValue.toStringAsFixed(0)}%'
        : '₹${_inr.format(promo.discountValue.round())}';
    final String meta = [
      'Min ₹${_inr.format(promo.minBookingAmount.round())}',
      if (expiry != null) 'Valid till ${DateFormat('dd MMM').format(expiry.toLocal())}',
    ].join('  •  ');

    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.rMd, boxShadow: AppShadows.sm),
      child: ClipRRect(
        borderRadius: AppRadius.rMd,
        child: IntrinsicHeight(
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: _stubWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(gradient: widget.palette.linear),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CustomText(
                                text: value,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: widget.palette.foreground,
                              ),
                            ),
                            CustomText(
                              text: 'OFF',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: widget.palette.foreground,
                              letterSpacing: 0.8,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 11, 10, 11),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // if (widget.highlight) ...[
                                //   Container(
                                //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                //     decoration: BoxDecoration(
                                //       color: AppColors.orange50,
                                //       borderRadius: BorderRadius.circular(20),
                                //     ),
                                //     child: Row(
                                //       mainAxisSize: MainAxisSize.min,
                                //       children: [
                                //         const Icon(
                                //           Icons.local_fire_department_rounded,
                                //           size: 11,
                                //           color: AppColors.orange,
                                //         ),
                                //         3.width,
                                //         CustomText(
                                //           text: 'Most Popular',
                                //           fontSize: 9.5,
                                //           fontWeight: FontWeight.bold,
                                //           color: AppColors.orange,
                                //         ),
                                //       ],
                                //     ),
                                //   ),
                                //   4.height,
                                // ],
                                CustomText(
                                  text: promo.code,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkText,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                4.height,
                                CustomText(
                                  text: meta,
                                  fontSize: 10,
                                  color: AppColors.slate500,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          8.width,
                          _copyButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(left: _stubWidth - _notchSize / 2, top: -_notchSize / 2, child: _notch()),
              Positioned(left: _stubWidth - _notchSize / 2, bottom: -_notchSize / 2, child: _notch()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notch() {
    return Container(
      width: _notchSize,
      height: _notchSize,
      decoration: const BoxDecoration(color: AppColors.backgroundColor, shape: BoxShape.circle),
    );
  }

  Widget _copyButton() {
    final Color accent = widget.palette.accent;
    return GestureDetector(
      onTap: _copyCode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: _copied ? accent.withValues(alpha: 0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 13, color: accent),
            5.width,
            CustomText(text: _copied ? 'Copied' : 'Copy', fontSize: 12, fontWeight: FontWeight.bold, color: accent),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatefulWidget {
  final OfferModel offer;
  final _Palette palette;

  const _OfferCard({required this.offer, required this.palette});

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  static final NumberFormat _inr = NumberFormat.decimalPattern('en_IN');

  bool _open = false;
  bool _copied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  OfferModel get offer => widget.offer;

  bool get _isPercentage => offer.discountType.toLowerCase() == 'percentage';

  String get _bigValue =>
      _isPercentage ? '${offer.discountValue.toStringAsFixed(0)}%' : '₹${_inr.format(offer.discountValue.round())}';

  int? get _daysLeft {
    final expiry = offer.expiryDate;
    if (expiry == null) return null;
    return expiry.toLocal().difference(DateTime.now()).inDays;
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: offer.offerId));
    _copyTimer?.cancel();
    setState(() => _copied = true);
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.rMd, boxShadow: AppShadows.sm),
      child: ClipRRect(
        borderRadius: AppRadius.rMd,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IntrinsicHeight(child: _summaryRow()),
                  if (_open)
                    Container(
                      color: AppColors.white,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: _details(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow() {
    final int? days = _daysLeft;
    final bool urgent = days != null && days <= 7;

    return Container(
      color: widget.palette.tint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, decoration: BoxDecoration(gradient: widget.palette.linear)),
          SizedBox(
            width: 88,
            child: Center(
              child: SizedBox(
                width: 52,
                height: 52,
                child: CustomPaint(
                  painter: _ScallopPainter(widget.palette.gradient),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: CustomText(
                            text: _bigValue,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: widget.palette.foreground,
                          ),
                        ),
                      ),
                      CustomText(
                        text: 'OFF',
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: widget.palette.foreground,
                        letterSpacing: 0.4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 6, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: offer.title,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  4.height,
                  CustomText(
                    text: 'Min ₹${_inr.format(offer.minBookingAmount.round())}',
                    fontSize: 12,
                    color: AppColors.slate500,
                    textAlign: TextAlign.left,
                  ),
                  if (days != null) ...[
                    6.height,
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: urgent ? AppColors.red500 : AppColors.grey400),
                        4.width,
                        CustomText(
                          text: days <= 0 ? 'Last day' : '$days ${days == 1 ? 'day' : 'days'} left',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: urgent ? AppColors.red500 : AppColors.grey500,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 11),
            child: Center(
              child: AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: AppColors.grey300, shape: BoxShape.circle, boxShadow: AppShadows.sm),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.grey600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _details() {
    final String? banner = offer.bannerImageUrl;
    final String? description = offer.description;
    final DateTime? expiry = offer.expiryDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (banner != null && banner.trim().isNotEmpty) ...[_banner(banner.trim()), 11.height],
        if (description != null && description.trim().isNotEmpty) ...[
          CustomText(text: description.trim(), fontSize: 12, color: AppColors.grey600, textAlign: TextAlign.left),
          11.height,
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _detailRow('Minimum booking', '₹${_inr.format(offer.minBookingAmount.round())}'),
              if (_isPercentage && offer.maxDiscount != null) ...[
                8.height,
                _detailRow('Maximum discount', '₹${_inr.format(offer.maxDiscount!.round())}'),
              ],
              if (expiry != null) ...[
                8.height,
                _detailRow('Valid till', DateFormat('dd MMM yyyy').format(expiry.toLocal())),
              ],
              8.height,
              _detailRow('Use code', offer.offerId),
            ],
          ),
        ),
        11.height,
        GestureDetector(
          onTap: _copyCode,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(gradient: widget.palette.linear, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 16, color: widget.palette.foreground),
                8.width,
                CustomText(
                  text: _copied ? 'Code Copied' : 'Copy Code',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.palette.foreground,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _banner(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 108,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(height: 108, width: double.infinity, color: AppColors.grey100);
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: CustomText(text: label, fontSize: 12, color: AppColors.grey500, textAlign: TextAlign.left),
        ),
        CustomText(text: value, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkText),
      ],
    );
  }
}

class _ScallopPainter extends CustomPainter {
  final List<Color> colors;

  const _ScallopPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    const int bumps = 13;
    final Offset center = size.center(Offset.zero);
    final double outer = size.width / 2;
    final double inner = outer * 0.9;
    final Path path = Path();

    for (int i = 0; i <= bumps * 2; i++) {
      final double radius = i.isEven ? outer : inner;
      final double angle = (i / (bumps * 2)) * 2 * math.pi - math.pi / 2;
      final Offset point = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScallopPainter oldDelegate) => !listEquals(oldDelegate.colors, colors);
}
