const mongoose = require('mongoose');

const { Expense } = require('../models/Expense');
const { predictCategory } = require('../services/mlService');
const asyncHandler = require('../utils/asyncHandler');

const getMonthRange = (month) => {
  const [year, monthNumber] = month.split('-').map(Number);
  const start = new Date(Date.UTC(year, monthNumber - 1, 1));
  const end = new Date(Date.UTC(year, monthNumber, 1));
  return { start, end };
};

const getExpenses = asyncHandler(async (req, res) => {
  const { month, category, sort = 'desc' } = req.query;

  const query = {
    userId: req.user._id,
  };

  if (month) {
    const { start, end } = getMonthRange(month);
    query.date = { $gte: start, $lt: end };
  }

  if (category) {
    query.category = category;
  }

  const expenses = await Expense.find(query).sort({
    date: sort === 'asc' ? 1 : -1,
    createdAt: sort === 'asc' ? 1 : -1,
  });

  res.status(200).json({
    expenses,
  });
});

const createExpense = asyncHandler(async (req, res) => {
  const { amount, description, date } = req.body;
  const prediction = await predictCategory(description);

  const expense = await Expense.create({
    userId: req.user._id,
    amount,
    description,
    category: prediction.category,
    predictedCategory: prediction.category,
    predictionConfidence: prediction.confidence,
    corrected: false,
    ...(date && { date }),
  });

  res.status(201).json({
    expense,
  });
});

const updateExpense = asyncHandler(async (req, res) => {
  const { id } = req.params;

  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid expense id',
    });
  }

  const expense = await Expense.findOne({
    _id: id,
    userId: req.user._id,
  });

  if (!expense) {
    return res.status(404).json({
      success: false,
      message: 'Expense not found',
    });
  }

  const { amount, description, category, date } = req.body;
  const descriptionChanged = description !== undefined && description !== expense.description;

  if (amount !== undefined) {
    expense.amount = amount;
  }

  if (description !== undefined) {
    expense.description = description;
  }

  if (descriptionChanged && category === undefined) {
    const prediction = await predictCategory(description);
    expense.category = prediction.category;
    expense.predictedCategory = prediction.category;
    expense.predictionConfidence = prediction.confidence;
    expense.corrected = false;
  } else if (descriptionChanged && category !== undefined) {
    const prediction = await predictCategory(description);
    expense.predictedCategory = prediction.category;
    expense.predictionConfidence = prediction.confidence;
    expense.category = category;
    expense.corrected = category !== expense.predictedCategory;
  } else if (category !== undefined) {
    expense.category = category;
    expense.corrected = category !== expense.predictedCategory;
  }

  if (date !== undefined) {
    expense.date = date;
  }

  const updatedExpense = await expense.save();

  res.status(200).json({
    expense: updatedExpense,
  });
});

const deleteExpense = asyncHandler(async (req, res) => {
  const { id } = req.params;

  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid expense id',
    });
  }

  const expense = await Expense.findOneAndDelete({
    _id: id,
    userId: req.user._id,
  });

  if (!expense) {
    return res.status(404).json({
      success: false,
      message: 'Expense not found',
    });
  }

  res.status(200).json({
    message: 'Expense deleted successfully',
  });
});

module.exports = {
  getExpenses,
  createExpense,
  updateExpense,
  deleteExpense,
};
