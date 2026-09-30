(function () {
  "use strict";

  const FOOD_EMOJIS = ["🍕", "🍔", "🍟", "🌭", "🥗", "🍜", "🍲", "🥘", "🍢", "🍹", "🥤", "☕", "🍰", "🍣", "🥟", "🍩"];

  function initEmojiBackground() {
    const container = document.getElementById("emojiBg");
    const count = window.innerWidth < 640 ? 14 : 24;
    for (let i = 0; i < count; i++) {
      const span = document.createElement("span");
      span.textContent = FOOD_EMOJIS[Math.floor(Math.random() * FOOD_EMOJIS.length)];
      const size = 16 + Math.random() * 28;
      const left = Math.random() * 100;
      const duration = 14 + Math.random() * 18;
      const delay = Math.random() * -30;
      span.style.left = left + "vw";
      span.style.fontSize = size + "px";
      span.style.animationDuration = duration + "s";
      span.style.animationDelay = delay + "s";
      container.appendChild(span);
    }
  }

  const chatWindow = document.getElementById("chatWindow");
  const form = document.getElementById("composerForm");
  const input = document.getElementById("messageInput");
  const sendBtn = document.getElementById("sendBtn");

  function scrollToBottom() {
    chatWindow.scrollTop = chatWindow.scrollHeight;
  }

  function addBubble(text, sender) {
    const row = document.createElement("div");
    row.className = "bubble-row " + sender;
    const bubble = document.createElement("div");
    bubble.className = "bubble";
    bubble.textContent = text;
    row.appendChild(bubble);
    chatWindow.appendChild(row);
    scrollToBottom();
    return row;
  }

  function addTypingIndicator() {
    const row = document.createElement("div");
    row.className = "bubble-row bot";
    row.id = "typingRow";
    const bubble = document.createElement("div");
    bubble.className = "bubble typing-dots";
    bubble.innerHTML = "<span></span><span></span><span></span>";
    row.appendChild(bubble);
    chatWindow.appendChild(row);
    scrollToBottom();
  }

  function removeTypingIndicator() {
    const row = document.getElementById("typingRow");
    if (row) row.remove();
  }

  function formatSom(amount) {
    return amount.toLocaleString("uz-UZ").replace(/,/g, " ") + " so'm";
  }

  function renderSets(sets) {
    const wrap = document.createElement("div");
    wrap.className = "sets-grid";

    sets.forEach((set) => {
      const card = document.createElement("div");
      card.className = "set-card";

      const header = document.createElement("div");
      header.className = "set-card-header";
      header.innerHTML =
        '<div class="set-card-title">' + escapeHtml(set.restaurant) + "</div>" +
        '<div class="set-card-rating">⭐ ' + Number(set.rating).toFixed(1) + "</div>";
      card.appendChild(header);

      const location = document.createElement("div");
      location.className = "set-card-location";
      location.textContent = "📍 " + set.location;
      if (set.people_count && set.people_count > 1) {
        location.textContent += "   •   👥 " + set.people_count + " kishi uchun";
      }
      card.appendChild(location);

      const dishList = document.createElement("ul");
      dishList.className = "set-card-dishes";
      set.dishes.forEach((dish) => {
        const li = document.createElement("li");
        const multiplier = set.people_count && set.people_count > 1
          ? '<span class="dish-qty"> × ' + set.people_count + "</span>"
          : "";
        li.innerHTML =
          '<span class="dish-name">' + escapeHtml(dish.name) +
          '<span class="dish-qty">(' + escapeHtml(dish.quantity) + ")</span>" + multiplier + "</span>" +
          '<span class="dish-price">' + formatSom(dish.price) + "</span>";
        dishList.appendChild(li);
      });
      card.appendChild(dishList);

      const total = document.createElement("div");
      total.className = "set-card-total";
      total.innerHTML =
        "<span>Jami</span><span class=\"amount\">" + formatSom(set.total) + "</span>";
      card.appendChild(total);

      wrap.appendChild(card);
    });

    const row = document.createElement("div");
    row.className = "bubble-row bot";
    row.appendChild(wrap);
    chatWindow.appendChild(row);
    scrollToBottom();
  }

  function escapeHtml(str) {
    const div = document.createElement("div");
    div.textContent = str == null ? "" : String(str);
    return div.innerHTML;
  }

  async function sendMessage(message) {
    addBubble(message, "user");
    input.value = "";
    sendBtn.disabled = true;
    addTypingIndicator();

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message }),
      });
      const data = await res.json();
      removeTypingIndicator();
      addBubble(data.reply || "...", "bot");
      if (data.sets && data.sets.length > 0) {
        renderSets(data.sets);
      }
    } catch (err) {
      removeTypingIndicator();
      addBubble("Kechirasiz, server bilan bog'lanishda xatolik yuz berdi. Qayta urinib ko'ring.", "bot");
    } finally {
      sendBtn.disabled = false;
      input.focus();
    }
  }

  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const message = input.value.trim();
    if (!message) return;
    sendMessage(message);
  });

  initEmojiBackground();
  addBubble("Byudjetingizni kiriting va men sizga shunga mos taom to'plamlarini taqdim etaman.", "bot");
})();
