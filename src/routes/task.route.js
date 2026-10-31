const express = require('express');
const router = express.Router();
const Task = require('../models/task.model');

router.get('/tasks', async (req, res) => {
    try {
        const tasks = await Task.find();
        res.status(200).json(tasks);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;