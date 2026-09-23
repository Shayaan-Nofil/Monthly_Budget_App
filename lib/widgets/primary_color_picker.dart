import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/haptics.dart';

/// HSV + preset swatches for choosing the app primary color.
class PrimaryColorPicker extends StatefulWidget {
  const PrimaryColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
  });

  final Color color;
  final ValueChanged<Color> onChanged;

  static const presets = <Color>[
    AppTheme.defaultPrimary,
    Color(0xFF1B7A4A),
    Color(0xFF30D158),
    Color(0xFF0A84FF),
    Color(0xFF5E5CE6),
    Color(0xFFBF5AF2),
    Color(0xFFFF9F0A),
    Color(0xFFFF453A),
    Color(0xFF64D2FF),
    Color(0xFFFF375F),
    Color(0xFFAC8E68),
    Color(0xFF8E8E93),
  ];

  @override
  State<PrimaryColorPicker> createState() => _PrimaryColorPickerState();
}

class _PrimaryColorPickerState extends State<PrimaryColorPicker> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.color);
  }

  @override
  void didUpdateWidget(covariant PrimaryColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _hsv = HSVColor.fromColor(widget.color);
    }
  }

  void _emit(HSVColor hsv) {
    setState(() => _hsv = hsv);
    widget.onChanged(hsv.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _hsv.toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: current,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: current.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppConstants.colorToHex(current),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Presets', style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final preset in PrimaryColorPicker.presets)
              _Swatch(
                color: preset,
                selected: _approxEqual(preset, current),
                onTap: () {
                  AppHaptics.selection();
                  _emit(HSVColor.fromColor(preset));
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Hue', style: theme.textTheme.titleSmall),
        Slider(
          value: _hsv.hue,
          max: 360,
          onChanged: (value) {
            _emit(_hsv.withHue(value));
          },
          onChangeEnd: (_) => AppHaptics.selection(),
        ),
        Text('Saturation', style: theme.textTheme.titleSmall),
        Slider(
          value: _hsv.saturation,
          onChanged: (value) {
            _emit(_hsv.withSaturation(value));
          },
          onChangeEnd: (_) => AppHaptics.selection(),
        ),
        Text('Brightness', style: theme.textTheme.titleSmall),
        Slider(
          value: _hsv.value,
          onChanged: (value) {
            _emit(_hsv.withValue(value.clamp(0.15, 1.0)));
          },
          onChangeEnd: (_) => AppHaptics.selection(),
        ),
      ],
    );
  }

  bool _approxEqual(Color a, Color b) {
    return (a.r - b.r).abs() < 0.02 &&
        (a.g - b.g).abs() < 0.02 &&
        (a.b - b.b).abs() < 0.02;
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: selected ? 6 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.onSurface
              : Colors.transparent,
          width: 2.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(width: 40, height: 40),
      ),
    );
  }
}
