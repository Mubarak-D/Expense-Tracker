const { Expense } = require('../models/Expense');

const toDateKey = (date) => date.toISOString().slice(0, 10);

const roundCurrency = (value) => Math.round((value + Number.EPSILON) * 100) / 100;

const getMonthBounds = (referenceDate = new Date()) => {
  const year = referenceDate.getUTCFullYear();
  const month = referenceDate.getUTCMonth();

  return {
    thisMonthStart: new Date(Date.UTC(year, month, 1)),
    nextMonthStart: new Date(Date.UTC(year, month + 1, 1)),
    lastMonthStart: new Date(Date.UTC(year, month - 1, 1)),
  };
};

const getTotalForRange = async (userId, start, end) => {
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

const getDashboardStats = async (userId) => {
  const now = new Date();
  const { thisMonthStart, nextMonthStart, lastMonthStart } = getMonthBounds(now);

  const last30Start = new Date(now);
  last30Start.setUTCDate(last30Start.getUTCDate() - 29);
  last30Start.setUTCHours(0, 0, 0, 0);

  const [thisMonthTotal, lastMonthTotal, categoryBreakdown, last30DaysRaw] =
    await Promise.all([
      getTotalForRange(userId, thisMonthStart, nextMonthStart),
      getTotalForRange(userId, lastMonthStart, thisMonthStart),
      Expense.aggregate([
        {
          $match: {
            userId,
            date: { $gte: thisMonthStart, $lt: nextMonthStart },
          },
        },
        {
          $group: {
            _id: '$category',
            total: { $sum: '$amount' },
          },
        },
        { $sort: { total: -1 } },
        {
          $project: {
            _id: 0,
            category: '$_id',
            total: { $round: ['$total', 2] },
          },
        },
      ]),
      Expense.aggregate([
        {
          $match: {
            userId,
            date: { $gte: last30Start, $lte: now },
          },
        },
        {
          $group: {
            _id: {
              $dateToString: {
                format: '%Y-%m-%d',
                date: '$date',
                timezone: 'UTC',
              },
            },
            total: { $sum: '$amount' },
          },
        },
        { $sort: { _id: 1 } },
        {
          $project: {
            _id: 0,
            date: '$_id',
            total: { $round: ['$total', 2] },
          },
        },
      ]),
    ]);

  const dailyTotalsByDate = new Map(last30DaysRaw.map((item) => [item.date, item.total]));
  const last30Days = [];

  for (let index = 0; index < 30; index += 1) {
    const date = new Date(last30Start);
    date.setUTCDate(last30Start.getUTCDate() + index);
    const dateKey = toDateKey(date);
    last30Days.push({
      date: dateKey,
      total: dailyTotalsByDate.get(dateKey) || 0,
    });
  }

  const topCategory = categoryBreakdown[0] || null;
  const dailyAverage = roundCurrency(thisMonthTotal / now.getUTCDate());
  const monthComparisonPercentage =
    lastMonthTotal === 0
      ? thisMonthTotal > 0
        ? 100
        : 0
      : roundCurrency(((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100);

  return {
    monthlyTotal: roundCurrency(thisMonthTotal),
    categoryBreakdown,
    topCategory,
    dailyAverage,
    last30Days,
    thisMonthTotal: roundCurrency(thisMonthTotal),
    lastMonthTotal: roundCurrency(lastMonthTotal),
    monthComparisonPercentage,
  };
};

module.exports = {
  getDashboardStats,
};
