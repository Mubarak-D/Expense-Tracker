import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/add_expense_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/login_screen.dart';
import 'screens/transactions_screen.dart';
import 'widgets/premium_loader.dart';

void main() {
  runApp(const ProviderScope(child: EtmlApp()));
}

class EtmlApp extends ConsumerWidget {
  const EtmlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'ETML',
      debugShowCheckedModeBanner: false,
      theme: EtmlTheme.dark,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 520),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: auth.when(
          data: (state) => state.isAuthenticated
              ? MainShell(
                  key: const ValueKey('main-shell'),
                  initialIndex: state.landingIndex,
                )
              : const LoginScreen(key: ValueKey('login-screen')),
          loading: () => const _BootScreen(key: ValueKey('boot-screen')),
          error: (_, __) => const LoginScreen(key: ValueKey('login-error')),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      InsightsScreen(),
      AddExpenseScreen(),
      TransactionsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.04, 0.02),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      bottomNavigationBar: _GlassNavBar(
        index: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Container(
        height: 68,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: EtmlColors.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66020A1C),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.insights_rounded,
              label: 'Insights',
              selected: index == 0,
              onTap: () => onChanged(0),
            ),
            _NavItem(
              icon: Icons.add_rounded,
              label: 'Add',
              selected: index == 1,
              onTap: () => onChanged(1),
            ),
            _NavItem(
              icon: Icons.receipt_long_rounded,
              label: 'Ledger',
              selected: index == 2,
              onTap: () => onChanged(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: selected ? EtmlColors.primaryGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21, color: Colors.white),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: PremiumLoader(size: 46),
      ),
    );
  }
}
