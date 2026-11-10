const mongoose = require('mongoose');
const Task = require('../models/Task');
const User = require('../models/user.model');
const { sendEmail } = require('../service/emailService')
// Các giá trị hợp lệ
const VALID_STATUSES = ['todo', 'in_progress', 'completed'];
const VALID_PRIORITIES = ['low', 'medium', 'high'];

// Điều kiện xem công việc:
// Người tạo, người được giao hoặc người được chia sẻ
const visibleTasks = (userId) => {
  const objectId = new mongoose.Types.ObjectId(userId);

  return {
    $or: [
      { createdBy: objectId },
      { assigneeIds: objectId },
      { sharedWithIds: objectId }
    ]
  };
};

// Kiểm tra ID người dùng có hợp lệ và tồn tại
const validateUsers = async (ids) => {
  if (!Array.isArray(ids)) return false;

  const uniqueIds = [...new Set(ids.map(id => String(id)))];

  if (!uniqueIds.every(id => mongoose.isValidObjectId(id))) {
    return false;
  }

  if (uniqueIds.length === 0) return true;

  const count = await User.countDocuments({
    _id: { $in: uniqueIds }
  });

  return count === uniqueIds.length;
};

// Lấy quyền chia sẻ của một người
const getSharedPermission = (task, userId) => {
  const permission = task.sharedPermissions?.find(
    item => item.userId.toString() === userId.toString()
  );

  // Dữ liệu chia sẻ cũ của C3 mặc định là Viewer
  return permission?.permission || 'viewer';
};

// Kiểm tra người dùng có phải Editor được chia sẻ không
const isSharedEditor = (task, userId) => {
  return getSharedPermission(task, userId) === 'editor';
};

// Kiểm tra ngày tháng
const parseDate = (value) => {
  if (value === null || value === '') return null;

  const date = new Date(value);

  if (isNaN(date.getTime())) return undefined;

  return date;
};

// LẤY DANH SÁCH CÔNG VIỆC
// LẤY DANH SÁCH CÔNG VIỆC
exports.getTasks = async (req, res) => {
  try {
    const filter = visibleTasks(req.userId);

    // Tìm kiếm theo tên công việc
    if (req.query.search) {
      const keyword = req.query.search.trim();

      if (keyword) {
        const escapedKeyword = keyword.replace(
          /[.*+?^${}()|[\]\\]/g,
          '\\$&'
        );

        filter.title = {
          $regex: escapedKeyword,
          $options: 'i'
        };
      }
    }

    // Lọc theo trạng thái
    if (req.query.status) {
      if (!VALID_STATUSES.includes(req.query.status)) {
        return res.status(400).json({
          message: 'Trạng thái không hợp lệ'
        });
      }

      filter.status = req.query.status;
    }

    // Lọc theo mức ưu tiên
    if (req.query.priority) {
      if (!VALID_PRIORITIES.includes(req.query.priority)) {
        return res.status(400).json({
          message: 'Mức ưu tiên không hợp lệ'
        });
      }

      filter.priority = req.query.priority;
    }

    // Lọc theo người phụ trách chính
    if (req.query.assigneeId) {
      if (!mongoose.isValidObjectId(req.query.assigneeId)) {
        return res.status(400).json({
          message: 'ID người phụ trách không hợp lệ'
        });
      }

      filter.primaryAssigneeId = new mongoose.Types.ObjectId(
        req.query.assigneeId
      );
    }

    const sortBy = req.query.sortBy || 'createdAt';

    if (!['dueDate', 'createdAt', 'priority'].includes(sortBy)) {
      return res.status(400).json({
        message: 'Kiểu sắp xếp không hợp lệ'
      });
    }

    const tasks = await Task.find(filter).lean();

    // Sắp xếp
    if (sortBy === 'dueDate') {
      tasks.sort((a, b) => {
        if (!a.dueDate && !b.dueDate) return 0;
        if (!a.dueDate) return 1;
        if (!b.dueDate) return -1;
        return new Date(a.dueDate) - new Date(b.dueDate);
      });
    } else if (sortBy === 'priority') {
      const priorityOrder = { high: 1, medium: 2, low: 3 };
      tasks.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);
    } else {
      tasks.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    return res.status(200).json(tasks);
  } catch (error) {
    console.error('GET TASKS ERROR:', error);
    return res.status(500).json({
      message: 'Không thể tải công việc'
    });
  }
};

