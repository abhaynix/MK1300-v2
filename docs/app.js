/**
 * Ant Esports MK1300 V2 - Showcase Website JavaScript Engine
 * Provides live 61-key keyboard visualization, RGB lighting effects, and clipboard actions.
 */

// Recovered 61-Key ANSI Geometry
const KEYBOARD_LAYOUT = [
  // Row 1 (14 keys)
  [
    { name: 'Esc', width: 'u-1', sub: '~' },
    { name: '1', width: 'u-1', sub: '!' },
    { name: '2', width: 'u-1', sub: '@' },
    { name: '3', width: 'u-1', sub: '#' },
    { name: '4', width: 'u-1', sub: '$' },
    { name: '5', width: 'u-1', sub: '%' },
    { name: '6', width: 'u-1', sub: '^' },
    { name: '7', width: 'u-1', sub: '&' },
    { name: '8', width: 'u-1', sub: '*' },
    { name: '9', width: 'u-1', sub: '(' },
    { name: '0', width: 'u-1', sub: ')' },
    { name: '-', width: 'u-1', sub: '_' },
    { name: '=', width: 'u-1', sub: '+' },
    { name: 'Backspace', width: 'u-2', sub: '' }
  ],
  // Row 2 (14 keys)
  [
    { name: 'Tab', width: 'u-15', sub: '' },
    { name: 'Q', width: 'u-1', sub: '' },
    { name: 'W', width: 'u-1', sub: '' },
    { name: 'E', width: 'u-1', sub: '' },
    { name: 'R', width: 'u-1', sub: '' },
    { name: 'T', width: 'u-1', sub: '' },
    { name: 'Y', width: 'u-1', sub: '' },
    { name: 'U', width: 'u-1', sub: '' },
    { name: 'I', width: 'u-1', sub: '' },
    { name: 'O', width: 'u-1', sub: '' },
    { name: 'P', width: 'u-1', sub: '' },
    { name: '[', width: 'u-1', sub: '{' },
    { name: ']', width: 'u-1', sub: '}' },
    { name: '\\', width: 'u-15', sub: '|' }
  ],
  // Row 3 (13 keys)
  [
    { name: 'Caps', width: 'u-175', sub: '' },
    { name: 'A', width: 'u-1', sub: '' },
    { name: 'S', width: 'u-1', sub: '' },
    { name: 'D', width: 'u-1', sub: '' },
    { name: 'F', width: 'u-1', sub: '' },
    { name: 'G', width: 'u-1', sub: '' },
    { name: 'H', width: 'u-1', sub: '' },
    { name: 'J', width: 'u-1', sub: '' },
    { name: 'K', width: 'u-1', sub: '' },
    { name: 'L', width: 'u-1', sub: '' },
    { name: ';', width: 'u-1', sub: ':' },
    { name: '\'', width: 'u-1', sub: '"' },
    { name: 'Enter', width: 'u-225', sub: '' }
  ],
  // Row 4 (12 keys)
  [
    { name: 'Shift', width: 'u-225', sub: '' },
    { name: 'Z', width: 'u-1', sub: '' },
    { name: 'X', width: 'u-1', sub: '' },
    { name: 'C', width: 'u-1', sub: '' },
    { name: 'V', width: 'u-1', sub: '' },
    { name: 'B', width: 'u-1', sub: '' },
    { name: 'N', width: 'u-1', sub: '' },
    { name: 'M', width: 'u-1', sub: '' },
    { name: ',', width: 'u-1', sub: '<' },
    { name: '.', width: 'u-1', sub: '>' },
    { name: '/', width: 'u-1', sub: '?' },
    { name: 'Shift', width: 'u-275', sub: '' }
  ],
  // Row 5 (8 keys)
  [
    { name: 'Ctrl', width: 'u-125', sub: '' },
    { name: 'Win', width: 'u-125', sub: '' },
    { name: 'Alt', width: 'u-125', sub: '' },
    { name: 'Space', width: 'u-625', sub: '' },
    { name: 'Alt', width: 'u-125', sub: '' },
    { name: 'Fn', width: 'u-125', sub: '' },
    { name: 'App', width: 'u-125', sub: '' },
    { name: 'Ctrl', width: 'u-125', sub: '' }
  ]
];

// State
let currentEffect = 'wave';
let activeKeyLabel = document.getElementById('active-key-label');
let keyboardElement = document.getElementById('keyboard');
let animFrame = null;
let animTick = 0;
let keyElements = [];

