import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../models/ticket_model.dart';
import '../theme/app_theme.dart';
import 'ticket_detail_screen.dart';

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
            if (tp.totalTickets > 0) ...[
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _buildStatusChart(tp),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: _buildPriorityChart(tp),
              ),
              const SizedBox(height: 28),
            ],

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
              ...tp.tickets.take(3).map((t) => _ticketCard(context, t)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart(TicketProvider tp) {
    final open = tp.openTickets;
    final inProgress = tp.inProgressTickets;
    final resolved = tp.resolvedTickets;
    final closed = tp.tickets.where((t) => t.status == TicketStatus.closed).length;
    final total = open + inProgress + resolved + closed;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status dos Chamados',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 35,
                      sections: [
                        if (open > 0)
                          PieChartSectionData(
                            color: AppTheme.accentOrange,
                            value: open.toDouble(),
                            title: '$open',
                            radius: 18,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (inProgress > 0)
                          PieChartSectionData(
                            color: AppTheme.accentBlue,
                            value: inProgress.toDouble(),
                            title: '$inProgress',
                            radius: 18,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (resolved > 0)
                          PieChartSectionData(
                            color: AppTheme.success,
                            value: resolved.toDouble(),
                            title: '$resolved',
                            radius: 18,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (closed > 0)
                          PieChartSectionData(
                            color: AppTheme.textMuted,
                            value: closed.toDouble(),
                            title: '$closed',
                            radius: 18,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem('Aberto', AppTheme.accentOrange),
                    const SizedBox(height: 6),
                    _legendItem('Em Andamento', AppTheme.accentBlue),
                    const SizedBox(height: 6),
                    _legendItem('Resolvido', AppTheme.success),
                    const SizedBox(height: 6),
                    _legendItem('Fechado', AppTheme.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChart(TicketProvider tp) {
    final priorityMap = tp.ticketsByPriority;
    final low = priorityMap[TicketPriority.low] ?? 0;
    final medium = priorityMap[TicketPriority.medium] ?? 0;
    final high = priorityMap[TicketPriority.high] ?? 0;
    final critical = priorityMap[TicketPriority.critical] ?? 0;
    final maxVal = [low, medium, high, critical].reduce((curr, next) => curr > next ? curr : next);

    if (tp.totalTickets == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chamados por Prioridade',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxVal == 0 ? 5 : (maxVal + 1).toDouble(),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: low.toDouble(),
                        color: AppTheme.textMuted,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: medium.toDouble(),
                        color: AppTheme.warning,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: high.toDouble(),
                        color: AppTheme.accentOrange,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: critical.toDouble(),
                        color: AppTheme.error,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                ],
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final style = GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        );
                        switch (value.toInt()) {
                          case 0:
                            return SideTitleWidget(
                              meta: meta,
                              child: Text('Baixa', style: style),
                            );
                          case 1:
                            return SideTitleWidget(
                              meta: meta,
                              child: Text('Média', style: style),
                            );
                          case 2:
                            return SideTitleWidget(
                              meta: meta,
                              child: Text('Alta', style: style),
                            );
                          case 3:
                            return SideTitleWidget(
                              meta: meta,
                              child: Text('Crítica', style: style),
                            );
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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


  Widget _ticketCard(BuildContext context, TicketModel t) {
    final (Color c, String s, IconData i) = switch (t.status) {
      TicketStatus.open => (AppTheme.accentOrange, 'Aberto', Icons.fiber_new_rounded),
      TicketStatus.inProgress => (AppTheme.accentBlue, 'Em Andamento', Icons.sync_rounded),
      TicketStatus.resolved => (AppTheme.success, 'Resolvido', Icons.check_circle_rounded),
      TicketStatus.closed => (AppTheme.textMuted, 'Fechado', Icons.archive_rounded),
    };
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: t.id))),
      child: Container(
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
      ),
    );
  }
}
