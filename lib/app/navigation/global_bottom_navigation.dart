import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A floating, glass-panel bottom navigation bar with a morphing gradient
/// pill that slides beneath the active destination, plus a slim accent
/// hairline that tracks it from above. Built to feel like a single
/// continuous piece of UI rather than five static buttons.
class GlobalBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const GlobalBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  static const _items = <_NavItem>[
    _NavItem(
      icon: Icons.home_rounded,
      label: 'Home',
      accent: Color(0xFF6C63FF),
    ),
    _NavItem(
      icon: Icons.calendar_month_rounded,
      label: 'Timetable',
      accent: Color(0xFF00B8A9),
    ),
    _NavItem(
      icon: Icons.query_stats_rounded,
      label: 'Marks',
      accent: Color(0xFFFF9F43),
    ),
    _NavItem(
      icon: Icons.fact_check_rounded,
      label: 'Attendance',
      accent: Color(0xFFEE5A6F),
    ),
    _NavItem(
      icon: Icons.auto_awesome_mosaic_rounded,
      label: 'More',
      accent: Color(0xFF7367F0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final activeAccent = _items[currentIndex].accent;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            height: 74,
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white)
                  .withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: activeAccent.withValues(alpha: 0.18),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _items.length;

                return Stack(
                  children: [
                    // Accent hairline that tracks the active destination.
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * currentIndex + itemWidth * 0.28,
                      top: 0,
                      width: itemWidth * 0.44,
                      height: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: activeAccent,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    // Morphing gradient pill behind the active icon.
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutBack,
                      left: itemWidth * currentIndex,
                      top: 10,
                      bottom: 10,
                      width: itemWidth,
                      child: Center(
                        child: TweenAnimationBuilder<Color?>(
                          tween: ColorTween(begin: activeAccent, end: activeAccent),
                          duration: const Duration(milliseconds: 420),
                          builder: (context, color, _) => Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  activeAccent,
                                  activeAccent.withValues(alpha: 0.62),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: activeAccent.withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Row(
                      children: List.generate(_items.length, (index) {
                        final item = _items[index];
                        final selected = index == currentIndex;
                        return Expanded(
                          child: _NavButton(
                            item: item,
                            selected: selected,
                            onTap: () {
                              if (!selected) {
                                HapticFeedback.selectionClick();
                                onDestinationSelected(index);
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: item.accent.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              scale: selected ? 1.06 : 1.0,
              child: Icon(
                item.icon,
                size: 23,
                color: selected
                    ? Colors.white
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
              ),
            ),
        //   const SizedBox(height: 5),
          //   AnimatedOpacity(
          //     duration: const Duration(milliseconds: 240),
          //     opacity: selected ? 1 : 0,
          //     child:
              
          //      Text(
          //       item.label,
          //       maxLines: 1,
          //       overflow: TextOverflow.clip,
          //       style: theme.textTheme.labelSmall?.copyWith(
          //         fontWeight: FontWeight.w800,
          //         fontSize: 10.5,
          //         letterSpacing: 0.2,
          //         color: item.accent,
          //       ),
          //     ),
          //   ),
         ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color accent;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.accent,
  });
}