// XEM CHI TIẾT CÔNG VIỆC
exports.getTaskById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ'
      });
    }

    const task = await Task.findOne({
      _id: id,
      ...visibleTasks(req.userId)
    })
      .populate('createdBy', 'name email')
      .populate('assigneeIds', 'name email')
      .populate('primaryAssigneeId', 'name email')
      .populate('sharedWithIds', 'name email');

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

// TẠO CÔNG VIỆC
exports.createTask = async (req, res) => {
  try {
    const {
      title,
      description,
      startDate,
      dueDate,
      priority = 'medium',
      status = 'todo',
      assigneeIds = [],
      primaryAssigneeId = null,
      sharedWithIds = [],
      sharedPermissions = []
    } = req.body;

    // 1. Kiểm tra tên công việc
    if (typeof title !== 'string' || !title.trim()) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc'
      });
    }

    // 2. Kiểm tra danh sách người dùng
    if (!Array.isArray(assigneeIds) || !Array.isArray(sharedWithIds)) {
      return res.status(400).json({
        message: 'Danh sách người dùng không hợp lệ'
      });
    }

    // 3. Kiểm tra trạng thái và mức ưu tiên
    if (!VALID_STATUSES.includes(status)) {
      return res.status(400).json({
        message: 'Trạng thái không hợp lệ'
      });
    }

    if (!VALID_PRIORITIES.includes(priority)) {
      return res.status(400).json({
        message: 'Mức ưu tiên không hợp lệ'
      });
    }

    // 4. Kiểm tra ID người dùng
    const allUserIds = [
      ...assigneeIds,
      ...sharedWithIds,
      ...(primaryAssigneeId ? [primaryAssigneeId] : [])
    ];

    if (!(await validateUsers(allUserIds))) {
      return res.status(400).json({
        message: 'Có ID người dùng không hợp lệ hoặc không tồn tại'
      });
    }

    // 5. Người phụ trách chính phải thuộc danh sách được giao
    if (
      primaryAssigneeId &&
      !assigneeIds.some(
        id => id.toString() === primaryAssigneeId.toString()
      )
    ) {
      return res.status(400).json({
        message: 'Người phụ trách chính phải nằm trong danh sách người được giao'
      });
    }

    // 6. Kiểm tra ngày tháng
    const start = startDate ? parseDate(startDate) : null;
    const due = dueDate ? parseDate(dueDate) : null;

    if (
      (startDate && !start) ||
      (dueDate && !due)
    ) {
      return res.status(400).json({
        message: 'Ngày tháng không hợp lệ'
      });
    }

    if (start && due && start > due) {
      return res.status(400).json({
        message: 'Ngày bắt đầu không được sau hạn hoàn thành'
      });
    }

    // 7. Kiểm tra quyền chia sẻ
    if (!Array.isArray(sharedPermissions)) {
      return res.status(400).json({
        message: 'Danh sách quyền chia sẻ không hợp lệ'
      });
    }

    const sharedIds = new Set(
      sharedWithIds.map(id => id.toString())
    );

    const permissionUserIds = new Set();

    for (const item of sharedPermissions) {
      if (
        !item ||
        !item.userId ||
        !mongoose.isValidObjectId(item.userId)
      ) {
        return res.status(400).json({
          message: 'Thông tin quyền chia sẻ không hợp lệ'
        });
      }

      const userId = item.userId.toString();

      if (
        !sharedIds.has(userId) ||
        !['viewer', 'editor'].includes(item.permission) ||
        permissionUserIds.has(userId)
      ) {
        return res.status(400).json({
          message: 'Thông tin quyền chia sẻ không hợp lệ'
        });
      }

      permissionUserIds.add(userId);
    }

    // 8. Tạo công việc
    const task = await Task.create({
      title: title.trim(),
      description: typeof description === 'string' ? description : '',
      createdBy: req.userId,
      assigneeIds,
      primaryAssigneeId,
      sharedWithIds,
      startDate: start,
      dueDate: due,
      priority,
      status,
      sharedPermissions
    });

    // 9. GỬI EMAIL CHO NGƯỜI ĐƯỢC GIAO VÀ NGƯỜI ĐƯỢC CHIA SẺ
    try {
      // Gộp hai danh sách để tránh gửi email trùng
      const recipientIds = [
        ...new Set([
          ...task.assigneeIds.map(id => id.toString()),
          ...task.sharedWithIds.map(id => id.toString())
        ])
      ];

      // Lấy thông tin người nhận
      const recipients = await User.find({
        _id: { $in: recipientIds }
      }).select('name email').lean();

      // Lấy tên người tạo
      const creator = await User.findById(req.userId)
        .select('name')
        .lean();

      // Lấy quyền chia sẻ của từng người
      const permissionMap = new Map(
        (task.sharedPermissions || []).map(item => [
          item.userId.toString(),
          item.permission
        ])
      );

      // Hàm xử lý nội dung HTML
      const escapeHtml = (value) =>
        String(value ?? '').replace(/[&<>"']/g, char => ({
          '&': '&amp;',
          '<': '&lt;',
          '>': '&gt;',
          '"': '&quot;',
          "'": '&#39;'
        })[char]);

      const priorityLabels = {
        low: 'Thấp',
        medium: 'Trung bình',
        high: 'Cao'
      };

      // Gửi email cho từng người
      const emailResults = await Promise.all(
        recipients.map(async user => {
          if (!user.email) {
            return {
              email: null,
              success: false,
              error: 'Người dùng chưa có email'
            };
          }

          const userId = user._id.toString();

          const isAssignee = task.assigneeIds.some(
            id => id.toString() === userId
          );

          const isShared = task.sharedWithIds.some(
            id => id.toString() === userId
          );

          const permission = permissionMap.get(userId) || 'viewer';

          const permissionLabel =
            permission === 'editor'
              ? 'Editor - Được xem và chỉnh sửa nội dung công việc'
              : 'Viewer - Chỉ được xem công việc';

          let notification;

          if (isAssignee && isShared) {
            notification = 'Bạn vừa được giao và được chia sẻ một công việc mới.';
          } else if (isAssignee) {
            notification = 'Bạn vừa được giao một công việc mới.';
          } else {
            notification = 'Bạn vừa được mời tham gia xem công việc trên TaskManager.';
          }

          const subject = isAssignee
            ? 'Bạn được giao công việc mới - TaskManager'
            : 'Bạn được mời chia sẻ công việc - TaskManager';

          return await sendEmail({
            to: user.email,
            subject,
            html: `
              <div style="font-family: Arial, sans-serif;
                          max-width: 600px; margin: auto;">

                <h2 style="color: #536DFE;">
                  TaskManager
                </h2>

                <p>Xin chào <b>${escapeHtml(user.name)}</b>,</p>

                <p>${notification}</p>

                <p>
                  Người tạo:
                  <b>${escapeHtml(creator?.name || 'TaskManager')}</b>
                </p>

                <div style="background: #f4f6fc;
                            padding: 16px;
                            border-radius: 8px;">

                  <p>
                    <b>Tên công việc:</b>
                    ${escapeHtml(task.title)}
                  </p>

                  <p>
                    <b>Mô tả:</b>
                    ${escapeHtml(task.description || 'Không có mô tả')}
                  </p>

                  <p>
                    <b>Hạn hoàn thành:</b>
                    ${
                      task.dueDate
                        ? new Date(task.dueDate).toLocaleString('vi-VN', {
                            timeZone: 'Asia/Ho_Chi_Minh'
                          })
                        : 'Chưa thiết lập'
                    }
                  </p>

                  <p>
                    <b>Mức ưu tiên:</b>
                    ${priorityLabels[task.priority]}
                  </p>

                  ${
                    isShared
                      ? `
                        <p>
                          <b>Quyền được cấp:</b>
                          ${permissionLabel}
                        </p>
                      `
                      : ''
                  }

                </div>

                <p>
                  Vui lòng đăng nhập TaskManager
                  để xem chi tiết công việc.
                </p>

                <p>Trân trọng,<br>TaskManager</p>

              </div>
            `
          });
        })
      );

      console.log(
        'KẾT QUẢ GỬI EMAIL GIAO VIỆC VÀ CHIA SẺ:',
        emailResults
      );

    } catch (emailError) {
      // Email lỗi không làm mất công việc đã tạo
      console.error(
        'LỖI GỬI EMAIL GIAO VIỆC VÀ CHIA SẺ:',
        emailError
      );
    }

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

