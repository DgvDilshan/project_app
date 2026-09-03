import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/picked_image.dart';
import '../services/leaf_diagnosis_service.dart';
import 'diagnosis_result_screen.dart';
import '../main.dart';
import '../localization/app_translations.dart';

enum ScanSource { camera, gallery }

extension ScanSourceUi on ScanSource {
  String get label => switch (this) {
    ScanSource.camera => 'Camera',
    ScanSource.gallery => 'Gallery',
  };
}

class ScanReviewScreen extends StatefulWidget {
  const ScanReviewScreen({super.key, required this.source});

  final ScanSource source;

  @override
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  final ImagePicker _picker = ImagePicker();
  final LeafDiagnosisService _diagnosisService = RealLeafDiagnosisService();

  PickedImage? _picked;
  bool _isAnalyzing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pick();
    });
  }

  Future<void> _pick() async {
    setState(() {
      _error = null;
      _picked = null;
    });

    try {
      final XFile? xfile = await _picker.pickImage(
        source: widget.source == ScanSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 90,
      );

      if (!mounted) return;

      if (xfile == null) {
        Navigator.of(context).maybePop();
        return;
      }

      final Uint8List bytes = await xfile.readAsBytes();
      if (!mounted) return;

      setState(() {
        _picked = PickedImage(
          bytes: bytes,
          sourceLabel: widget.source.label,
          fileName: xfile.name,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Unable to access ${widget.source.label.toLowerCase()}. Please try again.';
      });
    }
  }

  Future<void> _analyze() async {
    final picked = _picked;
    if (picked == null) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final result = await _diagnosisService.diagnose(picked);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              DiagnosisResultScreen(pickedImage: picked, result: result),
        ),
      );
    } on NotTeaLeafException catch (e) {
      if (!mounted) return;
      bool isSinhala = isSinhalaMode.value;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isSinhala ? 'අවවාදයයි' : 'Warning'),
          content: Text(isSinhala ? AppTranslations.get('not_tea_leaf_desc', true) : e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isSinhala ? 'හරි' : 'OK'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppTranslations.get('processing_error', isSinhalaMode.value);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isSinhala = isSinhalaMode.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.get('review_title', isSinhala)),
        actions: [
          IconButton(
            tooltip: 'Pick again',
            onPressed: _isAnalyzing ? null : _pick,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: _picked == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _error == null
                                ? const CircularProgressIndicator()
                                : Text(
                                    _error!,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.memory(
                                _picked!.bytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _picked!.fileName == null
                                    ? (isSinhala ? 'තෝරාගත් ඡායාරූපය' : 'Selected image')
                                    : (isSinhala ? 'තෝරාගත්තා: ${_picked!.fileName}' : 'Selected: ${_picked!.fileName}'),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_picked == null || _isAnalyzing)
                      ? null
                      : _analyze,
                  child: _isAnalyzing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(AppTranslations.get('proceed_button', isSinhala)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
