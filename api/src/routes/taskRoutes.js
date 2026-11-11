const express = require('express');
const router = express.Router();

const taskController = require('../controllers/taskController');
const authMiddleware = require('../middleware/auth.middleware');

router.use(authMiddleware);

router.get('/groups', taskController.getTaskGroups);
// E1 - Thống kê số lượng công việc theo trạng thái
router.get('/statistics', taskController.getTaskStatistics);
router.get('/', taskController.getTasks);
router.get('/:id', taskController.getTaskById);
router.post('/', taskController.createTask);
router.put('/:id', taskController.updateTask);
router.delete('/:id', taskController.deleteTask);

module.exports = router;