// CẬP NHẬT CÔNG VIỆC

exports.updateTask = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ'
      });
    }

    const task = await Task.findOne({
      _id: id,
      ...visibleTasks(req.userId)
    });

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc'
      });
    }

    // 1. Kiểm tra quyền người dùng
    const currentUserId = req.userId.toString();

    const isCreator =
      task.createdBy.toString() === currentUserId;

    const isAssignee = task.assigneeIds.some(
      userId => userId.toString() === currentUserId
    );

    const isEditor = isSharedEditor(task, currentUserId);

    // Viewer không được chỉnh sửa
    if (!isCreator && !isAssignee && !isEditor) {
      return res.status(403).json({
        message: 'Bạn chỉ có quyền xem công việc này'
      });
    }

    // 2. Người được giao chỉ được sửa trạng thái
    if (!isCreator && isAssignee && !isEditor) {
      const fields = Object.keys(req.body);

      if (fields.length !== 1 || fields[0] !== 'status') {
        return res.status(403).json({
          message: 'Bạn chỉ được phép cập nhật trạng thái công việc'
        });
      }

      if (!VALID_STATUSES.includes(req.body.status)) {
        return res.status(400).json({
          message: 'Trạng thái không hợp lệ'
        });
      }

      task.status = req.body.status;
      await task.save();

      return res.status(200).json({
        message: 'Cập nhật trạng thái thành công',
        task
      });
    }

    // 3. Editor chỉ được sửa nội dung
    if (!isCreator && isEditor) {
      const allowedEditorFields = [
        'title',
        'description',
        'startDate',
        'dueDate',
        'priority',
        'status'
      ];

      const fields = Object.keys(req.body);

      if (fields.length === 0) {
        return res.status(400).json({
          message: 'Không có dữ liệu cập nhật'
        });
      }

      if (fields.some(field => !allowedEditorFields.includes(field))) {
        return res.status(403).json({
          message: 'Editor không được phép thay đổi quyền chia sẻ hoặc người được giao'
        });
      }
    }

    // 4. Các trường được phép cập nhật
    const allowedFields = [
      'title',
      'description',
      'startDate',
      'dueDate',
      'priority',
      'status',
      'assigneeIds',
      'primaryAssigneeId',
      'sharedWithIds',
      'sharedPermissions'
    ];

    for (const field of Object.keys(req.body)) {
      if (!allowedFields.includes(field)) {
        return res.status(400).json({
          message: `Không được phép cập nhật trường ${field}`
        });
      }
    }

    const updateData = { ...req.body };

    // 5. Kiểm tra tên công việc
    if (updateData.title !== undefined) {
      if (
        typeof updateData.title !== 'string' ||
        !updateData.title.trim()
      ) {
        return res.status(400).json({
          message: 'Tên công việc không hợp lệ'
        });
      }

      updateData.title = updateData.title.trim();
    }

    // 6. Kiểm tra mô tả
    if (
      updateData.description !== undefined &&
      typeof updateData.description !== 'string'
    ) {
      return res.status(400).json({
        message: 'Mô tả không hợp lệ'
      });
    }

    // 7. Kiểm tra trạng thái
    if (
      updateData.status !== undefined &&
      !VALID_STATUSES.includes(updateData.status)
    ) {
      return res.status(400).json({
        message: 'Trạng thái không hợp lệ'
      });
    }

    // 8. Kiểm tra mức ưu tiên
    if (
      updateData.priority !== undefined &&
      !VALID_PRIORITIES.includes(updateData.priority)
    ) {
      return res.status(400).json({
        message: 'Mức ưu tiên không hợp lệ'
      });
    }

    // 9. Kiểm tra danh sách người dùng
    for (const field of ['assigneeIds', 'sharedWithIds']) {
      if (
        updateData[field] !== undefined &&
        !Array.isArray(updateData[field])
      ) {
        return res.status(400).json({
          message: 'Danh sách người dùng không hợp lệ'
        });
      }
    }

    const newAssignees =
      updateData.assigneeIds !== undefined
        ? updateData.assigneeIds
        : task.assigneeIds;

    const newPrimary =
      updateData.primaryAssigneeId !== undefined
        ? updateData.primaryAssigneeId
        : task.primaryAssigneeId;

    const newShared =
      updateData.sharedWithIds !== undefined
        ? updateData.sharedWithIds
        : task.sharedWithIds;

    // 10. Kiểm tra quyền chia sẻ
    const newPermissions =
      updateData.sharedPermissions !== undefined
        ? updateData.sharedPermissions
        : (task.sharedPermissions || []);

    if (!Array.isArray(newPermissions)) {
      return res.status(400).json({
        message: 'Danh sách quyền chia sẻ không hợp lệ'
      });
    }

    const sharedIdSet = new Set(
      newShared.map(userId => userId.toString())
    );

    const permissionMap = new Map();

    for (const item of newPermissions) {
      if (
        !item ||
        !item.userId ||
        !mongoose.isValidObjectId(item.userId)
      ) {
        return res.status(400).json({
          message: 'Thông tin quyền chia sẻ không hợp lệ'
        });
      }

      const userId = item.userId.toString();

      if (
        !sharedIdSet.has(userId) ||
        !['viewer', 'editor'].includes(item.permission) ||
        permissionMap.has(userId)
      ) {
        return res.status(400).json({
          message: 'Thông tin quyền chia sẻ không hợp lệ'
        });
      }

      permissionMap.set(userId, {
        userId,
        permission: item.permission
      });
    }

    // Người mới được chia sẻ mặc định là Viewer
    const normalizedPermissions = [...sharedIdSet].map(userId => {
      return permissionMap.get(userId) || {
        userId,
        permission: 'viewer'
      };
    });

    if (
      updateData.sharedPermissions !== undefined ||
      updateData.sharedWithIds !== undefined
    ) {
      updateData.sharedPermissions = normalizedPermissions;
    }

    // 11. Kiểm tra ID người dùng tồn tại
    const allUserIds = [
      ...newAssignees,
      ...newShared,
      ...(newPrimary ? [newPrimary] : [])
    ];

    if (!(await validateUsers(allUserIds))) {
      return res.status(400).json({
        message: 'Có ID người dùng không hợp lệ hoặc không tồn tại'
      });
    }

    // 12. Người phụ trách chính phải thuộc danh sách được giao
    if (
      newPrimary &&
      !newAssignees.some(
        userId => userId.toString() === newPrimary.toString()
      )
    ) {
      return res.status(400).json({
        message: 'Người phụ trách chính phải nằm trong danh sách người được giao'
      });
    }

    // 13. Kiểm tra ngày tháng
    if (updateData.startDate !== undefined) {
      const start = parseDate(updateData.startDate);

      if (updateData.startDate && !start) {
        return res.status(400).json({
          message: 'Ngày bắt đầu không hợp lệ'
        });
      }

      updateData.startDate = start;
    }

    if (updateData.dueDate !== undefined) {
      const due = parseDate(updateData.dueDate);

      if (updateData.dueDate && !due) {
        return res.status(400).json({
          message: 'Hạn hoàn thành không hợp lệ'
        });
      }

      updateData.dueDate = due;
    }

    const finalStart =
      updateData.startDate !== undefined
        ? updateData.startDate
        : task.startDate;

    const finalDue =
      updateData.dueDate !== undefined
        ? updateData.dueDate
        : task.dueDate;

    if (finalStart && finalDue && finalStart > finalDue) {
      return res.status(400).json({
        message: 'Ngày bắt đầu không được sau hạn hoàn thành'
      });
    }

    // 14. Lưu công việc
    // 14. Xác định người mới được mời chia sẻ

