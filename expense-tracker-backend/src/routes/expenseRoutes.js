const express = require('express');
const { body, param, query } = require('express-validator');

const {
  createExpense,
  deleteExpense,
  getExpenses,
  getExpenseStats,
  updateExpense,
} = require('../controllers/expenseController');
const { protect } = require('../middleware/authMiddleware');
const validateRequest = require('../middleware/validateRequest');
const { EXPENSE_CATEGORIES } = require('../models/Expense');

const router = express.Router();

router.use(protect);

router.get('/stats', getExpenseStats);

router.get(
  '/',
  [
    query('month')
      .optional()
      .matches(/^\d{4}-(0[1-9]|1[0-2])$/)
      .withMessage('Month must be in YYYY-MM format'),
    query('category')
      .optional()
      .isIn(EXPENSE_CATEGORIES)
      .withMessage('Invalid category'),
    query('sort').optional().isIn(['asc', 'desc']).withMessage('Sort must be asc or desc'),
  ],
  validateRequest,
  getExpenses
);

router.post(
  '/',
  [
    body('amount').isFloat({ min: 0 }).withMessage('Amount must be a number at least 0'),
    body('description').trim().notEmpty().withMessage('Description is required'),
    body('date').optional().isISO8601().withMessage('Date must be a valid ISO date'),
  ],
  validateRequest,
  createExpense
);

router.put(
  '/:id',
  [
    param('id').isMongoId().withMessage('Invalid expense id'),
    body('amount')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Amount must be a number at least 0'),
    body('description').optional().trim().notEmpty().withMessage('Description cannot be empty'),
    body('category')
      .optional()
      .isIn(EXPENSE_CATEGORIES)
      .withMessage('Invalid category'),
    body('date').optional().isISO8601().withMessage('Date must be a valid ISO date'),
  ],
  validateRequest,
  updateExpense
);

router.delete(
  '/:id',
  [param('id').isMongoId().withMessage('Invalid expense id')],
  validateRequest,
  deleteExpense
);

module.exports = router;
