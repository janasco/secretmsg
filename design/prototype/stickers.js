/* ==========================================================================
   SecretMsg — Sticker Studio prototype
   --------------------------------------------------------------------------
   Every style below is a genuinely different *design*: different layout,
   different type treatment, different texture. Not a background recolour of
   one card — which is what the current studio ships (all 7 themes share one
   layout and differ only in gradient).

   Rendering is real. Each style is a canvas draw function at 1080x1920, so
   "Download" produces an actual PNG. The current web studio's "Save Sticker"
   button only shows a tip telling you to screenshot it yourself; there is no
   export at all.

   All typefaces are Google Fonts. The app's CSP already permits them —
   `style-src 'self' https://fonts.googleapis.com` and
   `font-src 'self' https://fonts.gstatic.com` in security-headers.ts — so
   adding families needs no policy change.
   ========================================================================== */

const W = 1080;
const H = 1920;

/* ---------- helpers ------------------------------------------------------ */

function rr(ctx, x, y, w, h, r) {
  const rad = Math.min(r, w / 2, h / 2);
  ctx.beginPath();
  ctx.moveTo(x + rad, y);
  ctx.arcTo(x + w, y, x + w, y + h, rad);
  ctx.arcTo(x + w, y + h, x, y + h, rad);
  ctx.arcTo(x, y + h, x, y, rad);
  ctx.arcTo(x, y, x + w, y, rad);
  ctx.closePath();
}

function fillRR(ctx, x, y, w, h, r, fill) {
  rr(ctx, x, y, w, h, r);
  ctx.fillStyle = fill;
  ctx.fill();
}

/** Word-wrap into at most `max` lines, ellipsising the last one. */
function wrap(ctx, text, maxWidth, max) {
  const words = String(text).split(/\s+/).filter(Boolean);
  const lines = [];
  let line = '';
  for (const word of words) {
    const test = line ? line + ' ' + word : word;
    if (ctx.measureText(test).width <= maxWidth || !line) {
      line = test;
    } else {
      lines.push(line);
      line = word;
      if (lines.length === max - 1) break;
    }
  }
  if (lines.length < max && line) lines.push(line);
  if (lines.length === max) {
    // The wrap above may have cut words off; ellipsise the final line.
    let last = lines[max - 1];
    while (last && ctx.measureText(last + '…').width > maxWidth) {
      last = last.replace(/\s*\S*$/, '').trim();
    }
    lines[max - 1] = (last || '') + '…';
  }
  return lines;
}

/** Film grain via a cached noise tile — keeps the exported PNG from banding. */
let noiseTile = null;
function grain(ctx, alpha) {
  if (!noiseTile) {
    const c = document.createElement('canvas');
    c.width = c.height = 220;
    const n = c.getContext('2d');
    const img = n.createImageData(220, 220);
    for (let i = 0; i < img.data.length; i += 4) {
      const v = 200 + Math.random() * 55;
      img.data[i] = img.data[i + 1] = img.data[i + 2] = v;
      img.data[i + 3] = 255;
    }
    n.putImageData(img, 0, 0);
    noiseTile = c;
  }
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.globalCompositeOperation = 'overlay';
  const pat = ctx.createPattern(noiseTile, 'repeat');
  ctx.fillStyle = pat;
  ctx.fillRect(0, 0, W, H);
  ctx.restore();
}

function blob(ctx, cx, cy, r, color) {
  ctx.save();
  ctx.fillStyle = color;
  ctx.beginPath();
  // A slightly irregular circle reads as "organic" rather than "default circle".
  for (let i = 0; i <= 64; i++) {
    const a = (i / 64) * Math.PI * 2;
    const wob = 1 + Math.sin(a * 3 + cx) * 0.06 + Math.cos(a * 5 + cy) * 0.04;
    const px = cx + Math.cos(a) * r * wob;
    const py = cy + Math.sin(a) * r * wob;
    i ? ctx.lineTo(px, py) : ctx.moveTo(px, py);
  }
  ctx.closePath();
  ctx.fill();
  ctx.restore();
}

