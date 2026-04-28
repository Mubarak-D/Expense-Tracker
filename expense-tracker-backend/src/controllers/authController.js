const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const generateToken = require('../utils/generateToken');

const formatUserResponse = (user) => ({
  id: user._id,
  name: user.name,
  email: user.email,
});

const register = asyncHandler(async (req, res) => {
  const { name, email, password } = req.body;

  const existingUser = await User.findOne({ email });

  if (existingUser) {
    return res.status(409).json({
      success: false,
      message: 'Email is already registered',
    });
  }

  const user = await User.create({ name, email, password });

  return res.status(201).json({
    user: formatUserResponse(user),
    token: generateToken(user._id),
  });
});

const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  const user = await User.findOne({ email }).select('+password');

  if (!user || !(await user.comparePassword(password))) {
    return res.status(401).json({
      success: false,
      message: 'Invalid email or password',
    });
  }

  return res.status(200).json({
    user: formatUserResponse(user),
    token: generateToken(user._id),
  });
});

const getMe = asyncHandler(async (req, res) => {
  return res.status(200).json({
    user: formatUserResponse(req.user),
  });
});

module.exports = {
  register,
  login,
  getMe,
};
