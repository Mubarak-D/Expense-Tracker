const path = require('path');

require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const mongoose = require('mongoose');

const connectDB = require('../src/config/db');
const { Expense } = require('../src/models/Expense');
const Goal = require('../src/models/Goal');
const { RecurringExpense } = require('../src/models/RecurringExpense');
const User = require('../src/models/User');

const DEMO_USER = {
  name: 'Demo User',
  email: 'demo@etml.app',
  password: 'password123',
};

const LEGACY_DEMO_EMAILS = ['demo@etml.local'];
const DEFAULT_MONGO_URI = 'mongodb://localhost:27017/etml';
const CURRENT_MONTH_LIMIT = 50000;

const monthKey = (date) => {
  const year = date.getUTCFullYear();
  const month = `${date.getUTCMonth() + 1}`.padStart(2, '0');
  return `${year}-${month}`;
};

const utcDate = (year, monthIndex, day, hour = 9) =>
  new Date(Date.UTC(year, monthIndex, day, hour, 0, 0));

const dayInMonth = (year, monthIndex, preferredDay) => {
  const lastDay = new Date(Date.UTC(year, monthIndex + 1, 0)).getUTCDate();
  return Math.min(Math.max(preferredDay, 1), lastDay);
};

const buildDateFactory = (referenceDate) => {
  const year = referenceDate.getUTCFullYear();
  const monthIndex = referenceDate.getUTCMonth();
  const currentDay = referenceDate.getUTCDate();

  const previousMonthDate = new Date(Date.UTC(year, monthIndex - 1, 1));
  const previousMonthYear = previousMonthDate.getUTCFullYear();
  const previousMonthIndex = previousMonthDate.getUTCMonth();

  const nextMonthDate = new Date(Date.UTC(year, monthIndex + 1, 1));
  const nextMonthYear = nextMonthDate.getUTCFullYear();
  const nextMonthIndex = nextMonthDate.getUTCMonth();

  return {
    currentMonth: monthKey(referenceDate),
    currentMonthDay: (preferredDay, hour) =>
      utcDate(year, monthIndex, dayInMonth(year, monthIndex, Math.min(preferredDay, currentDay)), hour),
    nextMonthDay: (preferredDay, hour) =>
      utcDate(nextMonthYear, nextMonthIndex, dayInMonth(nextMonthYear, nextMonthIndex, preferredDay), hour),
    previousMonthDay: (preferredDay, hour) =>
      utcDate(
        previousMonthYear,
        previousMonthIndex,
        dayInMonth(previousMonthYear, previousMonthIndex, preferredDay),
        hour
      ),
  };
};

const expense = ({
  userId,
  amount,
  description,
  category,
  predictedCategory = category,
  predictionConfidence,
  date,
  corrected = false,
}) => ({
  userId,
  amount,
  description,
  category,
  predictedCategory,
  predictionConfidence,
  corrected,
  correctionSource: corrected ? 'manual' : 'ml',
  correctedAt: corrected ? date : null,
  date,
});

