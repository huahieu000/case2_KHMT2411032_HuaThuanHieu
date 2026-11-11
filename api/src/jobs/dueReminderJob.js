const Task = require('../models/Task');
const User = require('../models/user.model');
// D6 - Model lưu lịch sử gửi email
const EmailLog = require('../models/EmailLog');
const Notification = require('../models/Notification');
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
      // D5 - Tránh gửi email trùng cho cùng hạn và cùng cấu hình
      // D5 - Thời gian nhắc riêng của từng công việc
    const reminderHours = task.reminderHoursBefore ?? 24;
if (
  task.dueReminderFor &&
  new Date(task.dueReminderFor).getTime() ===
    new Date(task.dueDate).getTime() &&
  (task.dueReminderHoursBefore ?? 24) === reminderHours
) {
  continue;
}

// Tính thời điểm cần gửi email nhắc
const reminderTime = new Date(
  new Date(task.dueDate).getTime() -
  reminderHours * 60 * 60 * 1000
);

// Chưa đến thời điểm nhắc thì bỏ qua
if (now < reminderTime) {
  continue;
}

      // Lấy danh sách người cần nhận thông báo
      const recipientIds = [
        task.createdBy,
        ...(task.assigneeIds || []),
        task.primaryAssigneeId
      ].filter(Boolean);
      // D7 - Tạo thông báo trong ứng dụng cho từng người dùng
      const uniqueRecipientIds = [
        ...new Set(recipientIds.map(id => String(id)))
      ];

      for (const userId of uniqueRecipientIds) {
        const eventKey = [
          userId,
          String(task._id),
          new Date(task.dueDate).getTime(),
          reminderHours
        ].join(':');

        try {
          await Notification.updateOne(
            { eventKey },
            {
              $setOnInsert: {
                userId,
                taskId: task._id,
                eventKey,
                title: 'Công việc sắp đến hạn',
                message: `Công việc "${task.title}" sắp đến hạn hoàn thành.`,
                isRead: false,
                readAt: null
              }
            },
            { upsert: true }
          );
        } catch (error) {
          console.error('D7 - Lỗi tạo thông báo:', error.message);
        }
      }
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
  task.dueReminderHoursBefore = reminderHours;
  await task.save();
        // D6 - Lưu lịch sử gửi email thành công
  await EmailLog.create({
  taskId: task._id,
  recipientEmail: emails.join(','),
  subject: 'TaskManager - Công việc sắp đến hạn',
  status: 'success',
  sentAt: new Date()
});
    console.log('D5 - Đã gửi email nhắc hạn:', task.title);
} else {
  // D6 - Lưu lịch sử gửi email thất bại
  await EmailLog.create({
    taskId: task._id,
    recipientEmail: emails.join(','),
    subject: 'TaskManager - Công việc sắp đến hạn',
    status: 'failed',
    errorMessage: result.error?.message || result.error || 'Gửi email thất bại',
    sentAt: new Date()
  });

  console.error('D6 - Gửi email thất bại:', task.title);
}
  }
  } catch (error) {
    console.error('D3 - Lỗi kiểm tra hạn:', error);
  }
};

module.exports = { checkDueReminders };