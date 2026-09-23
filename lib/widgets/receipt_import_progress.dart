import 'dart:io';

import 'package:flutter/material.dart';

enum ReceiptImportStep {
  scanning,
  reading,
  understanding,
  finishing,
}

extension ReceiptImportStepX on ReceiptImportStep {
  String get title => switch (this) {
        ReceiptImportStep.scanning => 'Capture receipt',
        ReceiptImportStep.reading => 'Reading text',
        ReceiptImportStep.understanding => 'Understanding details',
        ReceiptImportStep.finishing => 'Preparing form',
      };

  String get subtitle => switch (this) {
        ReceiptImportStep.scanning => 'Open the scanner and snap a clear photo',
        ReceiptImportStep.reading => 'Pulling text from the image on your device',
        ReceiptImportStep.understanding => 'Gemini is filling name, total, category…',
        ReceiptImportStep.finishing => 'Opening Add item with your draft',
      };

  IconData get icon => switch (this) {
        ReceiptImportStep.scanning => Icons.document_scanner_outlined,
        ReceiptImportStep.reading => Icons.text_snippet_outlined,
        ReceiptImportStep.understanding => Icons.auto_awesome,
        ReceiptImportStep.finishing => Icons.check_circle_outline,
      };
}

/// Mutable progress state for [ReceiptImportProgressDialog].
class ReceiptImportProgressController extends ChangeNotifier {
  ReceiptImportStep _step = ReceiptImportStep.scanning;
  String? _imagePath;

  ReceiptImportStep get step => _step;
  String? get imagePath => _imagePath;

  void setStep(ReceiptImportStep step) {
    if (_step == step) return;
    _step = step;
    notifyListeners();
  }

  void setImagePath(String path) {
    _imagePath = path;
    notifyListeners();
  }
}

/// Full-screen-ish modal with thumbnail + stepped checklist.
class ReceiptImportProgressDialog extends StatelessWidget {
  const ReceiptImportProgressDialog({
    super.key,
    required this.controller,
  });

  final ReceiptImportProgressController controller;

  static Future<ReceiptImportProgressController> show(BuildContext context) {
    final controller = ReceiptImportProgressController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => PopScope(
        canPop: false,
        child: ReceiptImportProgressDialog(controller: controller),
      ),
    );
    return Future.value(controller);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final step = controller.step;
                  final imagePath = controller.imagePath;
                  final stepIndex = ReceiptImportStep.values.indexOf(step);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                step.icon,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Importing receipt',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: Text(
                                      step.subtitle,
                                      key: ValueKey(step),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          height: imagePath == null ? 0 : 140,
                          child: imagePath == null
                              ? const SizedBox.shrink()
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        File(imagePath),
                                        fit: BoxFit.cover,
                                      ),
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withValues(alpha: 0.05),
                                              Colors.black.withValues(alpha: 0.35),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Positioned(
                                        left: 12,
                                        bottom: 10,
                                        child: _ScanningBadge(),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        if (imagePath != null) const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (stepIndex + 1) / ReceiptImportStep.values.length,
                            minHeight: 6,
                            backgroundColor: scheme.primary.withValues(alpha: 0.12),
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        for (final s in ReceiptImportStep.values)
                          _StepRow(
                            step: s,
                            status: _statusFor(s, step),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  _StepStatus _statusFor(ReceiptImportStep row, ReceiptImportStep current) {
    final rowIndex = ReceiptImportStep.values.indexOf(row);
    final currentIndex = ReceiptImportStep.values.indexOf(current);
    if (rowIndex < currentIndex) return _StepStatus.done;
    if (rowIndex == currentIndex) return _StepStatus.active;
    return _StepStatus.pending;
  }
}

enum _StepStatus { pending, active, done }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.status});

  final ReceiptImportStep step;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color iconColor;
    final Widget leading;
    switch (status) {
      case _StepStatus.done:
        iconColor = scheme.primary;
        leading = Icon(Icons.check_circle, color: iconColor, size: 22);
      case _StepStatus.active:
        iconColor = scheme.primary;
        leading = SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: iconColor,
          ),
        );
      case _StepStatus.pending:
        iconColor = scheme.onSurface.withValues(alpha: 0.28);
        leading = Icon(Icons.radio_button_unchecked, color: iconColor, size: 22);
    }

    final titleColor = status == _StepStatus.pending
        ? scheme.onSurface.withValues(alpha: 0.4)
        : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: titleColor,
                fontWeight:
                    status == _StepStatus.active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Icon(
            step.icon,
            size: 18,
            color: iconColor.withValues(alpha: status == _StepStatus.pending ? 0.5 : 1),
          ),
        ],
      ),
    );
  }
}

class _ScanningBadge extends StatefulWidget {
  const _ScanningBadge();

  @override
  State<_ScanningBadge> createState() => _ScanningBadgeState();
}

class _ScanningBadgeState extends State<_ScanningBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Working…',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
