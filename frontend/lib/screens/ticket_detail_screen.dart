import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../models/message_model.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';

class TicketDetailScreen extends StatelessWidget {
  final TicketModel ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final (Color sc, String ss, IconData si) = switch (ticket.status) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text('#${ticket.id.substring(0, 8).toUpperCase()}',
            style: GoogleFonts.firaCode(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          if (ticket.status == TicketStatus.open)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              color: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'progress') {
                  context.read<TicketProvider>().updateTicketStatus(ticket.id, TicketStatus.inProgress);
                  Navigator.pop(context);
                } else if (v == 'resolve') {
                  context.read<TicketProvider>().resolveTicket(ticket.id, 'Resolvido pelo técnico.');
                  Navigator.pop(context);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'progress', child: Row(children: [
                  Icon(Icons.sync_rounded, color: AppTheme.accentBlue, size: 18), const SizedBox(width: 8),
                  Text('Em Andamento', style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13)),
                ])),
                PopupMenuItem(value: 'resolve', child: Row(children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18), const SizedBox(width: 8),
                  Text('Resolver', style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13)),
                ])),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title & Status
          Container(
            padding: const EdgeInsets.all(20), decoration: AppTheme.glassCard,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: AppTheme.statusBadge(sc),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(si, size: 14, color: sc), const SizedBox(width: 6),
                    Text(ss, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sc)),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: AppTheme.statusBadge(pc),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.flag_rounded, size: 14, color: pc), const SizedBox(width: 6),
                    Text(ps, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: pc)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              Text(ticket.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Text(ticket.description, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 16),

          // Info
          Container(
            padding: const EdgeInsets.all(20), decoration: AppTheme.glassCard,
            child: Column(children: [
              _infoRow(Icons.folder_outlined, 'Categoria', ticket.category),
              _divider(),
              _infoRow(Icons.business_outlined, 'Departamento', ticket.department),
              _divider(),
              _infoRow(Icons.person_outline, 'Solicitante', ticket.userName),
              _divider(),
              _infoRow(Icons.calendar_today_outlined, 'Criado em', dateFormat.format(ticket.createdAt)),
              if (ticket.resolvedAt != null) ...[
                _divider(),
                _infoRow(Icons.check_circle_outline, 'Resolvido em', dateFormat.format(ticket.resolvedAt!)),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          // AI Summary
          if (ticket.aiSummary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20), decoration: AppTheme.glassCard,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text('Resumo da IA', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ]),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.1)),
                  ),
                  child: Text(ticket.aiSummary, style: GoogleFonts.firaCode(fontSize: 12, color: AppTheme.textSecondary, height: 1.6)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Chat history
          if (ticket.chatHistory.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20), decoration: AppTheme.glassCard,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppTheme.accentCyan),
                  const SizedBox(width: 10),
                  Text('Histórico da Conversa', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const Spacer(),
                  Text('${ticket.chatHistory.length} msgs', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ]),
                const SizedBox(height: 16),
                ...ticket.chatHistory.map((m) => _chatBubble(m)),
              ]),
            ),
          ],
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
        const Spacer(),
        Flexible(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            textAlign: TextAlign.end)),
      ]),
    );
  }

  Widget _divider() => Divider(color: AppTheme.dividerColor.withValues(alpha: 0.5), height: 20);

  Widget _chatBubble(MessageModel m) {
    final isUser = m.sender == MessageSender.user;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser ? AppTheme.accentBlue.withValues(alpha: 0.1) : AppTheme.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isUser ? AppTheme.accentBlue : Colors.white).withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isUser ? Icons.person_rounded : Icons.smart_toy_rounded, size: 14,
              color: isUser ? AppTheme.accentBlue : AppTheme.accentCyan),
          const SizedBox(width: 6),
          Text(isUser ? 'Usuário' : 'IA', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
              color: isUser ? AppTheme.accentBlue : AppTheme.accentCyan)),
        ]),
        const SizedBox(height: 6),
        Text(m.content, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
      ]),
    );
  }
}
