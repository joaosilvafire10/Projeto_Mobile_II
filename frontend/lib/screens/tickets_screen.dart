import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/theme_provider.dart';
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

  String _selectedCategory = 'Todas';
  DateTimeRange? _selectedDateRange;

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
    return Consumer2<TicketProvider, AuthProvider>(
      builder: (context, tp, auth, _) {
        final user = auth.currentUser;
        final titleText = user?.role == 'ADMIN'
            ? 'Todos os Chamados'
            : user?.role == 'ANALISTA'
                ? 'Chamados - ${user?.department ?? ""}'
                : 'Meus Chamados';

        return Scaffold(
          appBar: AppBar(
            title: Text(titleText),
            actions: [
              Consumer<ThemeProvider>(
                builder: (context, theme, _) => IconButton(
                  icon: Icon(theme.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                  onPressed: () => theme.toggleTheme(),
                ),
              ),
              const SizedBox(width: 8),
            ],
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () {
                  final scaffold = Scaffold.maybeOf(ctx);
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
                    color: context.colors.surfaceCard,
                    borderRadius: BorderRadius.circular(12)),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12)),
                  labelColor: Colors.white,
                  unselectedLabelColor: context.colors.textMuted,
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
          body: Builder(
            builder: (context) {
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
                      Icon(Icons.wifi_off_rounded,
                          size: 48, color: context.colors.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        tp.errorMessage!,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: context.colors.textSecondary),
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

              return Column(
                children: [
                  _buildFilters(tp),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: tp.fetchTickets,
                      child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTicketList(tp.tickets),
                    _buildTicketList(tp.tickets
                        .where((t) => t.status == TicketStatus.open)
                        .toList()),
                    _buildTicketList(tp.tickets
                        .where((t) => t.status == TicketStatus.inProgress)
                        .toList()),
                    _buildTicketList(tp.tickets
                        .where((t) =>
                            t.status == TicketStatus.resolved ||
                            t.status == TicketStatus.closed)
                        .toList()),
                  ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilters(TicketProvider tp) {
    final categories = ['Todas', ...tp.tickets.map((t) => t.category).toSet().toList()..sort()];
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: context.colors.primaryDark,
        border: Border(bottom: BorderSide(color: context.colors.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedCategory,
                  items: categories,
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                  icon: Icons.category_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange,
                    );
                    if (range != null) {
                      setState(() => _selectedDateRange = range);
                    }
                  },
                  icon: Icon(Icons.calendar_today_rounded, size: 18, color: context.colors.textSecondary),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Período'
                        : ' - ',
                    style: GoogleFonts.inter(fontSize: 13, color: context.colors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: context.colors.dividerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'Todas';
                    _selectedDateRange = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Limpar', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textMuted),
          dropdownColor: context.colors.surfaceCard,
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Row(
              children: [
                Icon(icon, size: 16, color: context.colors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e, style: GoogleFonts.inter(fontSize: 13, color: context.colors.textPrimary), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTicketList(List<TicketModel> tickets) {
    var filtered = tickets.where((t) {
      bool passCat = _selectedCategory == 'Todas' || t.category == _selectedCategory;
      bool passDate = true;
      if (_selectedDateRange != null) {
        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        passDate = t.createdAt.isAfter(start) && t.createdAt.isBefore(end);
      }
      return passCat && passDate;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: FadeIn(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: context.colors.surfaceCard, shape: BoxShape.circle),
              child: Icon(Icons.confirmation_number_outlined,
                  size: 48, color: context.colors.textMuted),
            ),
            const SizedBox(height: 20),
            Text('Nenhum chamado encontrado',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary)),
            const SizedBox(height: 8),
            Text('Inicie um atendimento com a IA\npara criar chamados ou ajuste os filtros',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: context.colors.textMuted)),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (_, i) => FadeInUp(
        delay: Duration(milliseconds: i * 100),
        duration: const Duration(milliseconds: 400),
        child: _buildTicketCard(filtered[i]),
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    final (Color c, String s, IconData icon) = switch (ticket.status) {
      TicketStatus.open => (AppTheme.accentOrange, 'Aberto', Icons.fiber_new_rounded),
      TicketStatus.inProgress => (AppTheme.accentBlue, 'Em Andamento', Icons.sync_rounded),
      TicketStatus.resolved => (AppTheme.success, 'Resolvido', Icons.check_circle_rounded),
      TicketStatus.closed => (context.colors.textMuted, 'Fechado', Icons.archive_rounded),
    };

    final (Color pc, String ps) = switch (ticket.priority) {
      TicketPriority.low => (context.colors.textMuted, 'Baixa'),
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
        decoration: context.glassCard,
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
                            color: context.colors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('#${ticket.id.substring(0, 8).toUpperCase()}',
                        style: GoogleFonts.firaCode(
                            fontSize: 11, color: context.colors.textMuted)),
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
                  color: context.colors.textSecondary,
                  height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          // Footer
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primaryDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              _infoChip(Icons.folder_outlined, ticket.category),
              const SizedBox(width: 10),
              _infoChip(Icons.priority_high_rounded, ps, color: pc),
              const Spacer(),
              Text(_dateFormat.format(ticket.createdAt),
                  style:
                      GoogleFonts.inter(fontSize: 10, color: context.colors.textMuted)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, {Color? color}) {
    final c = color ?? context.colors.textMuted;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: c),
      const SizedBox(width: 4),
      Text(text,
          style: GoogleFonts.inter(
              fontSize: 11, color: c, fontWeight: FontWeight.w500)),
    ]);
  }
}
