import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../models/ticket_model.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tp = context.watch<TicketProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              // Abre o Drawer do Scaffold pai (HomeScreen)
              final scaffold = Scaffold.maybeOf(context);
              if (scaffold != null && scaffold.hasDrawer) {
                scaffold.openDrawer();
              }
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.2),
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: GoogleFonts.inter(color: AppTheme.accentBlue, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Olá, ${user?.name.split(' ').first ?? 'Usuário'}! 👋',
                    style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('Veja o resumo dos seus atendimentos',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
              ]),
            ),
            const SizedBox(height: 28),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Row(children: [
                Expanded(child: _statCard('Total', '${tp.totalTickets}', Icons.confirmation_number_rounded, AppTheme.accentBlue)),
                const SizedBox(width: 12),
                Expanded(child: _statCard('Abertos', '${tp.openTickets}', Icons.fiber_new_rounded, AppTheme.accentOrange)),
              ]),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Row(children: [
                Expanded(child: _statCard('Em Andamento', '${tp.inProgressTickets}', Icons.sync_rounded, AppTheme.accentPurple)),
                const SizedBox(width: 12),
                Expanded(child: _statCard('Resolvidos', '${tp.resolvedTickets}', Icons.check_circle_outline_rounded, AppTheme.success)),
              ]),
            ),
            const SizedBox(height: 28),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Text('Ações Rápidas', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 14),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _quickAction(Icons.smart_toy_rounded, 'Novo Atendimento IA',
                  'Descreva seu problema e receba suporte inteligente', AppTheme.primaryGradient),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: _quickAction(Icons.history_rounded, 'Histórico de Conversas',
                  'Veja atendimentos anteriores resolvidos pela IA',
                  const LinearGradient(colors: [AppTheme.accentPurple, AppTheme.accentPink])),
            ),
            const SizedBox(height: 28),
            FadeInUp(
              delay: const Duration(milliseconds: 700),
              child: Text('Chamados Recentes', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 12),
            if (tp.totalTickets == 0)
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.all(32), decoration: AppTheme.glassCard,
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.accentBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.inbox_rounded, color: AppTheme.accentBlue, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text('Nenhum chamado ainda', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Text('Inicie um atendimento com a IA\npara criar seu primeiro chamado',
                        textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted, height: 1.5)),
                  ]),
                ),
              )
            else
              ...tp.tickets.take(3).map(_ticketCard),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 14),
        Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _quickAction(IconData icon, String title, String subtitle, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(18), decoration: AppTheme.glassCard,
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 24)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 16),
      ]),
    );
  }

  Widget _ticketCard(TicketModel t) {
    final (Color c, String s, IconData i) = switch (t.status) {
      TicketStatus.open => (AppTheme.accentOrange, 'Aberto', Icons.fiber_new_rounded),
      TicketStatus.inProgress => (AppTheme.accentBlue, 'Em Andamento', Icons.sync_rounded),
      TicketStatus.resolved => (AppTheme.success, 'Resolvido', Icons.check_circle_rounded),
      TicketStatus.closed => (AppTheme.textMuted, 'Fechado', Icons.archive_rounded),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: AppTheme.glassCard,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(t.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: AppTheme.statusBadge(c),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(i, size: 12, color: c), const SizedBox(width: 4),
              Text(s, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Text(t.description, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.folder_outlined, size: 14, color: AppTheme.textMuted), const SizedBox(width: 4),
          Text(t.category, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(width: 12),
          const Icon(Icons.business_outlined, size: 14, color: AppTheme.textMuted), const SizedBox(width: 4),
          Expanded(child: Text(t.department, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis)),
        ]),
      ]),
    );
  }
}
