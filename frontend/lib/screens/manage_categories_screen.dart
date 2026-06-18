import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/category_provider.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _categoryNameController = TextEditingController();
  final _categoryDescController = TextEditingController();
  final _activityNameController = TextEditingController();
  final _activityDescController = TextEditingController();

  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _categoryDescController.dispose();
    _activityNameController.dispose();
    _activityDescController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nova Categoria',
          style: GoogleFonts.inter(
              color: context.colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome da Categoria',
                  hintText: 'Ex: Contabilidade, TI, RH',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryDescController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Descreva a área de atendimento',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _categoryNameController.clear();
              _categoryDescController.clear();
              Navigator.pop(ctx);
            },
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: context.colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _categoryNameController.text.trim();
              final desc = _categoryDescController.text.trim();
              if (name.isEmpty) return;

              final success = await context
                  .read<CategoryProvider>()
                  .addCategory(name, desc);

              if (mounted) {
                _categoryNameController.clear();
                _categoryDescController.clear();
                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Categoria criada com sucesso!'
                        : 'Erro ao criar categoria.'),
                    backgroundColor: success ? AppTheme.success : AppTheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showAddActivityDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nova Atividade em ${category.name}',
          style: GoogleFonts.inter(
              color: context.colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _activityNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome da Atividade',
                  hintText: 'Ex: Atualização de Windows',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _activityDescController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Descreva a tarefa ou escopo',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _activityNameController.clear();
              _activityDescController.clear();
              Navigator.pop(ctx);
            },
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: context.colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _activityNameController.text.trim();
              final desc = _activityDescController.text.trim();
              if (name.isEmpty) return;

              final success = await context
                  .read<CategoryProvider>()
                  .addActivity(name, desc, category.id);

              if (mounted) {
                _activityNameController.clear();
                _activityDescController.clear();
                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Atividade criada com sucesso!'
                        : 'Erro ao criar atividade.'),
                    backgroundColor: success ? AppTheme.success : AppTheme.error,
                  ),
                );
                // Refresh list locally
                setState(() {
                  _selectedCategory = context
                      .read<CategoryProvider>()
                      .categories
                      .firstWhere((c) => c.id == category.id);
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Categorias & Atividades',
          style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: categoryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecione uma categoria para gerenciar suas atividades:',
                    style: GoogleFonts.inter(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  // Categories Row/List
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryProvider.categories.length + 1,
                      itemBuilder: (ctx, index) {
                        if (index == categoryProvider.categories.length) {
                          // Add Category Button
                          return GestureDetector(
                            onTap: _showAddCategoryDialog,
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppTheme.accentBlue.withValues(alpha: 0.3),
                                    width: 1),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded,
                                      color: AppTheme.accentBlue, size: 28),
                                  SizedBox(height: 4),
                                  Text(
                                    'Adicionar',
                                    style: TextStyle(
                                        color: AppTheme.accentBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final category = categoryProvider.categories[index];
                        final isSelected = _selectedCategory?.id == category.id;

                        return SlideInRight(
                          duration: Duration(milliseconds: 200 + index * 50),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.accentBlue
                                    : context.colors.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.05),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.accentBlue
                                              .withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${category.activities.length} atividades',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: isSelected
                                              ? Colors.white.withValues(alpha: 0.8)
                                              : context.colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (category.activities.isEmpty)
                                    Positioned(
                                      top: 8,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              backgroundColor: context.colors.surfaceCard,
                                              title: const Text('Excluir Categoria'),
                                              content: Text(
                                                  'Deseja excluir a categoria "${category.name}"?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(c, false),
                                                    child: const Text('Não')),
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(c, true),
                                                    child: const Text('Sim')),
                                              ],
                                            ),
                                          );
                                          if (confirm == true && mounted) {
                                            await context
                                                .read<CategoryProvider>()
                                                .removeCategory(category.id);
                                            setState(() {
                                              if (_selectedCategory?.id ==
                                                  category.id) {
                                                _selectedCategory = null;
                                              }
                                            });
                                          }
                                        },
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16,
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.error,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Selected Category Activities List
                  Expanded(
                    child: _selectedCategory == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.category_outlined,
                                    size: 64, color: context.colors.textMuted),
                                const SizedBox(height: 16),
                                Text(
                                  'Selecione uma categoria acima\npara gerenciar suas atividades.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                      color: context.colors.textMuted, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Atividades de ${_selectedCategory!.name}',
                                          style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedCategory!.description.isNotEmpty
                                              ? _selectedCategory!.description
                                              : 'Sem descrição cadastrada.',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: context.colors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _showAddActivityDialog(_selectedCategory!),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Atividade'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentCyan,
                                      foregroundColor: context.colors.primaryDark,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: _selectedCategory!.activities.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Nenhuma atividade cadastrada para esta categoria.',
                                          style: GoogleFonts.inter(
                                              color: context.colors.textMuted,
                                              fontSize: 13),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount:
                                            _selectedCategory!.activities.length,
                                        itemBuilder: (ctx, idx) {
                                          final activity =
                                              _selectedCategory!.activities[idx];
                                          return FadeInUp(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: context.colors.surfaceCard,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.04)),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          activity.name,
                                                          style: GoogleFonts.inter(
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                              color: Colors.white,
                                                              fontSize: 14),
                                                        ),
                                                        if (activity
                                                            .description
                                                            .isNotEmpty) ...[
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            activity.description,
                                                            style: GoogleFonts.inter(
                                                                color: context.colors.textSecondary,
                                                                fontSize: 12),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        color: AppTheme.error,
                                                        size: 20),
                                                    onPressed: () async {
                                                      final confirm =
                                                          await showDialog<bool>(
                                                        context: context,
                                                        builder: (c) =>
                                                            AlertDialog(
                                                          backgroundColor:
                                                              context.colors.surfaceCard,
                                                          title: const Text(
                                                              'Excluir Atividade'),
                                                          content: Text(
                                                              'Deseja excluir a atividade "${activity.name}"?'),
                                                          actions: [
                                                            TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        c,
                                                                        false),
                                                                child: const Text(
                                                                    'Não')),
                                                            TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        c,
                                                                        true),
                                                                child: const Text(
                                                                    'Sim')),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true &&
                                                          mounted) {
                                                        await context
                                                            .read<
                                                                CategoryProvider>()
                                                            .removeActivity(
                                                                activity.id,
                                                                _selectedCategory!
                                                                    .id);
                                                        setState(() {
                                                          _selectedCategory = context
                                                              .read<
                                                                  CategoryProvider>()
                                                              .categories
                                                              .firstWhere((c) =>
                                                                  c.id ==
                                                                  _selectedCategory!
                                                                      .id);
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
