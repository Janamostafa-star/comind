// User storage
const users = [];
const sessions = [];
const studentStats = [];
const hostStats = []; // New: Track host statistics
const studySessions = []; // New: Track scheduled study sessions
const notes = []; // New: Track user notes
const meetings = []; // New: Track scheduled meetings
const conversations = []; // New: Track chat conversations
const generateId = () => Date.now().toString() + Math.random().toString(36).substring(2, 9);

class Note {
  static create(userId, data) {
    const note = {
      id: generateId(),
      userId,
      title: data.title || 'Untitled Note',
      content: data.content,
      slideNumber: data.slideNumber || 0,
      timestamp: new Date(),
      color: data.color || 0xFFFFFFFF
    };
    notes.push(note);
    return note;
  }

  static findByUserId(userId) {
    return notes.filter(n => n.userId === userId);
  }

  static update(id, data) {
    const note = notes.find(n => n.id === id);
    if (note) {
      if (data.title !== undefined) note.title = data.title;
      if (data.content !== undefined) note.content = data.content;
      if (data.slideNumber !== undefined) note.slideNumber = data.slideNumber;
      if (data.color !== undefined) note.color = data.color;
      note.updatedAt = new Date();
      return note;
    }
    return null;
  }

  static delete(id) {
    const index = notes.findIndex(n => n.id === id);
    if (index !== -1) {
      notes.splice(index, 1);
      return true;
    }
    return false;
  }
}

class ScheduledMeeting {
  static create(userId, data) {
    const meeting = {
      id: generateId(),
      userId,
      title: data.title,
      hostName: data.hostName || 'User',
      meetingId: data.meetingId || Math.random().toString(36).substring(7),
      startTime: new Date(data.startTime),
      endTime: new Date(data.endTime),
      participants: data.participants || ['You', 'AI Tutor'],
      aiRole: data.aiRole || 'tutor',
      durationMinutes: data.durationMinutes || 60
    };
    meetings.push(meeting);
    return meeting;
  }

  static findByUserId(userId) {
    return meetings.filter(m => m.userId === userId);
  }

  static delete(id) {
    const index = meetings.findIndex(m => m.id === id);
    if (index !== -1) {
      meetings.splice(index, 1);
      return true;
    }
    return false;
  }
}

class Chat {
  static create(userId, data) {
    const conv = {
      id: generateId(),
      userId,
      name: data.name,
      lastMessage: data.lastMessage || '',
      lastMessageTime: new Date(),
      unreadCount: data.unreadCount || 0,
      isOnline: data.isOnline !== undefined ? data.isOnline : true,
      avatarUrl: data.avatarUrl || null,
      isAi: data.isAi !== undefined ? data.isAi : false
    };
    conversations.push(conv);
    return conv;
  }

  static findByUserId(userId) {
    return conversations.filter(c => c.userId === userId);
  }

  static delete(id) {
    const index = conversations.findIndex(c => c.id === id);
    if (index !== -1) {
      conversations.splice(index, 1);
      return true;
    }
    return false;
  }
}

class ScheduledSession {
  constructor(id, userId, title, startTime, duration, aiMode) {
    this.id = id;
    this.userId = userId;
    this.title = title;
    this.startTime = new Date(startTime);
    this.duration = duration; // in minutes
    this.aiMode = aiMode;
    this.createdAt = new Date();
    this.status = 'scheduled'; // scheduled, active, completed, cancelled
  }

  static create(data) {
    const session = new ScheduledSession(
      generateId(),
      data.userId,
      data.title,
      data.startTime,
      data.duration,
      data.aiMode
    );
    studySessions.push(session);
    return session;
  }

  static findByUserId(userId) {
    // Filter out canceled or past sessions if needed, but for now return all future/recent
    return studySessions.filter(s => s.userId === userId);
  }

  static delete(id) {
    const index = studySessions.findIndex(s => s.id === id);
    if (index !== -1) {
      studySessions.splice(index, 1);
      return true;
    }
    return false;
  }
}

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
      generateId(),
      userData.name,
      userData.email,
      userData.password,
      userData.role || 'student'
    );
    users.push(user);

    // Initialize stats based on role
    if (user.role === 'student') {
      StudentStats.create(user.id);
    } else if (user.role === 'host') {
      HostStats.create(user.id);
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
      console.log(`Updating profile for user ${userId}:`, Object.keys(updates));
      if (updates.name) user.name = updates.name;
      if (updates.bio) user.bio = updates.bio;
      if (updates.profilePicture) {
        console.log(`  Updating profilePicture (length: ${updates.profilePicture.length})`);
        user.profilePicture = updates.profilePicture;
      }
    } else {
      console.log(`Attempted to update non-existent user ${userId}`);
    }
    return user;
  }

  static getAll() {
    return users;
  }

  static getAllStudents() {
    return users.filter(u => u.role === 'student');
  }

  static getAllHosts() {
    return users.filter(u => u.role === 'host');
  }
}

