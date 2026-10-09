// lib/features/student/screens/student_materials_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/student_provider.dart';
import '../../../shared/widgets/ep_card.dart';

class StudentMaterialsScreen extends StatefulWidget {
  final LessonModel lesson;
  final Color accentColor;

  const StudentMaterialsScreen({
    super.key,
    required this.lesson,
    required this.accentColor,
  });

  @override
  State<StudentMaterialsScreen> createState() => _StudentMaterialsScreenState();
}

enum _LearningTab {
  home,
  videos,
  pdfs,
  ppts,
  notes,
  practice,
}

class _StudentMaterialsScreenState extends State<StudentMaterialsScreen> {
  _LearningTab _activeTab = _LearningTab.home;

  // Video Player state
  MaterialModel? _activeVideo;
  bool _isPlaying = false;
  double _videoProgress = 0.35; // 35% through video
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<StudentProvider>();
      sp.fetchMaterials(widget.lesson.id);
      sp.fetchQuizzes(lessonId: widget.lesson.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudentProvider>();
    final counts = sp.currentCounts;

    // Filter published materials by active tab
    final videos = sp.materials.where((m) => m.materialType == 'video').toList();
    final pdfs = sp.materials.where((m) => m.materialType == 'pdf').toList();
    final ppts = sp.materials.where((m) => m.materialType == 'ppt').toList();
    final notes = sp.materials.where((m) => m.materialType == 'notes' || m.materialType == 'word').toList();

    // Set default active video if not set
    if (_activeVideo == null && videos.isNotEmpty) {
      _activeVideo = videos.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Lesson Header ──────────────────────────────────────────────
            _buildLessonHeader(context),

            // ── Main Two-Column or Adaptive Content ────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 768;
                  if (isWide) {
                    // Desktop / Tablet two-column layout (Section 20)
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left sidebar
                        SizedBox(
                          width: 280,
                          child: _buildSidebar(counts),
                        ),
                        const VerticalDivider(color: AppColors.divider, width: 1),
                        // Right main content
                        Expanded(
                          child: _buildMainContent(sp, videos, pdfs, ppts, notes),
                        ),
                      ],
                    );
                  } else {
                    // Mobile adaptive layout: Top category bar + Main view
                    return Column(
                      children: [
                        _buildMobileSidebarBar(counts),
                        const Divider(color: AppColors.divider, height: 1),
                        Expanded(
                          child: _buildMainContent(sp, videos, pdfs, ppts, notes),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Lesson Header ────────────────────────────────────────────────────────
  Widget _buildLessonHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.lesson.unitTitle ?? 'Unit 1 - Prose',
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '•  Classes 6–10 Curriculum',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.lesson.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Lesson Sidebar (Section 20) ──────────────────────────────────────────
  Widget _buildSidebar(LessonSidebarCounts counts) {
    return Container(
      color: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'LESSON MODULES',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _sidebarItem(
            tab: _LearningTab.home,
            icon: Icons.dashboard_rounded,
            label: 'Home / Summary',
            count: counts.home > 0 ? counts.home : 8,
          ),
          _sidebarItem(
            tab: _LearningTab.videos,
            icon: Icons.play_circle_fill_rounded,
            label: 'Videos',
            count: counts.videos > 0 ? counts.videos : 2,
            badgeColor: AppColors.indigo,
          ),
          _sidebarItem(
            tab: _LearningTab.pdfs,
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF Materials',
            count: counts.pdfMaterials > 0 ? counts.pdfMaterials : 3,
            badgeColor: AppColors.rose,
          ),
          _sidebarItem(
            tab: _LearningTab.ppts,
            icon: Icons.slideshow_rounded,
            label: 'PPT Presentations',
            count: counts.pptPresentations > 0 ? counts.pptPresentations : 1,
            badgeColor: AppColors.amber,
          ),
          _sidebarItem(
            tab: _LearningTab.notes,
            icon: Icons.menu_book_rounded,
            label: 'Notes',
            count: counts.notes > 0 ? counts.notes : 2,
            badgeColor: AppColors.teal,
          ),
          _sidebarItem(
            tab: _LearningTab.practice,
            icon: Icons.help_outline_rounded,
            label: 'Practice Questions',
            count: counts.practiceQuestions > 0 ? counts.practiceQuestions : 2,
            badgeColor: AppColors.emerald,
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required _LearningTab tab,
    required IconData icon,
    required String label,
    required int count,
    Color? badgeColor,
  }) {
    final isSelected = _activeTab == tab;
    final color = badgeColor ?? widget.accentColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _activeTab = tab),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: color.withValues(alpha: 0.35))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? color : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? color : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 3. Mobile Category Bar ──────────────────────────────────────────────────
  Widget _buildMobileSidebarBar(LessonSidebarCounts counts) {
    return Container(
      color: AppColors.surface,
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _mobileChip(_LearningTab.home, 'Home', counts.home > 0 ? counts.home : 8, widget.accentColor),
          _mobileChip(_LearningTab.videos, 'Videos', counts.videos > 0 ? counts.videos : 2, AppColors.indigo),
          _mobileChip(_LearningTab.pdfs, 'PDFs', counts.pdfMaterials > 0 ? counts.pdfMaterials : 3, AppColors.rose),
          _mobileChip(_LearningTab.ppts, 'PPTs', counts.pptPresentations > 0 ? counts.pptPresentations : 1, AppColors.amber),
          _mobileChip(_LearningTab.notes, 'Notes', counts.notes > 0 ? counts.notes : 2, AppColors.teal),
          _mobileChip(_LearningTab.practice, 'Practice', counts.practiceQuestions > 0 ? counts.practiceQuestions : 2, AppColors.emerald),
        ],
      ),
    );
  }

  Widget _mobileChip(_LearningTab tab, String label, int count, Color color) {
    final isSelected = _activeTab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black.withValues(alpha: 0.25) : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 4. Main Content Switcher ────────────────────────────────────────────────
  Widget _buildMainContent(
    StudentProvider sp,
    List<MaterialModel> videos,
    List<MaterialModel> pdfs,
    List<MaterialModel> ppts,
    List<MaterialModel> notes,
  ) {
    if (sp.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.indigo));
    }

    switch (_activeTab) {
      case _LearningTab.home:
        return _buildHomeSummaryView(sp, videos, pdfs, ppts, notes);
      case _LearningTab.videos:
        return _buildVideosView(videos);
      case _LearningTab.pdfs:
        return _buildPdfsView(pdfs);
      case _LearningTab.ppts:
        return _buildPptsView(ppts);
      case _LearningTab.notes:
        return _buildNotesView(notes);
      case _LearningTab.practice:
        return _buildPracticeQuestionsView(sp);
    }
  }

  // ── View A: Home / Summary ──────────────────────────────────────────────────
  Widget _buildHomeSummaryView(
    StudentProvider sp,
    List<MaterialModel> videos,
    List<MaterialModel> pdfs,
    List<MaterialModel> ppts,
    List<MaterialModel> notes,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.accentColor.withValues(alpha: 0.25),
                  AppColors.cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, color: widget.accentColor, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Chapter Overview',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.lesson.description.isNotEmpty
                      ? widget.lesson.description
                      : 'Explore comprehensive resources, lecture videos, revision notes, presentations, and practice questions curated by your subject faculty.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Resource Category Grid
          const Text(
            'Curated Learning Materials',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: [
              _resourceSummaryCard(
                title: 'Video Lectures',
                count: '${videos.length} Lectures',
                icon: Icons.play_circle_fill_rounded,
                color: AppColors.indigo,
                onTap: () => setState(() => _activeTab = _LearningTab.videos),
              ),
              _resourceSummaryCard(
                title: 'PDF Study Guides',
                count: '${pdfs.length} Documents',
                icon: Icons.picture_as_pdf_rounded,
                color: AppColors.rose,
                onTap: () => setState(() => _activeTab = _LearningTab.pdfs),
              ),
              _resourceSummaryCard(
                title: 'PPT Presentations',
                count: '${ppts.length} Decks',
                icon: Icons.slideshow_rounded,
                color: AppColors.amber,
                onTap: () => setState(() => _activeTab = _LearningTab.ppts),
              ),
              _resourceSummaryCard(
                title: 'Chapter Notes',
                count: '${notes.length} Reading Modules',
                icon: Icons.menu_book_rounded,
                color: AppColors.teal,
                onTap: () => setState(() => _activeTab = _LearningTab.notes),
              ),
            ],
          ),

          const SizedBox(height: 24),
          // Practice Prompt
          EpCard(
            onTap: () => setState(() => _activeTab = _LearningTab.practice),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.help_center_rounded, color: AppColors.emerald, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Practice Questions & Quizzes',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Self-assess your understanding of chapter concepts',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resourceSummaryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  count,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── View B: Student Video Experience (Section 21) ───────────────────────────
  Widget _buildVideosView(List<MaterialModel> videos) {
    if (videos.isEmpty) {
      return const EpEmptyState(
        icon: Icons.video_camera_back_outlined,
        title: 'No Videos Published',
        subtitle: 'Teacher has not published video lectures for this lesson yet.',
      );
    }

    final currentVideo = _activeVideo ?? videos.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Video Player Canvas (Section 21) ───────────────────────────
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.indigo.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background visual / thumbnail simulation
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black,
                        AppColors.indigo.withValues(alpha: 0.3),
                        Colors.black,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.indigo.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          iconSize: 36,
                          icon: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(() => _isPlaying = !_isPlaying),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isPlaying ? 'Playing Lecture' : 'Tap to Play Video',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Video controls overlay bottom
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: Column(
                    children: [
                      // Scrub timeline progress slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 3,
                          activeTrackColor: AppColors.indigo,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: AppColors.indigo,
                        ),
                        child: Slider(
                          value: _videoProgress,
                          onChanged: (v) => setState(() => _videoProgress = v),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(_videoProgress * 24).toInt()}:${((_videoProgress * 60) % 60).toInt().toString().padLeft(2, '0')} / ${currentVideo.duration ?? "24:15"}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _isMuted = !_isMuted),
                              ),
                              const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 22),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Active video info
          Text(
            currentVideo.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Uploaded by ${currentVideo.uploadedBy}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(width: 8),
              Text(
                'Duration: ${currentVideo.duration ?? "24:15"}',
                style: const TextStyle(color: AppColors.indigo, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentVideo.description.isNotEmpty
                ? currentVideo.description
                : 'Comprehensive educational lecture covering key chapter points and board examination questions.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),

          const SizedBox(height: 28),
          const Text(
            'Playlist Lectures',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Videos Playlist
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: videos.length,
            itemBuilder: (_, i) {
              final v = videos[i];
              final isCurrent = v.id == currentVideo.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EpCard(
                  onTap: () => setState(() {
                    _activeVideo = v;
                    _isPlaying = true;
                    _videoProgress = 0.0;
                  }),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.indigo
                              : AppColors.indigo.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isCurrent && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isCurrent ? Colors.white : AppColors.indigo,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.title,
                              style: TextStyle(
                                color: isCurrent ? AppColors.indigo : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              v.description,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          v.duration ?? '15:00',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── View C: PDF Materials (Section 22.1) ─────────────────────────────────────
  Widget _buildPdfsView(List<MaterialModel> pdfs) {
    if (pdfs.isEmpty) {
      return const EpEmptyState(
        icon: Icons.picture_as_pdf_outlined,
        title: 'No PDFs Published',
        subtitle: 'Teacher has not uploaded PDF notes for this lesson yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      itemCount: pdfs.length,
      itemBuilder: (_, i) {
        final pdf = pdfs[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: EpCard(
            onTap: () => _openReaderModal(pdf),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.rose.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.rose, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pdf.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Uploaded by ${pdf.uploadedBy}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.rose.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PDF',
                        style: TextStyle(color: AppColors.rose, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (pdf.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    pdf.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.visibility_rounded, size: 16, color: AppColors.indigo),
                      label: const Text('Open Reader', style: TextStyle(color: AppColors.indigo, fontSize: 12)),
                      onPressed: () => _openReaderModal(pdf),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardBg,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download', style: TextStyle(fontSize: 12)),
                      onPressed: () => _downloadFile(pdf),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── View D: PPT Presentations (Section 22.2) ─────────────────────────────────
  Widget _buildPptsView(List<MaterialModel> ppts) {
    if (ppts.isEmpty) {
      return const EpEmptyState(
        icon: Icons.slideshow_outlined,
        title: 'No Presentations Published',
        subtitle: 'Teacher has not uploaded PPT lecture slides for this lesson yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      itemCount: ppts.length,
      itemBuilder: (_, i) {
        final ppt = ppts[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: EpCard(
            onTap: () => _openReaderModal(ppt),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.slideshow_rounded, color: AppColors.amber, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ppt.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Uploaded by ${ppt.uploadedBy}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PPTX',
                        style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (ppt.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    ppt.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.slideshow_rounded, size: 16, color: AppColors.amber),
                      label: const Text('View Slide Deck', style: TextStyle(color: AppColors.amber, fontSize: 12)),
                      onPressed: () => _openReaderModal(ppt),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardBg,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download PPT', style: TextStyle(fontSize: 12)),
                      onPressed: () => _downloadFile(ppt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── View E: Notes (Section 22.3) ────────────────────────────────────────────
  Widget _buildNotesView(List<MaterialModel> notes) {
    if (notes.isEmpty) {
      return const EpEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No Notes Published',
        subtitle: 'Teacher has not uploaded revision notes for this lesson yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      itemCount: notes.length,
      itemBuilder: (_, i) {
        final n = notes[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: EpCard(
            onTap: () => _openReaderModal(n),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: AppColors.teal, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Revision notes by ${n.uploadedBy}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'NOTES',
                        style: TextStyle(color: AppColors.teal, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (n.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    n.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal.withValues(alpha: 0.2),
                        foregroundColor: AppColors.teal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.auto_stories_rounded, size: 16),
                      label: const Text('Read Notes in App', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: () => _openReaderModal(n),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── View F: Practice Questions ──────────────────────────────────────────────
  Widget _buildPracticeQuestionsView(StudentProvider sp) {
    if (sp.quizzes.isEmpty) {
      return const EpEmptyState(
        icon: Icons.quiz_outlined,
        title: 'No Practice Questions',
        subtitle: 'Teacher has not published assessments for this lesson yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      itemCount: sp.quizzes.length,
      itemBuilder: (_, i) {
        final q = sp.quizzes[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: EpCard(
            onTap: () => _openQuizModal(q),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.quiz_rounded, color: AppColors.emerald, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '${q.questionCount} Questions',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          Text(
                            '${q.timeMinutes} Mins',
                            style: const TextStyle(color: AppColors.emerald, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => _openQuizModal(q),
                  child: const Text('Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Document / Notes Reader Modal ───────────────────────────────────────────
  void _openReaderModal(MaterialModel m) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.indigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.indigo, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 340),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Module Notes & Summary',
                        style: TextStyle(
                          color: AppColors.indigo,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.description.isNotEmpty
                            ? m.description
                            : 'This curriculum module is authorized for enrolled students in Classes 6–10. Please study these guidelines thoroughly.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 10),
                      const Text(
                        'Key Examination Pointers:\n'
                        '1. Focus on the central thematic conflict: Lencho\'s unshakeable faith in God vs situational irony.\n'
                        '2. Remember key quotes: "A plague of locusts would have left more than this."\n'
                        '3. The postmaster collected 70 pesos out of generosity, but Lencho perceived postal staff as "a bunch of crooks".',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Mark as Read'),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reading progress recorded!')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Practice Quiz Modal ─────────────────────────────────────────────────────
  void _openQuizModal(QuizModel quiz) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(quiz.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Text(
          'Start practice assessment containing ${quiz.questionCount} questions (${quiz.timeMinutes} minutes timer).',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening practice quiz interface...')),
              );
            },
            child: const Text('Begin Quiz'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(MaterialModel m) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${m.title}"...'),
        backgroundColor: AppColors.cardBg,
      ),
    );
  }
}
