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
    'NAME': name,
    'CLASS': studentClass,
    'DIVISION': division,
    'GENDER': gender,
    'ROLL_NUMBER': rollNumber,
  };

  factory StudentRow.fromMap(Map<String, dynamic> map) => StudentRow(
    name: map['NAME']?.toString() ?? '',
    studentClass: map['CLASS']?.toString() ?? '',
    division: map['DIVISION']?.toString() ?? '',
    gender: map['GENDER']?.toString() ?? '',
    rollNumber: map['ROLL_NUMBER']?.toString() ?? '',
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