import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../models/ticket_model.dart';
import '../theme/app_theme.dart';
import 'ticket_detail_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Carrega chamados da API REST ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchTickets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Chamados'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              final scaffold = Scaffold.maybeOf(context);
              if (scaffold != null && scaffold.hasDrawer) {
                scaffold.openDrawer();
              }
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12)),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Todos'),
                Tab(text: 'Abertos'),
                Tab(text: 'Andamento'),
                Tab(text: 'Resolvidos'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer2<TicketProvider, AuthProvider>(
        builder: (_, tp, auth, __) {
          final userId = auth.currentUser?.id ?? '';

          // Indicador de carregamento
          if (tp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Mensagem de erro / sem conexão
          if (tp.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    tp.errorMessage!,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => tp.fetchTickets(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: tp.fetchTickets,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketList(tp.getTicketsByUser(userId)),
                _buildTicketList(tp
                    .getTicketsByUser(userId)
                    .where((t) => t.status == TicketStatus.open)
                    .toList()),
                _buildTicketList(tp
                    .getTicketsByUser(userId)
                    .where((t) => t.status == TicketStatus.inProgress)
                    .toList()),
                _buildTicketList(tp
                    .getTicketsByUser(userId)
                    .where((t) =>
                        t.status == TicketStatus.resolved ||
                        t.status == TicketStatus.closed)
                    .toList()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketList(List<TicketModel> tickets) {
    if (tickets.isEmpty) {
      return Center(
        child: FadeIn(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceCard, shape: BoxShape.circle),
              child: const Icon(Icons.confirmation_number_outlined,
                  size: 48, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            Text('Nenhum chamado encontrado',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text('Inicie um atendimento com a IA\npara criar chamados',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.textMuted)),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (_, i) => FadeInUp(
        delay: Duration(milliseconds: i * 100),
        duration: const Duration(milliseconds: 400),
        child: _buildTicketCard(tickets[i]),
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    final (Color c, String s, IconData icon) = switch (ticket.status) {
      TicketStatus.open => (AppTheme.accentOrange, 'Aberto', Icons.fiber_new_rounded),
      TicketStatus.inProgress => (AppTheme.accentBlue, 'Em Andamento', Icons.sync_rounded),
      TicketStatus.resolved => (AppTheme.success, 'Resolvido', Icons.check_circle_rounded),
      TicketStatus.closed => (AppTheme.textMuted, 'Fechado', Icons.archive_rounded),
    };

    final (Color pc, String ps) = switch (ticket.priority) {
      TicketPriority.low => (AppTheme.textMuted, 'Baixa'),
      TicketPriority.medium => (AppTheme.warning, 'Média'),
      TicketPriority.high => (AppTheme.accentOrange, 'Alta'),
      TicketPriority.critical => (AppTheme.error, 'Crítica'),
    };

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticketId: ticket.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.glassCard,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: c, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.title,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('#${ticket.id.substring(0, 8).toUpperCase()}',
                        style: GoogleFonts.firaCode(
                            fontSize: 11, color: AppTheme.textMuted)),
                  ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: AppTheme.statusBadge(c),
              child: Text(s,
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600, color: c)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(ticket.description,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          // Footer
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              _infoChip(Icons.folder_outlined, ticket.category),
              const SizedBox(width: 10),
              _infoChip(Icons.priority_high_rounded, ps, color: pc),
              const Spacer(),
              Text(_dateFormat.format(ticket.createdAt),
                  style:
                      GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, {Color? color}) {
    final c = color ?? AppTheme.textMuted;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: c),
      const SizedBox(width: 4),
      Text(text,
          style: GoogleFonts.inter(
              fontSize: 11, color: c, fontWeight: FontWeight.w500)),
    ]);
  }
}
