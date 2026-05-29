import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import '../models/message_model.dart';
import '../providers/ticket_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  static const _uuid = Uuid();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthProvider>().currentUser!;
    final comment = MessageModel(
      id: _uuid.v4(),
      content: text,
      sender: MessageSender.user,
      senderName: user.name,
    );

    context.read<TicketProvider>().addComment(widget.ticketId, comment);
    _commentController.clear();
    _scrollToBottom();
  }

  void _showEditStatusSheet(TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditStatusSheet(
        ticket: ticket,
        onSave: (status, priority) async {
          Navigator.pop(context);
          final ok = await context.read<TicketProvider>().editTicket(
            widget.ticketId,
            status: status,
            priority: priority,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok ? 'Chamado atualizado!' : 'Erro ao atualizar.'),
            backgroundColor: ok ? AppTheme.success : AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text('Excluir Chamado',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        content: Text(
            'Tem certeza que deseja excluir este chamado? Esta ação não pode ser desfeita.',
            style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('Excluir',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final ok = await context.read<TicketProvider>().deleteTicket(widget.ticketId);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context); // volta para a lista
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chamado excluído com sucesso.'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro ao excluir chamado.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketProvider>(
      builder: (context, tp, _) {
        final ticket = tp.getTicketById(widget.ticketId);
        if (ticket == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chamado')),
            body: const Center(child: Text('Chamado não encontrado')),
          );
        }

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
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 22),
              tooltip: 'Editar chamado',
              onPressed: () => _showEditStatusSheet(ticket),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppTheme.error),
              tooltip: 'Excluir chamado',
              onPressed: () => _confirmDelete(context),
            ),
          ],
          ),
          body: Column(
            children: [
              // Scrollable content area
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Title & Status Card
                    FadeInDown(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassCard,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            _badge(ss, sc, si),
                            const SizedBox(width: 8),
                            _badge(ps, pc, Icons.flag_rounded),
                          ]),
                          const SizedBox(height: 16),
                          Text(ticket.title, style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          const SizedBox(height: 12),
                          Text(ticket.description, style: GoogleFonts.inter(
                              fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Card
                    FadeInDown(
                      delay: const Duration(milliseconds: 100),
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassCard,
                        child: Column(children: [
                          _infoRow(Icons.folder_outlined, 'Categoria', ticket.category),
                          _divider(),
                          _infoRow(Icons.business_outlined, 'Departamento', ticket.department),
                          _divider(),
                          _infoRow(Icons.person_outline, 'Solicitante', ticket.userName),
                          _divider(),
                          _infoRow(Icons.calendar_today_outlined, 'Criado em',
                              _dateFormat.format(ticket.createdAt)),
                          if (ticket.resolvedAt != null) ...[
                            _divider(),
                            _infoRow(Icons.check_circle_outline, 'Resolvido em',
                                _dateFormat.format(ticket.resolvedAt!)),
                          ],
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AI Summary
                    if (ticket.aiSummary.isNotEmpty)
                      FadeInDown(
                        delay: const Duration(milliseconds: 200),
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.glassCard,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Text('Resumo da IA', style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                            ]),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryDark.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.1)),
                              ),
                              child: Text(ticket.aiSummary, style: GoogleFonts.firaCode(
                                  fontSize: 12, color: AppTheme.textSecondary, height: 1.6)),
                            ),
                          ]),
                        ),
                      ),
                    if (ticket.aiSummary.isNotEmpty) const SizedBox(height: 16),

                    // Chat History (AI conversation)
                    if (ticket.chatHistory.isNotEmpty) ...[
                      FadeInDown(
                        delay: const Duration(milliseconds: 300),
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.glassCard,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Icon(Icons.smart_toy_rounded, size: 20, color: AppTheme.accentCyan),
                              const SizedBox(width: 10),
                              Text('Conversa com IA', style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                              const Spacer(),
                              Text('${ticket.chatHistory.length} msgs', style: GoogleFonts.inter(
                                  fontSize: 12, color: AppTheme.textMuted)),
                            ]),
                            const SizedBox(height: 16),
                            ...ticket.chatHistory.map((m) => _chatBubble(m)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Comments / Messages Section
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassCard,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.forum_rounded, size: 20, color: AppTheme.accentBlue),
                            const SizedBox(width: 10),
                            Text('Mensagens', style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: AppTheme.statusBadge(AppTheme.accentBlue),
                              child: Text('${ticket.comments.length}', style: GoogleFonts.inter(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentBlue)),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          if (ticket.comments.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryDark.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 32,
                                    color: AppTheme.textMuted.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                Text('Nenhuma mensagem ainda',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                                const SizedBox(height: 4),
                                Text('Envie a primeira mensagem abaixo',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                              ]),
                            )
                          else
                            ...ticket.comments.map((c) => _commentBubble(c)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Input area for new comments
              _buildCommentInput(ticket),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput(TicketModel ticket) {
    final isClosed = ticket.status == TicketStatus.closed;

    if (isClosed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryMid,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        ),
        child: Center(
          child: Text('Chamado fechado — não é possível enviar novas mensagens.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _commentController,
                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendComment(),
                decoration: InputDecoration(
                  hintText: 'Escreva uma mensagem...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendComment,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentBlue.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: AppTheme.statusBadge(color),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
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
        Flexible(child: Text(value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            textAlign: TextAlign.end)),
      ]),
    );
  }

  Widget _divider() => Divider(color: AppTheme.dividerColor.withValues(alpha: 0.5), height: 20);

  Widget _commentBubble(MessageModel m) {
    final timeStr = DateFormat('dd/MM HH:mm').format(m.timestamp);
    return FadeInUp(
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_rounded, size: 14, color: AppTheme.accentBlue),
            ),
            const SizedBox(width: 8),
            Text(m.senderName ?? 'Usuário',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.accentBlue)),
            const Spacer(),
            Text(timeStr, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
          ]),
          const SizedBox(height: 10),
          Text(m.content, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, height: 1.5)),
        ]),
      ),
    );
  }

  Widget _chatBubble(MessageModel m) {
    final isUser = m.sender == MessageSender.user;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? AppTheme.accentBlue.withValues(alpha: 0.1)
            : AppTheme.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isUser ? AppTheme.accentBlue : Colors.white).withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isUser ? Icons.person_rounded : Icons.smart_toy_rounded, size: 14,
              color: isUser ? AppTheme.accentBlue : AppTheme.accentCyan),
          const SizedBox(width: 6),
          Text(isUser ? 'Usuário' : 'IA', style: GoogleFonts.inter(fontSize: 11,
              fontWeight: FontWeight.w600, color: isUser ? AppTheme.accentBlue : AppTheme.accentCyan)),
        ]),
        const SizedBox(height: 6),
        Text(m.content, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
      ]),
    );
  }
}

