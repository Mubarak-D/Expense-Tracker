const mongoose = require('mongoose');

const {
  createRecurringExpense,
  deleteRecurringExpense,
  listRecurringExpenses,
  postRecurringExpense,
  updateRecurringExpense,
} = require('../services/recurringExpenseService');
const asyncHandler = require('../utils/asyncHandler');

const getRecurringExpenses = asyncHandler(async (req, res) => {
  const recurringExpenses = await listRecurringExpenses(req.user._id);

  res.status(200).json({
    recurringExpenses,
  });
});

const saveRecurringExpense = asyncHandler(async (req, res) => {
  const { amount, description, category, nextRunDate } = req.body;

  const recurringExpense = await createRecurringExpense({
    userId: req.user._id,
    amount,
    description,
    category,
    nextRunDate,
  });

  res.status(201).json({
    recurringExpense,
  });
});

const editRecurringExpense = asyncHandler(async (req, res) => {
  const updates = {};
  for (const field of ['amount', 'description', 'category', 'nextRunDate', 'active']) {
    if (req.body[field] !== undefined) {
      updates[field] = req.body[field];
    }
  }

  const recurringExpense = await updateRecurringExpense({
    userId: req.user._id,
    id: req.params.id,
    updates,
  });

  if (!recurringExpense) {
    return res.status(404).json({
      success: false,
      message: 'Recurring expense not found',
    });
  }

  res.status(200).json({
    recurringExpense,
  });
});

const removeRecurringExpense = asyncHandler(async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid recurring expense id',
    });
  }

  const recurringExpense = await deleteRecurringExpense(req.user._id, req.params.id);

  if (!recurringExpense) {
    return res.status(404).json({
      success: false,
      message: 'Recurring expense not found',
    });
  }

  res.status(200).json({
    message: 'Recurring expense deleted successfully',
  });
});

const postNow = asyncHandler(async (req, res) => {
  const result = await postRecurringExpense({
    userId: req.user._id,
    id: req.params.id,
  });

  if (!result) {
    return res.status(404).json({
      success: false,
      message: 'Recurring expense not found',
    });
  }

  res.status(201).json(result);
});

module.exports = {
  editRecurringExpense,
  getRecurringExpenses,
  postNow,
  removeRecurringExpense,
  saveRecurringExpense,
};
