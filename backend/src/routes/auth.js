const express = require('express');
const router = express.Router();

router.get('/status', (req, res) => {
  res.json({ status: 'Auth service active' });
});

module.exports = router;