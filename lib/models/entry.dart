class Entry {
  int? id;
  int userId;
  String clockIn;
  String? clockOut;

  Entry({
    this.id,
    required this.userId,
    required this.clockIn,
    this.clockOut,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'clockIn': clockIn,
      'clockOut': clockOut
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      userId: map['userId'],
      clockIn: map['clockIn'],
      clockOut: map['clockOut'],
    );
  }
}