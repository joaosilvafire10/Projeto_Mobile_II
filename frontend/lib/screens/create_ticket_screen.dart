import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/ticket_provider.dart';
import '../providers/category_provider.dart';
import '../models/ticket_model.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  CategoryModel? _selectedCategory;
  ActivityModel? _selectedActivity;
  TicketPriority _selectedPriority = TicketPriority.medium;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories(activeOnly: true);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Regra de negócio 1: Categoria e Atividade são obrigatórias
    if (_selectedCategory == null || _selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecione a categoria e a atividade.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Converte prioridade para formato da API
    final priorityMap = {
      TicketPriority.low: 'BAIXA',
      TicketPriority.medium: 'MEDIA',
      TicketPriority.high: 'ALTA',
      TicketPriority.critical: 'CRITICA',
    };

    final ticket = await context.read<TicketProvider>().addTicket(
          title:
              '[Manual - ${_selectedActivity!.name}] ${_titleController.text.trim()}',
          description: _descController.text.trim(),
          priority: priorityMap[_selectedPriority]!,
          categoryId: _selectedCategory!.id,
          activityId: _selectedActivity!.id,
          department: _selectedCategory!.name,
          aiSummary:
              'Chamado aberto manualmente pelo usuário sem triagem da IA.',
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (ticket != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chamado criado com sucesso!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else {
      final error = context.read<TicketProvider>().errorMessage ??
          'Erro ao criar chamado.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Novo Chamado Manual',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: categoryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abertura de Chamado',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha as informações abaixo para encaminhar sua solicitação diretamente para a equipe técnica de suporte.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ── Título ──────────────────────────────────────────
                      _fieldLabel('Título do Problema'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O título é obrigatório.';
                          }
                          // Regra de negócio 2: mínimo 5 caracteres
                          if (value.trim().length < 5) {
                            return 'O título deve ter no mínimo 5 caracteres.';
                          }
                          // Regra de negócio 3: máximo 120 caracteres
                          if (value.trim().length > 120) {
                            return 'O título deve ter no máximo 120 caracteres.';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Ex: Erro ao emitir Nota Fiscal',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Categoria ───────────────────────────────────────
                      _fieldLabel('Categoria'),
                      const SizedBox(height: 8),
                      _dropdown<CategoryModel>(
                        hint: 'Selecione a Categoria...',
                        value: _selectedCategory,
                        items: categoryProvider.categories,
                        labelBuilder: (c) => c.name,
                        onChanged: (cat) {
                          setState(() {
                            _selectedCategory = cat;
                            _selectedActivity = null;
                          });
                        },
                        accentColor: AppTheme.accentBlue,
                      ),
                      const SizedBox(height: 20),

                      // ── Atividade ───────────────────────────────────────
                      if (_selectedCategory != null) ...[
                        _fieldLabel('Atividade'),
                        const SizedBox(height: 8),
                        _dropdown<ActivityModel>(
                          hint: 'Selecione a Atividade...',
                          value: _selectedActivity,
                          items: _selectedCategory!.activities,
                          labelBuilder: (a) => a.name,
                          onChanged: (act) {
                            setState(() => _selectedActivity = act);
                          },
                          accentColor: AppTheme.accentCyan,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Prioridade ──────────────────────────────────────
                      _fieldLabel('Prioridade'),
                      const SizedBox(height: 8),
                      _dropdown<TicketPriority>(
                        hint: '',
                        value: _selectedPriority,
                        items: TicketPriority.values,
                        labelBuilder: (p) => switch (p) {
                          TicketPriority.low => 'Baixa',
                          TicketPriority.medium => 'Média',
                          TicketPriority.high => 'Alta',
                          TicketPriority.critical => 'Crítica',
                        },
                        onChanged: (p) {
                          if (p != null) setState(() => _selectedPriority = p);
                        },
                        accentColor: AppTheme.accentOrange,
                      ),
                      const SizedBox(height: 20),

                      // ── Descrição ───────────────────────────────────────
                      _fieldLabel('Descrição Detalhada'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'A descrição é obrigatória.';
                          }
                          // Regra de negócio: mínimo 10 caracteres
                          if (value.trim().length < 10) {
                            return 'A descrição deve ter no mínimo 10 caracteres.';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText:
                              'Descreva o problema com o máximo de detalhes possível, incluindo mensagens de erro...',
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ── Botão de envio ──────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTheme.accentBlue.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Enviar Solicitação',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          dropdownColor: context.colors.surfaceCard,
          hint: Text(hint, style: GoogleFonts.inter(color: context.colors.textMuted)),
          value: value,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: accentColor),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item),
                  style: GoogleFonts.inter(color: Colors.white)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
