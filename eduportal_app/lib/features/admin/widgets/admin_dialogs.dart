// lib/features/admin/widgets/admin_dialogs.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/ep_button.dart';

class AdminDialogs {
  static Widget buildSheetInput({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. ADD STUDENT SHEET
  // ──────────────────────────────────────────────────────────────────────────
  static Future<void> showAddStudentSheet(
    BuildContext context,
    AdminProvider ap,
  ) async {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'student123');
    final rollCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final parentNameCtrl = TextEditingController();
    final parentPhoneCtrl = TextEditingController();
    DateTime dob = DateTime(2010, 5, 14);

    ClassModel? selectedClass = ap.classes.isNotEmpty ? ap.classes.first : null;
    List<SectionModel> sections = [];
    int? selectedSectionId;
    String? sectionError;
    var loadingSections = false;
    var saving = false;

    if (selectedClass != null) {
      try {
        sections = await ap.fetchClassSections(selectedClass.id);
        selectedSectionId = sections.isEmpty ? null : sections.first.id;
      } catch (error) {
        sectionError = error.toString();
      }
    }
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.amberGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Student',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Enroll student in Classes 6–10 with academic record preservation',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Form fields
                buildSheetInput(
                  ctrl: nameCtrl,
                  label: 'Full Name *',
                  hint: 'e.g. Rahul Sharma',
                  onChanged: (val) {
                    if (usernameCtrl.text.isEmpty && val.isNotEmpty) {
                      final generated = val.trim().toLowerCase().replaceAll(' ', '.');
                      setLocal(() {
                        usernameCtrl.text = generated;
                        if (emailCtrl.text.isEmpty) {
                          emailCtrl.text = '$generated@school.edu';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: buildSheetInput(
                        ctrl: rollCtrl,
                        label: 'Roll Number',
                        hint: selectedClass != null ? 'ROLL-${selectedClass!.id}A-01' : 'ROLL-10A-01',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildSheetInput(
                        ctrl: usernameCtrl,
                        label: 'Username *',
                        hint: 'rahul.s',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                buildSheetInput(
                  ctrl: emailCtrl,
                  label: 'Email Address',
                  hint: 'rahul.sharma@school.edu',
                ),
                const SizedBox(height: 10),
                buildSheetInput(
                  ctrl: passCtrl,
                  label: 'Default Password',
                  hint: 'student123',
                  obscure: true,
                ),
                const SizedBox(height: 10),

                // Class selector (Classes 6 to 10)
                const Text(
                  'Academic Class *',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ClassModel>(
                      value: selectedClass,
                      isExpanded: true,
                      dropdownColor: AppColors.cardBg,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      items: ap.classes.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                      onChanged: (c) {
                        if (c == null) return;
                        setLocal(() {
                          selectedClass = c;
                          sections = [];
                          selectedSectionId = null;
                          sectionError = null;
                          loadingSections = true;
                        });
                        ap.fetchClassSections(c.id).then((loadedSections) {
                          if (!ctx.mounted) return;
                          setLocal(() {
                            sections = loadedSections;
                            selectedSectionId = loadedSections.isEmpty
                                ? null
                                : loadedSections.first.id;
                            loadingSections = false;
                          });
                        }).catchError((Object error) {
                          if (!ctx.mounted) return;
                          setLocal(() {
                            sectionError = error.toString();
                            loadingSections = false;
                          });
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Section selector
                const Text(
                  'Section',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedSectionId,
                      isExpanded: true,
                      hint: Text(
                        loadingSections
                            ? 'Loading sections...'
                            : 'No section selected',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      dropdownColor: AppColors.cardBg,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      items: sections
                          .map(
                            (section) => DropdownMenuItem<int>(
                              value: section.id,
                              child: Text(section.name),
                            ),
                          )
                          .toList(),
                      onChanged: sections.isEmpty || loadingSections
                          ? null
                          : (sectionId) =>
                              setLocal(() => selectedSectionId = sectionId),
                    ),
                  ),
                ),
                if (sectionError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Could not load sections: $sectionError',
                    style: const TextStyle(color: AppColors.rose, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: buildSheetInput(
                        ctrl: phoneCtrl,
                        label: 'Student Phone',
                        hint: '+91 98765 43210',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildSheetInput(
                        ctrl: parentPhoneCtrl,
                        label: 'Parent Phone',
                        hint: '+91 98765 00000',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                buildSheetInput(
                  ctrl: parentNameCtrl,
                  label: 'Parent / Guardian Name',
                  hint: 'Mr. Ramesh Sharma',
                ),
                const SizedBox(height: 20),

                EpGradientButton(
                  label: 'Save & Enroll Student',
                  gradient: AppColors.amberGradient,
                  loading: saving,
                  onTap: () async {
                    if (saving) return;
                    if (nameCtrl.text.trim().isEmpty || usernameCtrl.text.trim().isEmpty || selectedClass == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields (Name, Username, Class)')),
                      );
                      return;
                    }
                    if (sectionError != null || loadingSections) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Wait for the selected class sections to load.'),
                        ),
                      );
                      return;
                    }
                    setLocal(() => saving = true);
                    final ok = await ap.createStudent(
                      username: usernameCtrl.text.trim(),
                      password: passCtrl.text.trim().isNotEmpty ? passCtrl.text.trim() : 'student123',
                      fullName: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim().isNotEmpty
                          ? emailCtrl.text.trim()
                          : '${usernameCtrl.text.trim()}@school.edu',
                      classId: selectedClass!.id,
                      sectionId: selectedSectionId,
                      rollNumber: rollCtrl.text.trim().isNotEmpty
                          ? rollCtrl.text.trim()
                          : null,
                      dateOfBirth: DateFormat('yyyy-MM-dd').format(dob),
                      contactNumber: phoneCtrl.text.trim(),
                      parentName: parentNameCtrl.text.trim(),
                      parentContact: parentPhoneCtrl.text.trim(),
                    );
                    if (ok && ctx.mounted) {
                      Navigator.pop(ctx);
                    } else if (ctx.mounted) {
                      setLocal(() => saving = false);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'Student enrolled successfully!' : 'Enrollment failed: ${ap.error ?? "Unknown error"}'),
                          backgroundColor: ok ? AppColors.emerald : AppColors.rose,
                        ),
                      );
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

  // ──────────────────────────────────────────────────────────────────────────
  // 2. ADD TEACHER SHEET
  // ──────────────────────────────────────────────────────────────────────────
  static void showAddTeacherSheet(BuildContext context, AdminProvider ap) {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'teacher123');
    final phoneCtrl = TextEditingController();

    ClassModel? selectedClass = ap.classes.isNotEmpty ? ap.classes.first : null;
    List<SubjectModel> availableSubjects() => ap.subjects.where((subject) {
          return subject.classes.contains(selectedClass?.name) ||
              subject.classId == selectedClass?.id;
        }).toList();
    SubjectModel? selectedSubject = availableSubjects().isNotEmpty
        ? availableSubjects().first
        : null;
    var saving = false;

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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.tealGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Teacher / Faculty',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Create faculty account with assigned class and subject permissions',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Full Name
                buildSheetInput(
                  ctrl: nameCtrl,
                  label: 'Full Name *',
                  hint: 'e.g. Ms. Priya Sharma',
                  onChanged: (val) {
                    if (usernameCtrl.text.isEmpty && val.isNotEmpty) {
                      final clean = val.trim().toLowerCase().replaceAll(' ', '.').replaceAll('ms.', '').replaceAll('mr.', '');
                      setLocal(() {
                        usernameCtrl.text = clean.startsWith('.') ? clean.substring(1) : clean;
                        if (emailCtrl.text.isEmpty) {
                          emailCtrl.text = '${usernameCtrl.text}@academyalys.com';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: buildSheetInput(
                        ctrl: usernameCtrl,
                        label: 'Username *',
                        hint: 'priya',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildSheetInput(
                        ctrl: passCtrl,
                        label: 'Default Password',
                        hint: 'teacher123',
                        obscure: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                buildSheetInput(
                  ctrl: emailCtrl,
                  label: 'Email Address',
                  hint: 'priya@academyalys.com',
                ),
                const SizedBox(height: 10),

                buildSheetInput(
                  ctrl: phoneCtrl,
                  label: 'Contact Number',
                  hint: '+91 98765 43210',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                // Initial Class & Subject Assignment
                const Text(
                  'Initial Assignment Scope',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Target Class
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Class', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ClassModel>(
                                value: selectedClass,
                                isExpanded: true,
                                dropdownColor: AppColors.cardBg,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                items: ap.classes.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                                onChanged: (c) {
                                  if (c == null) return;
                                  setLocal(() {
                                    selectedClass = c;
                                    final classSubjects = availableSubjects();
                                    selectedSubject = classSubjects.isEmpty
                                        ? null
                                        : classSubjects.first;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Subject
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Subject', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<SubjectModel>(
                                value: selectedSubject,
                                isExpanded: true,
                                dropdownColor: AppColors.cardBg,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                hint: const Text('No subjects for this class'),
                                items: availableSubjects()
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.name),
                                        ))
                                    .toList(),
                                onChanged: (s) => setLocal(() => selectedSubject = s),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                EpGradientButton(
                  label: 'Create Faculty & Assign',
                  gradient: AppColors.tealGradient,
                  loading: saving,
                  onTap: () async {
                    if (saving) return;
                    if (nameCtrl.text.trim().isEmpty || usernameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields (Name, Username)')),
                      );
                      return;
                    }
                    if (saving) return;
                    if (selectedClass == null || selectedSubject == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Select a class and one of its subjects.'),
                        ),
                      );
                      return;
                    }
                    setLocal(() => saving = true);
                    final ok = await ap.createTeacher(
                      username: usernameCtrl.text.trim(),
                      password: passCtrl.text.trim().isNotEmpty ? passCtrl.text.trim() : 'teacher123',
                      fullName: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim().isNotEmpty
                          ? emailCtrl.text.trim()
                          : '${usernameCtrl.text.trim()}@academyalys.com',
                      contactNumber: phoneCtrl.text.trim(),
                      classId: selectedClass!.id,
                      subjectId: selectedSubject!.id,
                    );
                    if (ok && ctx.mounted) {
                      Navigator.pop(ctx);
                    } else if (ctx.mounted) {
                      setLocal(() => saving = false);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'Teacher created and assigned successfully!' : 'Creation failed: ${ap.error ?? "Unknown error"}'),
                          backgroundColor: ok ? AppColors.emerald : AppColors.rose,
                        ),
                      );
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

  // ──────────────────────────────────────────────────────────────────────────
  // 3. ADD CLASS SHEET
  // ──────────────────────────────────────────────────────────────────────────
  static void showAddClassSheet(BuildContext context, AdminProvider ap) {
    final nameCtrl = TextEditingController();
    final gradeCtrl = TextEditingController(text: '10');
    var saving = false;

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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add New Class',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Create a new grade level workspace (e.g. Class 11)',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            buildSheetInput(ctrl: nameCtrl, label: 'Class Name *', hint: 'e.g. Class 11'),
            const SizedBox(height: 10),
            buildSheetInput(ctrl: gradeCtrl, label: 'Grade Level Number', hint: '11', keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            EpGradientButton(
              label: 'Create Class',
              gradient: AppColors.indigoGradient,
              loading: saving,
              onTap: () async {
                if (saving) return;
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a class name.')),
                  );
                  return;
                }
                final gradeLevel = int.tryParse(gradeCtrl.text.trim());
                if (gradeCtrl.text.trim().isNotEmpty && gradeLevel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid grade number.')),
                  );
                  return;
                }
                setLocal(() => saving = true);
                final ok = await ap.createClass(
                  nameCtrl.text.trim(),
                  gradeLevel: gradeLevel,
                );
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                } else if (ctx.mounted) {
                  setLocal(() => saving = false);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Class created successfully!'
                            : 'Failed to create class: ${ap.error ?? "Unknown error"}',
                      ),
                      backgroundColor: ok ? AppColors.emerald : AppColors.rose,
                    ),
                  );
                }
              },
            ),
          ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. ADD SUBJECT SHEET
  // ──────────────────────────────────────────────────────────────────────────
  static void showAddSubjectSheet(BuildContext context, AdminProvider ap) {
    if (ap.classes.isEmpty) {
      ap.fetchClasses();
    }
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    ClassModel? selectedClass = ap.classes.isNotEmpty ? ap.classes.first : null;
    var saving = false;

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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add New Subject',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Text(
                'Add curriculum subject and assign to class',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              buildSheetInput(
                ctrl: nameCtrl,
                label: 'Subject Name *',
                hint: 'e.g. Computer Science',
                onChanged: (val) {
                  if (codeCtrl.text.isEmpty && val.isNotEmpty) {
                    final code = val.trim().replaceAll(' ', '').toUpperCase();
                    setLocal(() {
                      codeCtrl.text = code.length > 4 ? code.substring(0, 4) : code;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              buildSheetInput(ctrl: codeCtrl, label: 'Subject Code *', hint: 'e.g. CS10'),
              const SizedBox(height: 10),
              const Text('Assign to Class', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ClassModel>(
                    value: selectedClass,
                    isExpanded: true,
                    dropdownColor: AppColors.cardBg,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    items: ap.classes.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: (c) => setLocal(() => selectedClass = c),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              EpGradientButton(
                label: 'Create Subject',
                gradient: AppColors.roseGradient,
                loading: saving,
                onTap: () async {
                  if (saving) return;
                  if (nameCtrl.text.trim().isEmpty ||
                      codeCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a subject name and code.'),
                      ),
                    );
                    return;
                  }
                  setLocal(() => saving = true);
                  final ok = await ap.createSubject(
                    name: nameCtrl.text.trim(),
                    code: codeCtrl.text.trim(),
                    classId: selectedClass?.id,
                  );
                  if (ok && ctx.mounted) {
                    Navigator.pop(ctx);
                  } else if (ctx.mounted) {
                    setLocal(() => saving = false);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Subject created successfully!'
                              : 'Failed to create subject: ${ap.error ?? "Unknown error"}',
                        ),
                        backgroundColor: ok ? AppColors.emerald : AppColors.rose,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showAddSectionSheet(
    BuildContext context,
    AdminProvider ap,
    int classId,
  ) {
    final nameCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    var saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Section',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              buildSheetInput(
                ctrl: nameCtrl,
                label: 'Section Name *',
                hint: 'e.g. Section C',
              ),
              const SizedBox(height: 10),
              buildSheetInput(
                ctrl: roomCtrl,
                label: 'Room (optional)',
                hint: 'e.g. Room 103',
              ),
              const SizedBox(height: 20),
              EpGradientButton(
                label: 'Save Section',
                gradient: AppColors.tealGradient,
                loading: saving,
                onTap: () async {
                  if (saving) return;
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a section name.'),
                      ),
                    );
                    return;
                  }
                  setLocal(() => saving = true);
                  final created = await ap.addSectionToClass(
                    classId,
                    nameCtrl.text.trim(),
                    room: roomCtrl.text.trim().isEmpty
                        ? null
                        : roomCtrl.text.trim(),
                  );
                  if (created && sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  } else if (sheetContext.mounted) {
                    setLocal(() => saving = false);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          created
                              ? 'Section added successfully.'
                              : 'Could not add section: ${ap.error ?? "Unknown error"}',
                        ),
                        backgroundColor:
                            created ? AppColors.emerald : AppColors.rose,
                      ),
                    );
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
