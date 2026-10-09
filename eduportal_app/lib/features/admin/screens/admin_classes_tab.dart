// lib/features/admin/screens/admin_classes_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/ep_card.dart';
import '../widgets/admin_dialogs.dart';

class AdminClassesTab extends StatefulWidget {
  const AdminClassesTab({super.key});

  @override
  State<AdminClassesTab> createState() => _AdminClassesTabState();
}

class _AdminClassesTabState extends State<AdminClassesTab> {
  // Active Management Context (Section 9.1)
  int _selectedClassIndex = 4; // Defaults to Class 10 (Index 4)
  int _activeSubTabIndex = 0; // 0: Overview, 1: Students, 2: Sections, 3: Teachers, 4: Subjects, 5: Lessons
  final String _selectedAcademicYear = '2026-2027';

  final List<String> _classLabels = ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
  final List<String> _subTabLabels = ['Overview', 'Students', 'Sections', 'Teachers', 'Subjects', 'Lessons'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveClassData();
    });
  }

  void _loadActiveClassData() {
    final ap = context.read<AdminProvider>();
    if (ap.classes.isNotEmpty) {
      final targetClassId = ap.classes.length > _selectedClassIndex
          ? ap.classes[_selectedClassIndex].id
          : ap.classes.last.id;
      ap.fetchClassTabs(targetClassId);
    } else {
      ap.fetchClasses().then((_) {
        if (mounted && ap.classes.isNotEmpty) {
          final targetClassId = ap.classes.length > _selectedClassIndex
              ? ap.classes[_selectedClassIndex].id
              : ap.classes.last.id;
          ap.fetchClassTabs(targetClassId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();
    final activeTabsData = ap.activeClassTabs;
    final currentClassName = _selectedClassIndex < _classLabels.length
        ? _classLabels[_selectedClassIndex]
        : 'Class 10';

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header & Academic Year Selector ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Class Management',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Academic Structure Workspace • Classes 6–10',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Academic Year Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.indigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.indigo.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.indigo),
                      const SizedBox(width: 6),
                      Text(
                        _selectedAcademicYear,
                        style: const TextStyle(
                          color: AppColors.indigo,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Class Selector Chips (Section 9.1: Classes 6-10) ──────────────
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _classLabels.length,
              itemBuilder: (context, i) {
                final isSelected = _selectedClassIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_classLabels[i]),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedClassIndex = i);
                        _loadActiveClassData();
                      }
                    },
                    selectedColor: AppColors.indigo,
                    backgroundColor: AppColors.cardBg,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.indigo : AppColors.divider,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Selected Class Sub-Tabs (Section 9.2) ─────────────────────────
          Container(
            color: AppColors.surface,
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _subTabLabels.length,
              itemBuilder: (context, i) {
                final isSelected = _activeSubTabIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _activeSubTabIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? AppColors.indigo : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _subTabLabels[i],
                      style: TextStyle(
                        color: isSelected ? AppColors.indigo : AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ── Tab Body Content ──────────────────────────────────────────────
          Expanded(
            child: ap.loading && activeTabsData == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.indigo))
                : _buildSubTabContent(currentClassName, activeTabsData),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabContent(String className, ClassTabsDataModel? tabsData) {
    switch (_activeSubTabIndex) {
      case 0:
        return _buildOverviewTab(className, tabsData?.overview ?? {});
      case 1:
        return _buildStudentsTab(className, tabsData?.students ?? []);
      case 2:
        return _buildSectionsTab(
          className,
          tabsData?.classInfo['id'] as int? ?? 0,
          tabsData?.sections ?? [],
        );
      case 3:
        return _buildTeachersTab(className, tabsData?.teachers ?? []);
      case 4:
        return _buildSubjectsTab(className, tabsData?.subjects ?? []);
      case 5:
        return _buildLessonsTab(className, tabsData?.lessons ?? []);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── 1. Class Summary & Overview (Section 9.3) ──────────────────────────────
  Widget _buildOverviewTab(String className, Map<String, dynamic> overview) {
    final totalStudents = overview['total_students'] ?? 32;
    final totalSections = overview['total_sections'] ?? 2;
    final totalSubjects = overview['total_subjects'] ?? 5;
    final totalTeachers = overview['total_teachers'] ?? 4;
    final status = overview['status'] ?? 'Active';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Context Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.indigo.withValues(alpha: 0.25),
                  AppColors.cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.indigo.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.indigoGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            className,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: AppColors.emerald,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Active Academic Management Workspace',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Academic Metrics',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: [
              _metricTile(
                title: 'Enrolled Students',
                val: '$totalStudents',
                subtitle: 'Registered Learners',
                icon: Icons.people_alt_rounded,
                color: AppColors.indigo,
              ),
              _metricTile(
                title: 'Sections',
                val: '$totalSections',
                subtitle: 'Active Cohorts',
                icon: Icons.meeting_room_rounded,
                color: AppColors.teal,
              ),
              _metricTile(
                title: 'Subjects',
                val: '$totalSubjects',
                subtitle: 'Curriculum Units',
                icon: Icons.menu_book_rounded,
                color: AppColors.amber,
              ),
              _metricTile(
                title: 'Faculty Members',
                val: '$totalTeachers',
                subtitle: 'Assigned Teachers',
                icon: Icons.badge_rounded,
                color: AppColors.rose,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String title,
    required String val,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                val,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Class Students Tab (Section 10.2) ────────────────────────────────────
  Widget _buildStudentsTab(String className, List<UserModel> students) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$className Students (${students.length})',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Class Context Inherited',
                  style: TextStyle(color: AppColors.indigo, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? const EpEmptyState(
                  icon: Icons.people_outline,
                  title: 'No Students Enrolled',
                  subtitle: 'Add students to this class in User Management',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final s = students[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: EpCard(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.indigo.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  s.fullName.isNotEmpty ? s.fullName[0] : 'S',
                                  style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.fullName,
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Roll No: ${s.rollNumber ?? "10-A-01"} • ${s.sectionName ?? "Section A"}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Active', style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── 3. Class Sections Tab ──────────────────────────────────────────────────
  Widget _buildSectionsTab(
    String className,
    int classId,
    List<SectionModel> sections,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$className Sections (${sections.length})',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: classId == 0
                    ? null
                    : () => AdminDialogs.showAddSectionSheet(
                          context,
                          context.read<AdminProvider>(),
                          classId,
                        ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add section'),
              ),
            ],
          ),
        ),
        Expanded(
          child: sections.isEmpty
              ? const Center(
                  child: Text(
                    'No sections yet. Add one for this class.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: sections.length,
                  itemBuilder: (_, i) {
                    final section = sections[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EpCard(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.meeting_room_rounded,
                                color: AppColors.teal,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Location: ${section.roomNumber ?? "Not set"}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.emerald,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── 4. Class Teachers Tab (Section 15 Explicit Permission) ──────────────────
  Widget _buildTeachersTab(String className, List<Map<String, dynamic>> teachers) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: teachers.length,
      itemBuilder: (_, i) {
        final t = teachers[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EpCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.rose, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['teacher_name'] ?? 'Faculty Member',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Subject: ${t['subject_name'] ?? "English"} • Section: ${t['section_name'] ?? "All"}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Assigned', style: TextStyle(color: AppColors.indigo, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 5. Class Subjects Tab ──────────────────────────────────────────────────
  Widget _buildSubjectsTab(String className, List<SubjectModel> subjects) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: subjects.length,
      itemBuilder: (_, i) {
        final s = subjects[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EpCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (s.iconColor != null)
                        ? Color(int.parse(s.iconColor!.replaceFirst('#', '0xFF'))).withValues(alpha: 0.15)
                        : AppColors.indigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.book_rounded, color: AppColors.indigo, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Code: ${s.code}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Configured', style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 6. Class Lessons Tab ───────────────────────────────────────────────────
  Widget _buildLessonsTab(String className, List<Map<String, dynamic>> lessons) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: lessons.length,
      itemBuilder: (_, i) {
        final l = lessons[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EpCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: AppColors.amber, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l['title'] ?? 'Lesson',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${l['unit_title'] ?? "Unit 1"} • ${l['subject_name'] ?? "Subject"}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${l['material_count'] ?? 8} materials',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
