import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/ticket_provider.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late ChatProvider _chatProvider;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _chatProvider = context.read<ChatProvider>();
      if (_chatProvider.messages.isEmpty) {
        _chatProvider.startConversation();
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _chatProvider.sendMessage(text);
    _scrollToBottom();
  }

  void _createTicket() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;
    final ticket = _chatProvider.createTicket(user.id, user.name);
    context.read<TicketProvider>().addTicket(ticket);
    _scrollToBottom();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('Chamado ${ticket.id.substring(0, 8).toUpperCase()} criado!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: AppTheme.success.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _markResolved() {
    _chatProvider.markAsResolved();
    _scrollToBottom();
  }

  void _newConversation() {
    _chatProvider.startConversation();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assistente IA', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            Consumer<ChatProvider>(builder: (_, chat, __) => Text(
              chat.isAiTyping ? 'Analisando...' : 'Online',
              style: GoogleFonts.inter(fontSize: 11,
                  color: chat.isAiTyping ? AppTheme.accentOrange : AppTheme.success, fontWeight: FontWeight.w500),
            )),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Nova conversa',
            onPressed: _newConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (_, chat, __) {
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: chat.messages.length + (chat.isAiTyping ? 1 : 0),
                  itemBuilder: (_, index) {
                    if (index == chat.messages.length && chat.isAiTyping) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(chat.messages[index]);
                  },
                );
              },
            ),
          ),
          // Action buttons
          Consumer<ChatProvider>(builder: (_, chat, __) {
            if (chat.isResolved && !chat.ticketCreated) {
              return _buildActionBar([
                _actionBtn('Resolvido ✅', AppTheme.success, _markResolved),
                _actionBtn('Abrir Chamado 📋', AppTheme.accentOrange, _createTicket),
              ]);
            }
            if (chat.ticketCreated || (chat.messages.length > 4 && !chat.isResolved)) {
              final btns = <Widget>[];
              if (!chat.ticketCreated) {
                btns.add(_actionBtn('Abrir Chamado 📋', AppTheme.accentBlue, _createTicket));
              }
              if (chat.ticketCreated) {
                btns.add(_actionBtn('Nova Conversa 🔄', AppTheme.accentCyan, _newConversation));
              }
              if (btns.isNotEmpty) return _buildActionBar(btns);
            }
            return const SizedBox.shrink();
          }),
          // Input
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildActionBar(List<Widget> children) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: children.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList(),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(child: Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
      ),
    );
  }

  Widget _buildInputArea() {
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
                controller: _messageController,
                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Descreva seu problema...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.accentBlue.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isUser = message.sender == MessageSender.user;
    final isSystem = message.sender == MessageSender.system;

    if (isSystem) {
      return FadeIn(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppTheme.success.withValues(alpha: 0.1),
              AppTheme.accentCyan.withValues(alpha: 0.05),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
          ),
          child: _parseMarkdown(message.content, AppTheme.textPrimary),
        ),
      );
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.accentBlue : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: _parseMarkdown(
                    message.content,
                    isUser ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _parseMarkdown(String text, Color baseColor) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');
    final buffer = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      if (i > 0) buffer.write('\n');
      buffer.write(lines[i]);
    }

    // Simple bold parsing
    final raw = buffer.toString();
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in boldRegex.allMatches(raw)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: raw.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < raw.length) {
      spans.add(TextSpan(text: raw.substring(lastEnd)));
    }

    // Simple italic parsing for _text_
    // Keeping it simple with RichText
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(color: baseColor, fontSize: 14, height: 1.5),
        children: spans.isEmpty ? [TextSpan(text: raw)] : spans,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return FadeIn(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18), topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _dot(0), const SizedBox(width: 4), _dot(200), const SizedBox(width: 4), _dot(400),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _dot(int delayMs) {
    return Pulse(
      delay: Duration(milliseconds: delayMs),
      infinite: true,
      child: Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: AppTheme.textMuted, shape: BoxShape.circle),
      ),
    );
  }
}
