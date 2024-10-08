class User {
  final String id;
  final String username;
  final String email;
  final double? rating;
  final List<String>? responses;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.rating,
    this.responses,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'rating': rating,
      'responses': responses ?? [],
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      rating: map['rating']?.toDouble(),
      responses: List<String>.from(map['responses'] ?? []),
    );
  }
}
