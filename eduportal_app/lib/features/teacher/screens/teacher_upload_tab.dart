// lib/features/teacher/screens/teacher_upload_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/teacher_provider.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/ep_card.dart';
import '../../../shared/widgets/ep_button.dart';

class TeacherUploadTab extends StatefulWidget {
  const TeacherUploadTab({super.key});

  @override
  State<TeacherUploadTab> createState() => _TeacherUploadTabState();
}

class _TeacherUploadTabState extends State<TeacherUploadTab> {
  SubjectModel? _selectedSubject;
  LessonModel? _selectedLesson;
  String _selectedType = 'video'; // video, pdf, ppt, notes, link
  String _publicationStatus = 'published'; // published, draft

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '24:15');
  final _urlCtrl = TextEditingController(text: 'https://www.youtube.com/watch?v=demo123');
  final _notesContentCtrl = TextEditingController();

  File? _selectedFile;
  String _fileName = '';

  static const List<_UploadTypeOption> _types = [
    _UploadTypeOption('video', 'Video Lecture', Icons.videocam_rounded, AppColors.indigo),
    _UploadTypeOption('pdf', 'PDF Notes', Icons.picture_as_pdf_rounded, AppColors.rose),
    _UploadTypeOption('ppt', 'PPT Deck', Icons.slideshow_rounded, AppColors.amber),
    _UploadTypeOption('notes', 'Study Notes', Icons.menu_book_rounded, AppColors.teal),
    _UploadTypeOption('link', 'Web Link', Icons.link_rounded, AppColors.emerald),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = context.read<TeacherProvider>();
      tp.fetchSubjects().then((_) {
        if (tp.subjects.isNotEmpty) {
          setState(() => _selectedSubject = tp.subjects.first);
          tp.fetchLessons(_selectedSubject!.id).then((_) {
            if (tp.lessons.isNotEmpty) {
              setState(() => _selectedLesson = tp.lessons.first);
              tp.fetchMaterials(_selectedLesson!.id);
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _urlCtrl.dispose();
    _notesContentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    List<String> ext = [];
    switch (_selectedType) {
      case 'video':
        ext = ['mp4', 'mkv', 'mov'];
        break;
      case 'pdf':
        ext = ['pdf'];
        break;
      case 'ppt':
        ext = ['ppt', 'pptx'];
        break;
      default:
        ext = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'];
    }

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ext,
      );
      if (files.isNotEmpty && files.single.path != null) {
        setState(() {
          _selectedFile = File(files.single.path!);
          _fileName = files.single.name;
          if (_titleCtrl.text.isEmpty) {
            _titleCtrl.text = files.single.name.replaceAll(RegExp(r'\.[^.]+$'), '');
          }
        });
      }
    } catch (e) {
      _showSnack('File picker not supported on this platform: $e', AppColors.amber);
    }
  }

  Future<void> _submitUpload() async {
    final tp = context.read<TeacherProvider>();
    if (_selectedSubject == null || _selectedLesson == null) {
      _showSnack('Please select subject and lesson', AppColors.amber);
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a title for the material', AppColors.amber);
      return;
    }

    String? externalUrl;
    if (_selectedType == 'video') {
      externalUrl = _urlCtrl.text.trim().isNotEmpty ? _urlCtrl.text.trim() : null;
    } else if (_selectedType == 'link') {
      externalUrl = _urlCtrl.text.trim();
    }

    final ok = await tp.uploadMaterial(
      lessonId: _selectedLesson!.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : (_selectedType == 'notes' ? _notesContentCtrl.text.trim() : ''),
      materialType: _selectedType,
      publicationStatus: _publicationStatus,
      duration: _selectedType == 'video' ? _durationCtrl.text.trim() : null,
      externalUrl: externalUrl,
      file: _selectedFile,
    );

    if (mounted) {
      _showSnack(
        ok ? 'Material saved & published successfully!' : 'Upload failed: ${tp.error ?? ""}',
        ok ? AppColors.emerald : AppColors.rose,
      );
      if (ok) {
        setState(() {
          _selectedFile = null;
          _fileName = '';
          _titleCtrl.clear();
          _descCtrl.clear();
          _notesContentCtrl.clear();
        });
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TeacherProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FadeInDown(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload & Publish',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Classes 6–10 Content Studio • Section 17 LMS Standard',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: AppColors.teal, size: 14),
                          SizedBox(width: 4),
                          Text('Authorized', style: TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Step 1 & 2: Subject & Lesson Selection (Scoped)
              FadeInUp(
                delay: const Duration(milliseconds: 50),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Scope (Class & Subject)',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Subject Dropdown
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<SubjectModel>(
                                  value: _selectedSubject,
                                  isExpanded: true,
                                  dropdownColor: AppColors.cardBg,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                  hint: const Text('Select Subject', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  items: tp.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                                  onChanged: (s) {
                                    if (s == null) return;
                                    setState(() {
                                      _selectedSubject = s;
                                      _selectedLesson = null;
                                    });
                                    tp.fetchLessons(s.id).then((_) {
                                      if (tp.lessons.isNotEmpty) {
                                        setState(() => _selectedLesson = tp.lessons.first);
                                        tp.fetchMaterials(_selectedLesson!.id);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Lesson Dropdown
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<LessonModel>(
                                  value: _selectedLesson,
                                  isExpanded: true,
                                  dropdownColor: AppColors.cardBg,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                  hint: const Text('Select Lesson', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  items: tp.lessons.map((l) => DropdownMenuItem(value: l, child: Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (l) {
                                    if (l == null) return;
                                    setState(() => _selectedLesson = l);
                                    tp.fetchMaterials(l.id);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Step 3: Material Type Selector
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Material Type',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _types.map((t) {
                          final isSel = _selectedType == t.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedType = t.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? t.color.withValues(alpha: 0.18) : AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel ? t.color : AppColors.divider,
                                    width: isSel ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(t.icon, color: isSel ? t.color : AppColors.textMuted, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      t.label,
                                      style: TextStyle(
                                        color: isSel ? t.color : AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Step 4: Material Details Card
              FadeInUp(
                delay: const Duration(milliseconds: 150),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      _buildInputLabel('Material Title'),
                      _buildTextField(
                        ctrl: _titleCtrl,
                        hint: _selectedType == 'video'
                            ? 'e.g. Chapter 1: Video Lecture - Line-by-Line Explanation'
                            : 'e.g. NCERT Solutions & Summary Notes',
                      ),
                      const SizedBox(height: 14),

                      // Description
                      _buildInputLabel('Description & Overview'),
                      _buildTextField(
                        ctrl: _descCtrl,
                        hint: 'Detailed notes, key takeaway summaries, or study directives...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),

                      // Dedicated Video fields
                      if (_selectedType == 'video') ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputLabel('Video Link or Embed URL'),
                                  _buildTextField(
                                    ctrl: _urlCtrl,
                                    hint: 'https://youtube.com/... or MP4 link',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputLabel('Duration'),
                                  _buildTextField(
                                    ctrl: _durationCtrl,
                                    hint: '24:15',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Document / File upload button
                      if (_selectedType == 'pdf' || _selectedType == 'ppt' || _selectedType == 'video') ...[
                        _buildInputLabel('Attach File (${_selectedType.toUpperCase()})'),
                        GestureDetector(
                          onTap: _pickFile,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedFile != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                                  color: _selectedFile != null ? AppColors.emerald : AppColors.indigo,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _fileName.isNotEmpty ? _fileName : 'Choose file from device...',
                                    style: TextStyle(
                                      color: _fileName.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.attach_file_rounded, color: AppColors.textMuted, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Publication Status Toggle
                      _buildInputLabel('Publication Status (Access Control)'),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _publicationStatus = 'published'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _publicationStatus == 'published'
                                      ? AppColors.emerald.withValues(alpha: 0.15)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _publicationStatus == 'published' ? AppColors.emerald : AppColors.divider,
                                    width: _publicationStatus == 'published' ? 1.5 : 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.public_rounded, color: AppColors.emerald, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Published (Live for Students)',
                                        style: TextStyle(color: AppColors.emerald, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _publicationStatus = 'draft'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _publicationStatus == 'draft'
                                      ? AppColors.amber.withValues(alpha: 0.15)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _publicationStatus == 'draft' ? AppColors.amber : AppColors.divider,
                                    width: _publicationStatus == 'draft' ? 1.5 : 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_outline_rounded, color: AppColors.amber, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Draft (Private to Teacher)',
                                        style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      EpGradientButton(
                        label: 'Upload & Save Material',
                        gradient: AppColors.tealGradient,
                        loading: tp.loading,
                        onTap: _submitUpload,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Section 2: "My Uploaded Materials" for this lesson
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Materials in ${_selectedLesson?.title ?? "Lesson"} (${tp.materials.length})',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (_selectedLesson != null)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.teal, size: 20),
                        onPressed: () => tp.fetchMaterials(_selectedLesson!.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (tp.materials.isEmpty)
                const EpEmptyState(
                  icon: Icons.folder_open_rounded,
                  title: 'No materials in this lesson yet',
                  subtitle: 'Use the form above to publish videos, PDFs, or presentations.',
                )
              else
                ...tp.materials.map((m) => _buildMaterialItem(m, tp)),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialItem(MaterialModel m, TeacherProvider tp) {
    final isPublished = m.publicationStatus.toLowerCase() == 'published';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _getColorForType(m.materialType).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getIconForType(m.materialType), color: _getColorForType(m.materialType), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      m.materialType.toUpperCase(),
                      style: TextStyle(color: _getColorForType(m.materialType), fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    if (m.duration != null && m.duration!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('• ${m.duration}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Publication status badge / toggle button
          GestureDetector(
            onTap: () {
              if (_selectedLesson == null) return;
              final newStatus = isPublished ? 'draft' : 'published';
              tp.setMaterialPublicationStatus(m.id, newStatus, _selectedLesson!.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPublished ? AppColors.emerald.withValues(alpha: 0.15) : AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isPublished ? AppColors.emerald : AppColors.amber, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3, backgroundColor: isPublished ? AppColors.emerald : AppColors.amber),
                  const SizedBox(width: 4),
                  Text(
                    isPublished ? 'Live' : 'Draft',
                    style: TextStyle(color: isPublished ? AppColors.emerald : AppColors.amber, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rose),
            onPressed: () {
              if (_selectedLesson != null) {
                tp.deleteMaterial(m.id, _selectedLesson!.id);
              }
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.videocam_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'ppt':
        return Icons.slideshow_rounded;
      case 'notes':
        return Icons.menu_book_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return AppColors.indigo;
      case 'pdf':
        return AppColors.rose;
      case 'ppt':
        return AppColors.amber;
      case 'notes':
        return AppColors.teal;
      default:
        return AppColors.emerald;
    }
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController ctrl,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _UploadTypeOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const _UploadTypeOption(this.id, this.label, this.icon, this.color);
}
