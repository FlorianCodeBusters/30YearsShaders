// Moteur du deck : mise à l'échelle du plateau, navigation, chrono, et la boîte à outils des maquettes.
(() => {
  "use strict";
  const W = 1920, H = 1080;
  const cadre = document.getElementById("cadre");
  const plateau = document.getElementById("plateau");
  const slides = [...document.querySelectorAll(".slide")];
  const fabriques = {};      // id de maquette -> fonction qui la construit
  const vivantes = new Map(); // élément .maquette -> { start, stop }
  let courante = -1;
  let depart = 0;            // début du chrono (0 = pas lancé)

  // ---------------------------------------------------------------- boîte à outils des maquettes
  const M = {
    el(tag, cls, parent, text) {
      const e = document.createElement(tag);
      if (cls) e.className = cls;
      if (text !== undefined) e.textContent = text;
      if (parent) parent.appendChild(e);
      return e;
    },
    canvas(parent, w, h, pixel) {
      const c = M.el("canvas", "ecran" + (pixel ? " pixel" : ""), parent);
      c.width = w; c.height = h;
      return c;
    },
    rang(parent) { return M.el("div", "rang", parent); },
    lecture(parent) { return M.el("div", "lecture", parent); },
    slider(parent, label, min, max, step, value, fmt, onChange) {
      const box = M.el("label", "commande", parent);
      const head = M.el("span", "", box, label + " ");
      const out = M.el("output", "", head);
      const input = M.el("input", "", box);
      input.type = "range"; input.min = min; input.max = max; input.step = step; input.value = value;
      const show = () => { out.textContent = fmt ? fmt(+input.value) : input.value; };
      input.addEventListener("input", () => { show(); onChange(+input.value); });
      show();
      return input;
    },
    toggle(parent, label, on, onChange) {
      const b = M.el("button", "inter", parent, label);
      b.type = "button"; b.setAttribute("aria-pressed", on ? "true" : "false");
      b.addEventListener("click", () => {
        const now = b.getAttribute("aria-pressed") !== "true";
        b.setAttribute("aria-pressed", now ? "true" : "false");
        onChange(now);
      });
      return b;
    },
    choice(parent, labels, index, onChange) {
      const box = M.el("div", "choix", parent);
      const buttons = labels.map((label, i) => {
        const b = M.el("button", "", box, label);
        b.type = "button"; b.setAttribute("aria-pressed", i === index ? "true" : "false");
        b.addEventListener("click", () => {
          buttons.forEach((o, j) => o.setAttribute("aria-pressed", j === i ? "true" : "false"));
          onChange(i);
        });
        return b;
      });
      return box;
    },
    button(parent, label, onClick, fort) {
      const b = M.el("button", "bouton" + (fort ? " fort" : ""), parent, label);
      b.type = "button"; b.addEventListener("click", onClick);
      return b;
    },
    // Position du pointeur dans les coordonnées internes du canvas.
    pos(canvas, ev) {
      const r = canvas.getBoundingClientRect();
      return { x: (ev.clientX - r.left) * canvas.width / r.width, y: (ev.clientY - r.top) * canvas.height / r.height };
    },
    // Glisser sur un canvas : cb(x, y, "down" | "move" | "up"). `hover` : aussi sans appuyer.
    drag(canvas, cb, hover) {
      let down = false;
      canvas.addEventListener("pointerdown", (e) => { down = true; canvas.setPointerCapture(e.pointerId); const p = M.pos(canvas, e); cb(p.x, p.y, "down"); });
      canvas.addEventListener("pointermove", (e) => { if (down || hover) { const p = M.pos(canvas, e); cb(p.x, p.y, "move"); } });
      const end = (e) => { if (down) { down = false; const p = M.pos(canvas, e); cb(p.x, p.y, "up"); } };
      canvas.addEventListener("pointerup", end); canvas.addEventListener("pointercancel", end);
    },
    // Boucle d'animation qu'on peut arrêter. fn(t en secondes, dt).
    loop(fn) {
      let id = 0, last = 0, t0 = 0;
      const tick = (now) => {
        if (!t0) { t0 = now; last = now; }
        const dt = Math.min((now - last) / 1000, 0.1); last = now;
        fn((now - t0) / 1000, dt);
        id = requestAnimationFrame(tick);
      };
      return { start() { if (!id) { t0 = 0; id = requestAnimationFrame(tick); } }, stop() { cancelAnimationFrame(id); id = 0; } };
    },
    // Générateur pseudo-aléatoire reproductible.
    rng(seed) {
      let a = seed >>> 0;
      return () => { a |= 0; a = (a + 0x6d2b79f5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
    },
    hash(x, y, seed) {
      const s = Math.sin(x * 127.1 + y * 311.7 + seed * 74.7) * 43758.5453;
      return s - Math.floor(s);
    },
    // Le bruit de Perlin de la démo, tel quel : une direction au hasard à chaque coin, un mélange doux entre.
    perlin(x, y, t, seed) {
      const ix = Math.floor(x), iy = Math.floor(y), fx = x - ix, fy = y - iy;
      const g = (cx, cy, dx, dy) => { const a = 6.2831853 * M.hash(cx, cy, seed) + t; return Math.cos(a) * dx + Math.sin(a) * dy; };
      const a = g(ix, iy, fx, fy), b = g(ix + 1, iy, fx - 1, fy), c = g(ix, iy + 1, fx, fy - 1), d = g(ix + 1, iy + 1, fx - 1, fy - 1);
      const sx = fx * fx * fx * (fx * (fx * 6 - 15) + 10), sy = fy * fy * fy * (fy * (fy * 6 - 15) + 10);
      return (a + (b - a) * sx + (c + (d - c) * sx - (a + (b - a) * sx)) * sy) * 1.4;
    },
    fbm(x, y, t, seed) {
      return M.perlin(x, y, t, seed) * 0.55 + M.perlin(x * 2.1, y * 2.1, -t * 1.3, seed + 1) * 0.28 + M.perlin(x * 4.3, y * 4.3, t * 1.7, seed + 2) * 0.17;
    },
    clamp(v, a, b) { return v < a ? a : v > b ? b : v; },
    mix(a, b, t) { return a + (b - a) * t; },
    fr(n) { return n.toLocaleString("fr-FR"); },
  };

  window.Deck = { M, register(id, fabrique) { fabriques[id] = fabrique; } };

  // ---------------------------------------------------------------- navigation
  function ajuster() {
    const s = Math.min(cadre.clientWidth / W, cadre.clientHeight / H);
    plateau.style.transform = `translate(-50%, -50%) scale(${s})`;
  }

  function maquettesDe(slide) { return [...slide.querySelectorAll("[data-maquette]")]; }

  function aller(n) {
    n = M.clamp(n, 0, slides.length - 1);
    if (n === courante) return;
    if (courante >= 0) {
      slides[courante].classList.remove("active");
      maquettesDe(slides[courante]).forEach((el) => { const m = vivantes.get(el); if (m && m.stop) m.stop(); });
    }
    courante = n;
    const slide = slides[n];
    slide.classList.add("active");
    maquettesDe(slide).forEach((el) => {
      if (!vivantes.has(el)) {
        const fabrique = fabriques[el.dataset.maquette];
        try { vivantes.set(el, fabrique ? fabrique(el) || {} : {}); }
        catch (err) { console.error("Maquette " + el.dataset.maquette, err); vivantes.set(el, {}); }
      }
      const m = vivantes.get(el);
      if (m.start) m.start();
    });
    majFrise();
    try { history.replaceState(null, "", "#d" + (n + 1)); } catch (e) { /* aperçu sans historique */ }
  }

  const PARTIES = ["Intro", "1996-2006", "2006-2016", "2016-2026", "Conclusion"];
  function majFrise() {
    const partie = +slides[courante].dataset.part;
    document.querySelectorAll("#frise .etape").forEach((e, i) => e.classList.toggle("ici", i === partie));
    document.getElementById("compteur").textContent = (courante + 1) + " / " + slides.length;
    majChrono();
  }

  // Chrono (touche T) : temps écoulé / temps prévu à la fin de la slide courante.
  function prevu(n) { let s = 0; for (let i = 0; i <= n; i++) s += +(slides[i].dataset.t || 0); return s; }
  function mmss(s) { s = Math.max(0, Math.round(s)); return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0"); }
  function majChrono() {
    const el = document.getElementById("chrono");
    if (el.hidden) return;
    const ecoule = depart ? (performance.now() - depart) / 1000 : 0;
    el.textContent = mmss(ecoule) + " / " + mmss(prevu(courante));
    el.classList.toggle("retard", ecoule > prevu(courante) + 20);
  }
  setInterval(majChrono, 1000);

  window.addEventListener("keydown", (e) => {
    const champ = e.target instanceof HTMLButtonElement;
    const k = e.key;
    if (e.ctrlKey || e.altKey || e.metaKey) return;
    let fait = true;
    if (k === "ArrowRight" || k === "PageDown" || (!champ && (k === " " || k === "Enter"))) aller(courante + 1);
    else if (k === "ArrowLeft" || k === "PageUp") aller(courante - 1);
    else if (k === "Home") aller(0);
    else if (k === "End") aller(slides.length - 1);
    else if (k === "t" || k === "T") {
      const el = document.getElementById("chrono");
      el.hidden = !el.hidden;
      if (!el.hidden && !depart) depart = performance.now();
      majChrono();
    } else if (k === "r" || k === "R") { depart = performance.now(); majChrono(); }
    else if (k === "f" || k === "F") {
      if (document.fullscreenElement) document.exitFullscreen();
      else if (document.documentElement.requestFullscreen) document.documentElement.requestFullscreen().catch(() => {});
    } else fait = false;
    if (fait) { e.preventDefault(); e.stopPropagation(); }
  }, true);

  document.getElementById("precedent").addEventListener("click", () => aller(courante - 1));
  document.getElementById("suivant").addEventListener("click", () => aller(courante + 1));
  window.addEventListener("resize", ajuster);
  window.addEventListener("hashchange", () => { const m = /^#d(\d+)$/.exec(location.hash); if (m) aller(+m[1] - 1); });

  window.Deck.demarrer = () => {
    document.getElementById("frise").insertAdjacentHTML("afterbegin", PARTIES.map((p) => `<span class="etape">${p}</span>`).join(""));
    ajuster();
    const m = /^#d(\d+)$/.exec(location.hash);
    aller(m ? +m[1] - 1 : 0);
  };
})();
