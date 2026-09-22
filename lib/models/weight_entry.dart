class WeightEntry {
  final String id;
  final DateTime date;
  final double weightKg;
  final String? note;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'note': note,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70.0,
      note: map['note'] as String?,
    );
  }
}