const buildDemoExpenses = (userId, dates) => [
  expense({
    userId,
    amount: 4200,
    description: 'weekly groceries at cargills',
    category: 'Food',
    predictionConfidence: 0.94,
    date: dates.currentMonthDay(1, 10),
  }),
  expense({
    userId,
    amount: 1850,
    description: 'uber ride to airport',
    category: 'Transport',
    predictionConfidence: 0.91,
    date: dates.currentMonthDay(2, 7),
  }),
  expense({
    userId,
    amount: 3800,
    description: 'electricity bill',
    category: 'Bills',
    predictionConfidence: 0.96,
    date: dates.currentMonthDay(2, 18),
  }),
  expense({
    userId,
    amount: 1450,
    description: 'mcdonalds dinner',
    category: 'Food',
    predictedCategory: 'Other',
    predictionConfidence: 0.54,
    corrected: true,
    date: dates.currentMonthDay(3, 20),
  }),
  expense({
    userId,
    amount: 2100,
    description: 'dialog reload and data add on',
    category: 'Bills',
    predictionConfidence: 0.88,
    date: dates.currentMonthDay(4, 11),
  }),
  expense({
    userId,
    amount: 950,
    description: 'pickme tuk ride',
    category: 'Transport',
    predictedCategory: 'Other',
    predictionConfidence: 0.49,
    corrected: true,
    date: dates.currentMonthDay(4, 21),
  }),
  expense({
    userId,
    amount: 3200,
    description: 'daraz headphones',
    category: 'Shopping',
    predictionConfidence: 0.9,
    date: dates.currentMonthDay(5, 14),
  }),
  expense({
    userId,
    amount: 4900,
    description: 'gym membership',
    category: 'Health',
    predictionConfidence: 0.82,
    date: dates.currentMonthDay(6, 8),
  }),
  expense({
    userId,
    amount: 2600,
    description: 'doctor appointment',
    category: 'Health',
    predictionConfidence: 0.87,
    date: dates.currentMonthDay(6, 16),
  }),
  expense({
    userId,
    amount: 1800,
    description: 'movie tickets',
    category: 'Entertainment',
    predictionConfidence: 0.89,
    date: dates.currentMonthDay(7, 19),
  }),
  expense({
    userId,
    amount: 3500,
    description: 'online course fee',
    category: 'Education',
    predictionConfidence: 0.92,
    date: dates.currentMonthDay(8, 13),
  }),
  expense({
    userId,
    amount: 1200,
    description: 'bus ticket to kandy',
    category: 'Transport',
    predictionConfidence: 0.84,
    date: dates.currentMonthDay(8, 6),
  }),
  expense({
    userId,
    amount: 1650,
    description: 'kfc bucket',
    category: 'Food',
    predictedCategory: 'Entertainment',
    predictionConfidence: 0.57,
    corrected: true,
    date: dates.currentMonthDay(9, 20),
  }),
  expense({
    userId,
    amount: 1390,
    description: 'netflix subscription',
    category: 'Entertainment',
    predictionConfidence: 0.86,
    date: dates.currentMonthDay(10, 9),
  }),
  expense({
    userId,
    amount: 990,
    description: 'spotify premium',
    category: 'Entertainment',
    predictedCategory: 'Bills',
    predictionConfidence: 0.58,
    corrected: true,
    date: dates.currentMonthDay(10, 9),
  }),
  expense({
    userId,
    amount: 2450,
    description: 'pharmacy purchase',
    category: 'Health',
    predictionConfidence: 0.81,
    date: dates.currentMonthDay(11, 17),
  }),
  expense({
    userId,
    amount: 5000,
    description: 'fuel refill',
    category: 'Transport',
    predictionConfidence: 0.93,
    date: dates.currentMonthDay(12, 18),
  }),
  expense({
    userId,
    amount: 750,
    description: 'cash withdrawal service charge',
    category: 'Other',
    predictionConfidence: 0.76,
    date: dates.currentMonthDay(12, 12),
  }),
  expense({
    userId,
    amount: 4100,
    description: 'water bill and maintenance fee',
    category: 'Bills',
    predictionConfidence: 0.9,
    date: dates.previousMonthDay(1, 10),
  }),
  expense({
    userId,
    amount: 3750,
    description: 'keells monthly grocery run',
    category: 'Food',
    predictionConfidence: 0.95,
    date: dates.previousMonthDay(2, 18),
  }),
  expense({
    userId,
    amount: 890,
    description: 'pickme ride to office',
    category: 'Transport',
    predictionConfidence: 0.86,
    date: dates.previousMonthDay(3, 8),
  }),
  expense({
    userId,
    amount: 6800,
    description: 'new work backpack',
    category: 'Shopping',
    predictionConfidence: 0.83,
    date: dates.previousMonthDay(4, 14),
  }),
  expense({
    userId,
    amount: 2200,
    description: 'dental checkup',
    category: 'Health',
    predictionConfidence: 0.88,
    date: dates.previousMonthDay(5, 15),
  }),
  expense({
    userId,
    amount: 1250,
    description: 'cinema snacks',
    category: 'Entertainment',
    predictedCategory: 'Food',
    predictionConfidence: 0.55,
    corrected: true,
    date: dates.previousMonthDay(6, 21),
  }),
  expense({
    userId,
    amount: 7200,
    description: 'aws certification practice exam',
    category: 'Education',
    predictionConfidence: 0.85,
    date: dates.previousMonthDay(8, 11),
  }),
  expense({
    userId,
    amount: 1500,
    description: 'mobile screen protector',
    category: 'Shopping',
    predictionConfidence: 0.8,
    date: dates.previousMonthDay(9, 17),
  }),
  expense({
    userId,
    amount: 620,
    description: 'train ticket',
    category: 'Transport',
    predictionConfidence: 0.82,
    date: dates.previousMonthDay(10, 7),
  }),
  expense({
    userId,
    amount: 2850,
    description: 'lunch with friends',
    category: 'Food',
    predictionConfidence: 0.79,
    date: dates.previousMonthDay(11, 13),
  }),
  expense({
    userId,
    amount: 1890,
    description: 'monthly cloud storage plan',
    category: 'Bills',
    predictedCategory: 'Other',
    predictionConfidence: 0.51,
    corrected: true,
    date: dates.previousMonthDay(12, 9),
  }),
  expense({
    userId,
    amount: 2300,
    description: 'ayurvedic medicine',
    category: 'Health',
    predictionConfidence: 0.77,
    date: dates.previousMonthDay(14, 16),
  }),
  expense({
    userId,
    amount: 4800,
    description: 'weekend hotel advance',
    category: 'Entertainment',
    predictedCategory: 'Other',
    predictionConfidence: 0.56,
    corrected: true,
    date: dates.previousMonthDay(16, 12),
  }),
  expense({
    userId,
    amount: 3400,
    description: 'english speaking workshop',
    category: 'Education',
    predictionConfidence: 0.84,
    date: dates.previousMonthDay(18, 19),
  }),
  expense({
    userId,
    amount: 560,
    description: 'parking fee',
    category: 'Transport',
    predictedCategory: 'Other',
    predictionConfidence: 0.53,
    corrected: true,
    date: dates.previousMonthDay(20, 18),
  }),
  expense({
    userId,
    amount: 2700,
    description: 'birthday gift',
    category: 'Shopping',
    predictedCategory: 'Other',
    predictionConfidence: 0.59,
    corrected: true,
    date: dates.previousMonthDay(22, 15),
  }),
  expense({
    userId,
    amount: 1800,
    description: 'temple donation and flowers',
    category: 'Other',
    predictionConfidence: 0.74,
    date: dates.previousMonthDay(24, 9),
  }),
  expense({
    userId,
    amount: 1250,
    description: 'notebook and pens',
    category: 'Education',
    predictedCategory: 'Shopping',
    predictionConfidence: 0.52,
    corrected: true,
    date: dates.previousMonthDay(26, 16),
  }),
];