function chromeGradient(ctx, x, y, w, h) {
  const g = ctx.createLinearGradient(x, y, x, y + h);
  g.addColorStop(0.0, '#ffffff');
  g.addColorStop(0.28, '#c9d6ff');
  g.addColorStop(0.5, '#7d8fd6');
  g.addColorStop(0.62, '#eaf0ff');
  g.addColorStop(1.0, '#8fa2e8');
  return g;
}

/** Emoji are unreliable in canvas across platforms — headless Chromium here has
    Noto Color Emoji installed and still renders tofu, and a downloaded PNG
    opened on a phone would render differently again. A clean typographic card
    is the better outcome anyway, so pictographs are dropped from the artwork.
    The caption the user copies keeps them. */
const PICTO = /\p{Extended_Pictographic}/gu;
function deemoji(s) {
  return String(s).replace(PICTO, '').replace(/\s{2,}/g, ' ').trim();
}

function label(ctx, text, x, y, size, color, spacing = 6) {
  ctx.save();
  ctx.font = `600 ${size}px "Space Grotesk", sans-serif`;
  ctx.fillStyle = color;
  ctx.letterSpacing = `${spacing}px`;
  ctx.textBaseline = 'middle';
  ctx.fillText(text.toUpperCase(), x, y);
  ctx.restore();
}

/* ---------- styles ------------------------------------------------------- */
/* Each entry: id, name, blurb, typeface, and draw(ctx, d).
   d = { prompt, name, handle, url } */

