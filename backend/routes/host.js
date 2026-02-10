const express = require('express');
const { verifyToken } = require('../middleware/auth');
const { User, HostStats } = require('../models/User');

const router = express.Router();

// ========== GET HOST DASHBOARD ==========
router.get('/dashboard', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.role !== 'host') {
      return res.status(403).json({ error: 'Access denied. Hosts only.' });
    }

    const stats = HostStats.findByHostId(req.userId);

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
          totalMeetingsCreated: 0,
          totalParticipants: 0,
          totalMeetingTime: 0,
          averageParticipantsPerMeeting: 0,
          activeMeetings: 0
        }
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== GET HOST PROFILE ==========
router.get('/profile', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.role !== 'host') {
      return res.status(403).json({ error: 'Access denied. Hosts only.' });
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

// ========== UPDATE HOST PROFILE ==========
router.put('/profile', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.role !== 'host') {
      return res.status(403).json({ error: 'Access denied. Hosts only.' });
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

// ========== GET HOST STATS ==========
router.get('/stats', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);
    
    if (!user || user.role !== 'host') {
      return res.status(403).json({ error: 'Access denied. Hosts only.' });
    }

    const stats = HostStats.findByHostId(req.userId);

    if (!stats) {
      return res.json({
        success: true,
        stats: {
          totalMeetingsCreated: 0,
          totalParticipants: 0,
          totalMeetingTime: 0,
          totalMeetingHours: 0,
          averageParticipantsPerMeeting: 0,
          activeMeetings: 0,
          lastActive: new Date()
        }
      });
    }

    res.json({
      success: true,
      stats: {
        totalMeetingsCreated: stats.totalMeetingsCreated,
        totalParticipants: stats.totalParticipants,
        totalMeetingTime: stats.totalMeetingTime,
        totalMeetingHours: Math.floor(stats.totalMeetingTime / 60),
        averageParticipantsPerMeeting: Math.round(stats.averageParticipantsPerMeeting),
        activeMeetings: stats.activeMeetings,
        lastActive: stats.lastActive
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== GET HOST MEETINGS (Placeholder) ==========
router.get('/meetings', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);
    
    if (!user || user.role !== 'host') {
      return res.status(403).json({ error: 'Access denied. Hosts only.' });
    }

    // This will be implemented when meeting system is ready
    res.json({
      success: true,
      meetings: [],
      message: 'Meeting list will be available when meeting system is implemented'
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== GET HOST ANALYTICS ==========
router.get('/analytics', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);
    
    if (!user || user.role !== 'host') {
      return res.status(403).json({ error: 'Access denied. Hosts only.' });
    }

    const stats = HostStats.findByHostId(req.userId);

    res.json({
      success: true,
      analytics: {
        overview: {
          totalMeetings: stats?.totalMeetingsCreated || 0,
          totalParticipants: stats?.totalParticipants || 0,
          activeMeetings: stats?.activeMeetings || 0
        },
        engagement: {
          averageParticipants: Math.round(stats?.averageParticipantsPerMeeting || 0),
          totalHoursHosted: Math.floor((stats?.totalMeetingTime || 0) / 60)
        },
        activity: {
          lastActive: stats?.lastActive || new Date(),
          accountCreated: user.createdAt
        }
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;