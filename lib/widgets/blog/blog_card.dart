import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_badge.dart';

class BlogCard extends StatelessWidget {
  final String title;
  final String summary;
  final String? imageUrl;
  final String category;
  final String authorName;
  final int viewCount;
  final VoidCallback? onTap;

  const BlogCard({
    super.key,
    required this.title,
    required this.summary,
    required this.category,
    required this.authorName,
    required this.viewCount,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.brandPrimary.withValues(alpha: 0.5),
                            AppColors.brandSecondary.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                      child: imageUrl != null
                          ? Image.network(imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox())
                          : const Center(
                              child: Icon(Icons.image_outlined,
                                  size: 48, color: Colors.white54)),
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: FwBadge(
                        label: category,
                        tone: FwBadgeTone.primary,
                        soft: false,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: text.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(summary,
                        style: text.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: AppColors.brandPrimary
                              .withValues(alpha: 0.2),
                          child: Text(
                            authorName.isNotEmpty
                                ? authorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.brandPrimaryDark,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(authorName,
                              style: text.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const Icon(Icons.visibility,
                            size: 12, color: AppColors.darkTextMuted),
                        const SizedBox(width: 2),
                        Text('$viewCount', style: text.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
