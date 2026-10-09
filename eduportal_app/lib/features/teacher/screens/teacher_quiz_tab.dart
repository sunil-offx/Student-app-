// lib/features/teacher/screens/teacher_quiz_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/teacher_provider.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/ep_card.dart';
import '../../../shared/widgets/ep_button.dart';

class TeacherQuizTab extends StatefulWidget {
  const TeacherQuizTab({super.key});

  @override
  State<TeacherQuizTab> createState() => _TeacherQuizTabState();
}

class _TeacherQuizTabState extends State<TeacherQuizTab> {
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
                        'Quizzes',
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
                            : () => _showCreateQuizSheet(context),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
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
                              Text('New Quiz',
                                  style: TextStyle(
                                    color: _selectedSubject != null
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Subject filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _selectedSubject == null,
                          color: AppColors.teal,
                          onTap: () {
                            setState(() => _selectedSubject = null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ...tp.subjects.asMap().entries.map((e) {
                          final s = e.value;
                          final sel = _selectedSubject?.id == s.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: '${s.name} (${s.className})',
                              selected: sel,
                              color: AppColors.teal,
                              onTap: () {
                                setState(() => _selectedSubject = s);
                                tp.fetchQuizzes(s.id);
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
              icon: Icons.quiz_outlined,
              title: 'Select a subject',
              subtitle: 'Choose a subject above to view and create quizzes',
            ),
          )
        else if (tp.loading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: EpLoadingShimmer(height: 90),
                ),
                childCount: 3,
              ),
            ),
          )
        else if (tp.quizzes.isEmpty)
          SliverFillRemaining(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EpEmptyState(
                  icon: Icons.quiz_outlined,
                  title: 'No quizzes yet',
                  subtitle: 'Create your first quiz for this subject',
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: EpGradientButton(
                    label: 'Create Quiz',
                    gradient: AppColors.tealGradient,
                    onTap: () => _showCreateQuizSheet(context),
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
                  final q = tp.quizzes[i];
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 60),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuizCard(quiz: q),
                    ),
                  );
                },
                childCount: tp.quizzes.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _showCreateQuizSheet(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) =>
            _CreateQuizScreen(subject: _selectedSubject!),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: const Cubic(0.22, 1, 0.36, 1))),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
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
          color: selected ? color.withValues(alpha: 0.15) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : AppColors.divider,
              width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;

  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return EpCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.quiz_rounded,
                color: AppColors.teal, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${quiz.questionCount} questions',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    const Text(' · ',
                        style: TextStyle(color: AppColors.textMuted)),
                    Text('${quiz.timeMinutes} min',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

// ──────── Create Quiz Screen ────────
class _CreateQuizScreen extends StatefulWidget {
  final SubjectModel subject;

  const _CreateQuizScreen({required this.subject});

  @override
  State<_CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<_CreateQuizScreen> {
  final _titleCtrl = TextEditingController();
  int _timeMinutes = 10;
  final List<_QuestionData> _questions = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addQuestion();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionData());
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) {
      _showSnack('Enter a quiz title', AppColors.amber);
      return;
    }
    final questions = _questions.map((q) => q.toMap()).where((q) {
      return (q['question_text'] as String).isNotEmpty;
    }).toList();

    if (questions.isEmpty) {
      _showSnack('Add at least one question', AppColors.amber);
      return;
    }
    setState(() => _saving = true);
    final ok = await context.read<TeacherProvider>().createQuiz(
          subjectId: widget.subject.id,
          title: _titleCtrl.text.trim(),
          timeMinutes: _timeMinutes,
          questions: questions,
        );
    if (mounted) {
      _showSnack(ok ? 'Quiz created!' : 'Failed to create quiz',
          ok ? AppColors.emerald : AppColors.rose);
      if (ok) Navigator.pop(context);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Create Quiz — ${widget.subject.name}',
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 15),
            overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('Publish',
                style: TextStyle(
                  color: _saving ? AppColors.textMuted : AppColors.teal,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Quiz title',
              prefixIcon: Icon(Icons.title_rounded,
                  color: AppColors.textMuted, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          EpCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: AppColors.teal, size: 18),
                    SizedBox(width: 8),
                    Text('Time limit (minutes)',
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _timeMinutes = (_timeMinutes - 5).clamp(5, 120)),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.cardBgAlt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.remove_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '$_timeMinutes',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _timeMinutes = (_timeMinutes + 5).clamp(5, 120)),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_rounded,
                            size: 16, color: AppColors.teal),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const EpSectionHeader(title: 'Questions'),
          const SizedBox(height: 14),
          ..._questions.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _QuestionEditor(
                index: i + 1,
                data: q,
                onRemove: _questions.length > 1
                    ? () => setState(() => _questions.removeAt(i))
                    : null,
                onChanged: () => setState(() {}),
              ),
            );
          }),
          EpOutlineButton(
            label: '+ Add Question',
            onTap: _addQuestion,
            borderColor: AppColors.teal.withValues(alpha: 0.4),
            textColor: AppColors.teal,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _QuestionData {
  final TextEditingController questionCtrl = TextEditingController();
  final List<TextEditingController> optionCtrls =
      List.generate(4, (_) => TextEditingController());
  int correctOption = 0;

  void dispose() {
    questionCtrl.dispose();
    for (final c in optionCtrls) {
      c.dispose();
    }
  }

  Map<String, dynamic> toMap() => {
        'question_text': questionCtrl.text.trim(),
        'options': optionCtrls.map((c) => c.text.trim()).toList(),
        'correct_option_index': correctOption,
      };
}

class _QuestionEditor extends StatefulWidget {
  final int index;
  final _QuestionData data;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _QuestionEditor({
    required this.index,
    required this.data,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  @override
  Widget build(BuildContext context) {
    return EpCard(
      borderColor: AppColors.teal.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Q ${widget.index}',
                style: const TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: const Icon(Icons.remove_circle_outline_rounded,
                      size: 18, color: AppColors.rose),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.data.questionCtrl,
            onChanged: (_) => widget.onChanged(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Question text',
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          ...widget.data.optionCtrls.asMap().entries.map((e) {
            final i = e.key;
            final ctrl = e.value;
            final isCorrect = widget.data.correctOption == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => widget.data.correctOption = i);
                      widget.onChanged();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.teal
                            : AppColors.cardBgAlt,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCorrect ? AppColors.teal : AppColors.divider,
                        ),
                      ),
                      child: isCorrect
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Option ${String.fromCharCode(65 + i)}',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isCorrect
                                ? AppColors.teal
                                : AppColors.indigo,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          const Text(
            'Tap the circle to mark correct answer',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
