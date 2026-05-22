import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/category_provider.dart';
import '../models/category_model.dart';
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

  CategoryModel? _selectedCategory;
  ActivityModel? _selectedActivity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _chatProvider = context.read<ChatProvider>();
      context.read<CategoryProvider>().fetchCategories(activeOnly: true);
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
          Expanded(
            child: Text(
              'Chamado ${ticket.id.substring(0, 8).toUpperCase()} criado!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
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
    setState(() {
      _selectedCategory = null;
      _selectedActivity = null;
    });
    // This will clear chat messages and allow choosing categories again
    _chatProvider.startConversation();
    _scrollToBottom();
  }

  Widget _buildScopeSelection(CategoryProvider categoryProvider) {
    return Scaffold(
      appBar: AppBar(
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
        title: Text(
          'Novo Chamado',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Como podemos te ajudar hoje?',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              duration: const Duration(milliseconds: 450),
              child: Text(
                'Selecione a categoria e atividade para iniciar o atendimento inteligente de suporte corporativo.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Step 1: Select Category
            FadeInUp(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '1. Selecione a Categoria',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CategoryModel>(
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceCard,
                    hint: Text(
                      'Escolha uma Categoria...',
                      style: GoogleFonts.inter(color: AppTheme.textMuted),
                    ),
                    value: _selectedCategory,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.accentBlue),
                    items: categoryProvider.categories.map((CategoryModel cat) {
                      return DropdownMenuItem<CategoryModel>(
                        value: cat,
                        child: Text(
                          cat.name,
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (CategoryModel? newCat) {
                      setState(() {
                        _selectedCategory = newCat;
                        _selectedActivity = null;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Step 2: Select Activity (if Category is selected)
            if (_selectedCategory != null) ...[
              FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '2. Selecione a Atividade',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentCyan,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ActivityModel>(
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      hint: Text(
                        'Escolha uma Atividade...',
                        style: GoogleFonts.inter(color: AppTheme.textMuted),
                      ),
                      value: _selectedActivity,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.accentCyan),
                      items: _selectedCategory!.activities
                          .map((ActivityModel act) {
                        return DropdownMenuItem<ActivityModel>(
                          value: act,
                          child: Text(
                            act.name,
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (ActivityModel? newAct) {
                        setState(() {
                          _selectedActivity = newAct;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Confirm Button
            if (_selectedCategory != null && _selectedActivity != null)
              FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _chatProvider.startConversation(
                          categoryName: _selectedCategory!.name,
                          activityName: _selectedActivity!.name,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        'Iniciar Atendimento Inteligente',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    if (chat.selectedCategoryName == null) {
      return _buildScopeSelection(categoryProvider);
    }

    return Scaffold(
      appBar: AppBar(
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
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.smart_toy_rounded,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assistente IA',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            Text(
              chat.isAiTyping ? 'Analisando...' : 'Online',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color:
                      chat.isAiTyping ? AppTheme.accentOrange : AppTheme.success,
                  fontWeight: FontWeight.w500),
            ),
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: chat.messages.length + (chat.isAiTyping ? 1 : 0),
              itemBuilder: (_, index) {
                if (index == chat.messages.length && chat.isAiTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(chat.messages[index]);
              },
            ),
          ),
          // Action buttons
          Consumer<ChatProvider>(builder: (_, chatVal, __) {
            if (chatVal.isResolved && !chatVal.ticketCreated) {
              return _buildActionBar([
                _actionBtn('Resolvido ✅', AppTheme.success, _markResolved),
                _actionBtn('Abrir Chamado 📋', AppTheme.accentOrange, _createTicket),
              ]);
            }
            if (chatVal.ticketCreated ||
                (chatVal.messages.length > 3 && !chatVal.isResolved)) {
              final btns = <Widget>[];
              if (!chatVal.ticketCreated) {
                btns.add(_actionBtn('Abrir Chamado 📋', AppTheme.accentBlue, _createTicket));
              }
              if (chatVal.ticketCreated) {
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
          children: children
              .map((w) => Expanded(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4), child: w)))
              .toList(),
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
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
                color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
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
                  )
                ],
              ),
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
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82),
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
                  child: const Icon(Icons.smart_toy_rounded,
                      size: 16, color: Colors.white),
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
                    border: isUser
                        ? null
                        : Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
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
              decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.smart_toy_rounded,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(200),
                const SizedBox(width: 4),
                _dot(400),
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
        width: 8,
        height: 8,
        decoration:
            BoxDecoration(color: AppTheme.textMuted, shape: BoxShape.circle),
      ),
    );
  }
}
