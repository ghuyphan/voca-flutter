// lib/ui/explore/models/explore_category.dart

import 'package:flutter/material.dart';
import '../../../services/i18n_service.dart';

/// Centralized category model matching lingua-tube exploration topics.
enum ExploreCategory {
  all('All'),
  trending('Trending'),
  animeDrama('Anime & Drama'),
  music('Music'),
  news('News'),
  vlog('Vlog'),
  conversation('Conversation');

  final String id;
  const ExploreCategory(this.id);

  static ExploreCategory fromId(String id) {
    return ExploreCategory.values.firstWhere(
      (cat) => cat.id.toLowerCase() == id.toLowerCase(),
      orElse: () => ExploreCategory.all,
    );
  }

  IconData get icon {
    switch (this) {
      case ExploreCategory.trending:
        return Icons.local_fire_department_rounded;
      case ExploreCategory.animeDrama:
        return Icons.movie_filter_rounded;
      case ExploreCategory.music:
        return Icons.music_note_rounded;
      case ExploreCategory.news:
        return Icons.newspaper_rounded;
      case ExploreCategory.vlog:
        return Icons.videocam_rounded;
      case ExploreCategory.conversation:
        return Icons.forum_rounded;
      case ExploreCategory.all:
        return Icons.explore_rounded;
    }
  }

  /// Canonical server-side category identifier passed to /api/recommended-videos
  String? get serverCategory {
    switch (this) {
      case ExploreCategory.animeDrama:
        return 'anime_drama';
      case ExploreCategory.music:
        return 'music';
      case ExploreCategory.news:
        return 'news';
      case ExploreCategory.vlog:
        return 'vlog';
      case ExploreCategory.conversation:
        return 'conversation';
      case ExploreCategory.all:
      case ExploreCategory.trending:
        return null;
    }
  }

  String? get searchKeyword {
    switch (this) {
      case ExploreCategory.animeDrama:
        return 'anime';
      case ExploreCategory.music:
        return 'music';
      case ExploreCategory.news:
        return 'news';
      case ExploreCategory.vlog:
        return 'vlog';
      case ExploreCategory.conversation:
        return 'conversation';
      case ExploreCategory.all:
      case ExploreCategory.trending:
        return null;
    }
  }

  String getLabel(BuildContext context) {
    switch (this) {
      case ExploreCategory.all:
        return context.t('explore.topicAll', null, 'All');
      case ExploreCategory.trending:
        return context.t('explore.topicTrending', null, 'Trending');
      case ExploreCategory.animeDrama:
        return context.t('explore.topicAnimeDrama', null, 'Anime & Drama');
      case ExploreCategory.music:
        return context.t('explore.topicMusic', null, 'Music');
      case ExploreCategory.news:
        return context.t('explore.topicNews', null, 'News');
      case ExploreCategory.vlog:
        return context.t('explore.topicVlog', null, 'Vlog');
      case ExploreCategory.conversation:
        return context.t('explore.topicConversation', null, 'Conversation');
    }
  }
}
