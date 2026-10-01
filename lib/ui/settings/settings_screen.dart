// lib/ui/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../models/voca_models.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Watch((context) {
          final settings = AppState.instance.userSettings.value;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // SECTION 1: Subtitle & Annotations
              _buildSectionHeader('SUBTITLES & FURIGANA'),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    // Furigana / Ruby Mode
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.translate_rounded, color: Color(0xFF38BDF8), size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Furigana / Pinyin Ruby',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Control reading annotations over Japanese Kanji or Chinese Hanzi.',
                            style: TextStyle(color: Colors.white60, fontSize: 12.5),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<RubyDisplayMode>(
                            segments: const [
                              ButtonSegment(
                                value: RubyDisplayMode.always,
                                label: Text('Always'),
                                icon: Icon(Icons.visibility_outlined, size: 16),
                              ),
                              ButtonSegment(
                                value: RubyDisplayMode.tap,
                                label: Text('Tap Only'),
                                icon: Icon(Icons.touch_app_outlined, size: 16),
                              ),
                              ButtonSegment(
                                value: RubyDisplayMode.never,
                                label: Text('Off'),
                                icon: Icon(Icons.visibility_off_outlined, size: 16),
                              ),
                            ],
                            selected: {settings.rubyMode},
                            onSelectionChanged: (Set<RubyDisplayMode> newSelection) {
                              AppState.instance.setRubyMode(newSelection.first);
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return const Color(0xFF6366F1);
                                  }
                                  return const Color(0xFF0F172A);
                                },
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return Colors.white70;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Colors.white10, height: 1),

                    // Subtitle Font Size
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.format_size_rounded, color: Color(0xFF38BDF8), size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Subtitle Font Size',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Adjust subtitle text scale for readability.',
                            style: TextStyle(color: Colors.white60, fontSize: 12.5),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<SubtitleSize>(
                            segments: const [
                              ButtonSegment(
                                value: SubtitleSize.small,
                                label: Text('Small'),
                              ),
                              ButtonSegment(
                                value: SubtitleSize.medium,
                                label: Text('Medium'),
                              ),
                              ButtonSegment(
                                value: SubtitleSize.large,
                                label: Text('Large'),
                              ),
                            ],
                            selected: {settings.subtitleSize},
                            onSelectionChanged: (Set<SubtitleSize> newSelection) {
                              AppState.instance.setSubtitleSize(newSelection.first);
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return const Color(0xFF6366F1);
                                  }
                                  return const Color(0xFF0F172A);
                                },
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return Colors.white70;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SECTION 2: Dictionary & Translation
              _buildSectionHeader('DICTIONARY & LOOKUP'),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    // Native Language
                    ListTile(
                      leading: const Icon(Icons.language_rounded, color: Color(0xFF818CF8)),
                      title: const Text(
                        'Explanation Language',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Target language for dictionary definitions & translations',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      trailing: DropdownButton<String>(
                        value: settings.nativeLanguage,
                        dropdownColor: const Color(0xFF1E293B),
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('🇺🇸 English', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'vi', child: Text('🇻🇳 Tiếng Việt', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'zh', child: Text('🇨🇳 中文', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'ja', child: Text('🇯🇵 日本語', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'ko', child: Text('🇰🇷 한국어', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (lang) {
                          if (lang != null) {
                            AppState.instance.setNativeLanguage(lang);
                          }
                        },
                      ),
                    ),

                    const Divider(color: Colors.white10, height: 1),

                    // Auto-pause toggle
                    SwitchListTile(
                      activeColor: const Color(0xFF6366F1),
                      secondary: const Icon(Icons.pause_circle_outline_rounded, color: Color(0xFF818CF8)),
                      title: const Text(
                        'Auto-pause on Word Lookup',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Pause video playback immediately when tapping a word or grammar pattern',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      value: settings.autoPauseOnLookup,
                      onChanged: (val) {
                        AppState.instance.setAutoPauseOnLookup(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SECTION 3: System & Info
              _buildSectionHeader('APPLICATION'),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info_outline_rounded, color: Colors.white70),
                      title: Text('Voca Version', style: TextStyle(color: Colors.white, fontSize: 15)),
                      trailing: Text('1.0.0 (Build 1)', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ),
                    Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: Icon(Icons.cloud_done_rounded, color: Colors.white70),
                      title: Text('Backend Architecture', style: TextStyle(color: Colors.white, fontSize: 15)),
                      trailing: Text('Edge + Supabase', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
