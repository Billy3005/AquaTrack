import asyncio
import os
import random
from datetime import datetime
from typing import Dict, Optional, Tuple

try:
    import ollama
except ImportError:
    ollama = None

try:
    import openai
except ImportError:
    openai = None

try:
    import anthropic
except ImportError:
    anthropic = None

# Import analytics service for enhanced personalization
try:
    from app.services.analytics_service import analytics_service
except ImportError:
    analytics_service = None

# Import CoachResponse from coach endpoint since it's defined there
try:
    from app.api.v1.endpoints.coach import CoachResponse
except ImportError:
    # Define CoachResponse locally if import fails
    from typing import List

    from pydantic import BaseModel, Field

    class CoachResponse(BaseModel):
        response: str
        suggestions: List[str] = Field(default_factory=list)
        action_items: List[str] = Field(default_factory=list)
        motivation_level: str = "medium"
        coaching_type: str = "general"


class AICoachService:
    """
    AI Coach service using Qwen (free local AI) for Vietnamese conversation
    Falls back to enhanced rule-based system if Ollama is not available
    """

    def __init__(self):
        """Initialize AI Coach service with multiple AI providers"""
        # AI Provider availability
        self.anthropic_available = False
        self.openai_available = False
        self.ollama_available = False

        # Model configurations
        self.ollama_model = "qwen2.5:3b"  # Qwen model for Vietnamese conversation

        # Initialize Anthropic Claude
        anthropic_api_key = os.getenv("ANTHROPIC_API_KEY")
        if anthropic and anthropic_api_key:
            try:
                self.anthropic_client = anthropic.Anthropic(api_key=anthropic_api_key)
                self.anthropic_available = True
                print("[OK] Anthropic Claude AI initialized")
            except Exception as e:
                print(f"[WARN] Anthropic initialization failed: {str(e)}")
        else:
            print("ANTHROPIC_API_KEY not set, using fallback inference")

        # Initialize OpenAI
        openai_api_key = os.getenv("OPENAI_API_KEY")
        if openai and openai_api_key:
            try:
                self.openai_client = openai.OpenAI(api_key=openai_api_key)
                self.openai_available = True
                print("OK OpenAI GPT initialized")
            except Exception as e:
                print(f"WARN OpenAI initialization failed: {str(e)}")
        else:
            print("OPENAI_API_KEY not set, using fallback inference")

        # Initialize Ollama (local)
        if ollama:
            try:
                models = ollama.list()
                self.ollama_available = True
                print("OK Ollama local AI initialized")

                # Check if our model is available
                model_names = [model["name"] for model in models.get("models", [])]
                if self.ollama_model not in model_names:
                    print(
                        f"[WARN] Model {self.ollama_model} not found. Available: {model_names}"
                    )
                    if model_names:
                        self.ollama_model = model_names[0]
                        print(f"[INFO] Using model: {self.ollama_model}")

            except Exception as e:
                print(f"Ollama not available: {str(e)}")
                print(
                    "To use AI Coach: Install Ollama and run 'ollama pull qwen2.5:3b'"
                )

        # Determine AI mode with priority: Anthropic > OpenAI > Ollama > Rules
        if self.anthropic_available:
            print("AI Coach mode: Anthropic Claude (Premium)")
        elif self.openai_available:
            print("AI Coach mode: OpenAI GPT (Cloud)")
        elif self.ollama_available:
            print("AI Coach mode: Qwen2.5 (Ollama Local)")
        else:
            print("AI Coach mode: Enhanced Rule-based")

    def _mask_user_message(self, message: str) -> str:
        """Mask user message for secure logging"""
        if len(message) <= 10:
            return message[:3] + "***"
        return message[:5] + "***" + message[-2:]

    async def generate_coach_response(
        self,
        user_message: str,
        user_context: Dict,
        hydration_data: Dict,
        user_id: str = None,
        db=None,
    ) -> CoachResponse:
        """
        Generate coach response with priority-based AI provider selection
        Priority: Anthropic Claude > OpenAI > Ollama > Enhanced Rules
        """
        # Secure logging - mask user message
        masked_message = self._mask_user_message(user_message)
        print(f"[GENERATE] Processing message: {masked_message}")

        # Try Anthropic Claude first
        if self.anthropic_available:
            try:
                return await self._generate_anthropic_response(
                    user_message, user_context, hydration_data, user_id, db
                )
            except Exception as e:
                print(
                    f"[FALLBACK] Anthropic failed, fallback to next provider: {str(e)}"
                )

        # Fallback to OpenAI
        if self.openai_available:
            try:
                return await self._generate_openai_response(
                    user_message, user_context, hydration_data, user_id, db
                )
            except Exception as e:
                print(f"[FALLBACK] OpenAI failed, fallback to next provider: {str(e)}")

        # Fallback to Ollama
        if self.ollama_available:
            try:
                print("[DEBUG] Calling Qwen via Ollama...")
                return await self._generate_ollama_response(
                    user_message, user_context, hydration_data, user_id, db
                )
            except Exception as e:
                print(f"[FALLBACK] Ollama failed, fallback to rules: {str(e)}")

        # Final fallback to enhanced rules
        return await self._generate_enhanced_rule_response(
            user_message, user_context, hydration_data
        )

    async def _generate_anthropic_response(
        self,
        user_message: str,
        user_context: Dict,
        hydration_data: Dict,
        user_id: str = None,
        db=None,
    ) -> CoachResponse:
        """Generate response using Anthropic Claude"""
        try:
            # Build analytics-enhanced context for Claude
            context_prompt = await self._get_analytics_enhanced_context(
                user_message, user_context, hydration_data, user_id, db
            )

            response = await asyncio.to_thread(
                self.anthropic_client.messages.create,
                model="claude-3-haiku-20240307",  # Fast and cost-effective
                max_tokens=200,
                temperature=0.7,
                system="""Bạn là AQUA AI - trợ lý hydration thông minh của app AquaTrack.

🎯 NHIỆM VỤ:
- Khuyến khích uống nước đều đặn bằng tiếng Việt tự nhiên
- Cá nhân hóa lời khuyên dựa trên data người dùng
- Tạo động lực tích cực và practical

💬 PHONG CÁCH:
- Thân thiện, không formal
- 1-2 câu ngắn gọn
- Emoji phù hợp (💧🌟💪⚡)
- Practical actions

🚫 TRÁNH:
- Lời khuyên y tế chuyên sâu
- Response quá dài
- Ngôn ngữ khô khan""",
                messages=[{"role": "user", "content": context_prompt}],
            )

            ai_text = response.content[0].text.strip()

            # Parse and structure response
            suggestions, action_items = self._parse_ai_response(ai_text, hydration_data)
            coaching_type, motivation_level = self._analyze_response_intent(
                ai_text, hydration_data
            )

            return CoachResponse(
                response=ai_text,
                suggestions=suggestions,
                action_items=action_items,
                motivation_level=motivation_level,
                coaching_type=coaching_type,
            )

        except Exception as e:
            print(f"[AI ERROR] Anthropic error: {str(e)}")
            raise

    async def _generate_openai_response(
        self,
        user_message: str,
        user_context: Dict,
        hydration_data: Dict,
        user_id: str = None,
        db=None,
    ) -> CoachResponse:
        """Generate response using OpenAI GPT"""
        try:
            # Build analytics-enhanced context
            context_prompt = await self._get_analytics_enhanced_context(
                user_message, user_context, hydration_data, user_id, db
            )

            response = await asyncio.to_thread(
                self.openai_client.chat.completions.create,
                model="gpt-3.5-turbo",
                max_tokens=150,
                temperature=0.7,
                messages=[
                    {
                        "role": "system",
                        "content": """Bạn là AQUA AI - trợ lý hydration thông minh của AquaTrack.

🎯 NHIỆM VỤ:
- Khuyến khích uống nước đều đặn (tiếng Việt)
- Cá nhân hóa theo data user
- Tạo động lực practical

💬 PHONG CÁCH:
- Thân thiện, ngắn gọn (1-2 câu)
- Emoji phù hợp: 💧🌟💪⚡
- Actionable advice

🚫 TRÁNH:
- Lời khuyên y tế chuyên sâu
- Response dài
- Ngôn ngữ formal""",
                    },
                    {"role": "user", "content": context_prompt},
                ],
            )

            ai_text = response.choices[0].message.content.strip()

            # Parse and structure response
            suggestions, action_items = self._parse_ai_response(ai_text, hydration_data)
            coaching_type, motivation_level = self._analyze_response_intent(
                ai_text, hydration_data
            )

            return CoachResponse(
                response=ai_text,
                suggestions=suggestions,
                action_items=action_items,
                motivation_level=motivation_level,
                coaching_type=coaching_type,
            )

        except Exception as e:
            print(f"[AI ERROR] OpenAI error: {str(e)}")
            raise

    async def _generate_ollama_response(
        self,
        user_message: str,
        user_context: Dict,
        hydration_data: Dict,
        user_id: str = None,
        db=None,
    ) -> CoachResponse:
        """Generate response using Qwen via Ollama AI"""
        try:
            # Build analytics-enhanced context
            prompt = await self._get_analytics_enhanced_context(
                user_message, user_context, hydration_data, user_id, db
            )

            # Call Ollama API with async thread protection
            response = await asyncio.to_thread(
                ollama.chat,
                model=self.ollama_model,
                messages=[
                    {
                        "role": "system",
                        "content": """Bạn là AQUA AI - trợ lý hydration thông minh của app AquaTrack Việt Nam.

NHIỆM VỤ:
- Khuyến khích người dùng uống nước đều đặn
- Cung cấp lời khuyên về hydration bằng tiếng Việt tự nhiên
- Tạo động lực tích cực và vui vẻ
- Cá nhân hóa dựa trên dữ liệu hydration của user

PHONG CÁCH TRẢ LỜI:
- Tiếng Việt thân thiện, không quá formal
- Sử dụng emoji phù hợp (💧🌟💪⚡)
- Ngắn gọn, không quá 2-3 câu
- Tích cực, khích lệ
- Đưa ra lời khuyên thực tế

TRÁNH:
- Lời khuyên y tế chuyên môn
- Câu trả lời quá dài
- Ngôn ngữ formal/khô khan

Hãy trả lời bằng tiếng Việt thân thiện và khuyến khích.""",
                    },
                    {"role": "user", "content": prompt},
                ],
                options={
                    "temperature": 0.8,  # Creative but not too random
                    "top_p": 0.9,
                    "num_predict": 150,  # Keep responses concise
                },
            )

            ai_text = response["message"]["content"].strip()

            # Parse response for suggestions and actions
            suggestions, action_items = self._parse_ai_response(ai_text, hydration_data)

            # Determine coaching type and motivation level
            coaching_type, motivation_level = self._analyze_response_intent(
                ai_text, hydration_data
            )

            return CoachResponse(
                response=ai_text,
                suggestions=suggestions,
                action_items=action_items,
                motivation_level=motivation_level,
                coaching_type=coaching_type,
            )

        except Exception as e:
            print(f"[AI ERROR] Qwen/Ollama error: {str(e)}")
            raise

    def _build_advanced_context(
        self,
        user_message: str,
        user_context: Dict,
        hydration_data: Dict,
        user_id: str = None,
        db=None,
    ) -> str:
        """Build comprehensive AI context with advanced personalization"""
        total_today = hydration_data.get("total_today", 0)
        log_count = hydration_data.get("log_count", 0)
        current_hour = datetime.now().hour

        # Time context in Vietnamese
        if current_hour < 6:
            time_context = "rạng sáng"
        elif current_hour < 12:
            time_context = "buổi sáng"
        elif current_hour < 14:
            time_context = "buổi trưa"
        elif current_hour < 18:
            time_context = "buổi chiều"
        elif current_hour < 22:
            time_context = "buổi tối"
        else:
            time_context = "đêm muộn"

        # Hydration status analysis
        goal_percentage = (total_today / 2000) * 100
        if total_today >= 2000:
            hydration_status = (
                f"đã hoàn thành mục tiêu ({total_today}ml = {goal_percentage:.0f}%)"
            )
        elif total_today >= 1500:
            remaining = 2000 - total_today
            hydration_status = f"sắp đạt mục tiêu ({total_today}ml, còn {remaining}ml)"
        elif total_today >= 1000:
            hydration_status = (
                f"đang tiến bộ ({total_today}ml = {goal_percentage:.0f}% mục tiêu)"
            )
        elif total_today >= 500:
            hydration_status = (
                f"cần cố gắng thêm ({total_today}ml = {goal_percentage:.0f}%)"
            )
        else:
            hydration_status = (
                f"cần bắt kịp ngay ({total_today}ml = {goal_percentage:.0f}%)"
            )

        # Activity pattern analysis
        if log_count == 0:
            activity_insight = "chưa có log nào hôm nay"
        elif log_count == 1:
            activity_insight = "mới bắt đầu log"
        elif log_count <= 3:
            activity_insight = f"có {log_count} lần log - khá ổn"
        else:
            activity_insight = f"rất tích cực với {log_count} lần log"

        # User context integration
        context_details = ""
        if user_context:
            if user_context.get("activity_level"):
                context_details += (
                    f"- Mức độ hoạt động: {user_context['activity_level']}\n"
                )
            if user_context.get("mood"):
                context_details += f"- Tâm trạng: {user_context['mood']}\n"
            if user_context.get("location"):
                context_details += f"- Vị trí: {user_context['location']}\n"
            if user_context.get("weather"):
                context_details += f"- Thời tiết: {user_context['weather']}\n"

        # Build comprehensive prompt
        prompt = f"""📱 USER MESSAGE: "{user_message}"

⏰ THỜI GIAN & BỐI CẢNH:
- Hiện tại: {time_context} ({current_hour}:00)
- Tình trạng hydration: {hydration_status}
- Hoạt động hôm nay: {activity_insight}

{context_details if context_details else ""}

🎯 YÊU CẦU RESPONSE:
- Trả lời tin nhắn của user bằng tiếng Việt thân thiện
- Dựa trên tình trạng hydration hiện tại để đưa ra lời khuyên phù hợp
- Cá nhân hóa theo behavior pattern của user
- Khuyến khích tích cực, practical và empathetic
- Ngắn gọn 1-2 câu với emoji phù hợp

Hãy response như AQUA AI coach thông minh với deep understanding về user."""

        return prompt

    async def _get_analytics_enhanced_context(
        self,
        user_message: str,
        user_context: Dict,
        hydration_data: Dict,
        user_id: str = None,
        db=None,
    ) -> str:
        """Build analytics-enhanced context for AI responses"""
        # Start with basic context - pass all parameters correctly
        base_context = self._build_advanced_context(
            user_message, user_context, hydration_data, user_id, db
        )

        # Add analytics insights if available
        if not (analytics_service and user_id and db):
            return base_context

        try:
            # Get user analytics profile
            profile = await analytics_service.get_user_analytics_profile(
                db, user_id, days=14
            )

            # Extract key insights for AI context
            user_segment = profile.get("user_segment", {}).get("segment", "unknown")
            coaching_style = profile.get("personalization_context", {}).get(
                "coaching_style_preference", "encouraging"
            )
            motivation_level = (
                profile.get("personalization_context", {})
                .get("motivation_indicators", {})
                .get("level", "medium")
            )

            # Get top recommendations
            recommendations = profile.get("coaching_recommendations", [])[:2]
            rec_context = ""
            if recommendations:
                rec_list = [f"- {rec['message']}" for rec in recommendations]
                rec_context = "\n📋 LỜI KHUYÊN ƯU TIÊN:\n" + "\n".join(rec_list)

            # Risk factors
            risks = profile.get("risk_factors", [])
            risk_context = ""
            if risks:
                high_risks = [risk for risk in risks if risk.get("severity") == "high"]
                if high_risks:
                    risk_context = f"\nWARN RISK FACTORS: {', '.join([r['type'] for r in high_risks])}"

            # Enhanced analytics context
            analytics_enhancement = f"""

📊 PHÂN TÍCH USER (14 ngày):
- User segment: {user_segment}
- Coaching style phù hợp: {coaching_style}
- Mức độ motivation: {motivation_level}{rec_context}{risk_context}

🎯 ENHANCED COACHING INSTRUCTION:
- Adapt tone theo coaching_style preference của user
- Consider user_segment để adjust expectation level
- Address risk factors nếu có trong response
- Sử dụng insights để tạo connection với user's behavior pattern"""

            return base_context + analytics_enhancement

        except Exception as e:
            print(f"[ANALYTICS] Error getting enhanced context: {str(e)}")
            return base_context

    def _parse_ai_response(
        self, ai_text: str, hydration_data: Dict
    ) -> Tuple[List[str], List[str]]:
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

    def _analyze_response_intent(
        self, ai_text: str, hydration_data: Dict
    ) -> Tuple[str, str]:
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
            motivation_level = "low"  # Maintenance mode
        else:
            motivation_level = "medium"

        return coaching_type, motivation_level

    async def _generate_enhanced_rule_response(
        self, user_message: str, user_context: Dict, hydration_data: Dict
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
        if any(
            word in user_message_lower
            for word in ["xin chào", "chào", "hello", "hi", "hey"]
        ):
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
                ],
            }

            if current_hour < 12:
                response = random.choice(time_responses["morning"])
            elif current_hour < 18:
                response = random.choice(time_responses["afternoon"])
            else:
                response = random.choice(time_responses["evening"])

            coaching_type = "greeting"

        # Progress inquiry responses
        elif any(
            word in user_message_lower
            for word in ["tiến độ", "progress", "thế nào", "how am i"]
        ):
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
        elif any(
            word in user_message_lower
            for word in ["động lực", "motivation", "khuyến khích", "encourage"]
        ):
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
        elif any(
            word in user_message_lower
            for word in ["bao nhiều", "how much", "uống", "drink"]
        ):
            if current_hour < 10:
                response = "Buổi sáng nên uống 500-700ml để khởi động! 🌅 Nước ấm hoặc nước lọc đều tốt! 💧"
            elif current_hour < 15:
                response = "Buổi trưa uống 300-500ml mỗi 2-3 tiếng! ⏰ Nghe cơ thể mình nói nhé! 👂"
            elif current_hour < 19:
                response = (
                    "Buổi chiều là thời điểm vàng! ✨ 400-600ml để tăng tập trung! 🎯"
                )
            else:
                response = "Tối uống vừa phải thôi! 🌙 200-300ml để không ảnh hưởng giấc ngủ! 😴"
            suggestions.append("Set timer mỗi 2 tiếng để nhắc uống nước")

        # Energy/tiredness
        elif any(
            word in user_message_lower
            for word in ["mệt", "tired", "năng lượng", "energy"]
        ):
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
            coaching_type=coaching_type,
        )

    def get_proactive_suggestion(self, hydration_data: Dict) -> Optional[str]:
        """Get proactive suggestion based on hydration data"""
        total_today = hydration_data.get("total_today", 0)
        log_count = hydration_data.get("log_count", 0)
        current_hour = datetime.now().hour

        suggestions = []

        # Time-based suggestions
        if current_hour == 8 and log_count == 0:
            suggestions.append(
                "🌅 Chào buổi sáng! Uống 1 ly nước ấm để đánh thức cơ thể nhé!"
            )
        elif current_hour == 12 and total_today < 800:
            suggestions.append("🍽️ Giờ ăn trưa rồi! Nhớ uống nước cùng bữa ăn nhé!")
        elif current_hour == 15 and total_today < 1200:
            suggestions.append(
                "☀️ Buổi chiều cần năng lượng! Uống nước để tăng tập trung!"
            )
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
