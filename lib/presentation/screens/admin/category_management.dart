import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/admin_guard.dart';
import '../../../core/constants/app_colors.dart';
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
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Thêm thể loại mới',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Name
                        TextField(
                          controller: nameController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Tên thể loại',
                            hintText: 'Nhập tên thể loại',
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Description
                        TextField(
                          controller: descriptionController,
                          style: const TextStyle(fontSize: 16),
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Mô tả',
                            hintText: 'Nhập mô tả thể loại',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(Icons.description),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Icon Selection
                        const Text(
                          'Chọn icon:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: iconOptions.length,
                            itemBuilder: (context, index) {
                              final option = iconOptions[index];
                              final isSelected = selectedIcon == option['name'];
                              final iconColor = Color(
                                int.parse(
                                      selectedColor.substring(1),
                                      radix: 16,
                                    ) +
                                    0xFF000000,
                              );
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIcon = option['name'] as String;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? iconColor.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? iconColor
                                          : AppColors.gray300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Icon(
                                          option['icon'] as IconData,
                                          color: isSelected
                                              ? iconColor
                                              : AppColors.textSecondary,
                                          size: 28,
                                        ),
                                      ),
                                      if (isSelected)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: iconColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Color Selection
                        const Text(
                          'Chọn màu:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: colorOptions.length,
                            itemBuilder: (context, index) {
                              final option = colorOptions[index];
                              final isSelected =
                                  selectedColor == option['value'];
                              final color = Color(
                                int.parse(
                                      option['value']!.substring(1),
                                      radix: 16,
                                    ) +
                                    0xFF000000,
                              );
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = option['value']!;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: isSelected ? 3 : 0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(color: AppColors.gray200, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: AppColors.gray300),
                          ),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng nhập tên thể loại'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            final categoryProvider =
                                Provider.of<CategoryProvider>(
                                  context,
                                  listen: false,
                                );
                            final success = await categoryProvider
                                .createCategory(
                                  name: nameController.text,
                                  description: descriptionController.text,
                                  iconName: selectedIcon,
                                  color: selectedColor,
                                );

                            if (!mounted) return;
                            Navigator.pop(context);

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thêm thể loại thành công'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    categoryProvider.error ?? 'Có lỗi xảy ra',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Thêm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Chỉnh sửa thể loại',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Name
                        TextField(
                          controller: nameController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Tên thể loại',
                            hintText: 'Nhập tên thể loại',
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Description
                        TextField(
                          controller: descriptionController,
                          style: const TextStyle(fontSize: 16),
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Mô tả',
                            hintText: 'Nhập mô tả thể loại',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(Icons.description),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Icon Selection
                        const Text(
                          'Chọn icon:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: iconOptions.length,
                            itemBuilder: (context, index) {
                              final option = iconOptions[index];
                              final isSelected = selectedIcon == option['name'];
                              final iconColor = Color(
                                int.parse(
                                      selectedColor.substring(1),
                                      radix: 16,
                                    ) +
                                    0xFF000000,
                              );
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIcon = option['name'] as String;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? iconColor.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? iconColor
                                          : AppColors.gray300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Icon(
                                          option['icon'] as IconData,
                                          color: isSelected
                                              ? iconColor
                                              : AppColors.textSecondary,
                                          size: 28,
                                        ),
                                      ),
                                      if (isSelected)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: iconColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Color Selection
                        const Text(
                          'Chọn màu:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: colorOptions.length,
                            itemBuilder: (context, index) {
                              final option = colorOptions[index];
                              final isSelected =
                                  selectedColor == option['value'];
                              final color = Color(
                                int.parse(
                                      option['value']!.substring(1),
                                      radix: 16,
                                    ) +
                                    0xFF000000,
                              );
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = option['value']!;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: isSelected ? 3 : 0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(color: AppColors.gray200, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: AppColors.gray300),
                          ),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final categoryProvider =
                                Provider.of<CategoryProvider>(
                                  context,
                                  listen: false,
                                );
                            final success = await categoryProvider
                                .updateCategory(
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
                                const SnackBar(
                                  content: Text('Cập nhật thành công'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    categoryProvider.error ?? 'Có lỗi xảy ra',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Cập nhật',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(CategoryModel category) {
    final categoryColor = Color(
      int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
    );

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Xác nhận xóa',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bạn có chắc muốn xóa thể loại "${category.name}"?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Category preview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: categoryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconFromName(category.iconName),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${category.bookCount} cuốn sách',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(color: AppColors.gray200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: AppColors.gray300),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final categoryProvider =
                              Provider.of<CategoryProvider>(
                                context,
                                listen: false,
                              );
                          final success = await categoryProvider.deleteCategory(
                            category.id,
                          );

                          if (!mounted) return;
                          Navigator.pop(context);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Xóa thành công'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  categoryProvider.error ?? 'Có lỗi xảy ra',
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AdminGuard(
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Quản lý thể loại',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: _loadCategories,
                tooltip: 'Làm mới',
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar with modern design
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm thể loại...',
                  hintStyle: TextStyle(color: AppColors.gray400, fontSize: 16),
                  prefixIcon: Icon(Icons.search, color: AppColors.gray400),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.gray400),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                            _loadCategories();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
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
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (categoryProvider.categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Chưa có thể loại nào',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhấn nút "Thêm thể loại" để bắt đầu',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categoryProvider.categories.length,
                    itemBuilder: (context, index) {
                      final category = categoryProvider.categories[index];
                      final categoryColor = Color(
                        int.parse(category.color.substring(1), radix: 16) +
                            0xFF000000,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showEditCategoryDialog(category),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  // Icon container
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          categoryColor,
                                          categoryColor.withOpacity(0.7),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: categoryColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getIconFromName(category.iconName),
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Category info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          category.description.isEmpty
                                              ? 'Không có mô tả'
                                              : category.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.book_outlined,
                                              size: 14,
                                              color: AppColors.gray500,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                '${category.bookCount} cuốn sách',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.gray500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Action buttons
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.info.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: AppColors.info,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _showEditCategoryDialog(category),
                                          tooltip: 'Chỉnh sửa',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _showDeleteConfirmDialog(
                                                category,
                                              ),
                                          tooltip: 'Xóa',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
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
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Thêm thể loại',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
