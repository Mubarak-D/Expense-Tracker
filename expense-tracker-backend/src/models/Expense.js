const mongoose = require('mongoose');

const EXPENSE_CATEGORIES = [
  'Food',
  'Transport',
  'Bills',
  'Shopping',
  'Health',
  'Entertainment',
  'Education',
  'Other',
];

const expenseSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    amount: {
      type: Number,
      required: [true, 'Amount is required'],
      min: [0, 'Amount must be at least 0'],
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      trim: true,
    },
    category: {
      type: String,
      enum: EXPENSE_CATEGORIES,
      default: 'Other',
    },
    predictedCategory: {
      type: String,
      enum: EXPENSE_CATEGORIES,
      default: 'Other',
    },
    predictionConfidence: {
      type: Number,
      min: 0,
      max: 1,
      default: 0,
    },
    corrected: {
      type: Boolean,
      default: false,
    },
    date: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = {
  Expense: mongoose.model('Expense', expenseSchema),
  EXPENSE_CATEGORIES,
};
