/**
 * Sticker Studio — canvas renderer.
 *
 * Draws one design at 1080x1920 (9:16, the Instagram/Snapchat story ratio).
 *
 * The organising idea is that every design is composed around the vertical
 * centre rather than stacked from the top. The old studio pinned content to the
 * top, so a short prompt left a large empty region in the middle of the card —
 * most visible on Terminal and Quiet Luxury. Here the headline is auto-fitted to
 * a target share of the frame and the whole stack is centred on the optical
 * middle, so a one-word prompt and a full sentence both produce a filled card.
 *
 * Canvas work must never run during render: /sticker-studio is prerendered to
 * static HTML at build time, where there is no document and no canvas.
 */

import type { Decor, FontSpec, Palette, StickerStyle } from './design';
import { W, H } from './constants';

export interface StickerData {
  prompt: string;
  name: string;
  handle: string;
  url: string;
}

/* ------------------------------------------------------------- primitives */

/** Rounded-rect path. `r` is clamped so a plate can never invert. */
function roundRectPath(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number): void {
  const rad = Math.max(0, Math.min(r, w / 2, h / 2));
  ctx.beginPath();
  ctx.moveTo(x + rad, y);
  ctx.arcTo(x + w, y, x + w, y + h, rad);
  ctx.arcTo(x + w, y + h, x, y + h, rad);
  ctx.arcTo(x, y + h, x, y, rad);
  ctx.arcTo(x, y, x + w, y, rad);
  ctx.closePath();
}

function fillRound(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number, fill: string): void {
  roundRectPath(ctx, x, y, w, h, r);
  ctx.fillStyle = fill;
  ctx.fill();
}

/** Apply a font spec to the context and return the CSS font shorthand used. */
function useFont(ctx: CanvasRenderingContext2D, font: FontSpec, sizePx: number): string {
  const css = `${font.weight} ${sizePx}px "${font.family}", "Inter", system-ui, sans-serif`;
  ctx.font = css;
  return css;
}

function setTracking(ctx: CanvasRenderingContext2D, em: number): void {
  // letterSpacing is widely available on canvas; where it is not, the text still
  // lays out correctly, it just loses the tracking.
  const anyCtx = ctx as CanvasRenderingContext2D & { letterSpacing?: string };
  if ('letterSpacing' in anyCtx) anyCtx.letterSpacing = `${em}em`;
}

/** Word-wrap to at most `maxLines`, ellipsising the final line when capped. */
function wrapText(ctx: CanvasRenderingContext2D, text: string, maxWidth: number, maxLines: number): string[] {
  const words = text.split(/\s+/).filter(Boolean);
  const lines: string[] = [];
  let line = '';
  for (const word of words) {
    const candidate = line ? `${line} ${word}` : word;
    if (ctx.measureText(candidate).width <= maxWidth || !line) {
      line = candidate;
    } else {
      lines.push(line);
      line = word;
      if (lines.length === maxLines - 1) break;
    }
  }
  if (lines.length < maxLines && line) lines.push(line);
  if (lines.length === maxLines) {
    let last = lines[maxLines - 1];
    while (last && ctx.measureText(`${last}…`).width > maxWidth) {
      last = last.replace(/\s*\S*$/, '').trim();
    }
    lines[maxLines - 1] = `${last || ''}…`;
  }
  return lines;
}

/**
 * Largest size in [min, max] at which `text` wraps to no more than `maxLines`
 * inside `maxWidth` AND the resulting stack is no taller than `targetHeight`.
 *
 * Both conditions matter. Without the height condition a five-word prompt at
 * the maximum size still leaves the middle of the card empty; without the width
 * condition a long prompt overflows the card instead of shrinking.
 */
/**
 * Fit the headline to the frame.
 *
 * Two constraints, and both matter. The width check stops text overflowing the
 * card. The height check is what fills the middle: a wide face like Unbounded
 * at 168px produced "send / me / anonymou…", and a tall condensed face at the
 * same size produced only two short lines with half the card empty, because
 * line count alone says nothing about how much of the frame was used.
 *
 * A size that fits both constraints is tried first. If none exists, the size
 * that fits the *height* best is taken and then shrunk until its lines fit the
 * width, so a tight card degrades to smaller type rather than to truncated
 * words.
 */