// Session management
class Session {
  static create(userId, token) {
    const session = {
      userId,
      token,
      createdAt: new Date(),
      dailyHistory: {}, // { 'YYYY-MM-DD': minutes }
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
      totalStudyTime: 0,
      meetingsJoined: 0,
      questionsAsked: 0,
      quizzesTaken: 0,
      averageQuizScore: 0,
      focusScore: 0,
      lastActive: new Date(),
      createdAt: new Date(),
      dailyHistory: {}, // { 'YYYY-MM-DD': minutes }
      forest: {
        treesPlanted: 0,
        seeds: 0,
        totalFocusMinutes: 0,
        recentGrowth: []
      },
      sessionsCompleted: 0,
      streakDays: 0,
      subjectBreakdown: {} // { subject: minutes }
    };
    studentStats.push(stats);
    return stats;
  }

  static findByStudentId(studentId) {
    return studentStats.find(s => s.studentId === studentId);
  }

  static updateStudyTime(studentId, minutes, subject = 'General') {
    const stats = studentStats.find(s => s.studentId === studentId);
    if (stats) {
      stats.totalStudyTime += minutes;
      stats.lastActive = new Date();

      const today = new Date().toISOString().split('T')[0];
      stats.dailyHistory[today] = (stats.dailyHistory[today] || 0) + minutes;

      // Update subject breakdown
      const subjectName = subject || 'General';
      stats.subjectBreakdown[subjectName] = (stats.subjectBreakdown[subjectName] || 0) + minutes;

      // Update streak
      this.calculateStreak(stats);
    }
    return stats;
  }

  static calculateStreak(stats) {
    const dates = Object.keys(stats.dailyHistory).sort((a, b) => b.localeCompare(a));
    if (dates.length === 0) {
      stats.streakDays = 0;
      return;
    }

    let streak = 0;
    const today = new Date().toISOString().split('T')[0];
    const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];

    // If not active today or yesterday, streak is broken
    if (dates[0] !== today && dates[0] !== yesterday) {
      stats.streakDays = 0;
      return;
    }

    let currentDate = new Date(dates[0]);
    for (let i = 0; i < dates.length; i++) {
      const dateStr = dates[i];
      const date = new Date(dateStr);

      // Check if this date is consecutive
      const expectedDate = new Date(currentDate);
      expectedDate.setDate(currentDate.getDate() - i);
      const expectedStr = expectedDate.toISOString().split('T')[0];

      if (dateStr === expectedStr) {
        streak++;
      } else {
        break;
      }
    }
    stats.streakDays = streak;
  }

  static incrementSessions(studentId) {
    const stats = studentStats.find(s => s.studentId === studentId);
    if (stats) {
      stats.sessionsCompleted += 1;
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
      stats.averageQuizScore =
        ((stats.averageQuizScore * (stats.quizzesTaken - 1)) + score) / stats.quizzesTaken;
    }
    return stats;
  }
}

// Host Statistics
class HostStats {
  static create(hostId) {
    const stats = {
      hostId,
      totalMeetingsCreated: 0,
      totalParticipants: 0,
      totalMeetingTime: 0, // in minutes
      averageParticipantsPerMeeting: 0,
      activeMeetings: 0,
      lastActive: new Date(),
      createdAt: new Date()
    };
    hostStats.push(stats);
    return stats;
  }

  static findByHostId(hostId) {
    return hostStats.find(s => s.hostId === hostId);
  }

  static incrementMeetings(hostId) {
    const stats = hostStats.find(s => s.hostId === hostId);
    if (stats) {
      stats.totalMeetingsCreated += 1;
      stats.lastActive = new Date();
    }
    return stats;
  }

  static addParticipants(hostId, count) {
    const stats = hostStats.find(s => s.hostId === hostId);
    if (stats) {
      stats.totalParticipants += count;
      // Recalculate average
      if (stats.totalMeetingsCreated > 0) {
        stats.averageParticipantsPerMeeting =
          stats.totalParticipants / stats.totalMeetingsCreated;
      }
    }
    return stats;
  }

  static addMeetingTime(hostId, minutes) {
    const stats = hostStats.find(s => s.hostId === hostId);
    if (stats) {
      stats.totalMeetingTime += minutes;
    }
    return stats;
  }

  static updateActiveMeetings(hostId, count) {
    const stats = hostStats.find(s => s.hostId === hostId);
    if (stats) {
      stats.activeMeetings = count;
    }
    return stats;
  }
}

module.exports = { User, Session, StudentStats, HostStats, ScheduledSession, Note, ScheduledMeeting, Chat };