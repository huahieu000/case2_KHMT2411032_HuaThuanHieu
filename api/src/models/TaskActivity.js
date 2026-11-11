
const mongoose = require('mongoose');

// E4 - Lưu lịch sử hoạt động của công việc
const taskActivitySchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Task',
      required: true,
      index: true
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },

    action: {
      type: String,
      enum: ['created', 'updated', 'status_changed', 'assignee_changed'],
      required: true
    },

    description: {
      type: String,
      required: true
    },

    changes: {
      type: mongoose.Schema.Types.Mixed,
      default: {}
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('TaskActivity', taskActivitySchema);
