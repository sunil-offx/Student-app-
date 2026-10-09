// lib/features/student/screens/student_quiz_attempt_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/student_provider.dart';
import '../../../shared/widgets/ep_appbar.dart';
import '../../../shared/widgets/ep_button.dart';
import '../../../shared/widgets/ep_card.dart';

class StudentQuizAttemptScreen extends StatefulWidget {
  final QuizModel quiz;
  const StudentQuizAttemptScreen({super.key, required this.quiz});

  @override
  State<StudentQuizAttemptScreen> createState() =>
      _StudentQuizAttemptScreenState();
}

class _StudentQuizAttemptScreenState extends State<StudentQuizAttemptScreen> {
  final Map<int, int> _answers = {};
  int _currentQuestion = 0;
  late Timer _timer;
  late int _secondsLeft;
  bool _submitted = false;
  Map<String, dynamic>? _result;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.quiz.timeMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _submitQuiz();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timerStr {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _submitQuiz() async {
    if (_submitted) return;
    _timer.cancel();
    setState(() => _submitting = true);
    final result = await context.read<StudentProvider>().submitQuiz(
          widget.quiz.id,
          _answers,
        );
    setState(() {
      _submitted = true;
      _result = result;
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _ResultScreen(
        quiz: widget.quiz,
        result: _result,
        onClose: () => Navigator.pop(context),
      );
    }

    final questions = widget.quiz.questions;
    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: EpAppBar(title: widget.quiz.title),
        body: const EpEmptyState(
          icon: Icons.quiz_outlined,
          title: 'No questions',
          subtitle: 'This quiz has no questions yet',
        ),
      );
    }

    final q = questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showExitDialog(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.quiz.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Q ${_currentQuestion + 1} of ${questions.length}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _secondsLeft < 60
                          ? AppColors.rose.withValues(alpha: 0.15)
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _secondsLeft < 60
                            ? AppColors.rose.withValues(alpha: 0.4)
                            : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: _secondsLeft < 60
                              ? AppColors.rose
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timerStr,
                          style: TextStyle(
                            color: _secondsLeft < 60
                                ? AppColors.rose
                                : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.cardBg,
                  color: AppColors.indigo,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.indigo.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        q.questionText,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Options
                    ...q.options.asMap().entries.map((e) {
                      final idx = e.key;
                      final opt = e.value;
                      final selected = _answers[q.id] == idx;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _answers[q.id] = idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.indigo.withValues(alpha: 0.12)
                                  : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? AppColors.indigo
                                    : AppColors.divider,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.indigo
                                        : AppColors.cardBgAlt,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.indigo
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + idx),
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    opt,
                                    style: TextStyle(
                                      color: selected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: selected
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Navigation
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentQuestion > 0)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                            () => _currentQuestion--),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: AppColors.divider),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_rounded,
                                    size: 16, color: AppColors.textSecondary),
                                SizedBox(width: 6),
                                Text('Previous',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_currentQuestion > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _submitting
                          ? null
                          : () {
                              if (_currentQuestion <
                                  questions.length - 1) {
                                setState(() => _currentQuestion++);
                              } else {
                                _submitQuiz();
                              }
                            },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppColors.indigoGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.indigo.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Center(
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _currentQuestion == questions.length - 1
                                      ? 'Submit Quiz'
                                      : 'Next',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Quiz?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Your progress will be lost if you exit.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit',
                style: TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final QuizModel quiz;
  final Map<String, dynamic>? result;
  final VoidCallback onClose;

  const _ResultScreen({
    required this.quiz,
    required this.result,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final score = result?['score'] ?? 0;
    final total = result?['total'] ?? quiz.questionCount;
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final passed = pct >= 50;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: passed
                      ? AppColors.emeraldGradient
                      : AppColors.roseGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: (passed ? AppColors.emerald : AppColors.rose)
                          .withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  passed
                      ? Icons.emoji_events_rounded
                      : Icons.sentiment_neutral_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                passed ? 'Great Work!' : 'Keep Practicing!',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                quiz.title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 40),
              // Score card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ScoreStat('Score', '$score/$total',
                        AppColors.indigo),
                    Container(
                        width: 1, height: 40, color: AppColors.divider),
                    _ScoreStat(
                        'Percentage', '$pct%', AppColors.teal),
                    Container(
                        width: 1, height: 40, color: AppColors.divider),
                    _ScoreStat('Result', passed ? 'Pass' : 'Fail',
                        passed ? AppColors.emerald : AppColors.rose),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              EpGradientButton(
                label: 'Done',
                gradient: AppColors.indigoGradient,
                onTap: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
