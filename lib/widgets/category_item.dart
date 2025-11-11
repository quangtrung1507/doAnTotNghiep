import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CategoryItem extends StatelessWidget {
  final String name;
  final String iconPath;

  const CategoryItem({
    Key? key,
    required this.name,
    required this.iconPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.card,
          child: Image.asset(iconPath, width: 30, height: 30),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 12, color: AppColors.textDark),
        ),
      ],
    );
  }
}
