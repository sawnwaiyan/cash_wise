import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class Categories {
  static const List<Category> all = [
    Category(id: 1,  name: 'Food',                icon: Icons.bento,                    color: Color(0xFFFF8A65)),
    Category(id: 2,  name: 'Cigarette',           icon: Icons.smoking_rooms,            color: Color(0xFF90A4AE)),
    Category(id: 3,  name: 'Alcohol',             icon: Icons.local_bar,                color: Color(0xFFCE93D8)),
    Category(id: 4,  name: 'Household Items',     icon: Icons.soap,                     color: Color(0xFF80DEEA)),
    Category(id: 5,  name: 'Weekend Outing',      icon: Icons.celebration,              color: Color(0xFFF48FB1)),
    Category(id: 6,  name: 'Bills',               icon: Icons.receipt_long,             color: Color(0xFFFFCC02)),
    Category(id: 7,  name: 'Transportation',      icon: Icons.train,                    color: Color(0xFF81C784)),
    Category(id: 8,  name: 'Girl Bar',            icon: Icons.nightlife,                color: Color(0xFFFF80AB)),
    Category(id: 9,  name: 'Clothes',             icon: Icons.checkroom,                color: Color(0xFF80CBC4)),
    Category(id: 10, name: 'Myanmar Food',        icon: Icons.rice_bowl,                color: Color(0xFFFFB74D)),
    Category(id: 11, name: 'Cosmetics',           icon: Icons.face_retouching_natural,  color: Color(0xFFF06292)),
    Category(id: 12, name: 'Computer Accessories',icon: Icons.computer,                 color: Color(0xFF64B5F6)),
    Category(id: 13, name: 'Rice',                icon: Icons.grass,                    color: Color(0xFFA5D6A7)),
    Category(id: 14, name: 'Others',              icon: Icons.category,                 color: Color(0xFFBCAAA4)),
  ];

  static Category byId(int id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.last);
}