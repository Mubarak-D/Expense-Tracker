const { Expense } = require('../models/Expense');
const { RecurringExpense } = require('../models/RecurringExpense');
const { applyMlFeedback } = require('./feedbackService');
const { predictCategory } = require('./mlService');

const addMonths = (date, months = 1) => {
  const next = new Date(date);
  const originalDay = next.getUTCDate();
  next.setUTCDate(1);
  next.setUTCMonth(next.getUTCMonth() + months);
  const lastDay = new Date(
    Date.UTC(next.getUTCFullYear(), next.getUTCMonth() + 1, 0)
  ).getUTCDate();
  next.setUTCDate(Math.min(originalDay, lastDay));
  return next;
};

const listRecurringExpenses = (userId) => {
  return RecurringExpense.find({ userId }).sort({
    active: -1,
    nextRunDate: 1,
    createdAt: -1,
  });
};

const createRecurringExpense = async ({
  userId,
  amount,
  description,
  category,
  nextRunDate,
}) => {
  const template = new RecurringExpense({
    userId,
    amount,
    description,
    category,
    nextRunDate,
  });

  return template.save();
};

const updateRecurringExpense = async ({ userId, id, updates }) => {
  return RecurringExpense.findOneAndUpdate(
    { _id: id, userId },
    { $set: updates },
    { new: true, runValidators: true }
  );
};

const deleteRecurringExpense = (userId, id) => {
  return RecurringExpense.findOneAndDelete({ _id: id, userId });
};

const postRecurringExpense = async ({ userId, id, date = new Date() }) => {
  const template = await RecurringExpense.findOne({ _id: id, userId });

  if (!template) {
    return null;
  }

  const prediction = await predictCategory(template.description);
  const expense = new Expense({
    userId,
    amount: template.amount,
    description: template.description,
    category: template.category,
    predictedCategory: prediction.category,
    predictionConfidence: prediction.confidence,
    corrected: template.category !== prediction.category,
    correctionSource: template.category !== prediction.category ? 'manual' : 'ml',
    correctedAt: template.category !== prediction.category ? new Date() : null,
    date,
  });

  if (template.category === prediction.category) {
    applyMlFeedback(expense, prediction);
  }

  await expense.save();

  template.lastPostedAt = date;
  template.nextRunDate = addMonths(template.nextRunDate);
  await template.save();

  return { expense, recurringExpense: template };
};

module.exports = {
  createRecurringExpense,
  deleteRecurringExpense,
  listRecurringExpenses,
  postRecurringExpense,
  updateRecurringExpense,
};
