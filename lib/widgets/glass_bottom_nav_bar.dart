import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/haptics.dart';

/// Floating iOS-style liquid-glass bottom navigation.
class GlassBottomNavBar extends StatelessWidget {
  const GlassBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  /// Space list bottoms / FABs need so they clear this bar.
  static double contentClearance(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return barHeight + bottomPadding + bottomInset + 8;
  }

  static const double barHeight = 64;
  static const double itemWidth = 100;
  static const double bottomPadding = 12;
  static const double horizontalMargin = 12;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<GlassNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final glassFill = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.62);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.85);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.55);

    // heightFactor keeps this from expanding to the full Scaffold height
    // (a plain Center would, and parks the bar mid-screen).
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding + 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor, width: 0.8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        highlight,
                        glassFill,
                        glassFill.withValues(alpha: glassFill.a * 0.85),
                      ],
                    ),
                  ),
                  child: SizedBox(
                    height: barHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          SizedBox(
                            width: itemWidth,
                            height: barHeight,
                            child: _GlassNavItem(
                              destination: destinations[i],
                              selected: i == selectedIndex,
                              onTap: () {
                                if (i == selectedIndex) return;
                                AppHaptics.selection();
                                onDestinationSelected(i);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final color = selected ? primary : muted;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.28 : 0.16,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: color,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
