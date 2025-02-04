class User {
  int? id;
  String name;

  User({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory User.fromMap(Map<String, dynamic> map){
    return User(
      id: map['id'],
      name: map['name'],
    );
  }
}