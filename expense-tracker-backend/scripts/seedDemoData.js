const path = require('path');

require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const mongoose = require('mongoose');

const connectDB = require('../src/config/db');
const { Expense } = require('../src/models/Expense');
const Goal = require('../src/models/Goal');
const { RecurringExpense } = require('../src/models/RecurringExpense');
const User = require('../src/models/User');

const DEMO_EMAIL = process.env.DEMO_SEED_EMAIL || 'demo@etml.local';
const DEMO_PASSWORD = process.env.DEMO_SEED_PASSWORD || 'password123';
const DEMO_NAME = process.env.DEMO_SEED_NAME || 'ETML Demo User';

const monthKey = (date) => {
  const year = date.getUTCFullYear();
  const month = `${date.getUTCMonth() + 1}`.padStart(2, '0');
  return `${year}-${month}`;
};

const utcDate = (year, monthIndex, day) => new Date(Date.UTC(year, monthIndex, day, 9, 0, 0));

const dayInMonth = (year, monthIndex, preferredDay) => {
  const lastDay = new Date(Date.UTC(year, monthIndex + 1, 0)).getUTCDate();
  return Math.min(Math.max(preferredDay, 1), lastDay);
};

const buildDateFactory = (referenceDate) => {
  const year = referenceDate.getUTCFullYear();
  const monthIndex = referenceDate.getUTCMonth();
  const today = referenceDate.getUTCDate();

  const currentMonthDay = (preferredDay) =>
    utcDate(year, monthIndex, dayInMonth(year, monthIndex, Math.min(preferredDay, today)));

  const lastMonthDate = new Date(Date.UTC(year, monthIndex - 1, 1));
  const lastMonthYear = lastMonthDate.getUTCFullYear();
  const lastMonthIndex = lastMonthDate.getUTCMonth();
  const previousMonthDay = (preferredDay) =>
    utcDate(lastMonthYear, lastMonthIndex, dayInMonth(lastMonthYear, lastMonthIndex, preferredDay));

  const nextMonthDate = new Date(Date.UTC(year, monthIndex + 1, 1));

  return {
    currentMonth: monthKey(referenceDate),
    currentMonthDay,
    nextMonthDay: (preferredDay) =>
      utcDate(
        nextMonthDate.getUTCFullYear(),
        nextMonthDate.getUTCMonth(),
        dayInMonth(nextMonthDate.getUTCFullYear(), nextMonthDate.getUTCMonth(), preferredDay)
      ),
    previousMonthDay,
  };
};

const buildDemoExpenses = (userId, dates) => [
  {
    userId,
    amount: 1250,
    description: 'Apartment rent',
    category: 'Bills',
    predictedCategory: 'Bills',
    predictionConfidence: 0.96,
    date: dates.currentMonthDay(1),
  },
  {
    userId,
    amount: 58.5,
    description: 'Fiber internet bill',
    category: 'Bills',
    predictedCategory: 'Bills',
    predictionConfidence: 0.94,
    date: dates.currentMonthDay(2),
  },
  {
    userId,
    amount: 142.75,
    description: 'Weekly groceries at supermarket',
    category: 'Food',
    predictedCategory: 'Food',
    predictionConfidence: 0.91,
    date: dates.currentMonthDay(3),
  },
  {
    userId,
    amount: 24.3,
    description: 'Uber ride home from office',
    category: 'Transport',
    predictedCategory: 'Transport',
    predictionConfidence: 0.88,
    date: dates.currentMonthDay(4),
  },
  {
    userId,
    amount: 18.75,
    description: 'Client lunch downtown',
    category: 'Food',
    predictedCategory: 'Shopping',
    predictionConfidence: 0.52,
    corrected: true,
    correctionSource: 'manual',
    correctedAt: dates.currentMonthDay(5),
    date: dates.currentMonthDay(5),
  },
  {
    userId,
    amount: 36.45,
    description: 'Pharmacy vitamins and cold medicine',
    category: 'Health',
    predictedCategory: 'Health',
    predictionConfidence: 0.84,
    date: dates.currentMonthDay(6),
  },
  {
    userId,
    amount: 49,
    description: 'Online data analytics course',
    category: 'Education',
    predictedCategory: 'Education',
    predictionConfidence: 0.86,
    date: dates.currentMonthDay(7),
  },
  {
    userId,
    amount: 31.2,
    description: 'Cinema tickets and snacks',
    category: 'Entertainment',
    predictedCategory: 'Entertainment',
    predictionConfidence: 0.83,
    date: dates.currentMonthDay(8),
  },
  {
    userId,
    amount: 89.99,
    description: 'Running shoes sale',
    category: 'Shopping',
    predictedCategory: 'Shopping',
    predictionConfidence: 0.9,
    date: dates.currentMonthDay(9),
  },
  {
    userId,
    amount: 6.75,
    description: 'Morning coffee near station',
    category: 'Food',
    predictedCategory: 'Food',
    predictionConfidence: 0.79,
    date: dates.currentMonthDay(10),
  },
  {
    userId,
    amount: 310,
    description: 'Monthly loan payment',
    category: 'Bills',
    predictedCategory: 'Bills',
    predictionConfidence: 0.89,
    date: dates.previousMonthDay(2),
  },
  {
    userId,
    amount: 78.4,
    description: 'Fuel refill for weekend trip',
    category: 'Transport',
    predictedCategory: 'Transport',
    predictionConfidence: 0.82,
    date: dates.previousMonthDay(5),
  },
  {
    userId,
    amount: 96.2,
    description: 'Family dinner at Thai restaurant',
    category: 'Food',
    predictedCategory: 'Entertainment',
    predictionConfidence: 0.48,
    corrected: true,
    correctionSource: 'manual',
    correctedAt: dates.previousMonthDay(8),
    date: dates.previousMonthDay(8),
  },
  {
    userId,
    amount: 22,
    description: 'Monthly music streaming plan',
    category: 'Entertainment',
    predictedCategory: 'Bills',
    predictionConfidence: 0.57,
    corrected: true,
    correctionSource: 'manual',
    correctedAt: dates.previousMonthDay(10),
    date: dates.previousMonthDay(10),
  },
  {
    userId,
    amount: 64.35,
    description: 'Books for certification prep',
    category: 'Education',
    predictedCategory: 'Education',
    predictionConfidence: 0.8,
    date: dates.previousMonthDay(14),
  },
  {
    userId,
    amount: 44.5,
    description: 'Doctor consultation co-pay',
    category: 'Health',
    predictedCategory: 'Health',
    predictionConfidence: 0.87,
    date: dates.previousMonthDay(18),
  },
  {
    userId,
    amount: 115.9,
    description: 'Office shirts and belt',
    category: 'Shopping',
    predictedCategory: 'Shopping',
    predictionConfidence: 0.92,
    date: dates.previousMonthDay(22),
  },
  {
    userId,
    amount: 13.6,
    description: 'Bus card top up',
    category: 'Transport',
    predictedCategory: 'Transport',
    predictionConfidence: 0.85,
    date: dates.previousMonthDay(25),
  },
];

