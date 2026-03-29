const express = require('express');
const jwt = require('jsonwebtoken');
const { verifyToken } = require('../middleware/auth');
const { User } = require('../models/User');

const router = express.Router();

router.get('/me', verifyToken, (req, res) => {
  try {
    const user = User.findById(req.userId);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      success: true,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/refresh', verifyToken, (req, res) => {
  try {
    const newToken = jwt.sign(
      { userId: req.userId, email: req.userEmail },
      process.env.JWT_SECRET || 'comind-secret-key-2026',
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      message: 'Token refreshed',
      token: newToken
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/verify', verifyToken, (req, res) => {
  res.json({
    success: true,
    message: 'Session is valid',
    userId: req.userId
  });
});

module.exports = router;