// Initialize Keyboard DOM
function renderKeyboard() {
  keyboardElement.innerHTML = '';
  keyElements = [];

  KEYBOARD_LAYOUT.forEach((row, rowIndex) => {
    const rowEl = document.createElement('div');
    rowEl.className = 'key-row';

    row.forEach((key, colIndex) => {
      const keyEl = document.createElement('div');
      keyEl.className = `keycap ${key.width}`;
      keyEl.dataset.name = key.name;
      keyEl.dataset.row = rowIndex;
      keyEl.dataset.col = colIndex;

      const ledEl = document.createElement('div');
      ledEl.className = 'key-led';

      const legendEl = document.createElement('span');
      legendEl.className = 'keycap-legend';
      legendEl.textContent = key.name;

      keyEl.appendChild(ledEl);
      keyEl.appendChild(legendEl);

      if (key.sub) {
        const subEl = document.createElement('span');
        subEl.className = 'keycap-sub';
        subEl.textContent = key.sub;
        keyEl.appendChild(subEl);
      }

      keyEl.addEventListener('click', () => onKeyClicked(keyEl, key));

      rowEl.appendChild(keyEl);
      keyElements.push({ el: keyEl, led: ledEl, row: rowIndex, col: colIndex });
    });

    keyboardElement.appendChild(rowEl);
  });
}

// Handle Key Selection & Reactive Flash
function onKeyClicked(keyEl, key) {
  document.querySelectorAll('.keycap.selected').forEach(el => el.classList.remove('selected'));
  keyEl.classList.add('selected');

  activeKeyLabel.textContent = `Selected: ${key.name} (${key.width.replace('u-', '').replace(/(\d)(\d+)/, '$1.$2')}u)`;

  if (currentEffect === 'reactive') {
    triggerRipple(parseInt(keyEl.dataset.row, 10), parseInt(keyEl.dataset.col, 10));
  }
}

// Ripple Effect on Keypress
function triggerRipple(originRow, originCol) {
  keyElements.forEach(item => {
    const dist = Math.hypot(item.row - originRow, item.col - originCol);
    setTimeout(() => {
      item.led.style.backgroundColor = '#ffedd5';
      item.led.style.boxShadow = '0 0 10px #ffedd5';
      setTimeout(() => {
        item.led.style.backgroundColor = '#333333';
        item.led.style.boxShadow = 'none';
      }, 300);
    }, dist * 50);
  });
}

// Animation Loop for Keyboard Lighting
function startAnimation() {
  if (animFrame) cancelAnimationFrame(animFrame);

  function loop() {
    animTick++;

    if (currentEffect === 'wave') {
      keyElements.forEach(item => {
        const hue = (animTick * 2 + item.col * 24 + item.row * 15) % 360;
        const color = `hsl(${hue}, 85%, 60%)`;
        item.led.style.backgroundColor = color;
        item.led.style.boxShadow = `0 0 6px ${color}`;
      });
    } else if (currentEffect === 'breathe') {
      const brightness = (Math.sin(animTick * 0.04) + 1) / 2; // 0 to 1
      const alpha = 0.2 + brightness * 0.8;
      const glow = brightness * 8;
      keyElements.forEach(item => {
        item.led.style.backgroundColor = `rgba(255, 237, 213, ${alpha})`;
        item.led.style.boxShadow = `0 0 ${glow}px rgba(255, 237, 213, ${alpha})`;
      });
    } else if (currentEffect === 'static') {
      keyElements.forEach(item => {
        item.led.style.backgroundColor = '#fafafa';
        item.led.style.boxShadow = '0 0 4px #fafafa';
      });
    }

    animFrame = requestAnimationFrame(loop);
  }

  loop();
}

// Effect Pill Buttons
document.querySelectorAll('.effect-pills .pill').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.effect-pills .pill').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    currentEffect = btn.dataset.effect;

    if (currentEffect === 'reactive') {
      keyElements.forEach(item => {
        item.led.style.backgroundColor = '#222222';
        item.led.style.boxShadow = 'none';
      });
    }
  });
});

// Copy to Clipboard Helpers
document.querySelectorAll('.copy-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const textToCopy = btn.dataset.copy;
    navigator.clipboard.writeText(textToCopy).then(() => {
      const originalText = btn.textContent;
      btn.textContent = 'Copied!';
      btn.classList.add('copied');
      setTimeout(() => {
        btn.textContent = originalText;
        btn.classList.remove('copied');
      }, 2000);
    });
  });
});

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  renderKeyboard();
  startAnimation();
});
