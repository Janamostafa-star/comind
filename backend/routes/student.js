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

// ========== GET STUDENT MEETINGS (Placeholder) ==========
router.get('/meetings', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);
    
    if (!user || user.role !== 'student') {
      return res.status(403).json({ error: 'Access denied. Students only.' });
    }

    // This will be implemented when meeting system is ready
    res.json({
      success: true,
      meetings: [],
      message: 'Meeting history will be available when meeting system is implemented'
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;