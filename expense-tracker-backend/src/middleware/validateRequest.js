const { validationResult } = require('express-validator');

const validateRequest = (req, res, next) => {
  const errors = validationResult(req);

  if (errors.isEmpty()) {
    return next();
  }

  const message = errors
    .array()
    .map((error) => error.msg)
    .join(', ');

  return res.status(400).json({
    success: false,
    message,
  });
};

module.exports = validateRequest;
