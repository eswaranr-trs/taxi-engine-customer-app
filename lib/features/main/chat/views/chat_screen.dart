import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/avatar_image/avatar_image.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:orange_taxi_customer_app/features/main/chat/controllers/chat_controller.dart';
import 'package:orange_taxi_customer_app/features/main/chat/widgets/chat_bubble.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
        title: Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarImage(size: 34, url: controller.peerAvatar),
              10.width,
              Flexible(
                child: CustomText(
                  text: controller.peerName,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Obx(() {
            final String phone = controller.peerPhone;
            if (phone.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.call, color: AppColors.primary),
              onPressed: () => launchUrl(Uri.parse('tel:$phone'), mode: LaunchMode.externalApplication),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.messages.isEmpty) {
                  return const _ChatShimmer();
                }
                if (controller.messages.isEmpty) {
                  return const Center(
                    child: CustomText(text: 'No messages yet', fontSize: 13, color: AppColors.grey400),
                  );
                }
                return ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) => ChatBubble(message: controller.messages[index]),
                );
              }),
            ),
            _QuickReplies(controller: controller),
            _InputBar(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _ChatShimmer extends StatelessWidget {
  const _ChatShimmer();

  // Alternating incoming/outgoing bubble placeholders.
  static const _rows = [false, true, false, true, false, true];

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const NeverScrollableScrollPhysics(),
        children: _rows.asMap().entries.map((e) {
          final isMe = e.value;
          final width = (120.0 + (e.key % 3) * 55).clamp(120.0, 240.0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMe) ...[const SkeletonBox(width: 28, height: 28, radius: 14), 8.width],
                SkeletonBox(width: width, height: 38, radius: 16),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  final ChatController controller;

  const _QuickReplies({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final replies = controller.quickReplies;
      final sending = controller.isSending.value;
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          itemCount: replies.length,
          separatorBuilder: (_, _) => 8.width,
          itemBuilder: (context, index) {
            final text = replies[index];
            return GestureDetector(
              onTap: sending ? null : () => controller.sendQuickReply(text),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: CustomText(text: text, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            );
          },
        ),
      );
    });
  }
}

class _InputBar extends StatelessWidget {
  final ChatController controller;

  const _InputBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: controller.messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.sendMessage(),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Type your Message...',
                  hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.grey400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          10.width,
          GestureDetector(
            onTap: controller.sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(gradient: AppColors.gradientButton, borderRadius: BorderRadius.circular(14)),
              child: Obx(
                () => controller.isSending.value
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.send_rounded, color: AppColors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
