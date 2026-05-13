const html     = document.documentElement;
const btn      = document.getElementById('themeBtn');
const iconSun  = document.getElementById('iconSun');
const iconMoon = document.getElementById('iconMoon');
let dark = true;

function applyTheme() {
  html.classList.toggle('dark', dark);
  iconSun.style.display  = dark  ? 'block' : 'none';
  iconMoon.style.display = !dark ? 'block' : 'none';
}

btn.addEventListener('click', () => { dark = !dark; applyTheme(); });
applyTheme();

const API_URL = 'https://npgmj6qyeh.execute-api.us-east-1.amazonaws.com/count';
async function updateCounter() {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3000);
    const res = await fetch(API_URL, { 
      method: 'POST',
      signal: controller.signal
    });
    clearTimeout(timeout);
    const data = await res.json();
    const count = data.count ?? data.visitor_count ?? null;
    document.getElementById('counter').textContent =
      count !== null ? Number(count).toLocaleString() : '—';
  } catch {
    document.getElementById('counter').textContent = '—';
  }
}
updateCounter();
