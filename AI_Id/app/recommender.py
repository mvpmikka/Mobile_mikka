"""Budget parsing (regex) and deterministic set-building / combination logic.

No arithmetic here is ever delegated to the LLM -- everything is plain
Python regex + integer math, per project requirements.
"""
import itertools
import re

MIN_BUDGET_RATIO = 0.8  # sets should use at least 80% of the budget when possible
MAX_COMBO_SIZE = 3
MAX_SETS = 5
MAX_PER_RESTAURANT = 2

PEOPLE_PATTERN = re.compile(
    r"(\d+)\s*(?:kishi\w*|nafar\w*|odam\w*|kishilar\w*|"
    r"человек\w*|чел\.?|persons?|people|guys)",
    re.IGNORECASE,
)

DRINK_REQUEST_KEYWORDS = [
    "ichimlik", "ichimliklar", "ichadigan", "napitok", "напит", "drink",
]


_NUMBER_WORD_MULTIPLIERS = [
    (r"million|mln", 1_000_000),
    (r"ming|k\b", 1_000),
]


def parse_people_count(text):
    """Extract a "for N people" count from free text (kishi/nafar/odam/people/...).

    Returns an int >= 1, or None if no people-count phrase was found.
    """
    if not text:
        return None
    match = PEOPLE_PATTERN.search(text)
    if not match:
        return None
    try:
        count = int(match.group(1))
    except ValueError:
        return None
    return count if count > 0 else None


def wants_drink(text):
    """Detect whether the user explicitly asked for a drink to be included."""
    if not text:
        return False
    lowered = text.lower()
    return any(k in lowered for k in DRINK_REQUEST_KEYWORDS)


def strip_people_phrase(text):
    """Remove a matched "N kishi/nafar/..." phrase so budget parsing doesn't
    mistake the people-count number for the money amount."""
    if not text:
        return text
    return PEOPLE_PATTERN.sub("", text)


def parse_budget_regex(text):
    """Try to extract a budget amount (in so'm) from free-form user text.

    Handles: "100000", "100000 so'm", "100 ming so'm", "100k", "100.5 ming".
    Returns an int amount, or None if nothing budget-like was found.
    """
    if not text:
        return None
    lowered = text.lower().replace(",", ".")

    # Look for "<number> <multiplier word>" first (e.g. "100 ming so'm")
    for pattern, multiplier in _NUMBER_WORD_MULTIPLIERS:
        match = re.search(r"(\d+(?:\.\d+)?)\s*(?:" + pattern + r")", lowered)
        if match:
            try:
                return int(float(match.group(1)) * multiplier)
            except ValueError:
                continue

    # Fall back to a plain number (optionally followed by so'm/som/sum)
    match = re.search(r"(\d{2,})\s*(?:so'?m|som|sum)?", lowered)
    if match:
        try:
            return int(match.group(1))
        except ValueError:
            return None

    return None


def _generate_restaurant_combos(dishes, budget):
    """All affordable dish combinations (size 1..MAX_COMBO_SIZE) for one restaurant."""
    combos = []
    seen_totals = set()
    for size in range(1, MAX_COMBO_SIZE + 1):
        for combo in itertools.combinations(dishes, size):
            categories = [d["category"] for d in combo]
            if size > 1 and "main" not in categories:
                continue  # multi-item sets should include at least one main dish
            if categories.count("drink") > 1:
                continue  # never stack more than one drink in a single set
            total = sum(d["price"] for d in combo)
            if total == 0 or total > budget:
                continue
            if total in seen_totals:
                continue
            seen_totals.add(total)
            combos.append({"dishes": list(combo), "total": total})
    return combos


def _scale_for_people(candidate, people_count):
    """Scale a single-person set's dishes/total up for a group of `people_count`."""
    scaled_dishes = [
        {
            "name": d["name"],
            "quantity": d["quantity"],
            "unit_price": d["price"],
            "price": d["price"] * people_count,
        }
        for d in candidate["dishes"]
    ]
    return {
        "restaurant": candidate["restaurant"],
        "location": candidate["location"],
        "rating": candidate["rating"],
        "dishes": scaled_dishes,
        "total": candidate["total"] * people_count,
        "people_count": people_count,
    }


def build_sets(restaurants, budget, people_count=1, include_drinks=False):
    """Build up to MAX_SETS recommended sets that fit the budget.

    By default only food is recommended (no drinks). Pass include_drinks=True
    when the user explicitly asked for a drink to be part of the set -- in
    that case each combo may include at most one drink alongside the food.

    If `people_count` > 1, the given `budget` is treated as the TOTAL budget
    for the whole group: a per-person budget (budget // people_count) is used
    to find a single-person combo, which is then scaled up (dishes/prices
    multiplied by people_count) so the group gets enough food for everyone.

    Returns (sets, cheapest_price). `sets` is a list of:
      {restaurant, location, rating, dishes, total, people_count}
    `cheapest_price` is the cheapest single dish found anywhere (used to
    craft a helpful "budget too low" message when no set fits).
    """
    people_count = max(1, people_count)
    effective_budget = budget // people_count if people_count > 1 else budget

    all_candidates = []
    cheapest_price = None

    for restaurant in restaurants:
        if include_drinks:
            food_dishes = restaurant["dishes"]
        else:
            food_dishes = [d for d in restaurant["dishes"] if d["category"] != "drink"]

        for dish in food_dishes:
            if dish["price"] > 0 and (cheapest_price is None or dish["price"] < cheapest_price):
                cheapest_price = dish["price"]

        combos = _generate_restaurant_combos(food_dishes, effective_budget)
        for combo in combos:
            all_candidates.append({
                "restaurant": restaurant["name"],
                "location": restaurant["location"],
                "rating": restaurant["rating"],
                "dishes": combo["dishes"],
                "total": combo["total"],
            })

    if not all_candidates:
        return [], cheapest_price

    # Prefer sets that use a healthy chunk of the (per-person) budget, closest first.
    target_min = effective_budget * MIN_BUDGET_RATIO
    all_candidates.sort(key=lambda c: (c["total"] < target_min, -c["total"]))

    selected = []
    per_restaurant_count = {}
    for candidate in all_candidates:
        r = candidate["restaurant"]
        if per_restaurant_count.get(r, 0) >= MAX_PER_RESTAURANT:
            continue
        selected.append(candidate)
        per_restaurant_count[r] = per_restaurant_count.get(r, 0) + 1
        if len(selected) >= MAX_SETS:
            break

    if people_count > 1:
        selected = [_scale_for_people(c, people_count) for c in selected]
    else:
        for c in selected:
            c["people_count"] = 1

    return selected, cheapest_price