const buildDemoRecurringExpenses = (userId, dates) => [
  {
    userId,
    amount: 1390,
    description: 'Netflix subscription',
    category: 'Entertainment',
    frequency: 'monthly',
    nextRunDate: dates.nextMonthDay(10),
    active: true,
    lastPostedAt: dates.currentMonthDay(10),
  },
  {
    userId,
    amount: 4900,
    description: 'Gym membership',
    category: 'Health',
    frequency: 'monthly',
    nextRunDate: dates.nextMonthDay(6),
    active: true,
    lastPostedAt: dates.currentMonthDay(6),
  },
  {
    userId,
    amount: 2100,
    description: 'Dialog phone bill',
    category: 'Bills',
    frequency: 'monthly',
    nextRunDate: dates.nextMonthDay(4),
    active: true,
    lastPostedAt: dates.currentMonthDay(4),
  },
  {
    userId,
    amount: 5500,
    description: 'Home internet package',
    category: 'Bills',
    frequency: 'monthly',
    nextRunDate: dates.nextMonthDay(15),
    active: true,
    lastPostedAt: dates.previousMonthDay(15),
  },
  {
    userId,
    amount: 3500,
    description: 'Online course platform',
    category: 'Education',
    frequency: 'monthly',
    nextRunDate: dates.nextMonthDay(20),
    active: true,
    lastPostedAt: dates.previousMonthDay(20),
  },
];

