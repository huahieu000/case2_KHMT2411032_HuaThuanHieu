const mongoose = require('mongoose');

const emailLogSchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Task',
      required: true
    },

    recipientEmail: {
      type: String,
      required: true
    },

    subject: {
      type: String,
      required: true
    },

    status: {
      type: String,
      enum: ['success', 'failed'],
      required: true
    },

    errorMessage: {
      type: String,
      default: null
    },

    sentAt: {
      type: Date,
      default: Date.now
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('EmailLog', emailLogSchema);