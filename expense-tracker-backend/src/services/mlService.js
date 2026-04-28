const axios = require('axios');

const { EXPENSE_CATEGORIES } = require('../models/Expense');

const fallbackPrediction = {
  category: 'Other',
  confidence: 0,
  allProbabilities: {},
};

const predictCategory = async (description) => {
  try {
    const baseUrl = process.env.ML_SERVICE_URL || 'http://localhost:8000';

    const response = await axios.post(
      `${baseUrl}/predict`,
      { description },
      {
        timeout: 5000,
      }
    );

    const predictedCategory = response.data?.category;

    if (!EXPENSE_CATEGORIES.includes(predictedCategory)) {
      return fallbackPrediction;
    }

    const confidence = Number(response.data?.confidence);

    return {
      category: predictedCategory,
      confidence: Number.isFinite(confidence) ? Math.min(Math.max(confidence, 0), 1) : 0,
      allProbabilities: response.data?.all_probabilities || {},
    };
  } catch (error) {
    return fallbackPrediction;
  }
};

module.exports = {
  predictCategory,
};
