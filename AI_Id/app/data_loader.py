"""Loads restaurant menu JSON files and location data, and merges them together."""
import json
import os
import re

RESTAURANTS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "restaurants")
LOCATIONS_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "locations", "location.json")

# Menu data explicitly marks drinks with an "Ichimlik:" name prefix (spacing
# after the colon is inconsistent across files, so the regex tolerates that).
DRINK_PREFIX_RE = re.compile(r"^ichimlik\s*:\s*", re.IGNORECASE)

# Defensive fallback for entries that forgot the "Ichimlik:" prefix.
FALLBACK_DRINK_KEYWORDS = [
    "choy", "sharbat", "coca", "cola", "maxito", "qahva", "stakan",
    "grafin", "choynak", "sok", "kompot",
]
SALAD_KEYWORDS = ["salad", "salat"]


def _classify_and_clean(raw_name, quantity):
    """Return (category, display_name) for a menu item.

    category is "drink", "salad", or "main". The explicit "Ichimlik:" prefix
    is the primary signal for drinks and is stripped from the display name;
    a keyword-based fallback catches entries where it's missing.
    """
    stripped = raw_name.strip()
    match = DRINK_PREFIX_RE.match(stripped)
    if match:
        return "drink", stripped[match.end():].strip()

    text = f"{stripped} {quantity}".lower()
    if any(k in text for k in FALLBACK_DRINK_KEYWORDS):
        return "drink", stripped
    if any(k in text for k in SALAD_KEYWORDS):
        return "salad", stripped
    return "main", stripped


def parse_price(price_str):
    """Defensively extract the numeric so'm amount from a price string.

    Strips everything except digits so malformed entries (missing spaces,
    stray colons, etc.) fail gracefully (return 0) instead of crashing.
    """
    if not isinstance(price_str, (str, int, float)):
        return 0
    digits = re.sub(r"[^\d]", "", str(price_str))
    if not digits:
        return 0
    return int(digits)


def _normalize(name):
    return re.sub(r"[^a-z0-9]", "", name.lower())


def _match_location(restaurant_key, locations):
    """Match a restaurant JSON filename (e.g. 'MarMar') to a location entry
    (e.g. 'MarMar Cafe') by normalized substring matching in either direction.
    """
    norm_key = _normalize(restaurant_key)
    for loc in locations:
        norm_loc_name = _normalize(loc.get("name", ""))
        if not norm_loc_name:
            continue
        if norm_key in norm_loc_name or norm_loc_name in norm_key:
            return loc
    return None


def load_locations():
    if not os.path.exists(LOCATIONS_FILE):
        return []
    with open(LOCATIONS_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def load_restaurants():
    """Returns a list of restaurant dicts:
    {name, location, rating, dishes: [{id, name, price(int), price_raw, quantity}]}
    """
    locations = load_locations()
    restaurants = []

    if not os.path.isdir(RESTAURANTS_DIR):
        return restaurants

    for filename in sorted(os.listdir(RESTAURANTS_DIR)):
        if not filename.lower().endswith(".json"):
            continue
        restaurant_key = os.path.splitext(filename)[0]
        filepath = os.path.join(RESTAURANTS_DIR, filename)
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                raw_items = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue

        dishes = []
        for item in raw_items:
            quantity = item.get("quantity", "").strip()
            category, display_dish_name = _classify_and_clean(item.get("name", ""), quantity)
            dishes.append({
                "id": item.get("id"),
                "name": display_dish_name,
                "category": category,
                "price": parse_price(item.get("price")),
                "price_raw": item.get("price"),
                "quantity": quantity,
            })

        matched_loc = _match_location(restaurant_key, locations)
        if matched_loc:
            display_name = matched_loc.get("name", restaurant_key)
            location = matched_loc.get("location", "Manzil ko'rsatilmagan")
            rating = matched_loc.get("rating")
        else:
            display_name = restaurant_key
            location = "Manzil ko'rsatilmagan"
            rating = None

        if rating is None:
            # TODO: replace with real rating source once available
            rating = round(4.0 + (hash(restaurant_key) % 10) / 10, 1)

        restaurants.append({
            "name": display_name,
            "location": location,
            "rating": rating,
            "dishes": dishes,
        })

    return restaurants