const buildDemoRecurringExpenses = (userId, dates) => [
  {
    userId,
    amount: 1250,
    description: 'Apartment rent',
    category: 'Bills',
    frequency: 'monthly',
    nextRunDate: dates.nextMonthDay(1),
    active: true,
    lastPostedAt: dates.currentMonthDay(1),
  },
  {
    userId,
    amount: 58.5,
    description: 'Fiber internet bill',
    category: 'Bills',
    frequency: 'monthly',
    nextRunDate: dates.nextMonthDay(2),
    active: true,
    lastPostedAt: dates.currentMonthDay(2),
  },
  {
    userId,
    amount: 22,
    description: 'Music streaming plan',
    category: 'Entertainment',
    frequency: 'monthly',
    nextRunDate: dates.nextMonthDay(10),
    active: true,
    lastPostedAt: dates.previousMonthDay(10),
  },
];

const seedDemoData = async () => {
  process.env.MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/etml';

  await connectDB();

  const existingUser = await User.findOne({ email: DEMO_EMAIL });

  if (existingUser) {
    await Promise.all([
      Expense.deleteMany({ userId: existingUser._id }),
      Goal.deleteMany({ userId: existingUser._id }),
      RecurringExpense.deleteMany({ userId: existingUser._id }),
    ]);
    await User.deleteOne({ _id: existingUser._id });
  }

  const user = await User.create({
    name: DEMO_NAME,
    email: DEMO_EMAIL,
    password: DEMO_PASSWORD,
  });

  const dates = buildDateFactory(new Date());

  await Promise.all([
    Expense.insertMany(buildDemoExpenses(user._id, dates)),
    Goal.create({
      userId: user._id,
      month: dates.currentMonth,
      monthlyLimit: 1950,
    }),
    RecurringExpense.insertMany(buildDemoRecurringExpenses(user._id, dates)),
  ]);

  const [expenseCount, correctionCount, recurringCount] = await Promise.all([
    Expense.countDocuments({ userId: user._id }),
    Expense.countDocuments({ userId: user._id, corrected: true }),
    RecurringExpense.countDocuments({ userId: user._id }),
  ]);

  console.log('Demo seed data ready.');
  console.log(`Login: ${DEMO_EMAIL} / ${DEMO_PASSWORD}`);
  console.log(`Expenses: ${expenseCount}`);
  console.log(`Manual corrections: ${correctionCount}`);
  console.log(`Budget month: ${dates.currentMonth}`);
  console.log(`Recurring templates: ${recurringCount}`);
};

seedDemoData()
  .catch((error) => {
    console.error('Demo seed failed:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