function fitHeadlineSize(
  ctx: CanvasRenderingContext2D,
  font: FontSpec,
  text: string,
  maxWidth: number,
  maxLines: number,
  targetHeight: number,
  max: number,
  min: number,
): { size: number; lines: string[] } {
  const attempt = (size: number) => {
    useFont(ctx, font, size);
    return wrapText(ctx, text, maxWidth, maxLines);
  };
  const fitsWidth = (lines: string[]) => lines.every((l) => ctx.measureText(l).width <= maxWidth);

  let heightBest = { size: min, lines: attempt(min), height: Infinity };
  for (let size = max; size >= min; size -= 2) {
    const lines = attempt(size);
    const height = lines.length * size * 1.04;
    if (height < heightBest.height) heightBest = { size, lines, height };
    if (height <= targetHeight && lines.length <= maxLines && fitsWidth(lines)) {
      return { size, lines };
    }
  }
  // Nothing satisfied both: honour the height, then shrink until it fits width.
  useFont(ctx, font, heightBest.size);
  let lines = heightBest.lines;
  let size = heightBest.size;
  while (size > min && !fitsWidth(lines)) {
    size -= 2;
    lines = attempt(size);
  }
  return { size, lines };
}

/* ------------------------------------------------------------- decoration */

let grainTile: HTMLCanvasElement | null = null;

function getGrainTile(): HTMLCanvasElement {
  if (grainTile) return grainTile;
  const tile = document.createElement('canvas');
  tile.width = 180;
  tile.height = 180;
  const tctx = tile.getContext('2d');
  if (tctx) {
    const img = tctx.createImageData(180, 180);
    for (let i = 0; i < img.data.length; i += 4) {
      const v = 190 + Math.random() * 65;
      img.data[i] = v;
      img.data[i + 1] = v;
      img.data[i + 2] = v;
      img.data[i + 3] = 255;
    }
    tctx.putImageData(img, 0, 0);
  }
  grainTile = tile;
  return tile;
}

function organicBlob(ctx: CanvasRenderingContext2D, cx: number, cy: number, r: number, fill: string): void {
  ctx.save();
  ctx.fillStyle = fill;
  ctx.beginPath();
  for (let i = 0; i <= 72; i++) {
    const a = (i / 72) * Math.PI * 2;
    const wobble = 1 + Math.sin(a * 3 + cx * 0.01) * 0.07 + Math.cos(a * 5 + cy * 0.01) * 0.05;
    const px = cx + Math.cos(a) * r * wobble;
    const py = cy + Math.sin(a) * r * wobble;
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  }
  ctx.closePath();
  ctx.fill();
  ctx.restore();
}

function chromeFill(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number): CanvasGradient {
  const g = ctx.createLinearGradient(0, y, 0, y + h);
  g.addColorStop(0, '#ffffff');
  g.addColorStop(0.26, '#c8d4ff');
  g.addColorStop(0.5, '#7d8fd6');
  g.addColorStop(0.64, '#eef2ff');
  g.addColorStop(1, '#8fa2e8');
  void x;
  void w;
  return g;
}

function paintDecor(ctx: CanvasRenderingContext2D, decor: Decor, palette: Palette): void {
  switch (decor) {
    case 'grain': {
      ctx.save();
      ctx.globalAlpha = palette.light ? 0.14 : 0.2;
      ctx.globalCompositeOperation = palette.light ? 'multiply' : 'overlay';
      const pattern = ctx.createPattern(getGrainTile(), 'repeat');
      if (pattern) {
        ctx.fillStyle = pattern;
        ctx.fillRect(0, 0, W, H);
      }
      ctx.restore();
      break;
    }
    case 'blobs': {
      organicBlob(ctx, 150, 1700, 320, hexA(palette.accent, 0.2));
      organicBlob(ctx, 950, 220, 280, hexA(palette.ink, 0.07));
      break;
    }
    case 'grid': {
      ctx.save();
      ctx.strokeStyle = hexA(palette.ink, 0.09);
      ctx.lineWidth = 2;
      for (let x = 0; x <= W; x += 90) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, H);
        ctx.stroke();
      }
      for (let y = 0; y <= H; y += 90) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(W, y);
        ctx.stroke();
      }
      ctx.restore();
      break;
    }
    case 'scan': {
      ctx.save();
      ctx.fillStyle = hexA(palette.accent, 0.08);
      for (let y = 0; y < H; y += 8) ctx.fillRect(0, y, W, 2);
      const vign = ctx.createRadialGradient(W / 2, H / 2, 200, W / 2, H / 2, 1150);
      vign.addColorStop(0, hexA(palette.accent, 0.06));
      vign.addColorStop(1, hexA('#000000', palette.light ? 0.06 : 0.42));
      ctx.fillStyle = vign;
      ctx.fillRect(0, 0, W, H);
      ctx.restore();
      break;
    }
    case 'duotone': {
      ctx.save();
      ctx.globalCompositeOperation = 'multiply';
      organicBlob(ctx, 120, 1620, 300, hexA(palette.accent, 0.42));
      organicBlob(ctx, 960, 260, 260, hexA(palette.ink, 0.16));
      ctx.restore();
      break;
    }
    case 'arch': {
      ctx.save();
      ctx.strokeStyle = hexA(palette.accent, 0.5);
      ctx.lineWidth = 10;
      for (const r of [200, 300, 400]) {
        ctx.beginPath();
        ctx.arc(W / 2, H + 40, r, Math.PI, 0);
        ctx.stroke();
      }
      break;
    }
    case 'shadow':
    case 'chrome':
      // Handled by the archetype, which needs to know about the type plate.
      break;
  }
}

