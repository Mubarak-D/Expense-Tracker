const mongoose = require('mongoose');

const { EXPENSE_CATEGORIES } = require('./Expense');

const RECURRING_FREQUENCIES = ['monthly'];

const recurringExpenseSchema = new mongoose.Schema(
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
      min: [Number.MIN_VALUE, 'Amount must be greater than 0'],
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
    frequency: {
      type: String,
      enum: RECURRING_FREQUENCIES,
      default: 'monthly',
    },
    nextRunDate: {
      type: Date,
      required: [true, 'Next run date is required'],
    },
    active: {
      type: Boolean,
      default: true,
    },
    lastPostedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

recurringExpenseSchema.index({ userId: 1, active: 1, nextRunDate: 1 });

module.exports = {
  RecurringExpense: mongoose.model('RecurringExpense', recurringExpenseSchema),
  RECURRING_FREQUENCIES,
};
