// User storage
const users = [];
const sessions = [];
const studentStats = []; // New: Track student statistics

class User {
  constructor(id, name, email, password, role) {
    this.id = id;
    this.name = name;
    this.email = email;
    this.password = password;
    this.role = role;
    this.createdAt = new Date();
    this.lastLogin = null;
    this.profilePicture = null;
    this.bio = null;
  }

  static findByEmail(email) {
    return users.find(u => u.email === email);
  }

  static findById(id) {
    return users.find(u => u.id === id);
  }

  static create(userData) {
    const user = new User(
      Date.now().toString(),
      userData.name,
      userData.email,
      userData.password,
      userData.role || 'student'
    );
    users.push(user);
    
    // Initialize student stats if student
    if (user.role === 'student') {
      StudentStats.create(user.id);
    }
    
    return user;
  }

  static updateLastLogin(userId) {
    const user = users.find(u => u.id === userId);
    if (user) {
      user.lastLogin = new Date();
    }
    return user;
  }

  static updateProfile(userId, updates) {
    const user = users.find(u => u.id === userId);
    if (user) {
      if (updates.name) user.name = updates.name;
      if (updates.bio) user.bio = updates.bio;
      if (updates.profilePicture) user.profilePicture = updates.profilePicture;
    }
    return user;
  }

  static getAll() {
    return users;
  }

  static getAllStudents() {
    return users.filter(u => u.role === 'student');
  }
}

// Session management
class Session {
  static create(userId, token) {
    const session = {
      userId,
      token,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000)
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

  static cleanExpired() {
    const now = new Date();
    const validSessions = sessions.filter(s => s.expiresAt > now);
    sessions.length = 0;
    sessions.push(...validSessions);
  }
}

// Student Statistics
class StudentStats {
  static create(studentId) {
    const stats = {
      studentId,
      totalStudyTime: 0, // in minutes
      meetingsJoined: 0,
      questionsAsked: 0,
      quizzesTaken: 0,
      averageQuizScore: 0,
      focusScore: 0, // 0-100
      lastActive: new Date(),
      createdAt: new Date()
    };
    studentStats.push(stats);
    return stats;
  }

  static findByStudentId(studentId) {
    return studentStats.find(s => s.studentId === studentId);
  }

  static updateStudyTime(studentId, minutes) {
    const stats = studentStats.find(s => s.studentId === studentId);
    if (stats) {
      stats.totalStudyTime += minutes;
      stats.lastActive = new Date();
    }
    return stats;
  }

  static incrementMeetings(studentId) {
    const stats = studentStats.find(s => s.studentId === studentId);
    if (stats) {
      stats.meetingsJoined += 1;
    }
    return stats;
  }

  static updateQuizStats(studentId, score) {
    const stats = studentStats.find(s => s.studentId === studentId);
    if (stats) {
      stats.quizzesTaken += 1;
      // Calculate new average
      stats.averageQuizScore = 
        ((stats.averageQuizScore * (stats.quizzesTaken - 1)) + score) / stats.quizzesTaken;
    }
    return stats;
  }
}

module.exports = { User, Session, StudentStats };