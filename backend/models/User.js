// This is like a blueprint for what a user looks like

const users = []; // Temporary storage - like a notebook

class User {
  constructor(id, name, email, password, role) {
    this.id = id;
    this.name = name;
    this.email = email;
    this.password = password;
    this.role = role; // 'student' or 'host'
    this.createdAt = new Date();
  }

  // Find user by email
  static findByEmail(email) {
    return users.find(u => u.email === email);
  }

  // Find user by ID
  static findById(id) {
    return users.find(u => u.id === id);
  }

  // Create new user
  static create(userData) {
    const user = new User(
      Date.now().toString(), // Generate unique ID
      userData.name,
      userData.email,
      userData.password,
      userData.role || 'student'
    );
    users.push(user); // Add to our list
    return user;
  }

  // Get all users
  static getAll() {
    return users;
  }
}

module.exports = User;