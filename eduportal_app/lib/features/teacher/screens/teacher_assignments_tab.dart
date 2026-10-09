// lib/features/teacher/screens/teacher_assignments_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/teacher_provider.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/ep_card.dart';
import '../../../shared/widgets/ep_button.dart';

class TeacherAssignmentsTab extends StatefulWidget {
  const TeacherAssignmentsTab({super.key});

  @override
  State<TeacherAssignmentsTab> createState() => _TeacherAssignmentsTabState();
}

class _TeacherAssignmentsTabState extends State<TeacherAssignmentsTab> {
  SubjectModel? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TeacherProvider>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assignments',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: _selectedSubject == null
                            ? null
                            : () => _showCreateAssignmentSheet(context),
                        child: Container(
                          height: 36,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            gradient: _selectedSubject != null
                                ? AppColors.tealGradient
                                : null,
                            color: _selectedSubject == null
                                ? AppColors.cardBg
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: _selectedSubject == null
                                ? Border.all(color: AppColors.divider)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  color: _selectedSubject != null
                                      ? Colors.white
                                      : AppColors.textMuted,
                                  size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'New',
                                style: TextStyle(
                                  color: _selectedSubject != null
                                      ? Colors.white
                                      : AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Subject filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Chip(
                          label: 'All',
                          selected: _selectedSubject == null,
                          onTap: () => setState(() => _selectedSubject = null),
                        ),
                        const SizedBox(width: 8),
                        ...tp.subjects.map((s) {
                          final sel = _selectedSubject?.id == s.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _Chip(
                              label: '${s.name} (${s.className})',
                              selected: sel,
                              onTap: () {
                                setState(() => _selectedSubject = s);
                                tp.fetchAssignments(s.id);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        if (_selectedSubject == null)
          const SliverFillRemaining(
            child: EpEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Select a subject',
              subtitle: 'Choose a subject above to view and create assignments',
            ),
          )
        else if (tp.loading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: EpLoadingShimmer(height: 110),
                ),
                childCount: 3,
              ),
            ),
          )
        else if (tp.assignments.isEmpty)
          SliverFillRemaining(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EpEmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No assignments yet',
                  subtitle: 'Create your first assignment for this class',
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: EpGradientButton(
                    label: 'Create Assignment',
                    gradient: AppColors.tealGradient,
                    onTap: () => _showCreateAssignmentSheet(context),
                  ),
                ),
              ],
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final a = tp.assignments[i];
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 60),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AssignmentCard(assignment: a),
                    ),
                  );
                },
                childCount: tp.assignments.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _showCreateAssignmentSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final maxScoreCtrl = TextEditingController(text: '100');
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'New Assignment — ${_selectedSubject!.name}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Assignment title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Instructions / description',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxScoreCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Maximum score',
                    prefixIcon: Icon(Icons.star_outline_rounded,
                        color: AppColors.amber, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                // Due date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (_, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.teal,
                            surface: AppColors.cardBg,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setLocal(() => dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: AppColors.teal, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                EpGradientButton(
                  label: 'Create Assignment',
                  gradient: AppColors.tealGradient,
                  onTap: () async {
                    if (titleCtrl.text.isEmpty) return;
                    Navigator.pop(ctx);
                    final ok = await context
                        .read<TeacherProvider>()
                        .createAssignment(
                      subjectId: _selectedSubject!.id,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      dueDate: dueDate,
                      maxScore: int.tryParse(maxScoreCtrl.text) ?? 100,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            ok ? 'Assignment created!' : 'Failed to create'),
                        backgroundColor:
                            ok ? AppColors.emerald : AppColors.rose,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final isOverdue = a.dueDate.isBefore(DateTime.now());
    final dueStr = DateFormat('dd MMM yyyy').format(a.dueDate);

    return EpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: AppColors.teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      a.subjectName,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppColors.rose.withValues(alpha: 0.12)
                      : AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isOverdue ? 'Closed' : 'Active',
                  style: TextStyle(
                    color: isOverdue ? AppColors.rose : AppColors.emerald,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.description,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text('Due $dueStr',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.star_outline_rounded,
                  size: 13, color: AppColors.amber),
              const SizedBox(width: 4),
              Text('${a.maxScore} pts',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withValues(alpha: 0.15)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.teal : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
