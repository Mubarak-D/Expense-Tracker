const express = require('express');
const { body, query } = require('express-validator');

const { getCurrentGoal, saveGoal } = require('../controllers/goalController');
const { protect } = require('../middleware/authMiddleware');
const validateRequest = require('../middleware/validateRequest');

const router = express.Router();

router.use(protect);

router.post(
  '/',
  [
    body('month')
      .optional()
      .matches(/^\d{4}-(0[1-9]|1[0-2])$/)
      .withMessage('Month must be in YYYY-MM format'),
    body('monthlyLimit')
      .isFloat({ gt: 0 })
      .withMessage('Monthly limit must be greater than 0'),
  ],
  validateRequest,
  saveGoal
);

router.get(
  '/current',
  [
    query('month')
      .optional()
      .matches(/^\d{4}-(0[1-9]|1[0-2])$/)
      .withMessage('Month must be in YYYY-MM format'),
  ],
  validateRequest,
  getCurrentGoal
);

module.exports = router;
