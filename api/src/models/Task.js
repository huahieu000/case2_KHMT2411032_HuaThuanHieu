const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema(
  {
    // Tên công việc
    title: {
      type: String,
      required: true,
      trim: true
    },

    // Mô tả
    description: {
      type: String,
      default: ''
    },

    // Người tạo
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },

    // Danh sách người được giao
    assigneeIds: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }],

    // Người phụ trách chính
    primaryAssigneeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null
    },

    // Danh sách người được chia sẻ
    sharedWithIds: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }],
    sharedPermissions: [{
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
      },
      permission: {
        type: String,
        enum: ['viewer', 'editor'],
        default: 'viewer'
      }
    }],

    // Ngày bắt đầu
    startDate: {
      type: Date,
      default: null
    },

    // Hạn hoàn thành
    dueDate: {
      type: Date,
      default: null
    },
    // D3 - Thời điểm đã gửi email nhắc hạn
dueReminderSentAt: {
  type: Date,
  default: null
},

// D3 - Hạn hoàn thành đã được nhắc
dueReminderFor: {
  type: Date,
  default: null
},
// D5 - Lưu số giờ đã dùng khi gửi email nhắc hạn
dueReminderHoursBefore: {
  type: Number,
  default: null
},
// D5 - Cấu hình số giờ nhắc trước hạn
reminderHoursBefore: {
  type: Number,
  enum: [1, 6, 12, 24, 48],
  default: 24
},  

    // Mức độ ưu tiên
    priority: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'medium'
    },

    // Trạng thái
    status: {
      type: String,
      enum: ['todo', 'in_progress', 'completed'],
      default: 'todo'
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('Task', taskSchema);