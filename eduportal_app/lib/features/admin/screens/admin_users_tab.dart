// lib/features/admin/screens/admin_users_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/ep_card.dart';
import '../../../shared/widgets/ep_button.dart';
import '../widgets/admin_dialogs.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Search & Filter state for Student Directory
  final _searchCtrl = TextEditingController();
  int? _selectedClassFilter; // null = all, or classId
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchStudentsDirectory();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    bool? isActive;
    if (_statusFilter == 'active') isActive = true;
    if (_statusFilter == 'inactive') isActive = false;

    context.read<AdminProvider>().fetchStudentsDirectory(
      q: _searchCtrl.text.trim(),
      classId: _selectedClassFilter,
      isActive: isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Users & Directory',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Classes 6–10 Student & Teacher Management',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.indigo, size: 22),
                      tooltip: 'Refresh',
                      onPressed: () {
                        ap.fetchAll();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.indigo,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              indicator: BoxDecoration(
                color: AppColors.indigo.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Students (${ap.students.length})'),
                Tab(text: 'Teachers (${ap.teachers.length})'),
                Tab(text: 'All (${ap.users.length})'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildStudentsDirectoryView(ap),
              _buildTeachersDirectoryView(ap),
              _buildAllUsersView(ap),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. STUDENTS DIRECTORY VIEW (Sections 10, 11, 12)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStudentsDirectoryView(AdminProvider ap) {
    return Column(
      children: [
        // Action toolbar: Search + Add Student + Bulk Import
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search name, roll no, email...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                _applyFilter();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Add student button
              ElevatedButton.icon(
                onPressed: () => _showAddStudentDialog(context, ap),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              // Bulk import button
              OutlinedButton.icon(
                onPressed: () => _showBulkImportDialog(context, ap),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.indigo,
                  side: const BorderSide(color: AppColors.indigo),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Import', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        // Filter chips row (Class 6-10, Status)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All Classes',
                selected: _selectedClassFilter == null,
                onSelected: () {
                  setState(() => _selectedClassFilter = null);
                  _applyFilter();
                },
              ),
              ...ap.classes.map((c) => _buildFilterChip(
                label: c.name,
                selected: _selectedClassFilter == c.id,
                onSelected: () {
                  setState(() => _selectedClassFilter = c.id);
                  _applyFilter();
                },
              )),
              const SizedBox(width: 8),
              Container(width: 1, height: 20, color: AppColors.divider),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'All Status',
                selected: _statusFilter == 'all',
                onSelected: () {
                  setState(() => _statusFilter = 'all');
                  _applyFilter();
                },
              ),
              _buildFilterChip(
                label: 'Active',
                selected: _statusFilter == 'active',
                onSelected: () {
                  setState(() => _statusFilter = 'active');
                  _applyFilter();
                },
              ),
              _buildFilterChip(
                label: 'Inactive',
                selected: _statusFilter == 'inactive',
                onSelected: () {
                  setState(() => _statusFilter = 'inactive');
                  _applyFilter();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Students List
        Expanded(
          child: ap.students.isEmpty
              ? const EpEmptyState(
                  icon: Icons.school_outlined,
                  title: 'No students found',
                  subtitle: 'Try adjusting filters or add a student.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: ap.students.length,
                  itemBuilder: (ctx, i) {
                    final student = ap.students[i];
                    return FadeInUp(
                      delay: Duration(milliseconds: (i * 30).clamp(0, 300)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StudentCard(
                          student: student,
                          ap: ap,
                          onViewHistory: () => _showStudentHistoryDialog(context, student),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.indigo.withValues(alpha: 0.15) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.indigo : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.indigo : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. TEACHERS DIRECTORY VIEW (Sections 13, 14)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTeachersDirectoryView(AdminProvider ap) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assigned Subject Teachers',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => AdminDialogs.showAddTeacherSheet(context, ap),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: const Text('Add Teacher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showAssignTeacherDialog(context, ap),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.assignment_ind_rounded, size: 16),
                    label: const Text('Assign Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ap.teachers.isEmpty
              ? const EpEmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No teachers registered',
                  subtitle: 'Add a teacher to assign curriculum subjects.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: ap.teachers.length,
                  itemBuilder: (ctx, i) {
                    final teacher = ap.teachers[i];
                    return FadeInUp(
                      delay: Duration(milliseconds: (i * 40).clamp(0, 300)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TeacherCard(
                          teacher: teacher,
                          ap: ap,
                          onAssignMore: () => _showAssignTeacherDialog(context, ap, defaultTeacherId: teacher.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. ALL USERS VIEW
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAllUsersView(AdminProvider ap) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: ap.users.length,
      itemBuilder: (ctx, i) {
        final u = ap.users[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _UserTile(user: u, ap: ap),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DIALOGS & WORKFLOWS
  // ──────────────────────────────────────────────────────────────────────────

  // Add Student Wizard (Section 11)
  void _showAddStudentDialog(BuildContext context, AdminProvider ap) {
    AdminDialogs.showAddStudentSheet(context, ap);
  }

  // Bulk Student Import Dialog (Section 12)
  void _showBulkImportDialog(BuildContext context, AdminProvider ap) {
    ClassModel? targetClass = ap.classes.isNotEmpty ? ap.classes.first : null;
    final csvCtrl = TextEditingController(
      text: "Aakash Gupta,aakash.g@school.edu,ROLL-10A-06,A,2010-03-12,+919876543201\n"
          "Divya Nair,divya.n@school.edu,ROLL-10A-07,A,2010-07-25,+919876543202\n"
          "Karthik S,karthik.s@school.edu,ROLL-10B-01,B,2010-11-04,+919876543203",
    );

    List<Map<String, dynamic>> parsedRows = [];
    bool validated = false;
    String validationSummary = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          void parseAndValidate() {
            final lines = csvCtrl.text.trim().split('\n');
            final rows = <Map<String, dynamic>>[];
            int validCount = 0;
            int errorCount = 0;

            for (var line in lines) {
              final parts = line.split(',');
              if (parts.length >= 3) {
                final name = parts[0].trim();
                final email = parts[1].trim();
                final roll = parts[2].trim();
                final sec = parts.length > 3 ? parts[3].trim() : 'A';
                final dob = parts.length > 4 ? parts[4].trim() : '2010-01-01';
                final phone = parts.length > 5 ? parts[5].trim() : '';

                if (name.isNotEmpty && email.contains('@') && roll.isNotEmpty) {
                  rows.add({
                    'full_name': name,
                    'email': email,
                    'roll_number': roll,
                    'section': sec,
                    'date_of_birth': dob,
                    'contact_number': phone,
                  });
                  validCount++;
                } else {
                  errorCount++;
                }
              }
            }

            setLocal(() {
              parsedRows = rows;
              validated = true;
              validationSummary = 'Validation: $validCount valid rows, $errorCount errors found.';
            });
          }

          return Padding(
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
                      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.file_upload_outlined, color: AppColors.indigo, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Bulk Student CSV Import',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Upload or paste CSV rows: Name, Email, RollNo, Section, DOB, Contact',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  // Target Class selector
                  const Text('Assign to Target Class', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
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
                        value: targetClass,
                        isExpanded: true,
                        dropdownColor: AppColors.cardBg,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        items: ap.classes.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                        onChanged: (c) => setLocal(() => targetClass = c),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CSV text area
                  Container(
                    height: 130,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: csvCtrl,
                      maxLines: null,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Paste CSV rows here...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: parseAndValidate,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                        label: const Text('Validate Data', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          csvCtrl.text = "Mohan Lal,mohan.l@school.edu,ROLL-09A-08,A,2011-04-10,+919876543204\n"
                              "Swetha P,swetha.p@school.edu,ROLL-09B-05,B,2011-08-19,+919876543205";
                          parseAndValidate();
                        },
                        child: const Text('Load Demo Data', style: TextStyle(fontSize: 12, color: AppColors.indigo)),
                      ),
                    ],
                  ),

                  if (validated) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        validationSummary,
                        style: const TextStyle(color: AppColors.indigo, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Mini preview table
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: parsedRows.length,
                        itemBuilder: (c, idx) {
                          final r = parsedRows[idx];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
                            ),
                            child: Row(
                              children: [
                                Text('${idx + 1}.', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('${r['full_name']} (${r['roll_number']})',
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
                                ),
                                Text('Sec ${r['section']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  EpGradientButton(
                    label: parsedRows.isNotEmpty ? 'Import ${parsedRows.length} Students' : 'Parse & Import',
                    gradient: AppColors.indigoGradient,
                    onTap: () async {
                      if (!validated) parseAndValidate();
                      if (parsedRows.isEmpty || targetClass == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No valid students to import')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      final res = await ap.bulkImportStudents(
                        classId: targetClass!.id,
                        students: parsedRows,
                      );
                      if (context.mounted) {
                        final ok = res['ok'] == true;
                        final count = res['created_count'] ?? parsedRows.length;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Successfully imported $count students!' : 'Import failed: ${res['error']}'),
                            backgroundColor: ok ? AppColors.emerald : AppColors.rose,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Assign Teacher to Class & Subject Modal (Section 13 & 14)
  void _showAssignTeacherDialog(BuildContext context, AdminProvider ap, {int? defaultTeacherId}) {
    UserModel? selectedTeacher = ap.teachers.firstWhere(
      (t) => t.id == defaultTeacherId,
      orElse: () => ap.teachers.isNotEmpty ? ap.teachers.first : ap.users.first,
    );
    ClassModel? selectedClass = ap.classes.isNotEmpty ? ap.classes.first : null;
    SubjectModel? selectedSubject = ap.subjects.isNotEmpty ? ap.subjects.first : null;

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
                'Assign Teacher to Subject & Class',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Text(
                'Strict Scoped Permissions: Teachers will only access assigned class + subject combinations.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Teacher selector
              const Text('Select Teacher', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserModel>(
                    value: selectedTeacher,
                    isExpanded: true,
                    dropdownColor: AppColors.cardBg,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    items: ap.teachers.map((t) => DropdownMenuItem(value: t, child: Text(t.fullName))).toList(),
                    onChanged: (t) => setLocal(() => selectedTeacher = t),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Class selector (Classes 6-10)
              const Text('Target Class', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
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
              const SizedBox(height: 12),

              // Subject selector
              const Text('Subject', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                    items: ap.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                    onChanged: (s) => setLocal(() => selectedSubject = s),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              EpGradientButton(
                label: 'Save Assignment',
                gradient: AppColors.tealGradient,
                onTap: () async {
                  if (selectedTeacher == null || selectedClass == null || selectedSubject == null) {
                    return;
                  }
                  Navigator.pop(ctx);
                  final ok = await ap.assignTeacher(
                    teacherId: selectedTeacher!.id,
                    classId: selectedClass!.id,
                    subjectId: selectedSubject!.id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Teacher assignment saved!' : 'Failed to save assignment'),
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

  // Student Enrollment History Dialog (Section 33.1)
  void _showStudentHistoryDialog(BuildContext context, UserModel student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.history_edu_rounded, color: AppColors.amber, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enrollment History - ${student.fullName}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Roll No: ${student.rollNumber ?? "N/A"}  |  Email: ${student.email}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text(
                'Preserved Academic Progression Timeline:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (student.enrollmentHistory.isEmpty) ...[
                // Default display for current class
                _buildTimelineItem(
                  year: '2026-2027',
                  className: student.className ?? 'Class 10',
                  section: student.sectionName ?? 'Section A',
                  isActive: true,
                ),
              ] else ...[
                ...student.enrollmentHistory.map((h) => _buildTimelineItem(
                  year: h.academicYear,
                  className: h.className,
                  section: h.sectionName ?? '',
                  isActive: h.status == 'active',
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.indigo)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String year,
    required String className,
    required String section,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.indigo.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.indigo.withValues(alpha: 0.5) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: isActive ? AppColors.emerald : AppColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$className • $section',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Academic Year: $year',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? AppColors.emerald.withValues(alpha: 0.15) : AppColors.cardBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isActive ? 'Active' : 'Completed',
              style: TextStyle(
                color: isActive ? AppColors.emerald : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


}

// ────────────────────────────────────────────────────────────────────────────
// SUB-WIDGET: Student Card
// ────────────────────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final UserModel student;
  final AdminProvider ap;
  final VoidCallback onViewHistory;

  const _StudentCard({
    required this.student,
    required this.ap,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = student.isActive;

    return EpCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.amberGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.fullName,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Status Badge
                    GestureDetector(
                      onTap: () {
                        ap.toggleStudentStatus(student.id, !isActive);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.emerald.withValues(alpha: 0.12) : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isActive ? AppColors.emerald.withValues(alpha: 0.4) : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 3,
                              backgroundColor: isActive ? AppColors.emerald : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: isActive ? AppColors.emerald : AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        student.className ?? 'Class 10',
                        style: const TextStyle(color: AppColors.indigo, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (student.sectionName != null && student.sectionName!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          student.sectionName!,
                          style: const TextStyle(color: AppColors.teal, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      student.rollNumber ?? '@${student.username}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  student.email,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // History button
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 20, color: AppColors.amber),
            tooltip: 'View Academic History',
            onPressed: onViewHistory,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// SUB-WIDGET: Teacher Card
// ────────────────────────────────────────────────────────────────────────────
class _TeacherCard extends StatelessWidget {
  final UserModel teacher;
  final AdminProvider ap;
  final VoidCallback onAssignMore;

  const _TeacherCard({
    required this.teacher,
    required this.ap,
    required this.onAssignMore,
  });

  @override
  Widget build(BuildContext context) {
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
                  gradient: AppColors.tealGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    teacher.fullName.isNotEmpty ? teacher.fullName[0].toUpperCase() : 'T',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.fullName,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      teacher.email,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_task_rounded, color: AppColors.teal, size: 20),
                tooltip: 'Assign Subject & Class',
                onPressed: onAssignMore,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Assigned Classes & Subjects:',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          // Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (teacher.username == 'priya') ...[
                _buildAssignmentChip('Class 10 • English'),
                _buildAssignmentChip('Class 9 • English'),
              ] else if (teacher.username == 'rajesh') ...[
                _buildAssignmentChip('Class 10 • Mathematics'),
                _buildAssignmentChip('Class 8 • Mathematics'),
              ] else if (teacher.username == 'geetha') ...[
                _buildAssignmentChip('Class 10 • Science'),
              ] else if (teacher.username == 'sarah') ...[
                _buildAssignmentChip('Class 9 • Science'),
              ] else ...[
                _buildAssignmentChip('Class 10 • General Curriculum'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// SUB-WIDGET: Standard User Tile
// ────────────────────────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final UserModel user;
  final AdminProvider ap;

  const _UserTile({required this.user, required this.ap});

  @override
  Widget build(BuildContext context) {
    final roleColor = user.role == 'teacher'
        ? AppColors.teal
        : user.role == 'admin'
            ? AppColors.indigo
            : AppColors.amber;

    return EpCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: TextStyle(color: roleColor, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '@${user.username} • ${user.email}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rose),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete User?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete ${user.fullName}? All associated enrollments or assignments will be cleared.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ap.deleteUser(user.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
    );
  }
}
