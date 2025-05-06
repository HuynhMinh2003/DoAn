
class CompanyInfo {
  final String? companyId; // optional, nếu lấy từ Firestore thì có
  final String nameCompany;
  final String emailCompany;
  final String phoneCompany;
  final String typeCompany;
  final String describeCompany;

  CompanyInfo({
    this.companyId,
    required this.nameCompany,
    required this.emailCompany,
    required this.phoneCompany,
    required this.typeCompany,
    required this.describeCompany,
  });

  // Tạo từ Firestore, có docId
  factory CompanyInfo.fromMap(Map<String, dynamic> map, [String? docId]) {
    return CompanyInfo(
      companyId: docId,
      nameCompany: map['nameCompany'] ?? '',
      emailCompany: map['emailCompany'] ?? '',
      phoneCompany: map['phoneCompany'] ?? '',
      typeCompany: map['typeCompany'] ?? '',
      describeCompany: map['describeCompany'] ?? '',
    );
  }

  // Convert thành Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'nameCompany': nameCompany,
      'emailCompany': emailCompany,
      'phoneCompany': phoneCompany,
      'typeCompany': typeCompany,
      'describeCompany': describeCompany,
    };
  }

  // Tạo bản sao với các giá trị mới
  CompanyInfo copyWith({
    String? companyId,
    String? nameCompany,
    String? emailCompany,
    String? phoneCompany,
    String? typeCompany,
    String? describeCompany,
  }) {
    return CompanyInfo(
      companyId: companyId ?? this.companyId,
      nameCompany: nameCompany ?? this.nameCompany,
      emailCompany: emailCompany ?? this.emailCompany,
      phoneCompany: phoneCompany ?? this.phoneCompany,
      typeCompany: typeCompany ?? this.typeCompany,
      describeCompany: describeCompany ?? this.describeCompany,
    );
  }
}