const deleteDemoUserData = async (user) => {
  if (!user) return;

  const [expenses, goals, recurring] = await Promise.all([
    Expense.deleteMany({ userId: user._id }),
    Goal.deleteMany({ userId: user._id }),
    RecurringExpense.deleteMany({ userId: user._id }),
  ]);

  await User.deleteOne({ _id: user._id });

  console.log(
    `Removed demo account ${user.email}: ${expenses.deletedCount} expenses, ${goals.deletedCount} goals, ${recurring.deletedCount} recurring templates.`
  );
};

const resetDemoAccounts = async () => {
  const demoUsers = await User.find({
    email: { $in: [DEMO_USER.email, ...LEGACY_DEMO_EMAILS] },
  });

  for (const user of demoUsers) {
    await deleteDemoUserData(user);
  }
};

const seedDemoData = async () => {
  process.env.MONGO_URI = process.env.MONGO_URI || DEFAULT_MONGO_URI;

  console.log('Connecting to MongoDB...');
  await connectDB();

  console.log('Resetting existing demo data...');
  await resetDemoAccounts();

  console.log('Creating demo user...');
  const user = await User.create(DEMO_USER);
  const dates = buildDateFactory(new Date());

  console.log('Creating expenses, budget goal, and recurring templates...');
  await Promise.all([
    Expense.insertMany(buildDemoExpenses(user._id, dates)),
    Goal.create({
      userId: user._id,
      month: dates.currentMonth,
      monthlyLimit: CURRENT_MONTH_LIMIT,
    }),
    RecurringExpense.insertMany(buildDemoRecurringExpenses(user._id, dates)),
  ]);

  const [
    expenseCount,
    correctionCount,
    lowConfidenceCount,
    recurringCount,
    nonDemoUserCount,
    currentMonthTotal,
  ] = await Promise.all([
    Expense.countDocuments({ userId: user._id }),
    Expense.countDocuments({ userId: user._id, corrected: true }),
    Expense.countDocuments({ userId: user._id, predictionConfidence: { $lt: 0.6 } }),
    RecurringExpense.countDocuments({ userId: user._id }),
    User.countDocuments({ email: { $ne: DEMO_USER.email } }),
    Expense.aggregate([
      {
        $match: {
          userId: user._id,
          date: {
            $gte: new Date(`${dates.currentMonth}-01T00:00:00.000Z`),
            $lt: new Date(
              Date.UTC(
                Number(dates.currentMonth.slice(0, 4)),
                Number(dates.currentMonth.slice(5, 7)),
                1
              )
            ),
          },
        },
      },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ]),
  ]);

  const spent = currentMonthTotal[0]?.total || 0;
  const progress = Math.round((spent / CURRENT_MONTH_LIMIT) * 100);

  console.log('');
  console.log('Demo seed data ready.');
  console.log(`Login: ${DEMO_USER.email} / ${DEMO_USER.password}`);
  console.log(`Expenses: ${expenseCount}`);
  console.log(`Manual corrections: ${correctionCount}`);
  console.log(`Low-confidence predictions: ${lowConfidenceCount}`);
  console.log(`Budget month: ${dates.currentMonth}`);
  console.log(`Budget progress: LKR ${spent.toLocaleString()} / ${CURRENT_MONTH_LIMIT.toLocaleString()} (${progress}%)`);
  console.log(`Recurring templates: ${recurringCount}`);
  console.log(`Non-demo users preserved: ${nonDemoUserCount}`);
};

seedDemoData()
  .then(async () => {
    await mongoose.disconnect();
    process.exit(0);
  })
  .catch(async (error) => {
    console.error('Demo seed failed:', error);
    await mongoose.disconnect();
    process.exit(1);
  });
