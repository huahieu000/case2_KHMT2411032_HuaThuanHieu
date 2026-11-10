
const User = require('../models/user.model');
const { sendEmail } = require('./emailService');

// D3 - Phát hiện thay đổi thông tin quan trọng
const getImportantChanges = (oldTask, newTask) => {
  const changes = [];

  const fields = {
    title: 'Tên công việc',
    description: 'Mô tả',
    dueDate: 'Hạn hoàn thành',
    priority: 'Mức ưu tiên',
    status: 'Trạng thái',
    assigneeIds: 'Người được giao',
    primaryAssigneeId: 'Người phụ trách chính'
  };

  const normalize = (field, value) => {
    if (field === 'dueDate') {
      return value ? new Date(value).getTime() : null;
    }

    if (field === 'assigneeIds') {
      return (value || [])
        .map(id => id.toString())
        .sort()
        .join(',');
    }

    if (field === 'primaryAssigneeId') {
      return value ? value.toString() : null;
    }

    return value ?? null;
  };

  for (const [field, label] of Object.entries(fields)) {
    const oldValue = normalize(field, oldTask[field]);
    const newValue = normalize(field, newTask[field]);

    if (oldValue !== newValue) {
      changes.push(label);
    }
  }

  return changes;
};

// D3 - Gửi email khi thông tin quan trọng thay đổi
const notifyTaskChanges = async (oldTask, newTask) => {
  const changes = getImportantChanges(oldTask, newTask);

  if (changes.length === 0) return;

  const recipientIds = [
    newTask.createdBy,
    ...(newTask.assigneeIds || []),
    newTask.primaryAssigneeId,
    ...(newTask.sharedWithIds || [])
  ].filter(Boolean);

  const users = await User.find({
    _id: { $in: recipientIds }
  }).select('email');

  const emails = [
    ...new Set(users.map(user => user.email).filter(Boolean))
  ];

  if (emails.length === 0) return;

  const escapeHtml = value => String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

  const result = await sendEmail({
    to: emails.join(','),
    subject: 'TaskManager - Thông tin công việc đã thay đổi',
    html: `
      <h2>Thông báo cập nhật công việc</h2>
      <p><b>Công việc:</b> ${escapeHtml(newTask.title)}</p>
      <p><b>Thông tin đã thay đổi:</b></p>
      <ul>
        ${changes.map(change => `<li>${escapeHtml(change)}</li>`).join('')}
      </ul>
      <p>Vui lòng mở TaskManager để xem thông tin mới nhất.</p>
    `
  });

  console.log('D3 - Kết quả email thay đổi:', result);
};

// Chỉ xuất các hàm sau khi đã khai báo
module.exports = {
  getImportantChanges,
  notifyTaskChanges
};
