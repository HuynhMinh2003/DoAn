class ResidentSummary {
  final String id;
  final String fullName;

  ResidentSummary({
    required this.id,
    required this.fullName,
  });

  factory ResidentSummary.fromJson(Map<String, dynamic> json) {
    return ResidentSummary(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
    };
  }
}