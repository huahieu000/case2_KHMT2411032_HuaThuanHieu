const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

exports.sendEmail = async ({ to, subject, html }) => {
    try {
        const info = await transporter.sendMail({
            from: `"TaskManager" <${process.env.EMAIL_USER}>`,
            to,
            subject,
            html,
        });

        console.log('Email gửi thành công:', info.messageId);

        return {
            success: true,
            messageId: info.messageId,
        };
    } catch (error) {
        console.error('Lỗi gửi email:', error.message);

        return {
            success: false,
            error: error.message,
        };
    }
};