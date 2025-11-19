import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/admin_guard.dart';
import '../../../providers/category_provider.dart';
import '../../../data/models/category_model.dart';

class CategoryManagement extends StatefulWidget {
  const CategoryManagement({super.key});

  @override
  State<CategoryManagement> createState() => _CategoryManagementState();
}

class _CategoryManagementState extends State<CategoryManagement> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    await categoryProvider.fetchCategories();
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedIcon = 'book';
    String selectedColor = '#6C63FF';

    final List<Map<String, dynamic>> iconOptions = [
      {'name': 'book', 'icon': Icons.book},
      {'name': 'psychology', 'icon': Icons.psychology},
      {'name': 'business', 'icon': Icons.business},
      {'name': 'science', 'icon': Icons.science},
      {'name': 'computer', 'icon': Icons.computer},
      {'name': 'music_note', 'icon': Icons.music_note},
      {'name': 'palette', 'icon': Icons.palette},
      {'name': 'school', 'icon': Icons.school},
    ];

    final List<Map<String, String>> colorOptions = [
      {'name': 'Tím', 'value': '#6C63FF'},
      {'name': 'Xanh dương', 'value': '#4285F4'},
      {'name': 'Xanh lá', 'value': '#34A853'},
      {'name': 'Cam', 'value': '#FBBC05'},
      {'name': 'Đỏ', 'value': '#EA4335'},
      {'name': 'Hồng', 'value': '#FF6B9D'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm thể loại mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên thể loại',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chọn icon:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: iconOptions.map((option) {
                    final isSelected = selectedIcon == option['name'];
                    return ChoiceChip(
                      label: Icon(option['icon'] as IconData),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedIcon = option['name'] as String;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chọn màu:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colorOptions.map((option) {
                    final isSelected = selectedColor == option['value'];
                    return ChoiceChip(
                      label: Container(
                        width: 40,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(
                                  option['value']!.substring(1),
                                  radix: 16,
                                ) +
                                0xFF000000,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedColor = option['value']!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên thể loại')),
                  );
                  return;
                }

                final categoryProvider = Provider.of<CategoryProvider>(
                  context,
                  listen: false,
                );
                final success = await categoryProvider.createCategory(
                  name: nameController.text,
                  description: descriptionController.text,
                  iconName: selectedIcon,
                  color: selectedColor,
                );

                if (!mounted) return;
                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm thể loại thành công')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(categoryProvider.error ?? 'Có lỗi xảy ra'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(
      text: category.description,
    );
    String selectedIcon = category.iconName;
    String selectedColor = category.color;

    final List<Map<String, dynamic>> iconOptions = [
      {'name': 'book', 'icon': Icons.book},
      {'name': 'psychology', 'icon': Icons.psychology},
      {'name': 'business', 'icon': Icons.business},
      {'name': 'science', 'icon': Icons.science},
      {'name': 'computer', 'icon': Icons.computer},
      {'name': 'music_note', 'icon': Icons.music_note},
      {'name': 'palette', 'icon': Icons.palette},
      {'name': 'school', 'icon': Icons.school},
    ];

    final List<Map<String, String>> colorOptions = [
      {'name': 'Tím', 'value': '#6C63FF'},
      {'name': 'Xanh dương', 'value': '#4285F4'},
      {'name': 'Xanh lá', 'value': '#34A853'},
      {'name': 'Cam', 'value': '#FBBC05'},
      {'name': 'Đỏ', 'value': '#EA4335'},
      {'name': 'Hồng', 'value': '#FF6B9D'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa thể loại'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên thể loại',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chọn icon:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: iconOptions.map((option) {
                    final isSelected = selectedIcon == option['name'];
                    return ChoiceChip(
                      label: Icon(option['icon'] as IconData),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedIcon = option['name'] as String;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chọn màu:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colorOptions.map((option) {
                    final isSelected = selectedColor == option['value'];
                    return ChoiceChip(
                      label: Container(
                        width: 40,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(
                                  option['value']!.substring(1),
                                  radix: 16,
                                ) +
                                0xFF000000,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedColor = option['value']!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final categoryProvider = Provider.of<CategoryProvider>(
                  context,
                  listen: false,
                );
                final success = await categoryProvider.updateCategory(
                  id: category.id,
                  name: nameController.text,
                  description: descriptionController.text,
                  iconName: selectedIcon,
                  color: selectedColor,
                );

                if (!mounted) return;
                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật thành công')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(categoryProvider.error ?? 'Có lỗi xảy ra'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa thể loại "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final categoryProvider = Provider.of<CategoryProvider>(
                context,
                listen: false,
              );
              final success = await categoryProvider.deleteCategory(
                category.id,
              );

              if (!mounted) return;
              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(categoryProvider.error ?? 'Có lỗi xảy ra'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'psychology':
        return Icons.psychology;
      case 'business':
        return Icons.business;
      case 'science':
        return Icons.science;
      case 'computer':
        return Icons.computer;
      case 'music_note':
        return Icons.music_note;
      case 'palette':
        return Icons.palette;
      case 'school':
        return Icons.school;
      default:
        return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý thể loại'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCategories,
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm thể loại...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadCategories();
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    _loadCategories();
                  } else {
                    Provider.of<CategoryProvider>(
                      context,
                      listen: false,
                    ).searchCategories(value);
                  }
                },
              ),
            ),

            // Categories list
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  if (categoryProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (categoryProvider.categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có thể loại nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categoryProvider.categories.length,
                    itemBuilder: (context, index) {
                      final category = categoryProvider.categories[index];
                      final categoryColor = Color(
                        int.parse(category.color.substring(1), radix: 16) +
                            0xFF000000,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconFromName(category.iconName),
                              color: categoryColor,
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.description),
                              const SizedBox(height: 4),
                              Text(
                                '${category.bookCount} cuốn sách',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showEditCategoryDialog(category),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _showDeleteConfirmDialog(category),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddCategoryDialog,
          icon: const Icon(Icons.add),
          label: const Text('Thêm thể loại'),
        ),
      ),
    );
  }
}
