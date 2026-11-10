const Task = require('../models/Task');
const User = require('../models/user.model');
const { sendEmail } = require('../service/emailService');

const checkDueReminders = async () => {
  try {
    const now = new Date();
    const next24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    // D3 - Tìm công việc sắp đến hạn trong 24 giờ
    const tasks = await Task.find({
      dueDate: {
        $gt: now,
        $lte: next24Hours
      },
      status: { $ne: 'completed' }
    });

    for (const task of tasks) {
      // Tránh gửi lại cho cùng một hạn hoàn thành
      if (
        task.dueReminderFor &&
        new Date(task.dueReminderFor).getTime() ===
          new Date(task.dueDate).getTime()
      ) {
        continue;
      }

      // Lấy danh sách người cần nhận thông báo
      const recipientIds = [
        task.createdBy,
        ...(task.assigneeIds || []),
        task.primaryAssigneeId
      ].filter(Boolean);

      const users = await User.find({
        _id: { $in: recipientIds }
      }).select('email');

      const emails = [
        ...new Set(users.map(user => user.email).filter(Boolean))
      ];

      if (emails.length === 0) continue;

      const result = await sendEmail({
        to: emails.join(','),
        subject: 'TaskManager - Công việc sắp đến hạn',
        html: `
          <h2>Thông báo công việc sắp đến hạn</h2>
          <p><b>Công việc:</b> ${task.title}</p>
          <p><b>Hạn hoàn thành:</b>
            ${new Date(task.dueDate).toLocaleString('vi-VN', {
              timeZone: 'Asia/Ho_Chi_Minh'
            })}
          </p>
          <p>Vui lòng hoàn thành công việc đúng hạn.</p>
        `
      });

      if (result.success) {
        task.dueReminderSentAt = new Date();
        task.dueReminderFor = task.dueDate;
        await task.save();

        console.log('D3 - Đã gửi email nhắc hạn:', task.title);
      }
    }
  } catch (error) {
    console.error('D3 - Lỗi kiểm tra hạn:', error);
  }
};

module.exports = { checkDueReminders };