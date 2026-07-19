import 'package:flutter/material.dart';

class StudentEntryProvider extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();

  // Sample suggestion list for the name Autocomplete.
  // Replace with your own dynamic/maintained list of names.
  final List<String> nameSuggestions = <String>[
    'Aarav Sharma',
    'Aditi Nair',
    'Arjun Menon',
    'Diya Pillai',
    'Ishaan Kumar',
    'Meera Iyer',
    'Rohan Varma',
    'Sneha Krishnan',
  ];

  // Sample dropdown options — replace with your real data.
  final List<String> categoryOptions = <String>[
    'Undergraduate',
    'Postgraduate',
    'Diploma',
    'Certificate',
  ];

  final List<String> programOptions = <String>[
    'Computer Science',
    'Mechanical',
    'Electrical',
    'Civil',
  ];

  String? selectedCategory;
  String? selectedProgram;

  // The list of entries added so far (in case you want to show/use it elsewhere).
  final List<Map<String, String>> entries = <Map<String, String>>[];

  void setName(String value) {
    nameController.text = value;
    // No notifyListeners needed here; TextEditingController notifies itself.
  }

  void setCategory(String? value) {
    selectedCategory = value;
    notifyListeners();
  }

  void setProgram(String? value) {
    selectedProgram = value;
    notifyListeners();
  }

  /// Returns an error message if invalid, or null if the entry was added.
  String? addToList() {
    final name = nameController.text.trim();

    if (name.isEmpty || selectedCategory == null || selectedProgram == null) {
      return 'Please fill in all fields';
    }

    entries.add({
      'name': name,
      'category': selectedCategory!,
      'program': selectedProgram!,
    });

    // Reset the form after adding.
    nameController.clear();
    selectedCategory = null;
    selectedProgram = null;
    notifyListeners();
    return null;
  }

  int expandedIndex = -1;

  void toggleExpand(int index) {
    if (expandedIndex == index) {
      expandedIndex = -1;
    } else {
      expandedIndex = index;
    }
    notifyListeners();
  }

  bool isExpanded(int index) => expandedIndex == index;
  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}