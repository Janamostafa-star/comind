// This is like a blueprint for what a user looks like

const users = []; // Temporary storage
const sessions = []; // Track active sessions

class User {
  constructor(id, name, email, password, role) {
    this.id = id;
    this.name = name;
    this.email = email;
    this.password = password;
    this.role = role; // 'student' or 'host'
    this.createdAt = new Date();
    this.lastLogin = null;
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
      Date.now().toString(),
      userData.name,
      userData.email,
      userData.password,
      userData.role || 'student'
    );
    users.push(user);
    return user;
  }

  // Update last login time
  static updateLastLogin(userId) {
    const user = users.find(u => u.id === userId);
    if (user) {
      user.lastLogin = new Date();
    }
    return user;
  }

  // Get all users
  static getAll() {
    return users;
  }
}

// Session management
class Session {
  static create(userId, token) {
    const session = {
      userId,
      token,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
    };
    sessions.push(session);
    return session;
  }

  static findByToken(token) {
    return sessions.find(s => s.token === token);
  }

  static deleteByUserId(userId) {
    const index = sessions.findIndex(s => s.userId === userId);
    if (index > -1) {
      sessions.splice(index, 1);
      return true;
    }
    return false;
  }

  // Clean up expired sessions
  static cleanExpired() {
    const now = new Date();
    const validSessions = sessions.filter(s => s.expiresAt > now);
    sessions.length = 0;
    sessions.push(...validSessions);
  }
}

module.exports = { User, Session };