const mongoose = require('mongoose');

const goalSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    month: {
      type: String,
      required: true,
      match: [/^\d{4}-(0[1-9]|1[0-2])$/, 'Month must be in YYYY-MM format'],
    },
    monthlyLimit: {
      type: Number,
      required: [true, 'Monthly limit is required'],
      min: [Number.MIN_VALUE, 'Monthly limit must be greater than 0'],
    },
  },
  {
    timestamps: true,
  }
);

goalSchema.index({ userId: 1, month: 1 }, { unique: true });

module.exports = mongoose.model('Goal', goalSchema);
