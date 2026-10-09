// lib/features/student/screens/student_assignments_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/ep_card.dart';

class StudentAssignmentsTab extends StatelessWidget {
  const StudentAssignmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudentProvider>();
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'Assignments',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        if (sp.loading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: EpLoadingShimmer(height: 110),
                ),
                childCount: 4,
              ),
            ),
          )
        else if (sp.assignments.isEmpty)
          const SliverFillRemaining(
            child: EpEmptyState(
              icon: Icons.assignment_outlined,
              title: 'No assignments',
              subtitle: 'You\'ll see assignments from your teachers here',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final a = sp.assignments[i];
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 60),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AssignmentCard(assignment: a),
                    ),
                  );
                },
                childCount: sp.assignments.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _AssignmentCard extends StatefulWidget {
  final AssignmentModel assignment;
  const _AssignmentCard({required this.assignment});

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  bool _submitting = false;

  Color get _statusColor {
    switch (widget.assignment.submissionStatus) {
      case 'submitted':
        return AppColors.teal;
      case 'graded':
        return AppColors.emerald;
      default:
        final overdue = widget.assignment.dueDate.isBefore(DateTime.now());
        return overdue ? AppColors.rose : AppColors.amber;
    }
  }

  String get _statusLabel {
    switch (widget.assignment.submissionStatus) {
      case 'submitted':
        return 'Submitted';
      case 'graded':
        return 'Graded ${widget.assignment.score}/${widget.assignment.maxScore}';
      default:
        final overdue = widget.assignment.dueDate.isBefore(DateTime.now());
        return overdue ? 'Overdue' : 'Pending';
    }
  }

  Future<void> _submit() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (files.isEmpty || files.single.path == null) return;
    setState(() => _submitting = true);
    final file = File(files.single.path!);
    final ok = await context.read<StudentProvider>().submitAssignment(
          widget.assignment.id,
          file,
        );
    if (mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Assignment submitted!' : 'Submission failed'),
          backgroundColor: ok ? AppColors.emerald : AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final dueStr = DateFormat('dd MMM yyyy').format(a.dueDate);
    return EpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                    const SizedBox(height: 3),
                    Text(
                      a.subjectName,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                'Due: $dueStr',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Max: ${a.maxScore} pts',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          if (a.submissionStatus == null ||
              a.submissionStatus == 'pending') ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _submitting ? null : _submit,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.indigoGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upload_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Submit Assignment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
          if (a.submissionStatus == 'graded' &&
              a.feedback != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.feedback_outlined,
                      color: AppColors.emerald, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a.feedback!,
                      style: const TextStyle(
                          color: AppColors.emerald, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
