// lib/features/admin/screens/admin_subjects_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/ep_card.dart';
import '../../../shared/widgets/ep_button.dart';

class AdminSubjectsTab extends StatelessWidget {
  const AdminSubjectsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subjects',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddSubjectSheet(context, ap),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.indigoGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Add Subject',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        if (ap.loading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: EpLoadingShimmer(height: 86),
                ),
                childCount: 4,
              ),
            ),
          )
        else if (ap.subjects.isEmpty)
          const SliverFillRemaining(
            child: EpEmptyState(
              icon: Icons.book_outlined,
              title: 'No subjects yet',
              subtitle: 'Add subjects and assign them to teachers',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final s = ap.subjects[i];
                  final colors = [
                    AppColors.indigo,
                    AppColors.teal,
                    AppColors.amber,
                    AppColors.rose,
                    AppColors.emerald,
                  ];
                  final color = colors[i % colors.length];
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 55),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EpCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.book_rounded,
                                      color: color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${s.code} · ${s.className}',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (s.teacher != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.teal.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      s.teacher!.fullName.split(' ').first,
                                      style: const TextStyle(
                                        color: AppColors.teal,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: () =>
                                        _showAssignTeacherSheet(context, s, ap),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.amber.withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              AppColors.amber.withValues(alpha: 0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'Assign Teacher',
                                        style: TextStyle(
                                          color: AppColors.amber,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (s.teacher == null) ...[
                              const SizedBox(height: 10),
                              const Divider(color: AppColors.divider),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () =>
                                    _showAssignTeacherSheet(context, s, ap),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_add_alt_1_rounded,
                                        size: 14, color: AppColors.textMuted),
                                    SizedBox(width: 6),
                                    Text('Tap to assign a teacher',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: ap.subjects.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _showAddSubjectSheet(BuildContext context, AdminProvider ap) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    ClassModel? selectedClass;

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
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Add New Subject',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'Subject name (e.g. Mathematics)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: codeCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Subject code (e.g. MATH10)'),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ClassModel>(
                    value: selectedClass,
                    hint: const Text('Assign to class',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 14)),
                    isExpanded: true,
                    dropdownColor: AppColors.cardBg,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted),
                    items: ap.classes.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.name));
                    }).toList(),
                    onChanged: (c) => setLocal(() => selectedClass = c),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              EpGradientButton(
                label: 'Create Subject',
                gradient: AppColors.indigoGradient,
                onTap: () async {
                  if (nameCtrl.text.isEmpty ||
                      codeCtrl.text.isEmpty ||
                      selectedClass == null) {
                    return;
                  }
                  Navigator.pop(ctx);
                  final ok = await ap.createSubject(
                    name: nameCtrl.text.trim(),
                    code: codeCtrl.text.trim(),
                    classId: selectedClass!.id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          ok ? 'Subject created!' : 'Failed to create subject'),
                      backgroundColor: ok ? AppColors.emerald : AppColors.rose,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignTeacherSheet(
      BuildContext context, SubjectModel subject, AdminProvider ap) {
    UserModel? selectedTeacher;

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
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Assign Teacher to ${subject.name}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (ap.teachers.isEmpty)
                const Text(
                  'No teachers available. Add a teacher first.',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 14),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserModel>(
                      value: selectedTeacher,
                      hint: const Text('Select teacher',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 14)),
                      isExpanded: true,
                      dropdownColor: AppColors.cardBg,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted),
                      items: ap.teachers.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.fullName),
                        );
                      }).toList(),
                      onChanged: (t) =>
                          setLocal(() => selectedTeacher = t),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              EpGradientButton(
                label: 'Assign Teacher',
                gradient: AppColors.tealGradient,
                onTap: selectedTeacher == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final ok = await ap.assignSubjectToTeacher(
                          subjectId: subject.id,
                          teacherId: selectedTeacher!.id,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? 'Teacher assigned!'
                                : 'Failed to assign teacher'),
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
    );
  }
}
