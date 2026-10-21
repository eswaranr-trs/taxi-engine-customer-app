import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavigationBar({super.key, required this.currentIndex, required this.onTap});

  static List<_NavItem> _items = [
    _NavItem(
      icon: Icon(Icons.home_outlined, size: 21, color: AppColors.grey400),
      activeIcon: Icon(Icons.home_rounded, size: 21),
      label: 'Home',
    ),
    _NavItem(
      icon: Icon(Icons.calendar_today_outlined, size: 21, color: AppColors.grey400),
      activeIcon: Icon(Icons.calendar_today, size: 21),
      label: 'Bookings',
    ),
    _NavItem(
      icon: SvgPicture.asset(
        'assets/icons/deals_outlined.svg',
        width: 22,
        height: 25,
        colorFilter: const ColorFilter.mode(AppColors.grey400, BlendMode.srcIn),
      ),
      activeIcon: SvgPicture.asset(
        'assets/icons/deals_filled.svg',
        width: 22,
        height: 22,
        fit: BoxFit.contain,
        colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn),
      ),
      label: 'Deals',
    ),
    _NavItem(
      icon: Icon(Icons.person_outline_rounded, size: 21, color: AppColors.grey400),
      activeIcon: Icon(Icons.person_rounded, size: 21),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(boxShadow: AppShadows.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / _items.length;

          return SizedBox(
            height: 78,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 64,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.9), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.07),
                          blurRadius: 24,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 64,
                  child: Row(
                    children: List.generate(_items.length, (index) {
                      final item = _items[index];
                      final isSelected = currentIndex == index;

                      return SizedBox(
                        width: itemWidth,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(index),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutBack,
                                top: isSelected ? -18 : 10,
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutBack,
                                  scale: isSelected ? 1 : 0.75,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 180),
                                    opacity: isSelected ? 1 : 0,
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [AppColors.yellowg, AppColors.primary],
                                        ),
                                        border: Border.all(color: AppColors.white.withValues(alpha: 0.9), width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.52),
                                            blurRadius: 14,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: AnimatedScale(
                                        duration: const Duration(milliseconds: 250),
                                        scale: isSelected ? 1 : 0.8,
                                        child: Center(
                                          child: SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: FittedBox(fit: BoxFit.contain, child: item.activeIcon),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                top: isSelected ? 42 : 19,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isSelected ? 0 : 1,
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: FittedBox(fit: BoxFit.contain, child: item.icon),
                                    ),
                                  ),
                                ),
                              ),

                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                top: 42,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 220),
                                  opacity: 1,
                                  child: CustomText(
                                    text: item.label,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.grey800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavItem {
  final Widget icon;
  final Widget activeIcon;
  final String label;

  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
