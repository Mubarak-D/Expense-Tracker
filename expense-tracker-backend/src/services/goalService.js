const Goal = require('../models/Goal');
const { Expense } = require('../models/Expense');

const roundCurrency = (value) => Math.round((value + Number.EPSILON) * 100) / 100;

const getCurrentMonth = (date = new Date()) => {
  const year = date.getUTCFullYear();
  const month = `${date.getUTCMonth() + 1}`.padStart(2, '0');
  return `${year}-${month}`;
};

const getMonthRange = (month) => {
  const [year, monthNumber] = month.split('-').map(Number);

  return {
    start: new Date(Date.UTC(year, monthNumber - 1, 1)),
    end: new Date(Date.UTC(year, monthNumber, 1)),
  };
};

const getTotalSpentForMonth = async (userId, month) => {
  const { start, end } = getMonthRange(month);
  const [result] = await Expense.aggregate([
    {
      $match: {
        userId,
        date: { $gte: start, $lt: end },
      },
    },
    {
      $group: {
        _id: null,
        total: { $sum: '$amount' },
      },
    },
  ]);

  return result?.total || 0;
};

const getStatus = (progressPercentage) => {
  if (progressPercentage < 80) return 'on_track';
  if (progressPercentage <= 100) return 'warning';
  return 'over_budget';
};

const getAchievement = (status) => {
  if (status === 'warning') {
    return {
      title: 'Careful Spender',
      description: 'You are close to your monthly limit. A few mindful choices can keep you steady.',
      unlocked: true,
    };
  }

  if (status === 'over_budget') {
    return {
      title: 'Reset Plan',
      description: 'You have gone over your goal. Adjust spending or update your monthly target.',
      unlocked: true,
    };
  }

  return {
    title: 'Budget Guardian',
    description: 'You are staying within your monthly spending goal.',
    unlocked: true,
  };
};

const buildGoalProgress = async (goal) => {
  const totalSpent = await getTotalSpentForMonth(goal.userId, goal.month);
  const remaining = goal.monthlyLimit - totalSpent;
  const progressPercentage =
    goal.monthlyLimit === 0 ? 0 : Math.round((totalSpent / goal.monthlyLimit) * 100);
  const status = getStatus(progressPercentage);

  return {
    goalSet: true,
    month: goal.month,
    monthlyLimit: roundCurrency(goal.monthlyLimit),
    totalSpent: roundCurrency(totalSpent),
    remaining: roundCurrency(remaining),
    progressPercentage,
    status,
    achievement: getAchievement(status),
  };
};

const upsertGoal = async ({ userId, month = getCurrentMonth(), monthlyLimit }) => {
  const goal = await Goal.findOneAndUpdate(
    { userId, month },
    { $set: { monthlyLimit } },
    {
      new: true,
      upsert: true,
      runValidators: true,
      setDefaultsOnInsert: true,
    }
  );

  return goal;
};

const getCurrentGoalProgress = async ({ userId, month = getCurrentMonth() }) => {
  const goal = await Goal.findOne({ userId, month });

  if (!goal) {
    return {
      goalSet: false,
      month,
      message: 'No budget goal set for this month.',
    };
  }

  return buildGoalProgress(goal);
};

module.exports = {
  getCurrentGoalProgress,
  getCurrentMonth,
  upsertGoal,
};
