const express = require('express');
const { body, param } = require('express-validator');

const {
  editRecurringExpense,
  getRecurringExpenses,
  postNow,
  removeRecurringExpense,
  saveRecurringExpense,
} = require('../controllers/recurringExpenseController');
const { protect } = require('../middleware/authMiddleware');
const validateRequest = require('../middleware/validateRequest');
const { EXPENSE_CATEGORIES } = require('../models/Expense');

const router = express.Router();

router.use(protect);

const idValidator = param('id').isMongoId().withMessage('Invalid recurring expense id');
const recurringValidators = [
  body('amount').isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
  body('description').trim().notEmpty().withMessage('Description is required'),
  body('category').optional().isIn(EXPENSE_CATEGORIES).withMessage('Invalid category'),
  body('nextRunDate').isISO8601().withMessage('Next run date must be a valid ISO date'),
];

router.get('/', getRecurringExpenses);
router.post('/', recurringValidators, validateRequest, saveRecurringExpense);
router.post('/:id/post', [idValidator], validateRequest, postNow);
router.put(
  '/:id',
  [
    idValidator,
    body('amount').optional().isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
    body('description').optional().trim().notEmpty().withMessage('Description cannot be empty'),
    body('category').optional().isIn(EXPENSE_CATEGORIES).withMessage('Invalid category'),
    body('nextRunDate').optional().isISO8601().withMessage('Next run date must be a valid ISO date'),
    body('active').optional().isBoolean().withMessage('Active must be true or false'),
  ],
  validateRequest,
  editRecurringExpense
);
router.delete('/:id', [idValidator], validateRequest, removeRecurringExpense);

module.exports = router;
