// Maquettes de l'intro et de la partie 1 (1996-2006).
(() => {
  "use strict";
  const { M, register } = window.Deck;

  // ------------------------------------------------------------------ Le rideau : 1996 | 2026
  register("rideau", (root) => {
    const box = M.el("div", "pile", root);
    const largeur = +root.dataset.largeur || 1060;   // data-largeur : plus petit sur la dernière slide
    box.style.cssText = `width:${largeur}px;height:${Math.round(largeur * 387 / 1060)}px;border:6px solid var(--encre);border-radius:8px;overflow:hidden;cursor:ew-resize;touch-action:none`;
    const apres = M.el("img", "", box), avant = M.el("img", "", box), barre = M.el("div", "", box);
    apres.src = window.DECK_IMAGES.scene_2026; avant.src = window.DECK_IMAGES.scene_1996;
    apres.alt = "La scène en 2026"; avant.alt = "La même scène en 1996";
    for (const img of [apres, avant]) img.style.cssText = "position:absolute;inset:0;width:100%;height:100%;object-fit:cover;max-width:none";
    barre.style.cssText = "position:absolute;top:0;bottom:0;width:8px;margin-left:-4px;background:#f2b824;box-shadow:0 0 0 3px #2a1f14";
    // data-sobre (dernière slide) : le rideau seul, sans la légende.
    const lecture = "sobre" in root.dataset ? null : M.lecture(root);
    let x = 0.5, libre = true;
    const poser = (v) => {
      x = M.clamp(v, 0.02, 0.98);
      avant.style.clipPath = `inset(0 ${(1 - x) * 100}% 0 0)`;
      barre.style.left = x * 100 + "%";
      if (lecture) lecture.innerHTML = "<b>1996</b> à gauche du rideau · <b>2026</b> à droite. Même géométrie, mêmes textures.";
    };
    const bouger = (e) => { const r = box.getBoundingClientRect(); libre = false; poser((e.clientX - r.left) / r.width); };
    box.addEventListener("pointerdown", (e) => { box.setPointerCapture(e.pointerId); bouger(e); });
    box.addEventListener("pointermove", (e) => { if (e.buttons) bouger(e); });
    const anim = M.loop((t) => { if (libre) poser(0.5 + 0.38 * Math.sin(t * 0.7)); });
    poser(0.5);
    return { start: () => { libre = true; anim.start(); }, stop: anim.stop };
  });

  // ------------------------------------------------------------------ Le pupitre du pipeline fixe
  register("interrupteurs", (root) => {
    const W = 320, H = 180;
    const cv = M.canvas(root, W, H, true); cv.style.width = "1040px";
    const ctx = cv.getContext("2d"), img = ctx.createImageData(W, H);
    const etat = { textures: true, lumiere: true, brouillard: true };
    const L = [0.48, 0.74, 0.47], BROUILLARD = [30, 34, 58];
    const eclat = (nx, ny, nz) => Math.max(0, nx * L[0] + ny * L[1] + nz * L[2]);

    function rendre() {
      for (let j = 0; j < H; j++) for (let i = 0; i < W; i++) {
        let dx = (i / W - 0.5) * 1.78, dy = (0.5 - j / H) - 0.1, dz = -1;
        const n = Math.hypot(dx, dy, dz); dx /= n; dy /= n; dz /= n;
        const ox = 0, oy = 1.25, oz = 0;
        let r = 14, g = 18, b = 38, dist = 60;
        // Une boule…
        const cx = 0.35, cy = 1.05, cz = -4.6, R = 1.05;
        const bx = ox - cx, by = oy - cy, bz = oz - cz;
        const B = bx * dx + by * dy + bz * dz, C = bx * bx + by * by + bz * bz - R * R, D = B * B - C;
        let touche = false;
        if (D > 0) {
          const t = -B - Math.sqrt(D);
          if (t > 0) {
            touche = true; dist = t;
            const nx = (ox + dx * t - cx) / R, ny = (oy + dy * t - cy) / R, nz = (oz + dz * t - cz) / R;
            // Éclairage « par sommet » : calculé sur une grille grossière de la boule, puis interpolé.
            const u = (Math.atan2(nz, nx) / 6.2831853 + 0.5) * 12, v = Math.acos(M.clamp(ny, -1, 1)) / 3.14159265 * 6;
            const u0 = Math.floor(u), v0 = Math.floor(v), fu = u - u0, fv = v - v0;
            const s = (uu, vv) => { const a = (uu / 12 - 0.5) * 6.2831853, p = vv / 6 * 3.14159265; return eclat(Math.sin(p) * Math.cos(a), Math.cos(p), Math.sin(p) * Math.sin(a)); };
            const lum = etat.lumiere ? 0.18 + 0.9 * M.mix(M.mix(s(u0, v0), s(u0 + 1, v0), fu), M.mix(s(u0, v0 + 1), s(u0 + 1, v0 + 1), fu), fv) : 1;
            const raye = etat.textures ? (Math.floor(u * 1) + Math.floor(v)) % 2 : 0;
            r = (raye ? 235 : 215) * lum; g = (raye ? 190 : 70) * lum; b = (raye ? 60 : 50) * lum;
          }
        }
        // …posée sur un sol.
        if (!touche && dy < 0) {
          const t = -oy / dy; dist = t;
          const px = ox + dx * t, pz = oz + dz * t;
          const lum = etat.lumiere ? 0.25 + 0.75 * eclat(0, 1, 0) : 1;
          const ombre = etat.lumiere && Math.hypot(px - 0.35 + 0.68, pz + 4.6 + 0.66) < 0.95 ? 0.75 : 1;   // pas de vraie ombre : un rond sombre peint
          let c = 120;
          if (etat.textures) c = ((Math.floor(px * 1.2) + Math.floor(pz * 1.2)) & 1) ? 150 : 82;
          r = c * lum * ombre; g = c * 0.92 * lum * ombre; b = c * 0.85 * lum * ombre;
        }
        if (etat.brouillard) {
          const f = M.clamp((dist - 5) / 15, 0, 1);
          r = M.mix(r, BROUILLARD[0], f); g = M.mix(g, BROUILLARD[1], f); b = M.mix(b, BROUILLARD[2], f);
        }
        const k = (j * W + i) * 4;
        img.data[k] = r; img.data[k + 1] = g; img.data[k + 2] = b; img.data[k + 3] = 255;
      }
      ctx.putImageData(img, 0, 0);
    }
    const rang = M.rang(root); rang.style.gap = "10px"; rang.style.flexWrap = "nowrap";
    M.toggle(rang, "Textures", true, (v) => { etat.textures = v; rendre(); });
    M.toggle(rang, "Lumière", true, (v) => { etat.lumiere = v; rendre(); });
    M.toggle(rang, "Brouillard", true, (v) => { etat.brouillard = v; rendre(); });
    for (const absent of ["Reflets", "Relief"]) { const b = M.toggle(rang, absent, false, () => {}); b.disabled = true; }
    const lecture = M.lecture(root);
    lecture.innerHTML = "Un effet = un <b>interrupteur</b> prévu par le fabricant. Sinon, pas d'effet.";
    rendre();
    return {};
  });

  // ------------------------------------------------------------------ La course : CPU contre GPU
  register("course", (root) => {
    const COLS = 26, ROWS = 14, CELL = 18, N = COLS * ROWS;
    const rang = M.rang(root); rang.style.gap = "26px"; rang.style.flexWrap = "nowrap";
    const pistes = ["CPU : 1 chirurgien, très rapide", "GPU : 364 ouvriers, plus lents"].map((titre) => {
      const col = M.el("div", "", rang); col.style.cssText = "display:flex;flex-direction:column;gap:10px;align-items:center";
      M.el("div", "lecture", col, titre);
      const cv = M.canvas(col, COLS * CELL, ROWS * CELL, false); cv.style.width = "468px";
      return { cv, ctx: cv.getContext("2d"), chrono: M.lecture(col) };
    });
    // L'image à peindre : un coucher de soleil sur la ville.
    const couleur = (x, y) => {
      const u = x / COLS, v = y / ROWS;
      if (Math.hypot(u - 0.68, (v - 0.42) * 0.56) < 0.13) return "#ffd24a";
      if (v > 0.72 - 0.16 * Math.abs(Math.sin(x * 1.7)) * (x % 3 === 0 ? 1.6 : 0.6)) return "#201a3a";
      return `rgb(${Math.round(250 - v * 120)},${Math.round(90 + v * 60)},${Math.round(110 + v * 90)})`;
    };
    const T_CPU = 5.2, T_GPU = 1.5;   // secondes pour finir
    let t = 0;
    function dessiner() {
      pistes.forEach((p, k) => {
        const ctx = p.ctx; ctx.fillStyle = "#18202b"; ctx.fillRect(0, 0, p.cv.width, p.cv.height);
        const faits = k === 0 ? Math.min(N, Math.floor(t / T_CPU * N)) : 0;
        const part = k === 1 ? M.clamp(t / T_GPU, 0, 1) : 0;
        for (let i = 0; i < N; i++) {
          const x = i % COLS, y = Math.floor(i / COLS);
          if (k === 0) {
            if (i < faits) { ctx.fillStyle = couleur(x, y); ctx.fillRect(x * CELL, y * CELL, CELL - 1, CELL - 1); }
            else if (i === faits) { ctx.fillStyle = "#fff"; ctx.fillRect(x * CELL, y * CELL, CELL - 1, CELL - 1); }
          } else {
            // Tous les pixels avancent en même temps, lentement : l'image entière monte en intensité.
            ctx.globalAlpha = part; ctx.fillStyle = couleur(x, y);
            ctx.fillRect(x * CELL, y * CELL, CELL - 1, CELL - 1); ctx.globalAlpha = 1;
          }
        }
        const fini = k === 0 ? T_CPU : T_GPU;
        p.chrono.innerHTML = t >= fini ? `Fini en <b>${fini.toFixed(1).replace(".", ",")} s</b>` : `${Math.min(t, fini).toFixed(1).replace(".", ",")} s…`;
      });
    }
    const anim = M.loop((_, dt) => { t += dt; dessiner(); if (t > T_CPU + 0.3) anim.stop(); });
    const bas = M.rang(root);
    M.button(bas, "Départ !", () => { t = 0; anim.stop(); anim.start(); }, true);
    const note = M.lecture(bas);
    note.innerHTML = "En 1080p : <b>2 073 600</b> pixels, 60 fois par seconde.";
    dessiner();
    // La course ne part qu'au clic sur « Départ ! » ; en revenant sur la slide, pistes remises à zéro.
    return { start() { t = 0; dessiner(); }, stop: anim.stop };
  });

  // ------------------------------------------------------------------ Le mini-shader : un programme par pixel
  register("minishader", (root) => {
    const PROGRAMMES = [
      { nom: "Dégradé", code: 'couleur = vec3(<span class="n">x</span>, <span class="n">y</span>, <span class="n">0.5</span>);', f: (x, y) => [x, y, 0.5] },
      { nom: "Disque", code: '<span class="k">if</span> (distance(pixel, centre) &lt; <span class="n">0.3</span>)\n     couleur = rose;\n<span class="k">else</span> couleur = nuit;', f: (x, y) => Math.hypot((x - 0.5) * 1.78, y - 0.5) < 0.3 ? [1, 0.2, 0.55] : [0.06, 0.08, 0.16] },
      { nom: "Vagues", code: 'couleur = vec3(<span class="n">0.5</span> + <span class="n">0.5</span> * sin(<span class="n">x</span> * <span class="n">20</span> + temps));', f: (x, y, t) => { const v = 0.5 + 0.5 * Math.sin(x * 20 + t * 3); return [v, v * 0.8, 1 - v * 0.6]; } },
      { nom: "Damier", code: 'couleur = (floor(<span class="n">x</span> * <span class="n">8</span>) + floor(<span class="n">y</span> * <span class="n">4.5</span>)) % <span class="n">2</span>\n          ? clair : sombre;', f: (x, y) => (Math.floor(x * 8) + Math.floor(y * 4.5)) % 2 ? [0.95, 0.78, 0.25] : [0.16, 0.12, 0.1] },
    ];
    let prog = 0, cols = 32, survol = null, temps = 0;
    const rang = M.rang(root); rang.style.alignItems = "flex-start"; rang.style.flexWrap = "nowrap";
    const cv = M.canvas(rang, 640, 360, true); cv.style.width = "640px";
    const ctx = cv.getContext("2d");
    const droite = M.el("div", "", rang); droite.style.cssText = "display:flex;flex-direction:column;gap:14px;width:390px";
    const code = M.el("pre", "code", droite);
    const lecture = M.lecture(droite); lecture.style.textAlign = "left"; lecture.style.minHeight = "126px";
    function dessiner() {
      const rows = Math.round(cols * 9 / 16), cw = 640 / cols, ch = 360 / rows, f = PROGRAMMES[prog].f;
      for (let j = 0; j < rows; j++) for (let i = 0; i < cols; i++) {
        const c = f((i + 0.5) / cols, (j + 0.5) / rows, temps);
        ctx.fillStyle = `rgb(${c[0] * 255 | 0},${c[1] * 255 | 0},${c[2] * 255 | 0})`;
        ctx.fillRect(Math.floor(i * cw), Math.floor(j * ch), Math.ceil(cw), Math.ceil(ch));
      }
      if (cols <= 48) {
        ctx.strokeStyle = "rgba(0,0,0,0.35)"; ctx.lineWidth = 1; ctx.beginPath();
        for (let i = 1; i < cols; i++) { ctx.moveTo(Math.floor(i * cw) + 0.5, 0); ctx.lineTo(Math.floor(i * cw) + 0.5, 360); }
        for (let j = 1; j < rows; j++) { ctx.moveTo(0, Math.floor(j * ch) + 0.5); ctx.lineTo(640, Math.floor(j * ch) + 0.5); }
        ctx.stroke();
      }
      let texte = `<b>${M.fr(cols * rows)}</b> pixels = ${M.fr(cols * rows)} exécutions du programme, à chaque image.`;
      if (survol) {
        const i = M.clamp(Math.floor(survol.x / cw), 0, cols - 1), j = M.clamp(Math.floor(survol.y / ch), 0, rows - 1);
        const x = (i + 0.5) / cols, y = (j + 0.5) / rows, c = f(x, y, temps);
        ctx.strokeStyle = "#fff"; ctx.lineWidth = 3; ctx.strokeRect(Math.floor(i * cw) + 1, Math.floor(j * ch) + 1, Math.ceil(cw) - 2, Math.ceil(ch) - 2);
        texte = `Pixel (${i}, ${j})<br>x = <b>${x.toFixed(2)}</b>, y = <b>${y.toFixed(2)}</b><br>→ couleur (${c.map((v) => v.toFixed(2)).join(", ")})`;
      }
      lecture.innerHTML = texte;
    }
    const majCode = () => { code.innerHTML = '<span class="c">// exécuté pour CHAQUE pixel</span>\n' + PROGRAMMES[prog].code; };
    M.drag(cv, (x, y) => { survol = { x, y }; }, true);
    cv.addEventListener("pointerleave", () => { survol = null; });
    const bas = M.rang(root);
    M.choice(bas, PROGRAMMES.map((p) => p.nom), 0, (i) => { prog = i; majCode(); });
    M.slider(bas, "Pixels en largeur :", 8, 160, 8, cols, null, (v) => { cols = v; });
    majCode();
    const anim = M.loop((t) => { temps = t; dessiner(); });
    return { start: anim.start, stop: anim.stop };
  });

  // ------------------------------------------------------------------ Du triangle au pixel
  register("triangle", (root) => {
    const COLS = 48, ROWS = 27, CELL = 22;
    const cv = M.canvas(root, COLS * CELL, ROWS * CELL, false); cv.style.width = "1040px"; cv.style.cursor = "grab";
    const ctx = cv.getContext("2d");
    const pts = [{ x: 230, y: 470, c: [255, 70, 70], n: "A" }, { x: 560, y: 90, c: [70, 220, 110], n: "B" }, { x: 880, y: 430, c: [80, 140, 255], n: "C" }];
    let etape = 2, pris = -1;
    const lecture = M.lecture(root);
    const TEXTES = [
      "<b>Vertex shader</b> : place les 3 sommets à l'écran. Déplacez-les.",
      "<b>Rastérisation</b> : la carte trouve quels pixels le triangle recouvre.",
      "<b>Fragment shader</b> : le programme qui choisit la couleur de chaque pixel.",
    ];
    function dessiner() {
      ctx.fillStyle = "#18202b"; ctx.fillRect(0, 0, cv.width, cv.height);
      const [a, b, c] = pts;
      const aire = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
      let couverts = 0;
      if (etape >= 1 && Math.abs(aire) > 1) {
        for (let j = 0; j < ROWS; j++) for (let i = 0; i < COLS; i++) {
          const px = (i + 0.5) * CELL, py = (j + 0.5) * CELL;
          const w0 = ((b.x - px) * (c.y - py) - (b.y - py) * (c.x - px)) / aire;
          const w1 = ((c.x - px) * (a.y - py) - (c.y - py) * (a.x - px)) / aire;
          const w2 = 1 - w0 - w1;
          if (w0 < 0 || w1 < 0 || w2 < 0) continue;
          couverts++;
          ctx.fillStyle = etape === 1 ? "#8c98a8" : `rgb(${a.c[0] * w0 + b.c[0] * w1 + c.c[0] * w2 | 0},${a.c[1] * w0 + b.c[1] * w1 + c.c[1] * w2 | 0},${a.c[2] * w0 + b.c[2] * w1 + c.c[2] * w2 | 0})`;
          ctx.fillRect(i * CELL + 1, j * CELL + 1, CELL - 2, CELL - 2);
        }
      }
      ctx.strokeStyle = "rgba(255,255,255,0.07)"; ctx.lineWidth = 1; ctx.beginPath();
      for (let i = 0; i <= COLS; i++) { ctx.moveTo(i * CELL + 0.5, 0); ctx.lineTo(i * CELL + 0.5, cv.height); }
      for (let j = 0; j <= ROWS; j++) { ctx.moveTo(0, j * CELL + 0.5); ctx.lineTo(cv.width, j * CELL + 0.5); }
      ctx.stroke();
      ctx.strokeStyle = "#fff"; ctx.lineWidth = 3; ctx.setLineDash(etape === 0 ? [] : [10, 8]);
      ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.lineTo(c.x, c.y); ctx.closePath(); ctx.stroke(); ctx.setLineDash([]);
      for (const p of pts) {
        ctx.fillStyle = `rgb(${p.c.join(",")})`; ctx.strokeStyle = "#fff"; ctx.lineWidth = 4;
        ctx.beginPath(); ctx.arc(p.x, p.y, 16, 0, 6.3); ctx.fill(); ctx.stroke();
        ctx.fillStyle = "#fff"; ctx.font = "700 26px sans-serif"; ctx.fillText(p.n, p.x + 22, p.y - 16);
      }
      lecture.innerHTML = TEXTES[etape] + (etape >= 1 ? ` &nbsp; 3 sommets → <b>${couverts}</b> pixels.` : "");
    }
    M.drag(cv, (x, y, phase) => {
      if (phase === "down") { pris = pts.findIndex((p) => Math.hypot(p.x - x, p.y - y) < 40); }
      if (pris >= 0 && phase !== "up") { pts[pris].x = M.clamp(x, 10, cv.width - 10); pts[pris].y = M.clamp(y, 10, cv.height - 10); dessiner(); }
      if (phase === "up") pris = -1;
    });
    const bas = M.rang(root);
    M.choice(bas, ["1 · Sommets", "2 · Rastérisation", "3 · Couleur par pixel"], 2, (i) => { etape = i; dessiner(); });
    dessiner();
    return {};
  });

  // ------------------------------------------------------------------ La lampe et le mur : normal map
  register("relief", (root) => {
    const W = 320, H = 180;
    const rang = M.rang(root); rang.style.flexWrap = "nowrap"; rang.style.alignItems = "flex-start";
    const cv = M.canvas(rang, W, H, false); cv.style.width = "800px"; cv.style.cursor = "crosshair";
    const droite = M.el("div", "", rang); droite.style.cssText = "display:flex;flex-direction:column;gap:10px;align-items:center;width:230px";
    const carte = M.canvas(droite, 160, 90, false); carte.style.width = "218px";
    M.el("div", "lecture", droite, "La normal map : une image de directions").style.fontSize = "19px";
    const ctx = cv.getContext("2d"), img = ctx.createImageData(W, H);
    // Le mur : des briques. Pour chaque pixel, sa couleur et la direction dans laquelle il « regarde ».
    const alb = new Float32Array(W * H * 3), nor = new Float32Array(W * H * 3);
    const BW = 54, BH = 22, J = 3;
    const haut = (x, y) => {
      const rangee = Math.floor(y / BH), xx = x + (rangee & 1) * BW / 2;
      const fx = ((xx % BW) + BW) % BW, fy = ((y % BH) + BH) % BH;
      const bord = Math.min(fx, BW - fx, fy, BH - fy);
      return M.clamp(bord / J, 0, 1) + 0.12 * M.perlin(x * 0.12, y * 0.12, 0, 3);
    };
    for (let j = 0; j < H; j++) for (let i = 0; i < W; i++) {
      const k = (j * W + i) * 3, rangee = Math.floor(j / BH), xx = i + (rangee & 1) * BW / 2;
      const fx = ((xx % BW) + BW) % BW, fy = j % BH, joint = Math.min(fx, BW - fx, fy, BH - fy) < J * 0.7;
      const ton = 0.75 + 0.5 * M.hash(Math.floor(xx / BW), rangee, 5);
      alb[k] = joint ? 0.62 : 0.62 * ton; alb[k + 1] = joint ? 0.6 : 0.27 * ton; alb[k + 2] = joint ? 0.55 : 0.2 * ton;
      const dx = haut(i + 1, j) - haut(i - 1, j), dy = haut(i, j + 1) - haut(i, j - 1);
      let nx = -dx * 1.6, ny = -dy * 1.6, nz = 1; const n = Math.hypot(nx, ny, nz);
      nor[k] = nx / n; nor[k + 1] = ny / n; nor[k + 2] = nz / n;
    }
    { // l'image de la normal map elle-même
      const c2 = carte.getContext("2d"), im2 = c2.createImageData(160, 90);
      for (let j = 0; j < 90; j++) for (let i = 0; i < 160; i++) {
        const k = (j * 2 * W + i * 2) * 3, o = (j * 160 + i) * 4;
        im2.data[o] = (nor[k] * 0.5 + 0.5) * 255; im2.data[o + 1] = (-nor[k + 1] * 0.5 + 0.5) * 255; im2.data[o + 2] = (nor[k + 2] * 0.5 + 0.5) * 255; im2.data[o + 3] = 255;
      }
      c2.putImageData(im2, 0, 0);
    }
    const etat = { relief: true, parPixel: true }, lampe = { x: 100, y: 70 };
    let libre = true;
    const lum = (x, y, k) => {
      const lx = lampe.x - x, ly = lampe.y - y, lz = 26, d = Math.hypot(lx, ly, lz);
      const nx = etat.relief && k >= 0 ? nor[k] : 0, ny = etat.relief && k >= 0 ? nor[k + 1] : 0, nz = etat.relief && k >= 0 ? nor[k + 2] : 1;
      return 0.07 + 2.3 * Math.max(0, (nx * lx + ny * ly + nz * lz) / d) / (1 + d * d / 5200);
    };
    function rendre() {
      const PAS = 80;   // en mode « par sommet » : un sommet tous les 80 pixels
      for (let j = 0; j < H; j++) for (let i = 0; i < W; i++) {
        const k = (j * W + i) * 3; let l;
        if (etat.parPixel) l = lum(i, j, k);
        else {
          const x0 = Math.floor(i / PAS) * PAS, y0 = Math.floor(j / PAS) * PAS, fx = (i - x0) / PAS, fy = (j - y0) / PAS;
          l = M.mix(M.mix(lum(x0, y0, -1), lum(x0 + PAS, y0, -1), fx), M.mix(lum(x0, y0 + PAS, -1), lum(x0 + PAS, y0 + PAS, -1), fx), fy);
        }
        const o = (j * W + i) * 4;
        img.data[o] = Math.min(255, alb[k] * l * 255); img.data[o + 1] = Math.min(255, alb[k + 1] * l * 255); img.data[o + 2] = Math.min(255, alb[k + 2] * l * 255); img.data[o + 3] = 255;
      }
      ctx.putImageData(img, 0, 0);
      ctx.fillStyle = "#ffe9a8"; ctx.strokeStyle = "#2a1f14"; ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.arc(lampe.x, lampe.y, 5, 0, 6.3); ctx.fill(); ctx.stroke();
    }
    M.drag(cv, (x, y) => { libre = false; lampe.x = x; lampe.y = y; rendre(); }, true);
    const bas = M.rang(root);
    M.choice(bas, ["Par sommet (1996)", "Par pixel (2001)"], 1, (i) => { etat.parPixel = i === 1; rendre(); });
    M.toggle(bas, "Normal map", true, (v) => { etat.relief = v; rendre(); });
    const lecture = M.lecture(root);
    lecture.innerHTML = "Promenez la <b>lampe</b>. Le mur est plat : c'est la texture qui ment.";
    const anim = M.loop((t) => { if (libre) { lampe.x = 160 + 110 * Math.cos(t * 0.8); lampe.y = 90 + 55 * Math.sin(t * 1.3); rendre(); } });
    rendre();
    return { start() { libre = true; anim.start(); }, stop: anim.stop };
  });

  // ------------------------------------------------------------------ La grille de flèches : le bruit de Perlin
  register("perlin", (root) => {
    const W = 256, H = 144, DW = 1024, DH = 576;
    const pile = M.el("div", "pile", root);
    const cv = M.canvas(pile, W, H, false); cv.style.width = DW + "px";
    const calque = M.canvas(pile, DW, DH, false); calque.style.width = "100%"; calque.style.height = "100%";
    const ctx = cv.getContext("2d"), img = ctx.createImageData(W, H), c2 = calque.getContext("2d");
    const etat = { mode: 0, grille: 6, fleches: true, palette: 0, graine: 1 };   // part du hasard brut
    const pal = [
      (v) => [v, v, v],
      (v) => { const s = Math.pow(v, 3); return [0.04 + 0.2 * v + s, 0.22 + 0.45 * v + s * 0.8, 0.42 + 0.5 * v + s * 0.5]; },
      (v) => { const n = M.clamp((v - 0.42) * 3.2, 0, 1); return [M.mix(0.25, 1, n), M.mix(0.5, 1, n), M.mix(0.9, 1, n)]; },
      (v, x) => { const m = 0.5 + 0.5 * Math.sin(x * 9 + (v - 0.5) * 16); const k = Math.pow(m, 0.35); return [0.2 + 0.75 * k, 0.2 + 0.72 * k, 0.22 + 0.68 * k]; },
      (v, x, y) => { const f = M.clamp(v * 1.5 - (1 - y) * 0.75 + 0.2, 0, 1); return [Math.min(1, f * 3), M.clamp(f * 3 - 1, 0, 1), M.clamp(f * 3 - 2, 0, 1)]; },
    ];
    function rendre(t) {
      const g = etat.grille, sy = g * H / W, riche = etat.palette >= 2;
      for (let j = 0; j < H; j++) for (let i = 0; i < W; i++) {
        const u = i / W, w = j / H; let v;
        if (etat.mode === 0) v = M.hash(i, j, etat.graine + Math.floor(t * 5));
        else if (riche) v = 0.5 + 0.62 * M.fbm(u * g, w * sy - (etat.palette === 4 ? t * 0.9 : 0), t * 0.5, etat.graine);
        else v = 0.5 + 0.5 * M.perlin(u * g, w * sy, t * 0.7, etat.graine);
        const c = pal[etat.palette](M.clamp(v, 0, 1), u, w), o = (j * W + i) * 4;
        img.data[o] = c[0] * 255; img.data[o + 1] = c[1] * 255; img.data[o + 2] = c[2] * 255; img.data[o + 3] = 255;
      }
      ctx.putImageData(img, 0, 0);
      c2.clearRect(0, 0, DW, DH);
      if (!etat.fleches || etat.mode === 0) return;
      const cell = DW / g, L = Math.min(34, cell * 0.36);
      c2.strokeStyle = "rgba(255,255,255,0.22)"; c2.lineWidth = 1.5; c2.beginPath();
      for (let x = 0; x <= g; x++) { c2.moveTo(x * cell, 0); c2.lineTo(x * cell, DH); }
      for (let y = 0; y * cell <= DH; y++) { c2.moveTo(0, y * cell); c2.lineTo(DW, y * cell); }
      c2.stroke();
      c2.strokeStyle = "#ffd24a"; c2.fillStyle = "#ffd24a"; c2.lineWidth = 4; c2.lineCap = "round";
      for (let x = 0; x <= g; x++) for (let y = 0; y * cell <= DH + 1; y++) {
        const a = 6.2831853 * M.hash(x, y, etat.graine) + t * 0.7, px = x * cell, py = y * cell, ex = px + Math.cos(a) * L, ey = py + Math.sin(a) * L;
        c2.beginPath(); c2.moveTo(px, py); c2.lineTo(ex, ey); c2.stroke();
        c2.beginPath(); c2.arc(ex, ey, 6, 0, 6.3); c2.fill();
      }
    }
    const r1 = M.rang(root);
    M.choice(r1, ["Hasard brut", "Perlin"], 0, (i) => { etat.mode = i; });
    M.toggle(r1, "Flèches", true, (v) => { etat.fleches = v; });
    M.slider(r1, "Grille :", 2, 16, 1, etat.grille, (v) => v + " cases", (v) => { etat.grille = v; });
    M.button(r1, "Relancer les dés", () => { etat.graine = 1 + Math.floor(Math.random() * 999); });
    const r2 = M.rang(root);
    M.el("span", "commande", r2, "Saupoudrer sur…");
    M.choice(r2, ["Rien", "L'eau", "Les nuages", "Le marbre", "Le feu"], 0, (i) => { etat.palette = i; });
    const anim = M.loop((t) => rendre(t));
    return { start: anim.start, stop: anim.stop };
  });
})();
