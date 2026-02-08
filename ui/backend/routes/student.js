const express = require('express');
const { verifyToken } = require('../middleware/auth');
const { User, StudentStats } = require('../models/User');

const router = express.Router();

// ========== GET STUDENT DASHBOARD ==========
router.get('/dashboard', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.role !== 'student') {
      return res.status(403).json({ error: 'Access denied. Students only.' });
    }

    const stats = StudentStats.findByStudentId(req.userId);

    res.json({
      success: true,
      dashboard: {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          bio: user.bio,
          profilePicture: user.profilePicture,
          createdAt: user.createdAt,
          lastLogin: user.lastLogin
        },
        stats: stats || {
          totalStudyTime: 0,
          meetingsJoined: 0,
          questionsAsked: 0,
          quizzesTaken: 0,
          averageQuizScore: 0,
          focusScore: 0
        }
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== GET STUDENT PROFILE ==========
router.get('/profile', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.role !== 'student') {
      return res.status(403).json({ error: 'Access denied. Students only.' });
    }

    res.json({
      success: true,
      profile: {
        id: user.id,
        name: user.name,
        email: user.email,
        bio: user.bio,
        profilePicture: user.profilePicture,
        role: user.role,
        createdAt: user.createdAt,
        lastLogin: user.lastLogin
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== UPDATE STUDENT PROFILE ==========
router.put('/profile', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.role !== 'student') {
      return res.status(403).json({ error: 'Access denied. Students only.' });
    }

    const { name, bio, profilePicture } = req.body;

    const updatedUser = User.updateProfile(req.userId, {
      name,
      bio,
      profilePicture
    });

    res.json({
      success: true,
      message: 'Profile updated successfully',
      profile: {
        id: updatedUser.id,
        name: updatedUser.name,
        email: updatedUser.email,
        bio: updatedUser.bio,
        profilePicture: updatedUser.profilePicture
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== GET STUDENT STATS ==========
router.get('/stats', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);

    if (!user || user.role !== 'student') {
      return res.status(403).json({ error: 'Access denied. Students only.' });
    }

    const stats = StudentStats.findByStudentId(req.userId);

    if (!stats) {
      return res.json({
        success: true,
        stats: {
          totalStudyTime: 0,
          meetingsJoined: 0,
          questionsAsked: 0,
          quizzesTaken: 0,
          averageQuizScore: 0,
          focusScore: 0,
          lastActive: new Date()
        }
      });
    }

    res.json({
      success: true,
      stats: {
        totalStudyTime: stats.totalStudyTime,
        totalStudyHours: Math.floor(stats.totalStudyTime / 60),
        meetingsJoined: stats.meetingsJoined,
        questionsAsked: stats.questionsAsked,
        quizzesTaken: stats.quizzesTaken,
        averageQuizScore: Math.round(stats.averageQuizScore),
        focusScore: stats.focusScore,
        lastActive: stats.lastActive
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== GET STUDENT SESSIONS ==========
router.get('/sessions', verifyToken, (req, res) => {
  try {
    const { ScheduledSession } = require('../models/User');
    const sessions = ScheduledSession.findByUserId(req.userId);

    // Map to frontend expected format if needed
    res.json({
      success: true,
      sessions: sessions.map(s => ({
        id: s.id,
        sessionName: s.title,
        startTime: s.startTime,
        duration: s.duration,
        aiMode: s.aiMode,
        userId: s.userId
      }))
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== CREATE SESSION ==========
router.post('/sessions', verifyToken, (req, res) => {
  try {
    const { ScheduledSession } = require('../models/User');
    const { sessionName, startTime, duration, aiMode } = req.body;

    const session = ScheduledSession.create({
      userId: req.userId,
      title: sessionName,
      startTime,
      duration,
      aiMode
    });

    res.json({
      success: true,
      message: 'Session scheduled successfully',
      session: {
        id: session.id,
        sessionName: session.title,
        startTime: session.startTime,
        duration: session.duration,
        aiMode: session.aiMode,
        userId: session.userId
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== FOREST & GARDEN ==========
router.get('/forest', verifyToken, (req, res) => {
  try {
    const { StudentStats } = require('../models/User');
    const stats = StudentStats.findByStudentId(req.userId);

    if (!stats) {
      // Should exist if user is student
      const { StudentStats } = require('../models/User');
      const newStats = StudentStats.create(req.userId);
      return res.json({ success: true, forest: newStats.forest });
    }

    // Ensure forest object exists (for old data)
    if (!stats.forest) {
      stats.forest = { treesPlanted: 0, seeds: 0, totalFocusMinutes: 0, recentGrowth: [] };
    } else if (stats.forest.totalFocusMinutes === undefined) {
      stats.forest.totalFocusMinutes = stats.totalStudyTime || 0; // Sync with legacy stat if missing
    }

    res.json({
      success: true,
      forest: stats.forest
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/forest/grow', verifyToken, (req, res) => {
  try {
    const { StudentStats } = require('../models/User');
    const { minutes, type, subject } = req.body;

    let stats = StudentStats.findByStudentId(req.userId);
    if (!stats) {
      stats = StudentStats.create(req.userId);
    }

    // Ensure forest object exists (for old data)
    if (!stats.forest) {
      stats.forest = { treesPlanted: 0, seeds: 0, totalFocusMinutes: 0, recentGrowth: [] };
    }

    // Logic replicated from frontend InMemoryForestRepository for consistency
    // 10 minutes = 1 seed
    const newlyEarnedSeeds = Math.floor(minutes / 10);
    const totalSeeds = stats.forest.seeds + newlyEarnedSeeds;

    // 5 seeds = 1 tree
    const newTrees = Math.floor(totalSeeds / 5);
    const remainingSeeds = totalSeeds % 5;

    // Update stats
    stats.forest.seeds = remainingSeeds;
    stats.forest.treesPlanted += newTrees;
    stats.forest.totalFocusMinutes += minutes;

    // Update daily history, subject breakdown, and streak via the helper
    StudentStats.updateStudyTime(req.userId, minutes, subject);

    // Increment completed sessions
    StudentStats.incrementSessions(req.userId);

    // Add growth entry
    const newGrowth = {
      id: Date.now().toString(),
      plantedDate: new Date(),
      type: newlyEarnedSeeds > 0 ? type : 'dead_shrub',
      focusMinutes: minutes
    };

    // Add to recent growth (keep last 50, plain array unshift)
    stats.forest.recentGrowth.unshift(newGrowth);
    if (stats.forest.recentGrowth.length > 50) {
      stats.forest.recentGrowth = stats.forest.recentGrowth.slice(0, 50);
    }

    res.json({
      success: true,
      forest: stats.forest,
      earned: { seeds: newlyEarnedSeeds, trees: newTrees },
      stats: {
        totalHours: Math.floor(stats.totalStudyTime / 60),
        sessionsCompleted: stats.sessionsCompleted,
        streakDays: stats.streakDays
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== NOTES ==========
router.get('/notes', verifyToken, (req, res) => {
  try {
    const { Note } = require('../models/User');
    res.json({ success: true, notes: Note.findByUserId(req.userId) });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/notes', verifyToken, (req, res) => {
  try {
    const { Note } = require('../models/User');
    const { title, content, slideNumber, color } = req.body;
    const note = Note.create(req.userId, { title, content, slideNumber, color });
    res.json({ success: true, note });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.put('/notes/:id', verifyToken, (req, res) => {
  try {
    const { Note } = require('../models/User');
    const note = Note.update(req.params.id, req.body);
    if (!note) {
      return res.status(404).json({ error: 'Note not found' });
    }
    res.json({ success: true, note });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

router.delete('/notes/:id', verifyToken, (req, res) => {
  try {
    const { Note } = require('../models/User');
    Note.delete(req.params.id);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== MEETINGS ==========
router.get('/meetings', verifyToken, (req, res) => {
  try {
    const { ScheduledMeeting } = require('../models/User');
    res.json({ success: true, meetings: ScheduledMeeting.findByUserId(req.userId) });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/meetings', verifyToken, (req, res) => {
  try {
    const { ScheduledMeeting } = require('../models/User');
    const meeting = ScheduledMeeting.create(req.userId, req.body);
    res.json({ success: true, meeting });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.delete('/meetings/:id', verifyToken, (req, res) => {
  try {
    const { ScheduledMeeting } = require('../models/User');
    ScheduledMeeting.delete(req.params.id);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== CHATS ==========
router.get('/chats', verifyToken, (req, res) => {
  try {
    const { Chat } = require('../models/User');
    res.json({ success: true, chats: Chat.findByUserId(req.userId) });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/chats', verifyToken, (req, res) => {
  try {
    const { Chat } = require('../models/User');
    const chat = Chat.create(req.userId, req.body);
    res.json({ success: true, chat });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== ANALYTICS ==========
router.get('/analytics', verifyToken, (req, res) => {
  try {
    const { StudentStats } = require('../models/User');
    const stats = StudentStats.findByStudentId(req.userId);
    if (!stats) {
      return res.json({
        success: true,
        dailyHistory: {},
        totalHours: 0,
        sessionsCompleted: 0,
        streakDays: 0,
        focusScore: 0,
        subjectBreakdown: {}
      });
    }
    res.json({
      success: true,
      dailyHistory: stats.dailyHistory || {},
      totalHours: stats.totalStudyTime ? (stats.totalStudyTime / 60) : 0,
      sessionsCompleted: stats.sessionsCompleted || 0,
      streakDays: stats.streakDays || 0,
      focusScore: stats.focusScore || 0,
      subjectBreakdown: stats.subjectBreakdown || {}
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;