// lib/ui/explore/widgets/feed_skeleton_card.dart

import 'package:flutter/material.dart';
import '../../widgets/voca_level_badge.dart';
import '../../widgets/voca_shimmer.dart';

/// Skeleton Loading Card with Shimmer matching full-width feed layout.
class FeedSkeletonCard extends StatelessWidget {
  const FeedSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    Widget shimmerThumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VocaShimmer.box(
              borderRadius: BorderRadius.zero,
            ),
            const Positioned(
              bottom: 8,
              left: 8,
              child: VocaLevelBadge(isLoading: true),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: VocaShimmer.box(
                width: 32,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        shimmerThumbnail,
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 2, right: 2, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VocaShimmer.circle(size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VocaShimmer.line(height: 14),
                    const SizedBox(height: 6),
                    VocaShimmer.line(width: 160, height: 14),
                    const SizedBox(height: 8),
                    VocaShimmer.line(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
