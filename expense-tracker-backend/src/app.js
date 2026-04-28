const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const errorMiddleware = require('./middleware/errorMiddleware');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'ETML backend API is running',
  });
});

app.use('/api/auth', authRoutes);

app.use(errorMiddleware);

module.exports = app;