const STYLES = [
  {
    id: 'editorial',
    name: 'Editorial',
    blurb: 'Magazine masthead. Instrument Serif, paper, hairline rules.',
    font: 'Instrument Serif',
    trend: 'quiet luxury / print revival',
    draw(ctx, d) {
      ctx.fillStyle = '#F2EEE6';
      ctx.fillRect(0, 0, W, H);

      // Paper warmth + grain so it does not read as flat #fff.
      ctx.fillStyle = 'rgba(180,150,110,0.06)';
      ctx.fillRect(0, 0, W, H);
      grain(ctx, 0.16);

      ctx.fillStyle = '#15120D';
      ctx.textBaseline = 'top';

      label(ctx, 'secretmsg', 96, 132, 30, '#15120D', 10);

      ctx.fillStyle = '#15120D';
      ctx.fillRect(96, 196, W - 192, 3);

      // Big serif statement, optically centred in the space between the two
      // rules so short and long prompts both sit balanced.
      ctx.font = '400 138px "Instrument Serif", serif';
      const lines = wrap(ctx, d.prompt, W - 192, 6);
      const blockH = lines.length * 148;
      let y = Math.max(300, (H - 300 - blockH) / 2);
      for (const line of lines) {
        ctx.fillText(line, 96, y);
        y += 148;
      }

      // Rule that tracks the type block rather than sitting at a fixed height.
      const ruleY = y + 20;
      ctx.fillStyle = '#15120D';
      ctx.fillRect(96, ruleY, W - 192, 2);

      ctx.font = '400 44px "Instrument Serif", serif';
      ctx.fillStyle = '#4A4237';
      ctx.fillText(d.name || 'Your Board', 96, ruleY + 62);
      ctx.font = '400 30px "Space Grotesk", sans-serif';
      ctx.fillStyle = '#7A7164';
      ctx.fillText(`@${d.handle || 'yourname'}`, 96, ruleY + 128);

      // Footer plate.
      ctx.fillStyle = '#15120D';
      ctx.fillRect(0, H - 300, W, 300);
      ctx.fillStyle = '#F2EEE6';
      ctx.font = '500 40px "Space Grotesk", sans-serif';
      ctx.textBaseline = 'middle';
      ctx.fillText(d.url, 96, H - 210);
      ctx.font = '400 28px "Space Grotesk", sans-serif';
      ctx.fillStyle = '#9A9184';
      ctx.fillText('100% anonymous · no sign-up', 96, H - 150);
    },
  },

  {
    id: 'neubrutal',
    name: 'Neubrutal',
    blurb: 'Archivo Black, acid yellow, hard offset shadow.',
    font: 'Archivo Black',
    trend: 'neubrutalism',
    draw(ctx, d) {
      ctx.fillStyle = '#FFE24A';
      ctx.fillRect(0, 0, W, H);

      // Grid paper, subtle.
      ctx.strokeStyle = 'rgba(20,18,14,0.07)';
      ctx.lineWidth = 2;
      for (let x = 0; x <= W; x += 90) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke(); }
      for (let y = 0; y <= H; y += 90) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke(); }

      const PAD = 88;
      // Hard shadow first, then the card — never a blur.
      fillRR(ctx, PAD + 16, PAD + 16, W - PAD * 2, H - PAD * 2 - 120, 0, '#141210');
      fillRR(ctx, PAD, PAD, W - PAD * 2, H - PAD * 2 - 120, 0, '#FFFDF5');

      ctx.strokeStyle = '#141210';
      ctx.lineWidth = 8;
      rr(ctx, PAD, PAD, W - PAD * 2, H - PAD * 2 - 120, 0);
      ctx.stroke();

      ctx.fillStyle = '#141210';
      ctx.textBaseline = 'top';

      label(ctx, 'anon drop', PAD + 48, PAD + 48, 28, '#141210', 8);

      ctx.font = '400 108px "Archivo Black", sans-serif';
      const lines = wrap(ctx, d.prompt.toUpperCase(), W - PAD * 2 - 96, 7);
      let y = PAD + 140;
      for (const line of lines) {
        ctx.fillText(line, PAD + 48, y);
        y += 116;
      }

      // Sticker chip.
      const chipY = H - PAD - 340;
      fillRR(ctx, PAD + 48, chipY, 420, 92, 46, '#141210');
      ctx.fillStyle = '#FFE24A';
      ctx.font = '400 40px "Archivo Black", sans-serif';
      ctx.textBaseline = 'middle';
      ctx.fillText('@' + (d.handle || 'yourname'), PAD + 84, chipY + 48);

      ctx.fillStyle = '#141210';
      ctx.font = '400 34px "Archivo Black", sans-serif';
      ctx.fillText(d.url, PAD + 48, chipY + 140);
      ctx.font = '400 26px "Space Grotesk", sans-serif';
      ctx.fillStyle = '#6B6459';
      ctx.fillText('screenshot this → put it on your story', PAD + 48, chipY + 200);
    },
  },

  {
    id: 'diecut',
    name: 'Die-Cut Sticker',
    blurb: 'Bricolage Grotesque with a white cut-line, like a real sticker.',
    font: 'Bricolage Grotesque',
    trend: 'physical merch / sticker culture',
    draw(ctx, d) {
      const g = ctx.createLinearGradient(0, 0, W, H);
      g.addColorStop(0, '#7C3AED');
      g.addColorStop(0.55, '#C026D3');
      g.addColorStop(1, '#F43F5E');
      ctx.fillStyle = g;
      ctx.fillRect(0, 0, W, H);

      blob(ctx, 200, 320, 230, 'rgba(255,255,255,0.10)');
      blob(ctx, 900, 1600, 300, 'rgba(255,255,255,0.08)');
      grain(ctx, 0.1);

      // Sticker body: a rounded plate with a thick white cut-line and a drop
      // shadow, which is what sells "physical sticker" rather than "div".
      const PAD = 110;
      const bw = W - PAD * 2;
      const bh = 1180;

      ctx.save();
      ctx.shadowColor = 'rgba(30,10,40,0.45)';
      ctx.shadowBlur = 60;
      ctx.shadowOffsetY = 26;
      fillRR(ctx, PAD, 330, bw, bh, 92, '#FFFFFF');
      ctx.restore();

      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 18;
      rr(ctx, PAD, 330, bw, bh, 92);
      ctx.stroke();

      ctx.textBaseline = 'top';
      label(ctx, 'send me one', PAD + 64, 414, 30, '#9A6BFF', 7);

      ctx.fillStyle = '#16081F';
      ctx.font = '800 96px "Bricolage Grotesque", sans-serif';
      const lines = wrap(ctx, d.prompt, bw - 128, 7);
      let y = 500;
      for (const line of lines) {
        ctx.fillText(line, PAD + 64, y);
        y += 108;
      }

      const footY = 330 + bh - 190;
      ctx.fillStyle = '#16081F';
      ctx.font = '800 40px "Bricolage Grotesque", sans-serif';
      ctx.fillText(d.name || 'Your Board', PAD + 64, footY);
      ctx.font = '600 30px "Space Grotesk", sans-serif';
      ctx.fillStyle = '#7C5C93';
      ctx.fillText('@' + (d.handle || 'yourname'), PAD + 64, footY + 56);

      fillRR(ctx, PAD + 64, footY + 112, bw - 128, 74, 37, '#16081F');
      ctx.fillStyle = '#FFFFFF';
      ctx.font = '600 30px "Space Grotesk", sans-serif';
      ctx.textBaseline = 'middle';
      ctx.fillText(d.url, PAD + 96, footY + 150);
    },
  },

  {
    id: 'terminal',
    name: 'Terminal',
    blurb: 'JetBrains Mono on pure black. Raw, no decoration.',
    font: 'JetBrains Mono',
    trend: 'raw / anti-design',
    draw(ctx, d) {
      ctx.fillStyle = '#05060A';
      ctx.fillRect(0, 0, W, H);

      ctx.strokeStyle = 'rgba(80,255,150,0.13)';
      ctx.lineWidth = 2;
      for (let y = 0; y <= H; y += 54) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke(); }

      // Scanline vignette.
      const vg = ctx.createRadialGradient(W / 2, H / 2, 200, W / 2, H / 2, 1100);
      vg.addColorStop(0, 'rgba(80,255,150,0.06)');
      vg.addColorStop(1, 'rgba(0,0,0,0.55)');
      ctx.fillStyle = vg;
      ctx.fillRect(0, 0, W, H);

      ctx.textBaseline = 'top';
      ctx.font = '700 34px "JetBrains Mono", monospace';

      ctx.fillStyle = '#4B5563';
      ctx.fillText('$ secretmsg compose --anon', 90, 170);

      ctx.fillStyle = '#50FF96';
      ctx.fillText('>', 90, 280);

      ctx.font = '700 82px "JetBrains Mono", monospace';
      const lines = wrap(ctx, d.prompt, W - 220, 8);
      let y = 300;
      for (const line of lines) {
        ctx.fillStyle = '#EAFFEF';
        ctx.fillText(line, 150, y);
        // Blinking caret after each line.
        ctx.fillStyle = '#50FF96';
        ctx.fillRect(152 + ctx.measureText(line).width, y + 8, 26, 66);
        y += 104;
      }

      // Cursor block.
      ctx.fillStyle = '#50FF96';
      ctx.fillRect(150, y + 20, 26, 66);

      // A result panel fills the middle. Without it the card was ~600px of
      // empty grid between the prompt and the footer, which read as broken.
      const py = Math.max(y + 150, 1080);
      fillRR(ctx, 90, py, W - 180, 330, 14, 'rgba(80,255,150,0.06)');
      ctx.strokeStyle = 'rgba(80,255,150,0.35)';
      ctx.lineWidth = 3;
      rr(ctx, 90, py, W - 180, 330, 14);
      ctx.stroke();

      ctx.font = '400 32px "JetBrains Mono", monospace';
      ctx.textBaseline = 'middle';
      ctx.fillStyle = '#50FF96';
      ctx.fillText('READY', 134, py + 66);
      ctx.fillStyle = '#6B7280';
      ctx.fillText('board    ' + (d.handle || 'yourname'), 134, py + 138);
      ctx.fillText('sender   <redacted>', 134, py + 196);
      ctx.fillText('tracking none', 134, py + 254);
      ctx.textBaseline = 'top';

      ctx.font = '400 32px "JetBrains Mono", monospace';
      ctx.fillStyle = '#6B7280';
      ctx.fillText('# board: ' + (d.handle || 'yourname'), 90, H - 420);
      ctx.fillStyle = '#50FF96';
      ctx.font = '700 38px "JetBrains Mono", monospace';
      ctx.fillText(d.url, 90, H - 340);
      ctx.font = '400 26px "JetBrains Mono", monospace';
      ctx.fillStyle = '#4B5563';
      ctx.fillText('// sender identity is never stored', 90, H - 260);

      // Blinking block cursor.
      ctx.fillStyle = 'rgba(80,255,150,0.85)';
      ctx.fillRect(90, H - 190, 22, 44);
    },
  },

  {
    id: 'chrome',
    name: 'Liquid Chrome',
    blurb: 'Gradient chrome lettering on deep space. Y2K, current again.',
    font: 'Poppins',
    trend: 'y2k revival / chrome',
    draw(ctx, d) {
      const g = ctx.createLinearGradient(0, 0, 0, H);
      g.addColorStop(0, '#1B1046');
      g.addColorStop(0.5, '#2A1170');
      g.addColorStop(1, '#08061C');
      ctx.fillStyle = g;
      ctx.fillRect(0, 0, W, H);

      blob(ctx, 780, 380, 300, 'rgba(120,90,255,0.32)');
      blob(ctx, 240, 1560, 260, 'rgba(255,120,220,0.22)');
      blob(ctx, 900, 1300, 190, 'rgba(90,230,255,0.20)');

      // Liquid highlight sweep.
      const sweep = ctx.createLinearGradient(0, 0, W, H);
      sweep.addColorStop(0, 'rgba(255,255,255,0.14)');
      sweep.addColorStop(0.4, 'rgba(255,255,255,0)');
      ctx.fillStyle = sweep;
      ctx.fillRect(0, 0, W, H);

      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';

      ctx.font = '600 34px "Poppins", sans-serif';
      ctx.letterSpacing = '12px';
      ctx.fillStyle = '#B9A8FF';
      ctx.fillText('SECRETMSG', W / 2, 150);
      ctx.letterSpacing = '0px';

      // Chrome lettering: filled with a multi-stop gradient, offset by a dark
      // under-copy so it reads as extruded.
      // Block is centred rather than started at a fixed y, so the headline sits
      // in the optical middle instead of leaving a gap above the pill.
      ctx.font = '800 112px "Poppins", sans-serif';
      const lines = wrap(ctx, d.prompt, W - 240, 6);
      let y = Math.max(330, (H - lines.length * 130) / 2 - 190);
      for (const line of lines) {
        ctx.save();
        ctx.translate(0, 10);
        ctx.fillStyle = 'rgba(10,4,40,0.85)';
        ctx.fillText(line, W / 2, y);
        ctx.restore();
        ctx.fillStyle = chromeGradient(ctx, 0, y, W, 112);
        ctx.fillText(line, W / 2, y);
        y += 130;
      }

      // Gloss bar across the chrome.
      ctx.save();
      ctx.globalCompositeOperation = 'overlay';
      const gloss = ctx.createLinearGradient(0, 300, 0, 340);
      gloss.addColorStop(0, 'rgba(255,255,255,0)');
      gloss.addColorStop(0.5, 'rgba(255,255,255,0.5)');
      gloss.addColorStop(1, 'rgba(255,255,255,0)');
      ctx.fillStyle = gloss;
      ctx.fillRect(0, 300, W, 60);
      ctx.restore();

      // Chrome pill.
      const pw = 720;
      ctx.fillStyle = chromeGradient(ctx, 0, 0, 0, 100);
      fillRR(ctx, (W - pw) / 2, H - 430, pw, 108, 54, ctx.fillStyle);
      ctx.strokeStyle = 'rgba(255,255,255,0.35)';
      ctx.lineWidth = 3;
      rr(ctx, (W - pw) / 2, H - 430, pw, 108, 54);
      ctx.stroke();

      ctx.font = '700 40px "Poppins", sans-serif';
      ctx.fillStyle = '#14063A';
      ctx.textBaseline = 'middle';
      ctx.fillText('@' + (d.handle || 'yourname'), W / 2, H - 374);

      ctx.font = '500 28px "Poppins", sans-serif';
      ctx.fillStyle = 'rgba(220,210,255,0.75)';
      ctx.fillText('tap the link · 100% anonymous', W / 2, H - 278);
      ctx.textAlign = 'left';
    },
  },

  {
    id: 'riso',
    name: 'Risograph',
    blurb: 'Two-colour duotone, grain, slight rotation. Print zine.',
    font: 'Fraunces',
    trend: 'risograph / indie print',
    draw(ctx, d) {
      ctx.fillStyle = '#F4F0E6';
      ctx.fillRect(0, 0, W, H);

      // Misregistration: the two ink plates are offset, which is the whole
      // signature of riso printing.
      const inkA = '#FF4B7B';
      const inkB = '#2B5FD9';

      ctx.save();
      ctx.translate(W / 2, H / 2);
      ctx.rotate(-0.028);
      ctx.translate(-W / 2, -H / 2);

      ctx.globalCompositeOperation = 'multiply';
      // Kept to the corners. At full strength these sat directly behind the
      // headline and the pink-on-pink contrast collapsed to nothing.
      blob(ctx, 130, 1560, 300, 'rgba(255,75,123,0.42)');
      blob(ctx, 960, 330, 260, 'rgba(43,95,217,0.32)');
      ctx.globalCompositeOperation = 'source-over';

      ctx.textBaseline = 'top';
      ctx.font = '800 30px "Space Grotesk", sans-serif';
      ctx.letterSpacing = '7px';
      ctx.fillStyle = inkA;
      ctx.fillText('SECRETMSG · ANON', 100, 130);

      ctx.font = '900 112px "Fraunces", serif';
      const lines = wrap(ctx, d.prompt, W - 220, 6);
      let y = 300;
      for (const line of lines) {
        ctx.fillStyle = 'rgba(43,95,217,0.55)';
        ctx.fillText(line, 100 + 9, y + 9);
        ctx.fillStyle = inkA;
        ctx.fillText(line, 100, y);
        y += 124;
      }

      ctx.globalCompositeOperation = 'multiply';
      fillRR(ctx, 100, y + 30, 560, 4, 2, inkB);
      ctx.globalCompositeOperation = 'source-over';

      ctx.font = '500 46px "Fraunces", serif';
      ctx.fillStyle = '#241F1A';
      ctx.fillText(d.name || 'Your Board', 100, y + 70);
      ctx.font = '500 32px "Space Grotesk", sans-serif';
      ctx.fillStyle = '#6B6259';
      ctx.fillText('@' + (d.handle || 'yourname'), 100, y + 136);

      fillRR(ctx, 100, y + 200, W - 200, 104, 6, inkB);
      ctx.fillStyle = '#F4F0E6';
      ctx.font = '700 38px "Space Grotesk", sans-serif';
      ctx.textBaseline = 'middle';
      ctx.fillText(d.url, 136, y + 253);
      ctx.letterSpacing = '0px';
      ctx.restore();

      grain(ctx, 0.28);
    },
  },

  {
    id: 'luxe',
    name: 'Quiet Luxury',
    blurb: 'Cormorant at light weight, charcoal, gold hairline.',
    font: 'Cormorant Garamond',
    trend: 'quiet luxury',
    draw(ctx, d) {
      ctx.fillStyle = '#14161A';
      ctx.fillRect(0, 0, W, H);

      // Vignette so the centre reads as lit.
      const vg = ctx.createRadialGradient(W / 2, H * 0.42, 100, W / 2, H * 0.42, 1000);
      vg.addColorStop(0, 'rgba(212,175,55,0.10)');
      vg.addColorStop(1, 'rgba(0,0,0,0.5)');
      ctx.fillStyle = vg;
      ctx.fillRect(0, 0, W, H);

      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';

      ctx.font = '400 30px "Cormorant Garamond", serif';
      ctx.letterSpacing = '14px';
      ctx.fillStyle = '#C9A227';
      ctx.fillText('SECRET MSG', W / 2, 150);
      ctx.letterSpacing = '0px';

      // Gold hairlines either side of a centred mark.
      ctx.fillStyle = 'rgba(201,162,39,0.5)';
      ctx.fillRect(W / 2 - 300, 226, 240, 1);
      ctx.fillRect(W / 2 + 60, 226, 240, 1);

      // The block is centred on the optical middle of the frame rather than
      // started at a fixed y, so a short prompt and a long one both sit
      // centred instead of leaving a large gap above the footer.
      ctx.font = '300 108px "Cormorant Garamond", serif';
      const lines = wrap(ctx, d.prompt, W - 260, 6);
      const blockH = lines.length * 126;
      let y = Math.max(360, (H - blockH) / 2 - 130);
      for (const line of lines) {
        ctx.fillStyle = '#F3F1EC';
        ctx.fillText(line, W / 2, y);
        y += 126;
      }

      ctx.font = '400 34px "Cormorant Garamond", serif';
      ctx.letterSpacing = '6px';
      ctx.fillStyle = '#9AA0A8';
      ctx.textBaseline = 'middle';
      ctx.fillText((d.name || 'Your Board').toUpperCase(), W / 2, y + 46);
      ctx.font = '400 26px "Space Grotesk", sans-serif';
      ctx.letterSpacing = '2px';
      ctx.fillStyle = '#6E747C';
      ctx.fillText('@' + (d.handle || 'yourname'), W / 2, y + 100);
      ctx.letterSpacing = '0px';

      // Gold underline as a drawn rule, not a border.
      ctx.fillStyle = '#C9A227';
      ctx.fillRect(W / 2 - 70, y + 168, 140, 2);
      ctx.textBaseline = 'top';

      ctx.font = '400 34px "Cormorant Garamond", serif';
      ctx.fillStyle = '#E8E5DF';
      ctx.fillText(d.url, W / 2, H - 330);
      ctx.font = '400 24px "Space Grotesk", sans-serif';
      ctx.fillStyle = '#6E747C';
      ctx.fillText('sent privately · never stored', W / 2, H - 250);
      ctx.textAlign = 'left';
    },
  },

  {
    id: 'bauhaus',
    name: 'Bauhaus',
    blurb: 'Geometric primitives, primary palette, Poppins.',
    font: 'Poppins',
    trend: 'bauhaus / geometric',
    draw(ctx, d) {
      ctx.fillStyle = '#F0EDE4';
      ctx.fillRect(0, 0, W, H);

      // Primitives live strictly in the top band and the bottom-right corner.
      // They previously overlapped the type block, which read as a collision
      // rather than as composition.
      ctx.fillStyle = '#E0301E';
      ctx.beginPath(); ctx.arc(215, 300, 132, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#1B4DD1';
      ctx.fillRect(790, 180, 170, 170);
      ctx.fillStyle = '#F5C518';
      ctx.beginPath();
      ctx.moveTo(880, 1780); ctx.lineTo(1010, 1540); ctx.lineTo(1140, 1780); ctx.closePath(); ctx.fill();
      ctx.strokeStyle = '#141414';
      ctx.lineWidth = 8;
      ctx.beginPath(); ctx.arc(760, 1660, 92, 0, Math.PI * 2); ctx.stroke();

      ctx.textBaseline = 'top';
      ctx.font = '800 28px "Poppins", sans-serif';
      ctx.letterSpacing = '6px';
      ctx.fillStyle = '#141414';
      ctx.fillText('ANONYMOUS BOARD', 120, 120);

      ctx.fillStyle = '#141414';
      ctx.fillRect(120, 620, 220, 14);

      // Type block occupies the middle band only.
      ctx.font = '800 96px "Poppins", sans-serif';
      const lines = wrap(ctx, d.prompt, W - 300, 5);
      let y = 760;
      for (const line of lines) {
        ctx.fillText(line, 120, y);
        y += 112;
      }

      ctx.fillStyle = '#1B4DD1';
      ctx.fillRect(120, y + 24, W - 240, 6);
      ctx.fillStyle = '#141414';
      ctx.font = '700 42px "Poppins", sans-serif';
      ctx.fillText(d.name || 'Your Board', 120, y + 60);
      ctx.font = '500 30px "Poppins", sans-serif';
      ctx.fillStyle = '#5C574E';
      ctx.fillText('@' + (d.handle || 'yourname'), 120, y + 118);

      // The plate is sized from the measured text, and the type steps down if a
      // long handle would still overflow — a 30-char handle at 34px is wider
      // than the card, and clipping a URL looks like a bug.
      ctx.font = '700 34px "Poppins", sans-serif';
      let size = 34;
      while (size > 18 && ctx.measureText(d.url).width > W - 312) size -= 2;
      ctx.font = `700 ${size}px "Poppins", sans-serif`;
      const pw = Math.min(W - 240, ctx.measureText(d.url).width + 72);
      fillRR(ctx, 120, y + 176, pw, 100, 6, '#E0301E');
      ctx.fillStyle = '#F0EDE4';
      ctx.textBaseline = 'middle';
      ctx.fillText(d.url, 156, y + 227);
      ctx.letterSpacing = '0px';
    },
  },
];

