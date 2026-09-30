"""Restaurant recommendation chatbot -- server entry point.

Run with: python main.py
Then open http://127.0.0.1:5000 in a browser.
"""
from dotenv import load_dotenv

load_dotenv()

from flask import Flask, jsonify, render_template, request

from app.data_loader import load_restaurants
from app.llm_client import LLMClient
from app.recommender import (
    build_sets,
    parse_budget_regex,
    parse_people_count,
    strip_people_phrase,
    wants_drink,
)

app = Flask(__name__)

RESTAURANTS = load_restaurants()
llm = LLMClient()


def _serialize_sets(sets_data):
    return [
        {
            "restaurant": s["restaurant"],
            "location": s["location"],
            "rating": s["rating"],
            "dishes": [
                {
                    "name": d["name"],
                    "price": d["price"],
                    "quantity": d["quantity"],
                    "unit_price": d.get("unit_price", d["price"]),
                }
                for d in s["dishes"]
            ],
            "total": s["total"],
            "people_count": s.get("people_count", 1),
        }
        for s in sets_data
    ]


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/chat", methods=["POST"])
def chat():
    payload = request.get_json(silent=True) or {}
    user_message = (payload.get("message") or "").strip()

    if not user_message:
        return jsonify({"reply": "Xabar bo'sh bo'lmasligi kerak.", "sets": []})

    people_count = parse_people_count(user_message) or 1
    budget_text = strip_people_phrase(user_message) if people_count > 1 else user_message

    budget = parse_budget_regex(budget_text)
    if budget is None:
        budget = llm.extract_budget(budget_text)

    if not budget or budget <= 0:
        reply = llm.general_reply(user_message)
        return jsonify({"reply": reply, "sets": []})

    include_drinks = wants_drink(user_message)
    sets_data, cheapest_price = build_sets(RESTAURANTS, budget, people_count, include_drinks)

    if not sets_data:
        reply = llm.no_match_reply(budget, cheapest_price, people_count)
        return jsonify({"reply": reply, "sets": []})

    reply = llm.describe_sets(budget, sets_data, people_count, include_drinks)
    return jsonify({"reply": reply, "sets": _serialize_sets(sets_data)})


if __name__ == "__main__":
    # host="0.0.0.0" so a phone on the same Wi-Fi can reach this dev
    # server too (default 127.0.0.1 only accepts connections from this
    # machine) — needed for physical-device testing via AI_API_BASE_URL.
    app.run(debug=True, host="0.0.0.0", port=5000)
