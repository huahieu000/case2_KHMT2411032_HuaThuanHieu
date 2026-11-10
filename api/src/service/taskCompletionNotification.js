const User = require('../models/user.model');
const { sendEmail } = require('./emailService');

// D4 - Gửi email khi công việc hoàn thành
const notifyTaskCompleted = async (oldTask, task) => {
  // Chỉ gửi khi trạng thái chuyển sang completed
  if (
    oldTask.status === 'completed' ||
    task.status !== 'completed'
  ) {
    return;
  }

  // Danh sách người nhận
  const recipientIds = [
    task.createdBy,
    ...(task.assigneeIds || []),
    task.primaryAssigneeId,
    ...(task.sharedWithIds || [])
  ].filter(Boolean);

  const users = await User.find({
    _id: { $in: recipientIds }
  }).select('email');

  const emails = [
    ...new Set(users.map(user => user.email).filter(Boolean))
  ];

  if (emails.length === 0) return;

  const escapeHtml = value =>
    String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');

  const result = await sendEmail({
    to: emails.join(','),
    subject: 'TaskManager - Công việc đã hoàn thành',
    html: `
      <h2>Thông báo hoàn thành công việc</h2>
      <p><b>Tên công việc:</b> ${escapeHtml(task.title)}</p>
      <p><b>Trạng thái:</b> Đã hoàn thành</p>
      <p>Vui lòng mở TaskManager để xem chi tiết.</p>
    `
  });

  console.log('D4 - Kết quả email hoàn thành:', result);
};

module.exports = { notifyTaskCompleted };