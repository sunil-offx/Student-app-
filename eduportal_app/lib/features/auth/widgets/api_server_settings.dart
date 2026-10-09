import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class ApiServerSettings {
  static Future<void> show(BuildContext context) async {
    final api = ApiService();
    final controller = TextEditingController(
      text: api.configuredBaseUrl?.replaceFirst(RegExp(r'/api$'), '') ?? '',
    );
    var saving = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Connect live backend',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste your deployed FastAPI service URL. The app will verify its health endpoint before saving.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'HTTPS backend URL',
                  hintText: 'https://your-service.onrender.com',
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: AppColors.rose),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() {
                        saving = true;
                        errorMessage = null;
                      });
                      try {
                        await api.configureBaseUrl(controller.text);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Live backend connected.'),
                            ),
                          );
                        }
                      } catch (error) {
                        setDialogState(() {
                          errorMessage = error
                              .toString()
                              .replaceFirst('Bad state: ', '')
                              .replaceFirst('FormatException: ', '');
                          saving = false;
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test and save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}
