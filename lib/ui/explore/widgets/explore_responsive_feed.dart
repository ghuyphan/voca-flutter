// lib/ui/explore/widgets/explore_responsive_feed.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import 'feed_skeleton_card.dart';

/// Reusable Responsive Feed builder unifying mobile 1-column list & tablet multi-column grid,
/// matching lingua-tube's responsive grid layout and AGENTS.md.
class ExploreResponsiveFeed extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool isLoadingMore;
  final RefreshCallback? onRefresh;
  final ScrollPhysics? physics;
  final double bottomPadding;

  const ExploreResponsiveFeed({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.isLoadingMore = false,
    this.onRefresh,
    this.physics,
    this.bottomPadding = 20.0,
  });

  /// Factory helper for skeleton shimmer feeds.
  static Widget buildSkeletonFeed(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= VocaTokens.tabletBreakpoint;

        if (!isTablet) {
          return ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (_, __) => const FeedSkeletonCard(),
          );
        }
        final crossAxisCount = width >= 1100 ? 3 : 2;
        const double spacing = 20.0;
        const double horizontalPadding = 16.0 * 2;
        final cardWidth = (width - horizontalPadding - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final cardHeight = (cardWidth / (16 / 9)) + 100.0;
        final childAspectRatio = cardWidth / cardHeight;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: width >= 1100 ? 6 : 4,
          itemBuilder: (_, __) => const FeedSkeletonCard(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final totalCount = itemCount + (isLoadingMore ? 1 : 0);

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= VocaTokens.tabletBreakpoint;

        if (!isTablet) {
          return ListView.separated(
            physics: physics ?? const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
            itemCount: totalCount,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              if (index >= itemCount) {
                return _buildLoadingMoreIndicator(colors);
              }
              return itemBuilder(context, index);
            },
          );
        }

        final crossAxisCount = width >= 1100 ? 3 : 2;
        const double spacing = 20.0;
        const double horizontalPadding = 16.0 * 2;
        final cardWidth = (width - horizontalPadding - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final metaHeight = MediaQuery.textScalerOf(context).scale(100.0);
        final cardHeight = (cardWidth / (16 / 9)) + metaHeight;
        final childAspectRatio = cardWidth / cardHeight;

        return CustomScrollView(
          physics: physics ?? const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate(
                  itemBuilder,
                  childCount: itemCount,
                ),
              ),
            ),
            if (isLoadingMore)
              SliverToBoxAdapter(
                child: _buildLoadingMoreIndicator(colors),
              ),
            SliverToBoxAdapter(
              child: SizedBox(height: bottomPadding),
            ),
          ],
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        color: colors.accentPrimary,
        backgroundColor: colors.bgCard,
        child: content,
      );
    }

    return content;
  }

  Widget _buildLoadingMoreIndicator(VocaColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
          ),
        ),
      ),
    );
  }
}
