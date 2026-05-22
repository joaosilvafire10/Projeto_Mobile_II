import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
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

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione a categoria e a atividade.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;
    final uuid = const Uuid();

    // Direciona o chamado para o grupo/departamento da categoria selecionada
    final String department = _selectedCategory!.name;

    final ticket = TicketModel(
      id: uuid.v4(),
      title: '[Manual - ${_selectedActivity!.name}] ${_titleController.text.trim()}',
      description: _descController.text.trim(),
      userId: user.id,
      userName: user.name,
      department: department,
      status: TicketStatus.open,
      priority: _selectedPriority,
      category: _selectedCategory!.name,
      createdAt: DateTime.now(),
      aiSummary: 'Chamado aberto manualmente pelo usuário sem triagem da IA.',
    );

    context.read<TicketProvider>().addTicket(ticket);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chamado manual criado com sucesso!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.pop(context); // Return to previous screen
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
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Title Field
                      Text(
                        'Título do Problema',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'O título é obrigatório.'
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Erro ao emitir Nota Fiscal',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category Dropdown
                      Text(
                        'Categoria',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CategoryModel>(
                            isExpanded: true,
                            dropdownColor: AppTheme.surfaceCard,
                            hint: Text(
                              'Selecione a Categoria...',
                              style: GoogleFonts.inter(color: AppTheme.textMuted),
                            ),
                            value: _selectedCategory,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.accentBlue),
                            items: categoryProvider.categories
                                .map((CategoryModel cat) {
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
                      const SizedBox(height: 20),

                      // Activity Dropdown (if Category selected)
                      if (_selectedCategory != null) ...[
                        Text(
                          'Atividade',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ActivityModel>(
                              isExpanded: true,
                              dropdownColor: AppTheme.surfaceCard,
                              hint: Text(
                                'Selecione a Atividade...',
                                style:
                                    GoogleFonts.inter(color: AppTheme.textMuted),
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
                        const SizedBox(height: 20),
                      ],

                      // Priority Dropdown
                      Text(
                        'Prioridade',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TicketPriority>(
                            isExpanded: true,
                            dropdownColor: AppTheme.surfaceCard,
                            value: _selectedPriority,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.accentOrange),
                            items: TicketPriority.values
                                .map((TicketPriority priority) {
                              String label = 'Média';
                              if (priority == TicketPriority.low) {
                                label = 'Baixa';
                              } else if (priority == TicketPriority.high) {
                                label = 'Alta';
                              } else if (priority == TicketPriority.critical) {
                                label = 'Crítica';
                              }
                              return DropdownMenuItem<TicketPriority>(
                                value: priority,
                                child: Text(
                                  label,
                                  style: GoogleFonts.inter(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (TicketPriority? newPriority) {
                              if (newPriority != null) {
                                setState(() {
                                  _selectedPriority = newPriority;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description Field
                      Text(
                        'Descrição Detalhada',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 6,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'A descrição é obrigatória.'
                            : null,
                        decoration: const InputDecoration(
                          hintText:
                              'Descreva o problema com o máximo de detalhes possível, incluindo mensagens de erro...',
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Submit Button
                      SizedBox(
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
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: Text(
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
}
