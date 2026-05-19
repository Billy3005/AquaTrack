import os
import random
from datetime import datetime
from typing import Dict, List, Optional, Tuple

try:
    import ollama
except ImportError:
    ollama = None

# Import CoachResponse from coach endpoint since it's defined there
try:
    from app.api.v1.endpoints.coach import CoachResponse
except ImportError:
    # Define CoachResponse locally if import fails
    from typing import List
    from pydantic import BaseModel

    class CoachResponse(BaseModel):
        response: str
        suggestions: List[str] = []
        action_items: List[str] = []
        motivation_level: str = "medium"
        coaching_type: str = "general"


class AICoachService:
    """
    AI Coach service using Ollama (free local AI) for Vietnamese conversation
    Falls back to enhanced rule-based system if Ollama is not available
    """

    def __init__(self):
        """Initialize AI Coach service"""
        self.ollama_available = False
        self.model_name = "llama3.2:1b"  # Lightweight model for speed

        if ollama:
            try:
                # Test if Ollama is running
                models = ollama.list()
                self.ollama_available = True
                print("Ollama AI Coach initialized successfully")

                # Check if our model is available
                model_names = [model['name'] for model in models.get('models', [])]
                if self.model_name not in model_names:
                    print(f"Model {self.model_name} not found. Available models: {model_names}")
                    # Fallback to any available model
                    if model_names:
                        self.model_name = model_names[0]
                        print(f"Using model: {self.model_name}")

            except Exception as e:
                print(f"Ollama not available: {str(e)}")
                print("To use AI Coach: Install Ollama and run 'ollama pull llama3.2:1b'")
        else:
            print("Ollama package not installed")

        print(f"AI Coach mode: {'Ollama AI' if self.ollama_available else 'Enhanced Rule-based'}")

    async def generate_coach_response(
        self,
        user_message: str,
        user_context: Dict,
        hydration_data: Dict
    ) -> CoachResponse:
        """
        Generate coach response using AI or enhanced rules
        """
        if self.ollama_available:
            return await self._generate_ai_response(user_message, user_context, hydration_data)
        else:
            return await self._generate_enhanced_rule_response(user_message, user_context, hydration_data)

    async def _generate_ai_response(
        self,
        user_message: str,
        user_context: Dict,
        hydration_data: Dict
    ) -> CoachResponse:
        """Generate response using Ollama AI"""
        try:
            # Build context prompt
            prompt = self._build_ai_prompt(user_message, user_context, hydration_data)

            # Call Ollama API
            response = ollama.chat(
                model=self.model_name,
                messages=[
                    {
                        'role': 'system',
                        'content': '''Bạn là AQUA AI - trợ lý hydration thông minh và thân thiện của ứng dụng AquaTrack.

NHIỆM VỤ:
- Khuyến khích người dùng uống nước đều đặn
- Cung cấp lời khuyên về hydration bằng tiếng Việt tự nhiên
- Tạo động lực tích cực và vui vẻ
- Cá nhân hóa dựa trên dữ liệu hydration của user

PHONG CÁCH TRAU LỜI:
- Tiếng Việt thân thiện, không quá formal
- Sử dụng emoji phù hợp (💧🌟💪)
- Ngắn gọn, không quá 2-3 câu
- Tích cực, khích lệ
- Đưa ra lời khuyên thực tế

TRÁNH:
- Lời khuyên y tế chuyên môn
- Câu trả lời quá dài
- Ngôn ngữ formal/khô khan'''
                    },
                    {
                        'role': 'user',
                        'content': prompt
                    }
                ],
                options={
                    'temperature': 0.8,  # Creative but not too random
                    'top_p': 0.9,
                    'max_tokens': 150    # Keep responses concise
                }
            )

            ai_text = response['message']['content'].strip()

            # Parse response for suggestions and actions
            suggestions, action_items = self._parse_ai_response(ai_text, hydration_data)

            # Determine coaching type and motivation level
            coaching_type, motivation_level = self._analyze_response_intent(ai_text, hydration_data)

            return CoachResponse(
                response=ai_text,
                suggestions=suggestions,
                action_items=action_items,
                motivation_level=motivation_level,
                coaching_type=coaching_type
            )

        except Exception as e:
            print(f"🤖 Ollama AI error: {str(e)}")
            # Fallback to enhanced rules
            return await self._generate_enhanced_rule_response(user_message, user_context, hydration_data)

    def _build_ai_prompt(self, user_message: str, user_context: Dict, hydration_data: Dict) -> str:
        """Build comprehensive prompt for AI"""
        total_today = hydration_data.get("total_today", 0)
        log_count = hydration_data.get("log_count", 0)
        current_hour = datetime.now().hour

        # Time context
        time_context = "buổi sáng" if current_hour < 12 else "buổi chiều" if current_hour < 18 else "buổi tối"

        # Hydration status
        if total_today >= 2000:
            hydration_status = "đã đạt mục tiêu"
        elif total_today >= 1000:
            hydration_status = f"đã uống {total_today}ml, cần thêm {2000-total_today}ml"
        else:
            hydration_status = f"mới uống {total_today}ml, cần cải thiện"

        prompt = f"""THÔNG TIN NGƯỜI DÙNG:
- Tin nhắn: "{user_message}"
- Thời gian: {time_context} ({current_hour}h)
- Tình trạng hydration: {hydration_status}
- Số lần log hôm nay: {log_count}

NGỮ CẢNH THÊM:
{user_context}

Hãy trả lời như AQUA AI coach thân thiện, khuyến khích user dựa trên thông tin trên."""

        return prompt

    def _parse_ai_response(self, ai_text: str, hydration_data: Dict) -> Tuple[List[str], List[str]]:
        """Parse AI response to extract suggestions and actions"""
        suggestions = []
        action_items = []

        # Simple parsing - look for action keywords
        if "uống nước" in ai_text.lower() or "uống thêm" in ai_text.lower():
            total_today = hydration_data.get("total_today", 0)
            if total_today < 1000:
                action_items.append("Uống 500ml nước ngay")
            elif total_today < 1500:
                action_items.append("Uống 300ml nước")
            else:
                action_items.append("Uống 200ml nước")

        if "nhắc nhở" in ai_text.lower() or "reminder" in ai_text.lower():
            suggestions.append("Set timer mỗi 30 phút để nhắc uống nước")

        if "tuyệt vời" in ai_text.lower() or "xuất sắc" in ai_text.lower():
            suggestions.append("Tiếp tục duy trì thói quen tốt!")

        return suggestions, action_items

    def _analyze_response_intent(self, ai_text: str, hydration_data: Dict) -> Tuple[str, str]:
        """Analyze AI response to determine coaching type and motivation level"""
        text_lower = ai_text.lower()
        total_today = hydration_data.get("total_today", 0)

        # Determine coaching type
        if any(word in text_lower for word in ["chào", "xin chào", "hi", "hello"]):
            coaching_type = "greeting"
        elif any(word in text_lower for word in ["tuyệt vời", "xuất sắc", "giỏi lắm"]):
            coaching_type = "achievement"
        elif any(word in text_lower for word in ["uống nước", "cần", "nên"]):
            coaching_type = "reminder"
        elif any(word in text_lower for word in ["động lực", "cố gắng", "tiếp tục"]):
            coaching_type = "encouragement"
        else:
            coaching_type = "general"

        # Determine motivation level
        if total_today < 500:
            motivation_level = "high"  # Need strong motivation
        elif total_today >= 2000:
            motivation_level = "low"   # Maintenance mode
        else:
            motivation_level = "medium"

        return coaching_type, motivation_level

    async def _generate_enhanced_rule_response(
        self,
        user_message: str,
        user_context: Dict,
        hydration_data: Dict
    ) -> CoachResponse:
        """Enhanced rule-based responses when AI is not available"""

        total_today = hydration_data.get("total_today", 0)
        log_count = hydration_data.get("log_count", 0)
        current_hour = datetime.now().hour

        user_message_lower = user_message.lower().strip()

        suggestions = []
        action_items = []
        motivation_level = "medium"
        coaching_type = "general"

        # Enhanced greeting responses
        if any(word in user_message_lower for word in ["xin chào", "chào", "hello", "hi", "hey"]):
            time_responses = {
                "morning": [
                    f"Chào buổi sáng! ☀️ Bạn đã uống {total_today}ml rồi. Hãy bắt đầu ngày mới với năng lượng tích cực! 💧",
                    f"Buổi sáng tươi mới! 🌅 Đã {total_today}ml trong túi. Uống thêm nước để khởi động não bộ nhé! 🧠✨",
                ],
                "afternoon": [
                    f"Chào buổi chiều! 🌞 {total_today}ml và đang tăng! Cần một chút nước để tăng năng lượng không? ⚡",
                    f"Buổi chiều vui vẻ! ☀️ {log_count} lần log hôm nay - bạn đang làm rất tốt! 💪",
                ],
                "evening": [
                    f"Chào buổi tối! 🌙 Hôm nay đã {total_today}ml - thành tích tuyệt vời! 🌟",
                    f"Tối tốt lành! ✨ {total_today}ml hôm nay, cơ thể bạn cảm ơn! 🙏",
                ]
            }

            if current_hour < 12:
                response = random.choice(time_responses["morning"])
            elif current_hour < 18:
                response = random.choice(time_responses["afternoon"])
            else:
                response = random.choice(time_responses["evening"])

            coaching_type = "greeting"

        # Progress inquiry responses
        elif any(word in user_message_lower for word in ["tiến độ", "progress", "thế nào", "how am i"]):
            if total_today >= 2000:
                response = f"Xuất sắc! 🎉 {total_today}ml - bạn đã vượt mục tiêu! Cơ thể đang hoạt động tối ưu! 💫"
                motivation_level = "high"
                coaching_type = "achievement"
            elif total_today >= 1500:
                remaining = 2000 - total_today
                response = f"Tuyệt vời! 🌟 Còn {remaining}ml nữa thôi! Bạn đang rất gần đích! 🎯"
                suggestions.append("Uống 2-3 ly nước nhỏ trong 2 giờ tới")
                motivation_level = "medium"
            elif total_today >= 1000:
                remaining = 2000 - total_today
                response = f"Khá tốt! 💪 Còn {remaining}ml để hoàn thành mục tiêu. Cố gắng lên! 🚀"
                action_items.append(f"Uống {min(500, remaining)}ml nước")
            else:
                response = f"Cần cải thiện! 📈 Mới {total_today}ml thôi. Uống ngay 1 ly nước lớn để bắt kịp nhé! 💧"
                motivation_level = "high"
                action_items.append("Uống 500ml nước ngay bây giờ")

        # Motivation requests
        elif any(word in user_message_lower for word in ["động lực", "motivation", "khuyến khích", "encourage"]):
            motivational_responses = [
                "Mỗi giọt nước là một món quà cho cơ thể! 🎁 Bạn đang đầu tư vào sức khỏe tương lai! ✨",
                "Nước = năng lượng = thành công! ⚡ Bạn có thể làm được! 💪",
                "Cơ thể bạn biết ơn mỗi ly nước bạn uống! 🙏 Hãy tiếp tục chăm sóc bản thân! 💖",
                "Hydration tốt = tâm trạng tốt! 😊 Bạn đang trên đường đúng! 🛤️",
            ]
            response = random.choice(motivational_responses)
            motivation_level = "high"
            coaching_type = "encouragement"

        # Hydration advice
        elif any(word in user_message_lower for word in ["bao nhiều", "how much", "uống", "drink"]):
            if current_hour < 10:
                response = "Buổi sáng nên uống 500-700ml để khởi động! 🌅 Nước ấm hoặc nước lọc đều tốt! 💧"
            elif current_hour < 15:
                response = "Buổi trưa uống 300-500ml mỗi 2-3 tiếng! ⏰ Nghe cơ thể mình nói nhé! 👂"
            elif current_hour < 19:
                response = "Buổi chiều là thời điểm vàng! ✨ 400-600ml để tăng tập trung! 🎯"
            else:
                response = "Tối uống vừa phải thôi! 🌙 200-300ml để không ảnh hưởng giấc ngủ! 😴"
            suggestions.append("Set timer mỗi 2 tiếng để nhắc uống nước")

        # Energy/tiredness
        elif any(word in user_message_lower for word in ["mệt", "tired", "năng lượng", "energy"]):
            if total_today < 1000:
                response = "Mệt mỏi có thể do thiếu nước! 😴 Uống 1-2 ly nước và cảm nhận sự khác biệt! ✨"
                action_items.append("Uống 400ml nước để tăng năng lượng")
            else:
                response = "Hydration tốt rồi! 👍 Mệt có thể do thiếu ngủ hoặc stress. Hãy nghỉ ngơi! 😊"
            coaching_type = "advice"

        # Default contextual responses
        else:
            if total_today < 500:
                responses = [
                    "Hôm nay cần uống nhiều nước hơn! 💧 Bắt đầu ngay với 1 ly nước lớn nhé! 🥤",
                    "Cơ thể đang khát nước! 🏜️ Hãy cho nó thứ cần thiết nhất! 💝",
                ]
                motivation_level = "high"
                action_items.append("Uống 500ml nước ngay")
            elif total_today >= 2000:
                responses = [
                    "Tuyệt vời! Bạn đã đạt mục tiêu! 🎉 Tôi có thể giúp gì khác không? 😊",
                    "Perfect hydration! 💯 Cơ thể bạn đang cảm ơn bạn đấy! 🙏✨",
                ]
                motivation_level = "low"
            else:
                responses = [
                    f"Đang tiến bộ tốt! 📈 {total_today}ml rồi! Tiếp tục cố gắng nhé! 💪",
                    f"Bạn đang trên đường đạt mục tiêu! 🎯 Còn {2000-total_today}ml nữa thôi! 🚀",
                ]

            response = random.choice(responses)

        return CoachResponse(
            response=response,
            suggestions=suggestions,
            action_items=action_items,
            motivation_level=motivation_level,
            coaching_type=coaching_type
        )

    def get_proactive_suggestion(self, hydration_data: Dict) -> Optional[str]:
        """Get proactive suggestion based on hydration data"""
        total_today = hydration_data.get("total_today", 0)
        log_count = hydration_data.get("log_count", 0)
        current_hour = datetime.now().hour

        suggestions = []

        # Time-based suggestions
        if current_hour == 8 and log_count == 0:
            suggestions.append("🌅 Chào buổi sáng! Uống 1 ly nước ấm để đánh thức cơ thể nhé!")
        elif current_hour == 12 and total_today < 800:
            suggestions.append("🍽️ Giờ ăn trưa rồi! Nhớ uống nước cùng bữa ăn nhé!")
        elif current_hour == 15 and total_today < 1200:
            suggestions.append("☀️ Buổi chiều cần năng lượng! Uống nước để tăng tập trung!")
        elif current_hour == 18 and total_today < 1600:
            suggestions.append("🌆 Sắp hết ngày rồi! Cố gắng uống thêm nước nhé!")

        # Progress-based suggestions
        if total_today < 400 and current_hour > 10:
            suggestions.append("💧 Cần bù nước gấp! Hãy uống 500ml ngay để bắt kịp!")
        elif total_today >= 2000:
            suggestions.append("🎉 Xuất sắc! Bạn đã đạt mục tiêu hôm nay!")

        return random.choice(suggestions) if suggestions else None


# Global service instance
ai_coach_service = AICoachService()