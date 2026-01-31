const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// ========== SIGNUP ROUTE ==========
router.post('/signup', async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    // Check if all fields are provided
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    // Check if user already exists
    if (User.findByEmail(email)) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Hash password (scramble it for security)
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const user = User.create({
      name,
      email,
      password: hashedPassword,
      role: role || 'student'
    });

    // Create login token (VIP pass)
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      'comind-secret-key-2026',
      { expiresIn: '24h' }
    );

    // Send success response
    res.status(201).json({
      success: true,
      message: 'User created successfully',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role
      },
      token
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== LOGIN ROUTE ==========
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check if fields are provided
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    // Find user
    const user = User.findByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Check if password is correct
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Create login token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      'comind-secret-key-2026',
      { expiresIn: '24h' }
    );

    // Send success response
    res.json({
      success: true,
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role
      },
      token
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== LOGOUT ROUTE ==========
router.post('/logout', (req, res) => {
  // Client will delete the token
  res.json({ success: true, message: 'Logged out successfully' });
});

module.exports = router;