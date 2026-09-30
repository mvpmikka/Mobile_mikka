"""Thin wrapper around the DeepSeek (deepseek-v4-flash) chat API.

The LLM is only ever used for: intent/free-text understanding, a JSON-based
budget-extraction fallback, and turning already-computed numbers into
friendly Uzbek text. It never computes prices, totals, or budgets itself.
"""
import json
import os

from openai import OpenAI

DEEPSEEK_MODEL = "deepseek-v4-flash"


def _fmt(amount):
    return f"{amount:,}".replace(",", " ")

SYSTEM_PROMPT = (
    "Sening isming Mikka -- restoran va taom to'plamlarini tavsiya qiluvchi "
    "do'stona chatbot yordamchisisan. Faqat taom/restoran tavsiyalari "
    "mavzusida gaplash. Qisqa, samimiy va iliq tarzda javob ber. Hech qachon "
    "narx yoki summalarni o'zing hisoblama yoki o'ylab topma -- senga "
    "beriladigan raqamlarni faqat chiroyli so'zlar bilan ifodala.\n\n"
    "TIL QOIDASI: Foydalanuvchi qaysi tilda yozsa (o'zbek, rus, ingliz yoki "
    "boshqa til), sen ham aynan o'sha tilda javob ber. Tilni har xabarda "
    "qaytadan aniqla va shunga moslash -- foydalanuvchi tilni almashtirsa, "
    "sen ham darhol almashtir."
)


class LLMClient:
    def __init__(self):
        api_key = os.environ.get("DEEPSEEK_API_KEY")
        self.enabled = bool(api_key)
        self._client = None
        if self.enabled:
            self._client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com")

    def _chat(self, messages, temperature=0.7, max_tokens=400):
        if not self.enabled:
            return None
        try:
            response = self._client.chat.completions.create(
                model=DEEPSEEK_MODEL,
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens,
                timeout=15,
            )
            return response.choices[0].message.content
        except Exception:
            return None

    def extract_budget(self, user_text):
        """LLM fallback for budget extraction. Returns int or None."""
        if not self.enabled:
            return None
        messages = [
            {"role": "system", "content": (
                "Foydalanuvchi xabaridan byudjet summasini (so'm) chiqarib ol. "
                "Faqat JSON qaytar, boshqa hech narsa yozma: "
                '{"amount": <butun son yoki null>}'
            )},
            {"role": "user", "content": user_text},
        ]
        raw = self._chat(messages, temperature=0, max_tokens=50)
        if not raw:
            return None
        try:
            cleaned = raw.strip().strip("`").replace("json", "", 1) if raw.strip().startswith("```") else raw
            data = json.loads(cleaned)
            amount = data.get("amount")
            return int(amount) if amount else None
        except (json.JSONDecodeError, ValueError, TypeError, AttributeError):
            return None

    def general_reply(self, user_text):
        """Friendly free-form chat reply (greetings, off-topic, help, etc.)."""
        fallback = (
            "Men Mikkaman 🍽️ Byudjetingizni kiriting va men sizga shunga mos taom "
            "to'plamlarini taqdim etaman. Masalan: \"100000 so'm\" yoki \"150 ming so'm\"."
        )
        if not self.enabled:
            return fallback
        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_text},
        ]
        reply = self._chat(messages)
        return reply or fallback

    def describe_sets(self, budget, sets_data, people_count=1, include_drinks=False):
        """Turn already-computed set data into a friendly intro message.

        `sets_data` numbers are fed in as-is and must not be altered by the LLM.
        """
        people_note = f" ({people_count} kishi uchun)" if people_count > 1 else ""
        fallback = f"{_fmt(budget)} so'm byudjetingiz{people_note} uchun quyidagi to'plamlarni tavsiya qilaman:"
        if not self.enabled:
            return fallback

        summary_lines = []
        for s in sets_data:
            dish_names = ", ".join(d["name"] for d in s["dishes"])
            summary_lines.append(f"- {s['restaurant']}: {dish_names} (jami {s['total']} so'm)")
        context = "\n".join(summary_lines)
        people_line = f"Kishilar soni: {people_count}.\n" if people_count > 1 else ""
        drink_note = (
            "To'plamlarda ichimlik ham bor, chunki foydalanuvchi buni so'radi."
            if include_drinks else
            "Faqat taomlar tavsiya qilinadi, ichimliklar yo'q."
        )

        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": (
                f"Foydalanuvchi byudjeti: {budget} so'm.\n"
                f"{people_line}"
                f"Quyidagi to'plamlar allaqachon hisoblab bo'lingan (raqamlarni o'zgartirma):\n"
                f"{context}\n\n"
                "Shu ma'lumotlar asosida foydalanuvchiga 1-2 gapli iliq, qisqa kirish "
                "xabari yoz. Raqamlarni takrorlashing shart emas, kartalar alohida ko'rsatiladi. "
                f"{drink_note}"
            )},
        ]
        reply = self._chat(messages, temperature=0.7, max_tokens=150)
        return reply or fallback

    def no_match_reply(self, budget, cheapest_price, people_count=1):
        people_note = f" ({people_count} kishi uchun)" if people_count > 1 else ""
        fallback = (
            f"Afsuski, {_fmt(budget)} so'm byudjetga{people_note} mos to'plam topilmadi. "
            f"Eng arzon taom {_fmt(cheapest_price)} so'm turadi."
            if cheapest_price else
            f"Afsuski, {_fmt(budget)} so'm byudjetga{people_note} mos to'plam topilmadi."
        )
        if not self.enabled:
            return fallback
        people_line = f"Kishilar soni: {people_count}.\n" if people_count > 1 else ""
        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": (
                f"Foydalanuvchi byudjeti {budget} so'm, lekin hech qanday to'plam mos kelmadi.\n"
                f"{people_line}"
                f"Eng arzon mavjud taom narxi: {cheapest_price} so'm. "
                "Buni do'stona tarzda tushuntir va byudjetni oshirishni taklif qil. "
                "Raqamlarni o'zgartirma."
            )},
        ]
        reply = self._chat(messages, temperature=0.7, max_tokens=150)
        return reply or fallback
