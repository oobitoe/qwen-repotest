import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/cash_entity.dart';
import '../data/cash_repository.dart';

/// Halaman sesi kasir: buka/tutup sesi dan lihat riwayat.
class CashPage extends ConsumerStatefulWidget {
  const CashPage({super.key});

  @override
  ConsumerState<CashPage> createState() => _CashPageState();
}

class _CashPageState extends ConsumerState<CashPage> {
  final _balanceCtrl = TextEditingController();
  String? _registerId;

  @override
  void dispose() {
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sessions = ref.watch(cashSessionsProvider);
    final registers = ref.watch(cashRegistersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cashRegister)),
      body: Column(
        children: [
          // Aktif session card
          sessions.when(
            data: (items) {
              final open = items.where((s) => s.status == 'open').firstOrNull;
              if (open == null) {
                return _OpenSessionCard(
                  l10n: l10n,
                  registers: registers.when(
                    data: (r) => r,
                    loading: () => const [],
                    error: (e, st) => const [],
                  ),
                  registerId: _registerId,
                  balanceCtrl: _balanceCtrl,
                  onRegisterChanged: (v) => setState(() => _registerId = v),
                  onOpen: () => _openSession(context),
                );
              }
              return _ActiveSessionCard(
                session: open,
                l10n: l10n,
                onClose: () => _closeSession(context, open.id),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('$e')),
          ),
          const Divider(height: 1),
          // Riwayat sesi
          Expanded(
            child: sessions.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(l10n.noData,
                        style: theme.textTheme.bodyMedium),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final s = items[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(s.id.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(s.registerName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${s.openedBy}  ·  ${s.status}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Text(
                        _idr(s.openingBalance),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  String _idr(double v) {
    final nf = NumberFormat.simpleCurrency(
        locale: 'id_ID', name: 'Rp ', decimalDigits: 0);
    return nf.format(v);
  }

  Future<void> _openSession(BuildContext context) async {
    if (_registerId == null || _balanceCtrl.text.isEmpty) return;
    final repo = ref.read(cashRepositoryProvider);
    await repo.openSession(
      registerId: _registerId!,
      registerName: _registerId!,
      openingBalance: double.tryParse(_balanceCtrl.text) ?? 0,
      openedBy: 'kasir',
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _closeSession(BuildContext context, String sessionId) async {
    await showDialog(
      context: context,
      builder: (_) => _CloseDialog(sessionId: sessionId),
    );
    ref.invalidate(cashSessionsProvider);
  }
}

class _OpenSessionCard extends StatelessWidget {
  const _OpenSessionCard({
    required this.l10n,
    required this.registers,
    required this.registerId,
    required this.balanceCtrl,
    required this.onRegisterChanged,
    required this.onOpen,
  });

  final AppLocalizations l10n;
  final List<CashRegisterEntity> registers;
  final String? registerId;
  final TextEditingController balanceCtrl;
  final ValueChanged<String?> onRegisterChanged;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.openSession, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: registerId,
                decoration: InputDecoration(
                  labelText: l10n.register,
                  prefixIcon: const Icon(AppIcons.registerRounded),
                ),
                items: [
                  for (final r in registers)
                    DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: onRegisterChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: balanceCtrl,
                decoration: InputDecoration(
                  labelText: '${l10n.openingBalance} (Rp)',
                  prefixIcon: const Icon(AppIcons.accountBalanceRounded),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: registerId == null || balanceCtrl.text.isEmpty
                      ? null
                      : onOpen,
                  child: Text(l10n.open),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.session,
    required this.l10n,
    required this.onClose,
  });

  final CashSessionEntity session;
  final AppLocalizations l10n;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.activeSession,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          )),
                  const Icon(Icons.access_time, size: 16),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(session.registerName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Text('${l10n.openedBy}: ${session.openedBy}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('${l10n.openingBalance}: ${_idr(session.openingBalance)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onClose,
                  child: Text(l10n.closeSession),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _idr(double v) {
  final nf = NumberFormat.simpleCurrency(
      locale: 'id_ID', name: 'Rp ', decimalDigits: 0);
  return nf.format(v);
}

class _CloseDialog extends ConsumerStatefulWidget {
  const _CloseDialog({required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<_CloseDialog> createState() => _CloseDialogState();
}

class _CloseDialogState extends ConsumerState<_CloseDialog> {
  final _actualCtrl = TextEditingController();

  @override
  void dispose() {
    _actualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.closeSession),
      content: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _actualCtrl,
              decoration: InputDecoration(
                labelText: '${l10n.actualBalance} (Rp)',
                prefixIcon: const Icon(AppIcons.accountBalanceRounded),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final repo = ref.read(cashRepositoryProvider);
            repo.closeSession(
              sessionId: widget.sessionId,
              actualBalance: double.tryParse(_actualCtrl.text) ?? 0,
              closedBy: 'kasir',
            );
            Navigator.of(context).pop();
          },
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
