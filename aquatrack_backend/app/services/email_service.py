"""
Email service for user verification, notifications, and marketing
Supports multiple providers: SMTP, SendGrid, AWS SES
"""
import asyncio
import secrets
import smtplib
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Dict, List, Optional

from jinja2 import Environment, FileSystemLoader
from pydantic import EmailStr
from sqlalchemy.orm import Session

from app.core.config import settings
from app.crud.user import user_crud


class EmailVerificationService:
    """Service for handling email verification tokens and sending verification emails"""

    def __init__(self):
        self.verification_tokens: Dict[str, Dict] = {}
        self.template_env = Environment(loader=FileSystemLoader("app/templates/email"))

    def generate_verification_token(self, user_id: str, email: str) -> str:
        """Generate a secure verification token"""
        token = secrets.token_urlsafe(32)
        expires_at = datetime.utcnow() + timedelta(hours=24)

        self.verification_tokens[token] = {
            "user_id": user_id,
            "email": email,
            "expires_at": expires_at,
            "created_at": datetime.utcnow(),
        }

        return token

    def verify_token(self, token: str) -> Optional[Dict]:
        """Verify and consume a verification token"""
        token_data = self.verification_tokens.get(token)

        if not token_data:
            return None

        # Check if token is expired
        if datetime.utcnow() > token_data["expires_at"]:
            # Remove expired token
            del self.verification_tokens[token]
            return None

        # Remove used token (one-time use)
        del self.verification_tokens[token]
        return token_data

    def cleanup_expired_tokens(self):
        """Remove expired tokens to prevent memory leaks"""
        current_time = datetime.utcnow()
        expired_tokens = [
            token for token, data in self.verification_tokens.items()
            if current_time > data["expires_at"]
        ]

        for token in expired_tokens:
            del self.verification_tokens[token]

    async def send_verification_email(
        self,
        user_email: str,
        user_name: str,
        verification_token: str
    ) -> bool:
        """Send email verification email"""
        try:
            verification_link = f"{settings.FRONTEND_URL}/verify-email?token={verification_token}"

            html_content = self._get_verification_email_template(
                user_name=user_name,
                verification_link=verification_link
            )

            success = await self._send_email(
                to_email=user_email,
                subject="Xác thực tài khoản AquaTrack của bạn",
                html_content=html_content
            )

            return success

        except Exception as e:
            print(f"Failed to send verification email: {e}")
            return False

    def _get_verification_email_template(self, user_name: str, verification_link: str) -> str:
        """Generate HTML email template for verification"""
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Xác thực tài khoản AquaTrack</title>
            <style>
                body {{ font-family: 'SF Pro Display', -apple-system, sans-serif; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #0D1B2A 0%, #1B4A73 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f8f9fa; padding: 30px; }}
                .button {{ display: inline-block; background: #00B4D8; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; }}
                .footer {{ background: #e9ecef; padding: 20px; border-radius: 0 0 10px 10px; font-size: 12px; color: #6c757d; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🌊 Chào mừng đến với AquaTrack!</h1>
                    <p>Xin chào {user_name}!</p>
                </div>

                <div class="content">
                    <h2>Xác thực tài khoản của bạn</h2>
                    <p>Cảm ơn bạn đã đăng ký AquaTrack! Để hoàn tất quá trình đăng ký, vui lòng click vào nút bên dưới để xác thực email của bạn:</p>

                    <p style="text-align: center; margin: 30px 0;">
                        <a href="{verification_link}" class="button">Xác thực tài khoản</a>
                    </p>

                    <p>Hoặc copy link này vào trình duyệt:</p>
                    <p style="background: #e9ecef; padding: 10px; border-radius: 5px; word-break: break-all;">
                        {verification_link}
                    </p>

                    <p><strong>Lưu ý:</strong> Link này sẽ hết hạn sau 24 giờ.</p>

                    <h3>Tại sao cần xác thực email?</h3>
                    <ul>
                        <li>🔐 Bảo mật tài khoản của bạn</li>
                        <li>📧 Nhận thông báo quan trọng</li>
                        <li>🎯 Nhận lời khuyên hydration cá nhân</li>
                        <li>👥 Kết nối với bạn bè</li>
                    </ul>
                </div>

                <div class="footer">
                    <p>Nếu bạn không tạo tài khoản này, vui lòng bỏ qua email này.</p>
                    <p>© 2026 AquaTrack - Ứng dụng theo dõi hydration thông minh</p>
                </div>
            </div>
        </body>
        </html>
        """


class EmailNotificationService:
    """Service for sending various notification emails"""

    async def send_password_reset_email(
        self,
        user_email: str,
        user_name: str,
        reset_token: str
    ) -> bool:
        """Send password reset email"""
        try:
            reset_link = f"{settings.FRONTEND_URL}/reset-password?token={reset_token}"

            html_content = self._get_password_reset_template(
                user_name=user_name,
                reset_link=reset_link
            )

            success = await self._send_email(
                to_email=user_email,
                subject="Đặt lại mật khẩu AquaTrack",
                html_content=html_content
            )

            return success

        except Exception as e:
            print(f"Failed to send password reset email: {e}")
            return False

    async def send_welcome_email(
        self,
        user_email: str,
        user_name: str
    ) -> bool:
        """Send welcome email after verification"""
        try:
            html_content = self._get_welcome_email_template(user_name)

            success = await self._send_email(
                to_email=user_email,
                subject="🌊 Chào mừng bạn đến với AquaTrack!",
                html_content=html_content
            )

            return success

        except Exception as e:
            print(f"Failed to send welcome email: {e}")
            return False

    async def send_hydration_reminder_email(
        self,
        user_email: str,
        user_name: str,
        current_progress: int,
        daily_goal: int = 2000
    ) -> bool:
        """Send hydration reminder email"""
        try:
            html_content = self._get_hydration_reminder_template(
                user_name=user_name,
                current_progress=current_progress,
                daily_goal=daily_goal
            )

            success = await self._send_email(
                to_email=user_email,
                subject="💧 Nhắc nhở hydration từ AquaTrack",
                html_content=html_content
            )

            return success

        except Exception as e:
            print(f"Failed to send hydration reminder: {e}")
            return False

    def _get_password_reset_template(self, user_name: str, reset_link: str) -> str:
        """Generate password reset email template"""
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Đặt lại mật khẩu AquaTrack</title>
            <style>
                body {{ font-family: 'SF Pro Display', -apple-system, sans-serif; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #0D1B2A 0%, #1B4A73 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f8f9fa; padding: 30px; }}
                .button {{ display: inline-block; background: #dc3545; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; }}
                .footer {{ background: #e9ecef; padding: 20px; border-radius: 0 0 10px 10px; font-size: 12px; color: #6c757d; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔐 Đặt lại mật khẩu</h1>
                    <p>Xin chào {user_name}!</p>
                </div>

                <div class="content">
                    <h2>Yêu cầu đặt lại mật khẩu</h2>
                    <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản AquaTrack của bạn.</p>

                    <p style="text-align: center; margin: 30px 0;">
                        <a href="{reset_link}" class="button">Đặt lại mật khẩu</a>
                    </p>

                    <p><strong>Lưu ý quan trọng:</strong></p>
                    <ul>
                        <li>Link này chỉ có hiệu lực trong 1 giờ</li>
                        <li>Chỉ sử dụng được một lần</li>
                        <li>Nếu bạn không yêu cầu, hãy bỏ qua email này</li>
                    </ul>

                    <p>Để bảo mật tài khoản, vui lòng không chia sẻ link này với ai khác.</p>
                </div>

                <div class="footer">
                    <p>Nếu bạn không yêu cầu đặt lại mật khẩu, tài khoản của bạn vẫn an toàn.</p>
                    <p>© 2026 AquaTrack - Bảo mật là ưu tiên hàng đầu</p>
                </div>
            </div>
        </body>
        </html>
        """

    def _get_welcome_email_template(self, user_name: str) -> str:
        """Generate welcome email template"""
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Chào mừng đến với AquaTrack!</title>
            <style>
                body {{ font-family: 'SF Pro Display', -apple-system, sans-serif; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #00B4D8 0%, #7B5EA7 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f8f9fa; padding: 30px; }}
                .tip {{ background: #e3f2fd; border-left: 4px solid #00B4D8; padding: 15px; margin: 15px 0; }}
                .footer {{ background: #e9ecef; padding: 20px; border-radius: 0 0 10px 10px; font-size: 12px; color: #6c757d; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎉 Chào mừng {user_name}!</h1>
                    <p>Tài khoản của bạn đã được kích hoạt thành công!</p>
                </div>

                <div class="content">
                    <h2>Bắt đầu hành trình hydration thông minh!</h2>
                    <p>AquaTrack sẵn sàng giúp bạn duy trì thói quen uống nước lành mạnh với:</p>

                    <div class="tip">
                        <strong>🤖 AI Coach cá nhân</strong><br>
                        Nhận lời khuyên thông minh dựa trên thói quen của bạn
                    </div>

                    <div class="tip">
                        <strong>📸 Smart Scan</strong><br>
                        Chụp ảnh ly nước để AI tính toán chính xác lượng nước
                    </div>

                    <div class="tip">
                        <strong>👥 Kết nối bạn bè</strong><br>
                        Cùng bạn bè thi đấu và động viên nhau
                    </div>

                    <div class="tip">
                        <strong>🏆 Level & Achievement</strong><br>
                        Nhận XP và unlock avatar khi đạt mục tiêu
                    </div>

                    <h3>Tips để bắt đầu:</h3>
                    <ol>
                        <li>Đặt mục tiêu hydration cá nhân (khuyến nghị 2000ml/ngày)</li>
                        <li>Log ly nước đầu tiên bằng Smart Scan</li>
                        <li>Kết nối với bạn bè để tạo động lực</li>
                        <li>Chat với AI Coach khi cần lời khuyên</li>
                    </ol>

                    <p>Chúc bạn có một hành trình hydration thành công! 💧</p>
                </div>

                <div class="footer">
                    <p>Mọi thắc mắc, vui lòng liên hệ support@aquatrack.app</p>
                    <p>© 2026 AquaTrack - Sống khỏe mỗi ngày</p>
                </div>
            </div>
        </body>
        </html>
        """

    def _get_hydration_reminder_template(
        self,
        user_name: str,
        current_progress: int,
        daily_goal: int
    ) -> str:
        """Generate hydration reminder email template"""
        percentage = int((current_progress / daily_goal) * 100)
        remaining = daily_goal - current_progress

        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Nhắc nhở Hydration</title>
            <style>
                body {{ font-family: 'SF Pro Display', -apple-system, sans-serif; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #00B4D8 0%, #90E0EF 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f8f9fa; padding: 30px; }}
                .progress-bar {{ background: #e9ecef; height: 20px; border-radius: 10px; overflow: hidden; }}
                .progress-fill {{ background: linear-gradient(90deg, #00B4D8, #90E0EF); height: 100%; width: {percentage}%; }}
                .footer {{ background: #e9ecef; padding: 20px; border-radius: 0 0 10px 10px; font-size: 12px; color: #6c757d; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>💧 {user_name}, đã uống đủ nước chưa?</h1>
                    <p>Hãy cùng kiểm tra tiến độ hôm nay!</p>
                </div>

                <div class="content">
                    <h2>Tiến độ hydration hôm nay</h2>
                    <div class="progress-bar">
                        <div class="progress-fill"></div>
                    </div>
                    <p style="text-align: center; margin: 15px 0;">
                        <strong>{current_progress}ml / {daily_goal}ml ({percentage}%)</strong>
                    </p>

                    {"<p style='color: #28a745; font-weight: bold;'>🎉 Tuyệt vời! Bạn đã đạt mục tiêu hôm nay!</p>" if current_progress >= daily_goal else f"<p style='color: #dc3545; font-weight: bold;'>Còn {remaining}ml nữa để đạt mục tiêu!</p>"}

                    <h3>Lời khuyên từ AI Coach:</h3>
                    {"<p>Hãy duy trì thói quen tuyệt vời này! Uống nước đều đặn giúp duy trì năng lượng và sức khỏe tốt.</p>" if current_progress >= daily_goal else "<p>Hãy uống 1-2 ly nước ngay bây giờ. Chia nhỏ lượng nước còn lại trong ngày để dễ đạt mục tiêu!</p>"}

                    <p style="text-align: center; margin: 30px 0;">
                        <strong>Mở AquaTrack ngay để log nước!</strong>
                    </p>
                </div>

                <div class="footer">
                    <p>Để tắt nhắc nhở email, vào Settings trong app.</p>
                    <p>© 2026 AquaTrack - Nhắc nhở thông minh</p>
                </div>
            </div>
        </body>
        </html>
        """


class EmailService:
    """Main email service combining verification and notifications"""

    def __init__(self):
        self.verification_service = EmailVerificationService()
        self.notification_service = EmailNotificationService()
        self.smtp_config = {
            "host": settings.SMTP_HOST,
            "port": settings.SMTP_PORT,
            "username": settings.SMTP_USERNAME,
            "password": settings.SMTP_PASSWORD,
            "use_tls": settings.SMTP_USE_TLS,
        }

    async def _send_email(
        self,
        to_email: str,
        subject: str,
        html_content: str
    ) -> bool:
        """Send email using configured SMTP"""
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = settings.FROM_EMAIL
            msg['To'] = to_email

            # Add HTML content
            html_part = MIMEText(html_content, 'html', 'utf-8')
            msg.attach(html_part)

            # Send email
            with smtplib.SMTP(self.smtp_config["host"], self.smtp_config["port"]) as server:
                if self.smtp_config["use_tls"]:
                    server.starttls()

                if self.smtp_config["username"] and self.smtp_config["password"]:
                    server.login(self.smtp_config["username"], self.smtp_config["password"])

                server.send_message(msg)
                return True

        except Exception as e:
            print(f"SMTP email failed: {e}")
            return False

    async def send_verification_email(
        self,
        user_id: str,
        user_email: str,
        user_name: str
    ) -> Optional[str]:
        """Generate and send verification email"""
        token = self.verification_service.generate_verification_token(user_id, user_email)
        success = await self.verification_service.send_verification_email(
            user_email, user_name, token
        )
        return token if success else None

    async def verify_email_token(self, token: str, db: Session) -> bool:
        """Verify email token and activate user"""
        token_data = self.verification_service.verify_token(token)

        if not token_data:
            return False

        # Update user as verified
        user = user_crud.get(db, token_data["user_id"])
        if user and user.email == token_data["email"]:
            # Mark email as verified
            user_crud.update_preferences(
                db, user_id=user.id, preferences={"email_verified": True}
            )

            # Send welcome email
            await self.notification_service.send_welcome_email(
                user.email, user.username or "AquaTrack User"
            )

            return True

        return False

    def cleanup_expired_tokens(self):
        """Clean up expired verification tokens"""
        self.verification_service.cleanup_expired_tokens()


# Global email service instance
email_service = EmailService()


# Background task for cleanup
async def cleanup_expired_tokens_task():
    """Background task to clean up expired tokens periodically"""
    while True:
        try:
            email_service.cleanup_expired_tokens()
            await asyncio.sleep(3600)  # Clean up every hour
        except Exception as e:
            print(f"Token cleanup error: {e}")
            await asyncio.sleep(300)  # Retry in 5 minutes on error