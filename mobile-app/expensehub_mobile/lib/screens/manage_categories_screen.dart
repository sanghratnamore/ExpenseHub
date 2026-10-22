import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';

class ManageCategoriesScreen extends StatefulWidget {
  final String categoryType;

  const ManageCategoriesScreen({super.key, required this.categoryType});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final categoryService = CategoryService();
  final authService = AuthService();

  late Future<List<Category>> categoriesFuture;

  String get categoryType => widget.categoryType.toUpperCase();

  bool get isIncome => categoryType == 'INCOME';

  Color get mainColor => isIncome ? Colors.green.shade600 : Colors.red.shade600;

  Color get lightColor => isIncome ? Colors.green.shade50 : Colors.red.shade50;

  @override
  void initState() {
    super.initState();

    categoriesFuture = categoryService.getCategories();
  }

  Future<void> refreshCategories() async {
    setState(() {
      categoriesFuture = categoryService.getCategories();
    });
  }

  Future<void> deleteCategory(Category category) async {
    try {
      await categoryService.deleteCategory(categoryId: category.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: mainColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text('${category.name} deleted'),
        ),
      );

      refreshCategories();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(error.toString()),
        ),
      );
    }
  }

  Future<void> openAddCategorySheet() async {
    final nameController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isIncome
                    ? 'This will be added as an Income category'
                    : 'This will be added as an Expense category',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Category name',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter category name')),
                      );
                      return;
                    }

                    final token = await authService.getToken();
                    final userId = await authService.getUserId();

                    if (!context.mounted) return;

                    if (token == null || userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in again')),
                      );
                      return;
                    }

                    try {
                      await categoryService.createCategory(
                        name: name,
                        type: categoryType,
                        userId: int.parse(userId),
                      );

                      if (!context.mounted) return;

                      Navigator.pop(context);
                      refreshCategories();
                    } catch (error) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Save Category'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          icon: const Icon(Icons.close),
        ),
        title: Text(isIncome ? 'Income Categories' : 'Expense Categories'),
        actions: [
          GestureDetector(
            onTap: openAddCategorySheet,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 18, color: mainColor),
                  const SizedBox(width: 5),
                  Text(
                    'New',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: mainColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allCategories = snapshot.data ?? [];

          final categories = allCategories.where((category) {
            final type = category.type?.toUpperCase() ?? 'EXPENSE';

            return type == categoryType;
          }).toList();

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No categories yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: openAddCategorySheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                    style: FilledButton.styleFrom(backgroundColor: mainColor),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final category = categories[index];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: lightColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncome ? Icons.trending_up : Icons.trending_down,
                        size: 20,
                        color: mainColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Edit category will be added next.
                      },
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        deleteCategory(category);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
