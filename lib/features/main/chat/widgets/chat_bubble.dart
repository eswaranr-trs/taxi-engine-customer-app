import 'package:flutter/material.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/features/main/chat/models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    final bubble = Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withValues(alpha: .5) : AppColors.grey100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        // Min-width row so the bubble hugs the text; tick trails the last line.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: CustomText(
                text: message.text,
                fontSize: 13,
                textAlign: TextAlign.left,
                color: AppColors.darkSlate,
                maxLines: 50,
              ),
            ),
            if (isMe) ...[
              6.width,
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.isRead ? AppColors.green : AppColors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // final avatar = Container(
    //   width: 28,
    //   height: 28,
    //   decoration: BoxDecoration(
    //     shape: BoxShape.circle,
    //     color: AppColors.grey100,
    //     image: message.avatarUrl != null
    //         ? DecorationImage(image: NetworkImage(message.avatarUrl!), fit: BoxFit.cover)
    //         : null,
    //   ),
    //   child: message.avatarUrl == null
    //       ? const Center(
    //           child: CustomText(text: 'A', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
    //         )
    //       : null,
    // );

    // Support agent avatar (no url) gets an orange circle
    // final agentAvatar = Container(
    //   width: 28,
    //   height: 28,
    //   decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.gradientButton),
    //   child: const Center(
    //     child: CustomText(text: 'A', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
    //   ),
    // );

    // final leading = message.avatarUrl != null ? avatar : agentAvatar;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMe
            ? [
                bubble,
                // if (message.avatarUrl != null) ...[8.width, avatar],
              ]
            : [
                // leading,
                8.width, bubble,
              ],
      ),
    );
  }
}