/** Add alpha to a hex colour. Returns the input unchanged if it cannot parse. */
export function hexA(hex: string, alpha: number): string {
  const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex.trim());
  if (!m) return hex;
  const r = parseInt(m[1], 16);
  const g = parseInt(m[2], 16);
  const b = parseInt(m[3], 16);
  return `rgba(${r},${g},${b},${alpha})`;
}

/* --------------------------------------------------------------- content */

/**
 * Lay a set of items out centred on `centreY`. Each item reports its own
 * height through `measure` and paints itself from a supplied top edge.
 */
function centreStack(
  items: { measure: () => number; draw: (top: number) => void; gap: number }[],
  centreY: number,
): void {
  const total = items.reduce((sum, it) => sum + it.measure() + it.gap, 0);
  let y = centreY - total / 2;
  for (const it of items) {
    y += it.gap;
    it.draw(y);
    y += it.measure();
  }
}

/* ------------------------------------------------------------ archetypes */

/** Everything the archetypes need, resolved once. */
interface Ctx {
  ctx: CanvasRenderingContext2D;
  style: StickerStyle;
  data: StickerData;
  pad: number;
  inner: number;
}

function paintBackground(ctx: CanvasRenderingContext2D, palette: Palette): void {
  if (palette.bg.length === 1) {
    ctx.fillStyle = palette.bg[0];
    ctx.fillRect(0, 0, W, H);
    return;
  }
  const g = ctx.createLinearGradient(0, 0, W * 0.35, H);
  g.addColorStop(0, palette.bg[0]);
  g.addColorStop(1, palette.bg[palette.bg.length - 1]);
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, W, H);
}

