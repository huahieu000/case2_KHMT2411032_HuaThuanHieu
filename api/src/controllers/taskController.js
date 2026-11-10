
const mongoose = require('mongoose');
const Task = require('../models/Task');

const visibleTasks = (userId) => ({
  $or: [
    { createdBy: userId },
    { assigneeIds: userId }
  ]
});

exports.getTasks = async (req, res) => {
  try {
    const userId = req.userId;

    const tasks = await Task.find(visibleTasks(userId))
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json(tasks);
  } catch (error) {
    console.error('GET TASKS ERROR:', error);
    return res.status(500).json({
      message: 'Không thể tải công việc'
    });
  }
};

exports.getTaskById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ'
      });
    }

    const task = await Task.findOne({
      _id: new mongoose.Types.ObjectId(id),
      $or: [
        { createdBy: new mongoose.Types.ObjectId(userId) },
        { assigneeIds: new mongoose.Types.ObjectId(userId) }
      ]
    });

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc'
      });
    }

    return res.status(200).json(task);
  } catch (error) {
    console.error('GET TASK BY ID ERROR:', error);

    return res.status(500).json({
      message: 'Lỗi khi lấy chi tiết công việc'
    });
  }
};
exports.createTask = async (req, res) => {
  try {
    const {
      title,
      description,
      startDate,
      dueDate,
      priority,
      status
    } = req.body;

    if (!title || !title.trim()) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc'
      });
    }

    const task = await Task.create({
      title: title.trim(),
      description: description || '',
      createdBy: req.userId,
      startDate: startDate || null,
      dueDate: dueDate || null,
      priority: priority || 'medium',
      status: status || 'todo'
    });

    return res.status(201).json({
      message: 'Thêm công việc thành công',
      task
    });
  } catch (error) {
    console.error('CREATE TASK ERROR:', error);

    return res.status(500).json({
      message: 'Lỗi khi thêm công việc'
    });
  }
};

exports.updateTask = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ'
      });
    }

    const allowedFields = [
      'title',
      'description',
      'startDate',
      'dueDate',
      'priority',
      'status'
    ];

    const updateData = {};

    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updateData[field] = req.body[field];
      }
    }

    if (
      updateData.title !== undefined &&
      (typeof updateData.title !== 'string' || !updateData.title.trim())
    ) {
      return res.status(400).json({
        message: 'Tên công việc không hợp lệ'
      });
    }

    if (updateData.title !== undefined) {
      updateData.title = updateData.title.trim();
    }

    const task = await Task.findOneAndUpdate(
      {
        _id: id,
        ...visibleTasks(req.userId)
      },
      { $set: updateData },
      {
        new: true,
        runValidators: true
      }
    );

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc hoặc bạn không có quyền sửa'
      });
    }

    return res.status(200).json({
      message: 'Cập nhật công việc thành công',
      task
    });

  } catch (error) {
    console.error('UPDATE TASK ERROR:', error);

    return res.status(500).json({
      message: 'Lỗi khi cập nhật công việc'
    });
  }
};

exports.deleteTask = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ'
      });
    }

    const task = await Task.findOneAndDelete({
      _id: id,
      ...visibleTasks(req.userId)
    });

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc hoặc bạn không có quyền xóa'
      });
    }

    return res.status(200).json({
      message: 'Xóa công việc thành công',
      task
    });

  } catch (error) {
    console.error('DELETE TASK ERROR:', error);

    return res.status(500).json({
      message: 'Lỗi khi xóa công việc'
    });
  }
};
