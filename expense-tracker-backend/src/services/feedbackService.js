const applyMlFeedback = (expense, prediction) => {
  expense.category = prediction.category;
  expense.predictedCategory = prediction.category;
  expense.predictionConfidence = prediction.confidence;
  expense.corrected = false;
  expense.correctionSource = 'ml';
  expense.correctedAt = null;
};

const applyCategoryFeedback = (expense, category) => {
  expense.category = category;

  if (category === expense.predictedCategory) {
    expense.corrected = false;
    expense.correctionSource = 'ml';
    expense.correctedAt = null;
    return;
  }

  expense.corrected = true;
  expense.correctionSource = 'manual';
  expense.correctedAt = new Date();
};

const roundRatio = (value) => Math.round((value + Number.EPSILON) * 100) / 100;

const getFeedbackExport = async (Expense, userId) => {
  const expenses = await Expense.find({
    userId,
    corrected: true,
    correctionSource: 'manual',
  })
    .select('description predictedCategory category predictionConfidence correctedAt')
    .sort({ correctedAt: -1, updatedAt: -1 })
    .lean();

  return {
    count: expenses.length,
    data: expenses.map((expense) => ({
      description: expense.description,
      predictedCategory: expense.predictedCategory,
      correctedCategory: expense.category,
      confidence: expense.predictionConfidence,
      correctedAt: expense.correctedAt,
    })),
  };
};

const getFeedbackSummary = async (Expense, userId) => {
  const [totals, correctedGroups] = await Promise.all([
    Expense.aggregate([
      { $match: { userId } },
      {
        $group: {
          _id: null,
          totalExpenses: { $sum: 1 },
          totalCorrections: {
            $sum: {
              $cond: [{ $eq: ['$corrected', true] }, 1, 0],
            },
          },
          lowConfidenceCorrections: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ['$corrected', true] },
                    { $lt: ['$predictionConfidence', 0.6] },
                  ],
                },
                1,
                0,
              ],
            },
          },
        },
      },
    ]),
    Expense.aggregate([
      {
        $match: {
          userId,
          corrected: true,
        },
      },
      {
        $group: {
          _id: '$predictedCategory',
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1, _id: 1 } },
      { $limit: 1 },
    ]),
  ]);

  const totalExpenses = totals[0]?.totalExpenses || 0;
  const totalCorrections = totals[0]?.totalCorrections || 0;

  return {
    totalCorrections,
    lowConfidenceCorrections: totals[0]?.lowConfidenceCorrections || 0,
    mostCorrectedPredictedCategory: correctedGroups[0]?._id || null,
    correctionRate: totalExpenses === 0 ? 0 : roundRatio(totalCorrections / totalExpenses),
  };
};

module.exports = {
  applyMlFeedback,
  applyCategoryFeedback,
  getFeedbackExport,
  getFeedbackSummary,
};