function drawArchetype(c: Ctx): void {
  const { ctx, style, data, pad, inner } = c;
  const { palette, font } = style;
  const centreY = H * 0.5;

  // Headline is fitted to roughly half the frame so short and long prompts both
  // fill the middle rather than leaving it bare.
  useFont(ctx, font, 100);
  setTracking(ctx, font.tracking ?? 0);
  const fit = fitHeadlineSize(ctx, font, data.prompt, inner, 6, H * 0.52, 168, 46);
  const lineH = fit.size * 1.04;
  const headH = fit.lines.length * lineH;

  /* The meta region is three rows: board name, handle, link plate. Their
     offsets live here and are used by both the measuring and the painting
     pass — when these were computed separately they drifted and the handle
     was drawn on top of the board name. */
  const metaMetrics = () => {
    const nameFs = Math.max(24, Math.min(34, fit.size * 0.22));
    const handleFs = Math.max(20, Math.min(28, fit.size * 0.17));
    const plateFs = Math.max(22, Math.min(32, fit.size * 0.2));
    return {
      nameFs,
      handleFs,
      plateFs,
      nameBase: nameFs * 1.15,
      handleBase: nameFs * 1.15 + handleFs * 1.9,
      plateTop: nameFs * 1.15 + handleFs * 2.7,
      get height() {
        return this.plateTop + this.plateFs * 2.1;
      },
    };
  };

  const measureMeta = (): number => metaMetrics().height;

  const paintHeadline = (top: number): void => paintHeadlineWith(palette, style)(top);

  const paintMeta = (top: number): void => paintMetaWith(palette)(top);

  /** Paint functions take their palette so the plate archetype can render the
   *  same stack in the plate's own inks rather than the background's. */
  function paintHeadlineWith(p: Palette, s: StickerStyle) {
    return (top: number): void => {
      useFont(ctx, font, fit.size);
      setTracking(ctx, font.tracking ?? 0);
      ctx.textBaseline = 'top';
      ctx.textAlign = 'center';
      fit.lines.forEach((line, i) => {
        const y = top + i * lineH;
        if (s.decor === 'chrome') {
          ctx.save();
          ctx.translate(0, 9);
          ctx.fillStyle = hexA('#0A0428', 0.85);
          ctx.fillText(line, W / 2, y);
          ctx.restore();
          ctx.fillStyle = chromeFill(ctx, W / 2 - inner / 2, y, inner, fit.size);
        } else {
          ctx.fillStyle = p.ink;
        }
        ctx.fillText(line, W / 2, y);
      });
      ctx.textAlign = 'left';
    };
  }

  function paintMetaWith(p: Palette) {
    return (top: number): void => {
      const m = metaMetrics();
      ctx.textAlign = 'center';
      ctx.textBaseline = 'alphabetic';

      ctx.font = `600 ${m.nameFs}px "Inter", system-ui, sans-serif`;
      ctx.fillStyle = p.ink;
      ctx.fillText(data.name || 'Your Board', W / 2, top + m.nameBase);

      ctx.font = `500 ${m.handleFs}px "Inter", system-ui, sans-serif`;
      ctx.fillStyle = p.ink2;
      ctx.fillText(`@${data.handle || 'yourname'}`, W / 2, top + m.handleBase);

      // Link plate, sized from the measured text so a long handle cannot clip.
      let size = m.plateFs;
      ctx.font = `600 ${size}px "Inter", system-ui, sans-serif`;
      while (size > 16 && ctx.measureText(data.url).width > inner - 80) {
        size -= 1;
        ctx.font = `600 ${size}px "Inter", system-ui, sans-serif`;
      }
      const plateW = Math.min(inner, ctx.measureText(data.url).width + 64);
      const plateH = size * 1.95;
      fillRound(ctx, (W - plateW) / 2, top + m.plateTop, plateW, plateH, plateH / 2, p.accent);
      ctx.fillStyle = p.onAccent;
      ctx.textBaseline = 'middle';
      ctx.fillText(data.url, W / 2, top + m.plateTop + plateH / 2);
      ctx.textAlign = 'left';
      ctx.textBaseline = 'alphabetic';
    };
  }

  const headlineItem = { measure: () => headH, draw: paintHeadline, gap: 0 };
  const metaItem = { measure: measureMeta, draw: paintMeta, gap: 56 };

  switch (style.archetype) {
    case 'stack': {
      paintDecor(ctx, style.decor, palette);
      centreStack([headlineItem, metaItem], centreY);
      break;
    }

    case 'framed': {
      paintDecor(ctx, style.decor, palette);
      // Rules are placed against the measured stack so they always hug content.
      const total = headH + 56 + measureMeta();
      const top = centreY - total / 2;
      ctx.fillStyle = hexA(palette.ink, 0.85);
      ctx.fillRect(pad, top - 78, inner, 3);
      centreStack([headlineItem, metaItem], centreY);
      ctx.fillRect(pad, centreY + total / 2 + 78, inner, 3);
      break;
    }

    case 'medallion': {
      paintDecor(ctx, style.decor, palette);
      const r = 132;
      const total = r * 2 + 72 + headH + 56 + measureMeta();
      const top = centreY - total / 2;
      // Medallion carries the initials, so a board name is always legible even
      // when the headline is short.
      const initials = (data.name || 'B').trim().slice(0, 2).toUpperCase();
      const g = ctx.createLinearGradient(pad, top, W - pad, top + r * 2);
      g.addColorStop(0, palette.accent);
      g.addColorStop(1, hexA(palette.accent, 0.55));
      ctx.save();
      ctx.shadowColor = hexA('#000000', palette.light ? 0.18 : 0.4);
      ctx.shadowBlur = 44;
      ctx.shadowOffsetY = 18;
      ctx.beginPath();
      ctx.arc(W / 2, top + r, r, 0, Math.PI * 2);
      ctx.fillStyle = g;
      ctx.fill();
      ctx.restore();
      ctx.fillStyle = palette.onAccent;
      ctx.font = `700 ${Math.round(r * 0.78)}px "Inter", system-ui, sans-serif`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(initials, W / 2, top + r + 6);
      ctx.textAlign = 'left';
      ctx.textBaseline = 'alphabetic';
      centreStack([headlineItem, metaItem], centreY + r + 36);
      break;
    }

    case 'banded': {
      const bandH = Math.max(headH + 300, H * 0.52);
      const bandTop = centreY - bandH / 2;
      ctx.fillStyle = hexA(palette.accent, 0.16);
      ctx.fillRect(0, bandTop, W, bandH);
      ctx.fillStyle = palette.accent;
      ctx.fillRect(0, bandTop, W, 8);
      ctx.fillRect(0, bandTop + bandH - 8, W, 8);
      paintDecor(ctx, style.decor, palette);
      centreStack([headlineItem, metaItem], centreY);
      break;
    }

    case 'plate': {
      paintDecor(ctx, style.decor, palette);
      // The plate is measured from content so the type never sits on an edge.
      const contentH = headH + 56 + measureMeta();
      const plateH = contentH + 300;
      const plateTop = centreY - plateH / 2;
      const plateW = inner + 60;
      const plateX = (W - plateW) / 2;

      // Plate fill is derived from the background, never `palette.ink` — on the
      // dark palettes the plate went the same colour as the type sitting on it
      // and the whole card came out blank.
      const plateFill = palette.light ? '#FFFFFF' : '#F7F5F1';
      const plateInk = '#14120E';
      const plateInk2 = '#6B6154';

      ctx.save();
      if (style.decor === 'shadow') {
        // Hard offset, never a blur — that is what makes neubrutism read.
        fillRound(ctx, plateX + 18, plateTop + 18, plateW, plateH, 56, hexA('#000000', 0.9));
      } else {
        ctx.shadowColor = hexA('#000000', palette.light ? 0.16 : 0.45);
        ctx.shadowBlur = 60;
        ctx.shadowOffsetY = 24;
      }
      fillRound(ctx, plateX, plateTop, plateW, plateH, 56, plateFill);
      ctx.restore();

      // Cut-line, which is what sells a physical sticker.
      ctx.strokeStyle = palette.accent;
      ctx.lineWidth = 10;
      roundRectPath(ctx, plateX, plateTop, plateW, plateH, 56);
      ctx.stroke();

      // Repaint the stack in the plate's own inks. Chrome lettering is dropped
      // here: a chrome gradient on a pale plate is unreadable.
      const platePalette: Palette = { ...palette, ink: plateInk, ink2: plateInk2 };
      const plateStyle: StickerStyle = {
        ...style,
        decor: style.decor === 'chrome' ? 'grain' : style.decor,
      };
      centreStack(
        [
          {
            measure: headlineItem.measure,
            draw: paintHeadlineWith(platePalette, plateStyle),
            gap: 0,
          },
          { measure: metaItem.measure, draw: paintMetaWith(platePalette), gap: 56 },
        ],
        centreY,
      );
      break;
    }

    case 'poster': {
      paintDecor(ctx, style.decor, palette);
      centreStack([headlineItem, metaItem], centreY + 30);
      // Footer rail anchors the composition at the foot of the frame.
      ctx.fillStyle = palette.accent;
      ctx.fillRect(0, H - 150, W, 150);
      ctx.fillStyle = palette.onAccent;
      ctx.font = '600 38px "Inter", system-ui, sans-serif';
      ctx.textBaseline = 'middle';
      ctx.textAlign = 'center';
      ctx.fillText('100% anonymous · no sign-up', W / 2, H - 75);
      ctx.textAlign = 'left';
      ctx.textBaseline = 'alphabetic';
      break;
    }

    case 'terminal': {
      paintDecor(ctx, style.decor, palette);
      const promptFs = Math.max(28, Math.min(46, fit.size * 0.34));
      ctx.font = `700 ${promptFs}px "${font.family}", monospace`;
      const lines = wrapText(ctx, `> ${data.prompt}`, inner - 120, 8);
      const lineStep = promptFs * 1.3;
      const panelH = lines.length * lineStep + 150;
      const metaH = measureMeta();
      // Panel and meta are centred as one group, so the two can never collide
      // the way they did when the panel was positioned independently.
      const groupH = 62 + panelH + 72 + metaH;
      const groupTop = centreY - groupH / 2;
      const panelTop = groupTop + 62;

      ctx.textBaseline = 'top';
      ctx.font = `500 30px "Inter", system-ui, sans-serif`;
      ctx.fillStyle = hexA(palette.ink2, 0.85);
      ctx.fillText('$ secretmsg compose --anon', pad + 8, groupTop);

      fillRound(ctx, pad, panelTop, inner, panelH, 28, hexA(palette.accent, 0.08));
      ctx.strokeStyle = hexA(palette.accent, 0.4);
      ctx.lineWidth = 3;
      roundRectPath(ctx, pad, panelTop, inner, panelH, 28);
      ctx.stroke();

      ctx.font = `700 ${promptFs}px "${font.family}", monospace`;
      lines.forEach((line, i) => {
        const y = panelTop + 72 + i * lineStep;
        ctx.fillStyle = palette.ink;
        ctx.fillText(line, pad + 44, y);
        const caretX = pad + 44 + ctx.measureText(line).width + 12;
        ctx.fillStyle = palette.accent;
        ctx.fillRect(caretX, y + 4, promptFs * 0.3, promptFs * 0.82);
      });

      paintMeta(panelTop + panelH + 72);
      break;
    }

    case 'badge': {
      paintDecor(ctx, style.decor, palette);
      const badgeFs = 30;
      const badgeLabel = 'ANONYMOUS BOARD';
      // Measured, not a guessed 340: with tracking applied a fixed width
      // clipped the label on Cobalt Navy and Denim Badge.
      ctx.font = `700 ${badgeFs}px "Inter", system-ui, sans-serif`;
      setTracking(ctx, 0.08);
      const badgeW = Math.min(inner, ctx.measureText(badgeLabel).width + 72);
      setTracking(ctx, 0);
      const badgeH = 74;
      const badgeY = centreY - headH / 2 - badgeH - 70;
      fillRound(ctx, (W - badgeW) / 2, badgeY, badgeW, badgeH, badgeH / 2, palette.accent);
      ctx.fillStyle = palette.onAccent;
      ctx.font = `700 ${badgeFs}px "Inter", system-ui, sans-serif`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      setTracking(ctx, 0.08);
      ctx.fillText(badgeLabel, W / 2, badgeY + badgeH / 2);
      setTracking(ctx, 0);
      ctx.textAlign = 'left';
      ctx.textBaseline = 'alphabetic';
      centreStack([headlineItem, metaItem], centreY + (badgeH + 70) / 2);
      break;
    }
  }
}

