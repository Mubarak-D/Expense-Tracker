const asyncHandler = require('../utils/asyncHandler');
const { getCurrentGoalProgress, upsertGoal } = require('../services/goalService');

const saveGoal = asyncHandler(async (req, res) => {
  const { month, monthlyLimit } = req.body;

  const goal = await upsertGoal({
    userId: req.user._id,
    month,
    monthlyLimit,
  });

  res.status(200).json({
    goal,
  });
});

const getCurrentGoal = asyncHandler(async (req, res) => {
  const progress = await getCurrentGoalProgress({
    userId: req.user._id,
    month: req.query.month,
  });

  res.status(200).json(progress);
});

module.exports = {
  saveGoal,
  getCurrentGoal,
};
