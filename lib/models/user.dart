class User {
  final int? id; // Nullable for new users not yet in DB
  final String username;
  final String password; // In a real app, NEVER store plain text passwords. Hash them!
  final String? programId; // Add programId field to associate user with a program

  User({
    this.id, 
    required this.username, 
    required this.password,
    this.programId, // Make it optional
  });

  // Convert a User into a Map. Keys must correspond to names of columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password, // Again, HASH THIS before storing
      'program_id': programId, // Add program_id to map
    };
  }

  // Extract a User object from a Map object.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'], // Be careful retrieving this
      programId: map['program_id'], // Extract program_id from map
    );
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username}'; // Avoid printing password
  }
} 