// Danh sách người đã được chia sẻ trước đó
const oldSharedIds = new Set(
  (task.sharedWithIds || []).map(
    userId => userId.toString()
  )
);

// Lấy những người mới được thêm vào
const newSharedUserIds =
  updateData.sharedWithIds !== undefined
    ? updateData.sharedWithIds
        .map(userId => userId.toString())
        .filter(userId => !oldSharedIds.has(userId))
    : [];

// 15. Lưu công việc
Object.assign(task, updateData);

await task.save();
// D2 - Gửi email cho người mới được mời
if (newSharedUserIds.length > 0) {
  try {
    const invitedUsers = await User.find({
      _id: { $in: newSharedUserIds }
    }).select('name email').lean();

    const creator = await User.findById(task.createdBy)
      .select('name')
      .lean();

    for (const user of invitedUsers) {
      if (!user.email) continue;

      const permission = task.sharedPermissions.find(
        item => item.userId.toString() === user._id.toString()
      )?.permission || 'viewer';

      const result = await sendEmail({
        to: user.email,
        subject: 'Bạn được mời tham gia công việc - TaskManager',
        html: `
          <div style="font-family: Arial, sans-serif;">
            <h2 style="color: #536DFE;">TaskManager</h2>
            <p>Xin chào ${user.name},</p>
            <p>Bạn vừa được mời xem hoặc tham gia công việc.</p>
            <p><b>Người tạo:</b> ${creator?.name || 'TaskManager'}</p>
            <p><b>Công việc:</b> ${task.title}</p>
            <p><b>Quyền:</b> ${permission === 'editor' ? 'Editor - Chỉnh sửa' : 'Viewer - Chỉ xem'}</p>
            <p>Vui lòng đăng nhập TaskManager để xem chi tiết.</p>
          </div>
        `
      });

      console.log('D2 - KẾT QUẢ GỬI EMAIL:', user.email, result);
    }
  } catch (emailError) {
    console.error('D2 - LỖI GỬI EMAIL:', emailError);
  }
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

// XÓA CÔNG VIỆC
exports.deleteTask = async (req, res) => {
  try {
    const { id } = req.params;

    // 1. Kiểm tra ID công việc
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ'
      });
    }

    // 2. Tìm công việc
    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc'
      });
    }

    // 3. Kiểm tra quyền xóa
    const isCreator =
      task.createdBy.toString() === req.userId.toString();

    if (!isCreator) {
      return res.status(403).json({
        message: 'Chỉ người tạo công việc mới có quyền xóa'
      });
    }

    // 4. Tiến hành xóa
    await Task.findByIdAndDelete(id);

    // 5. Trả kết quả
    return res.status(200).json({
      message: 'Xóa công việc thành công'
    });

  } catch (error) {
    console.error('DELETE TASK ERROR:', error);

    return res.status(500).json({
      message: 'Lỗi khi xóa công việc'
    });
  }
};


// LẤY DANH SÁCH CÔNG VIỆC THEO 4 NHÓM
exports.getTaskGroups = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.userId);

    const [created, assigned, responsible, shared] = await Promise.all([
      Task.find({
        createdBy: userId
      }).sort({ createdAt: -1 }).lean(),

      Task.find({
        assigneeIds: userId,
        primaryAssigneeId: { $ne: userId },
        createdBy: { $ne: userId }
      }).sort({ createdAt: -1 }).lean(),

      Task.find({
        primaryAssigneeId: userId,
        createdBy: { $ne: userId }
      }).sort({ createdAt: -1 }).lean(),

      Task.find({
        sharedWithIds: userId,
        createdBy: { $ne: userId },
        assigneeIds: { $ne: userId },
        primaryAssigneeId: { $ne: userId }
      }).sort({ createdAt: -1 }).lean()
    ]);

    return res.status(200).json({
      created,
      assigned,
      responsible,
      shared
    });

  } catch (error) {
    console.error('GET TASK GROUPS ERROR:', error);

    return res.status(500).json({
      message: 'Không thể tải nhóm công việc'
    });
  }
};

