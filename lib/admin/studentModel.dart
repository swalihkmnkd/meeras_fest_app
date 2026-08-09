class StudentRow {
  final String name;
  final String studentClass;
  final String division;
  final String gender;
  final String rollNumber;

  StudentRow({
    required this.name,
    required this.studentClass,
    this.division = '',
    required this.gender,
    required this.rollNumber,
  });

  // Gender is always uppercased here so whatever casing the UI (dropdown,
  // Excel sheet, etc.) sends in, Firestore always ends up storing
  // 'MALE' / 'FEMALE' / 'OTHER' consistently.
  Map<String, dynamic> toMap() => {
    'name': name,
    'class': studentClass,
    'division': division,
    'gender': gender.toUpperCase(),
    'rollNumber': rollNumber,
  };

  factory StudentRow.fromMap(Map<String, dynamic> map) => StudentRow(
    name: map['name']?.toString() ?? '',
    studentClass: map['class']?.toString() ?? '',
    division: map['division']?.toString() ?? '',
    gender: map['gender']?.toString() ?? '',
    rollNumber: map['rollNumber']?.toString() ?? '',
  );

  StudentRow copyWith({
    String? name,
    String? studentClass,
    String? division,
    String? gender,
    String? rollNumber,
  }) {
    return StudentRow(
      name: name ?? this.name,
      studentClass: studentClass ?? this.studentClass,
      division: division ?? this.division,
      gender: gender ?? this.gender,
      rollNumber: rollNumber ?? this.rollNumber,
    );
  }
}