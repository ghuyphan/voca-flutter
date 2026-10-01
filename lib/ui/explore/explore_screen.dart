// lib/ui/explore/explore_screen.dart

import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../video/video_player_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  String _selectedTier = 'all';

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    final lang = AppState.instance.activeLanguage.value;

    try {
      final list = await AppState.instance.apiClient.getRecommendedVideos(
        lang: lang,
        tier: _selectedTier == 'all' ? null : _selectedTier,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _videos = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = AppState.instance.activeLanguage.value;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Explore Videos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // Language Switcher Dropdown
          DropdownButton<String>(
            value: currentLang,
            dropdownColor: const Color(0xFF1E293B),
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.language, color: Colors.white70),
            items: const [
              DropdownMenuItem(value: 'ja', child: Text('🇯🇵 Japanese', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'zh', child: Text('🇨🇳 Chinese', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'ko', child: Text('🇰🇷 Korean', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'en', child: Text('🇺🇸 English', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (val) {
              if (val != null) {
                AppState.instance.setLanguage(val);
                _loadVideos();
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tier Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All Levels'),
                  _buildFilterChip('beginner', 'Beginner'),
                  _buildFilterChip('elementary', 'Elementary'),
                  _buildFilterChip('intermediate', 'Intermediate'),
                  _buildFilterChip('advanced', 'Advanced'),
                ],
              ),
            ),

            // Video List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _videos.isEmpty
                      ? const Center(child: Text('No videos found', style: TextStyle(color: Colors.white60)))
                      : RefreshIndicator(
                          onRefresh: _loadVideos,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _videos.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final item = _videos[index];
                              final videoId = item['videoId'] as String? ?? '';
                              final title = item['title'] as String? ?? '';
                              final channel = item['channel'] as String? ?? '';
                              final duration = item['duration'] as int? ?? 0;
                              final levels = item['levels'] as Map<String, dynamic>?;
                              final levelTag = levels?[currentLang] as String?;

                              final durationStr =
                                  '${duration ~/ 60}:${(duration % 60).toString().padLeft(2, '0')}';

                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => VideoPlayerScreen(
                                        videoId: videoId,
                                        title: title,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Thumbnail with Duration & Level Badge
                                      Stack(
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: Image.network(
                                              'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: Colors.black26,
                                                child: const Icon(Icons.broken_image, color: Colors.white30),
                                              ),
                                            ),
                                          ),
                                          // Duration tag
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.8),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                durationStr,
                                                style: const TextStyle(color: Colors.white, fontSize: 11),
                                              ),
                                            ),
                                          ),
                                          // Level badge
                                          if (levelTag != null)
                                            Positioned(
                                              top: 8,
                                              left: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF6366F1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  levelTag,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),

                                      // Video Info
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              channel,
                                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String tier, String label) {
    final isSelected = _selectedTier == tier;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedTier = tier);
          _loadVideos();
        },
        backgroundColor: const Color(0xFF1E293B),
        selectedColor: const Color(0xFF6366F1),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? Colors.transparent : Colors.white12),
        ),
      ),
    );
  }
}
