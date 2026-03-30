const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

app.use(cors());
app.use(express.json());

const authRoutes = require('./routes/auth');
const sessionRoutes = require('./routes/session');

app.use('/api/auth', authRoutes);
app.use('/api/session', sessionRoutes);

app.get('/test', (req, res) => {
  res.json({ message: '✅ Backend is running!' });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});