/* ------------------------------------------------------------------ entry */

/**
 * Render one design into a canvas at full 1080x1920.
 *
 * Pictographs are stripped: canvas colour-emoji fallback is inconsistent
 * between browsers and would render differently again once the PNG is opened on
 * a phone, so a clean typographic card is the dependable result. The caption
 * the visitor copies keeps its emoji.
 */
const PICTOGRAPH = /\p{Extended_Pictographic}/gu;

export function stripPictographs(input: string): string {
  return input.replace(PICTOGRAPH, '').replace(/\s{2,}/g, ' ').trim();
}

export function renderSticker(
  canvas: HTMLCanvasElement,
  style: StickerStyle,
  data: StickerData,
): void {
  canvas.width = W;
  canvas.height = H;
  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const prompt = stripPictographs(data.prompt) || 'say something honest';
  const resolved: StickerData = { ...data, prompt };

  ctx.save();
  try {
    ctx.clearRect(0, 0, W, H);
    ctx.textBaseline = 'alphabetic';
    ctx.textAlign = 'left';
    paintBackground(ctx, style.palette);

    const pad = 96;
    drawArchetype({
      ctx,
      style,
      data: resolved,
      pad,
      inner: W - pad * 2,
    });
  } finally {
    ctx.restore();
  }
}

export function stickerToBlob(canvas: HTMLCanvasElement): Promise<Blob | null> {
  return new Promise((resolve) => canvas.toBlob(resolve, 'image/png'));
}
