const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const auth = require('../middleware/auth');

// Profile Management Routes
router.post('/', auth, profileController.createProfile);
router.get('/', auth, profileController.getProfiles);
router.get('/:id', auth, profileController.getProfileById);
router.put('/:id', auth, profileController.updateProfile);
router.delete('/:id', auth, profileController.deleteProfile);
router.post('/batch', auth, profileController.batchOperations);
router.post('/upload-secret', auth, profileController.uploadProfileSecret);
router.get('/:id/logs', auth, profileController.getProfileLogs);
router.post('/generate-ac', auth, profileController.generateActivationCode);

module.exports = router;