/* ---------- public API --------------------------------------------------- */

const Studio = {
  W,
  H,
  styles: STYLES,

  /** Render style `id` with data `d` into canvas `canvas` at its native size. */
  render(canvas, id, d) {
    const style = STYLES.find((s) => s.id === id) || STYLES[0];
    canvas.width = W;
    canvas.height = H;
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, W, H);
    // Strip pictographs once, centrally, so no draw function has to remember.
    const clean = { ...d, prompt: deemoji(d.prompt || '') || 'say something honest' };
    ctx.save();
    try {
      style.draw(ctx, clean);
    } finally {
      ctx.restore();
    }
  },

  /** Wait until every face used by the styles is actually loaded, so canvas
      text does not silently fall back to a system font. */
  async ready() {
    if (!document.fonts) return;
    const needed = [
      '400 138px "Instrument Serif"',
      '800 108px "Archivo Black"',
      '800 96px "Bricolage Grotesque"',
      '700 76px "JetBrains Mono"',
      '800 112px "Poppins"',
      '900 112px "Fraunces"',
      '300 108px "Cormorant Garamond"',
      '700 34px "Space Grotesk"',
    ];
    await Promise.all(
      needed.map((f) => document.fonts.load(f).catch(() => null))
    );
    await document.fonts.ready;
  },

  /** Export as PNG. */
  toBlob(canvas) {
    return new Promise((resolve) => canvas.toBlob(resolve, 'image/png'));
  },
};

window.Studio = Studio;