/// Bottom sheet para editar status e prioridade do chamado
class _EditStatusSheet extends StatefulWidget {
  final TicketModel ticket;
  final void Function(TicketStatus status, TicketPriority priority) onSave;

  const _EditStatusSheet({required this.ticket, required this.onSave});

  @override
  State<_EditStatusSheet> createState() => _EditStatusSheetState();
}

class _EditStatusSheetState extends State<_EditStatusSheet> {
  late TicketStatus _status;
  late TicketPriority _priority;

  @override
  void initState() {
    super.initState();
    _status = widget.ticket.status;
    _priority = widget.ticket.priority;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Editar Chamado', style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 24),

        // Status
        Text('Status', style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: TicketStatus.values.map((s) {
          final selected = _status == s;
          final label = switch (s) {
            TicketStatus.open => 'Aberto',
            TicketStatus.inProgress => 'Em Andamento',
            TicketStatus.resolved => 'Resolvido',
            TicketStatus.closed => 'Fechado',
          };
          final color = switch (s) {
            TicketStatus.open => AppTheme.accentOrange,
            TicketStatus.inProgress => AppTheme.accentBlue,
            TicketStatus.resolved => AppTheme.success,
            TicketStatus.closed => AppTheme.textMuted,
          };
          return GestureDetector(
            onTap: () => setState(() => _status = s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.2) : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? color : Colors.white.withValues(alpha: 0.08), width: selected ? 2 : 1),
              ),
              child: Text(label, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: selected ? color : AppTheme.textSecondary)),
            ),
          );
        }).toList()),
        const SizedBox(height: 20),

        // Priority
        Text('Prioridade', style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: TicketPriority.values.map((p) {
          final selected = _priority == p;
          final label = switch (p) {
            TicketPriority.low => 'Baixa',
            TicketPriority.medium => 'Média',
            TicketPriority.high => 'Alta',
            TicketPriority.critical => 'Crítica',
          };
          final color = switch (p) {
            TicketPriority.low => AppTheme.textMuted,
            TicketPriority.medium => AppTheme.warning,
            TicketPriority.high => AppTheme.accentOrange,
            TicketPriority.critical => AppTheme.error,
          };
          return GestureDetector(
            onTap: () => setState(() => _priority = p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.2) : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? color : Colors.white.withValues(alpha: 0.08), width: selected ? 2 : 1),
              ),
              child: Text(label, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: selected ? color : AppTheme.textSecondary)),
            ),
          );
        }).toList()),
        const SizedBox(height: 28),

        // Save
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              onPressed: () => widget.onSave(_status, _priority),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Salvar Alterações', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ]),
    );
  }
}
