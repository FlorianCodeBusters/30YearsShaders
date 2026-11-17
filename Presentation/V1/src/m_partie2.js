// Maquettes de la partie 2 (2006-2016).
(() => {
  "use strict";
  const { M, register } = window.Deck;

  // ------------------------------------------------------------------ La table de mixage : HDR, glow, tonemapping
  register("postfx", (root) => {
    const W = 320, H = 180;
    const cv = M.canvas(root, W, H, false); cv.style.width = "1040px";
    const ctx = cv.getContext("2d"), img = ctx.createImageData(W, H);
    // L'image de départ : une enseigne au néon, dessinée une fois.
    const src = document.createElement("canvas"); src.width = W; src.height = H;
    const s = src.getContext("2d");
    s.fillStyle = "#07090f"; s.fillRect(0, 0, W, H);
    s.fillStyle = "#151a26"; s.fillRect(0, 128, W, 52);
    s.lineCap = "round"; s.lineJoin = "round";
    s.strokeStyle = "#ff2f8a"; s.lineWidth = 4; s.font = "700 54px Trebuchet MS, sans-serif"; s.textAlign = "center";
    s.strokeText("PERLIN", 160, 86);
    s.strokeStyle = "#27d7ff"; s.lineWidth = 3; s.strokeRect(40, 26, 240, 82);
    s.strokeStyle = "#ffcf3a"; s.beginPath(); s.arc(276, 142, 16, 0, 6.3); s.stroke();
    s.beginPath(); s.moveTo(30, 150); s.lineTo(120, 150); s.stroke();
    const base = s.getImageData(0, 0, W, H).data;
    const lin = new Float32Array(W * H * 3), neon = new Float32Array(W * H);
    for (let i = 0; i < W * H; i++) {
      for (let c = 0; c < 3; c++) lin[i * 3 + c] = Math.pow(base[i * 4 + c] / 255, 2.2);
      neon[i] = Math.max(base[i * 4], base[i * 4 + 1], base[i * 4 + 2]) > 150 ? 1 : 0;   // ce qui émet de la lumière
    }
    const etat = { intensite: 4, glow: true, tonemap: true };
    const halo = new Float32Array(W * H * 3), tmp = new Float32Array(W * H * 3);
    function flou(a, b, rayon, horizontal) {   // flou « boîte » dans une direction
      for (let j = 0; j < H; j++) for (let i = 0; i < W; i++) for (let c = 0; c < 3; c++) {
        let somme = 0;
        for (let k = -rayon; k <= rayon; k++) {
          const x = horizontal ? M.clamp(i + k, 0, W - 1) : i, y = horizontal ? j : M.clamp(j + k, 0, H - 1);
          somme += a[(y * W + x) * 3 + c];
        }
        b[(j * W + i) * 3 + c] = somme / (2 * rayon + 1);
      }
    }
    function rendre() {
      const I = etat.intensite;
      // 1. Ce qui dépasse le blanc de l'écran…
      for (let i = 0; i < W * H; i++) for (let c = 0; c < 3; c++) halo[i * 3 + c] = Math.max(0, lin[i * 3 + c] * (neon[i] ? I : 1) - 1);
      // 2. …on le floute : c'est le glow.
      for (let passe = 0; passe < 2; passe++) { flou(halo, tmp, 7, true); flou(tmp, halo, 7, false); }
      for (let i = 0; i < W * H; i++) for (let c = 0; c < 3; c++) {
        let v = lin[i * 3 + c] * (neon[i] ? I : 1);
        if (etat.glow) v += halo[i * 3 + c] * 1.6;
        // 3. On ramène le tout dans ce que l'écran sait afficher.
        v = etat.tonemap ? v / (1 + v) * 1.35 : Math.min(1, v);
        img.data[i * 4 + c] = Math.pow(M.clamp(v, 0, 1), 1 / 2.2) * 255;
      }
      for (let i = 0; i < W * H; i++) img.data[i * 4 + 3] = 255;
      ctx.putImageData(img, 0, 0);
      lecture.innerHTML = `Dans l'image, le néon vaut <b>${I.toFixed(1).replace(".", ",")}</b>. L'écran, lui, s'arrête à 1.` +
        (etat.tonemap ? "" : " Sans tonemapping : tout ce qui dépasse devient <b>blanc</b>.");
    }
    const rang = M.rang(root);
    M.slider(rang, "Intensité des néons :", 1, 8, 0.5, etat.intensite, (v) => "× " + v.toFixed(1).replace(".", ","), (v) => { etat.intensite = v; rendre(); });
    M.toggle(rang, "Glow", true, (v) => { etat.glow = v; rendre(); });
    M.toggle(rang, "Tonemapping", true, (v) => { etat.tonemap = v; rendre(); });
    const lecture = M.lecture(root);
    rendre();
    return {};
  });

  // ------------------------------------------------------------------ Les fléchettes : SSAO
  register("ssao", (root) => {
    const W = 1040, H = 430, BANDE = 86;
    const cv = M.canvas(root, W, H + BANDE + 14, false); cv.style.width = W + "px"; cv.style.cursor = "ew-resize";
    const ctx = cv.getContext("2d");
    // Le décor vu en coupe : la hauteur du sol pour chaque x.
    const sol = (x) => {
      if (x < 170) return 110;                     // un mur à gauche
      if (x > 330 && x < 470) return 280;          // une caisse
      if (x > 600 && x < 690) return 400;          // un fossé
      if (x > 860) return 190;                     // une marche
      return 330;
    };
    const etat = { n: 8, flou: false, graine: 7, x: 520 };
    const RAYON = 78;
    function ao(x, n, rand) {   // part des fléchettes tombées « dans le dur »
      const y = sol(x); let cachees = 0; const pts = [];
      for (let i = 0; i < n; i++) {
        const a = rand() * Math.PI, r = RAYON * Math.sqrt(rand());
        const px = x + Math.cos(a) * r, py = y - Math.sin(a) * r - 1;
        const dedans = py > sol(px);
        if (dedans) cachees++;
        pts.push([px, py, dedans]);
      }
      return { valeur: 1 - cachees / n, pts };
    }
    function dessiner() {
      ctx.fillStyle = "#18202b"; ctx.fillRect(0, 0, cv.width, cv.height);
      ctx.fillStyle = "#3b475a"; ctx.beginPath(); ctx.moveTo(0, H);
      for (let x = 0; x <= W; x += 2) ctx.lineTo(x, sol(x));
      ctx.lineTo(W, H); ctx.closePath(); ctx.fill();
      ctx.strokeStyle = "#8ea0b8"; ctx.lineWidth = 3; ctx.beginPath();
      for (let x = 0; x <= W; x += 2) { if (x === 0) ctx.moveTo(x, sol(x)); else ctx.lineTo(x, sol(x)); }
      ctx.stroke();
      // Le pixel observé et ses fléchettes.
      const y = sol(etat.x), tir = ao(etat.x, etat.n, M.rng(etat.graine * 131 + 5));
      ctx.strokeStyle = "rgba(255,255,255,0.5)"; ctx.setLineDash([6, 6]); ctx.lineWidth = 2;
      ctx.beginPath(); ctx.arc(etat.x, y, RAYON, Math.PI, 0); ctx.stroke(); ctx.setLineDash([]);
      for (const [px, py, dedans] of tir.pts) {
        ctx.fillStyle = dedans ? "#ff5a4f" : "#5fe08c";
        ctx.beginPath(); ctx.arc(px, py, 7, 0, 6.3); ctx.fill();
      }
      ctx.fillStyle = "#ffd24a"; ctx.beginPath(); ctx.arc(etat.x, y, 9, 0, 6.3); ctx.fill();
      // La bande du bas : la même estimation pour tous les pixels de l'écran.
      const pas = 4, vals = [];
      for (let x = 0; x < W; x += pas) vals.push(ao(x + pas / 2, etat.n, M.rng(etat.graine * 977 + x)).valeur);
      const lisse = vals.map((v, i) => {
        if (!etat.flou) return v;
        let s = 0, c = 0;
        for (let k = -7; k <= 7; k++) { const u = vals[i + k]; if (u !== undefined) { s += u; c++; } }
        return s / c;
      });
      lisse.forEach((v, i) => { const g = Math.round(40 + v * 215); ctx.fillStyle = `rgb(${g},${g},${g})`; ctx.fillRect(i * pas, H + 14, pas, BANDE); });
      ctx.fillStyle = "#ffd24a"; ctx.fillRect(etat.x - 1.5, H + 8, 3, BANDE + 6);
      const cachees = tir.pts.filter((p) => p[2]).length;
      lecture.innerHTML = `<b>${cachees}</b> sur <b>${etat.n}</b> dans le décor → pixel assombri de <b>${Math.round((1 - tir.valeur) * 100)} %</b>`;
    }
    M.drag(cv, (x) => { etat.x = M.clamp(x, 20, W - 20); dessiner(); }, true);
    const rang = M.rang(root);
    const PALIERS = [2, 4, 8, 16, 32, 64, 128];
    M.slider(rang, "Fléchettes par pixel :", 0, PALIERS.length - 1, 1, 2, (v) => String(PALIERS[v]), (v) => { etat.n = PALIERS[v]; dessiner(); });
    M.toggle(rang, "Flou", false, (v) => { etat.flou = v; dessiner(); });
    M.button(rang, "Relancer", () => { etat.graine++; dessiner(); });
    const lecture = M.lecture(root);
    dessiner();
    return {};
  });

  // ------------------------------------------------------------------ La volière : les boids
  register("boids", (root) => {
    const W = 1040, H = 520;
    const cv = M.canvas(root, W, H, false); cv.style.width = W + "px";
    const ctx = cv.getContext("2d");
    const etat = { n: 220, sep: true, ali: true, coh: true };
    let boids = [];
    const peupler = () => {
      const rand = M.rng(42);
      boids = Array.from({ length: 600 }, () => { const a = rand() * 6.283; return { x: rand() * W, y: rand() * H, vx: Math.cos(a) * 90, vy: Math.sin(a) * 90 }; });
    };
    function pas(dt) {
      const n = etat.n, VISION = 62, MIN = 20;
      for (let i = 0; i < n; i++) {
        const b = boids[i]; let cx = 0, cy = 0, dx = 0, dy = 0, fx = 0, fy = 0, voisins = 0;
        for (let j = 0; j < n; j++) {
          if (j === i) continue;
          const o = boids[j]; let ex = o.x - b.x, ey = o.y - b.y;
          ex -= W * Math.round(ex / W); ey -= H * Math.round(ey / H);
          const d = Math.hypot(ex, ey);
          if (d < VISION) {
            cx += ex; cy += ey; dx += o.vx; dy += o.vy; voisins++;
            if (d < MIN) { const k = (1 - d / MIN) / Math.max(d, 0.01); fx -= ex * k; fy -= ey * k; }
          }
        }
        let ax = 0, ay = 0;
        if (etat.sep) { ax += 900 * fx; ay += 900 * fy; }
        if (voisins) {
          if (etat.coh) { ax += 1.2 * cx / voisins; ay += 1.2 * cy / voisins; }
          if (etat.ali) { ax += 2.5 * (dx / voisins - b.vx); ay += 2.5 * (dy / voisins - b.vy); }
        }
        b.nvx = b.vx + ax * dt; b.nvy = b.vy + ay * dt;
      }
      for (let i = 0; i < n; i++) {
        const b = boids[i], v = Math.hypot(b.nvx, b.nvy) || 1, k = M.clamp(v, 70, 180) / v;
        b.vx = b.nvx * k; b.vy = b.nvy * k;
        b.x = (b.x + b.vx * dt + W) % W; b.y = (b.y + b.vy * dt + H) % H;
      }
    }
    function dessiner() {
      ctx.fillStyle = "#18202b"; ctx.fillRect(0, 0, W, H);
      for (let i = 0; i < etat.n; i++) {
        const b = boids[i], a = Math.atan2(b.vy, b.vx);
        ctx.fillStyle = `hsl(${(a / 6.283 + 0.5) * 360},85%,68%)`;
        ctx.beginPath();
        ctx.moveTo(b.x + Math.cos(a) * 11, b.y + Math.sin(a) * 11);
        ctx.lineTo(b.x + Math.cos(a + 2.5) * 7, b.y + Math.sin(a + 2.5) * 7);
        ctx.lineTo(b.x + Math.cos(a - 2.5) * 7, b.y + Math.sin(a - 2.5) * 7);
        ctx.fill();
      }
    }
    const rang = M.rang(root);
    const lecture = M.lecture(root);
    const maj = () => { lecture.innerHTML = `<b>${M.fr(etat.n)}</b> oiseaux → <b>${M.fr(etat.n * (etat.n - 1))}</b> comparaisons par image. À 4 096 : <b>16,8 millions</b>.`; };
    M.slider(rang, "Oiseaux :", 20, 600, 20, etat.n, null, (v) => { etat.n = v; maj(); });
    M.toggle(rang, "S'écarter", true, (v) => { etat.sep = v; });
    M.toggle(rang, "S'aligner", true, (v) => { etat.ali = v; });
    M.toggle(rang, "Se regrouper", true, (v) => { etat.coh = v; });
    peupler(); maj();
    const anim = M.loop((_, dt) => { pas(Math.min(dt, 0.033)); dessiner(); });
    return { start: anim.start, stop: anim.stop };
  });

  // ------------------------------------------------------------------ La boule témoin : PBR
  register("pbr", (root) => {
    const S = 260;
    const rang = M.rang(root); rang.style.flexWrap = "nowrap"; rang.style.gap = "34px";
    const cv = M.canvas(rang, S, S, false); cv.style.width = "540px";
    const ctx = cv.getContext("2d"), img = ctx.createImageData(S, S);
    const droite = M.el("div", "", rang); droite.style.cssText = "display:flex;flex-direction:column;gap:20px;align-items:flex-start;width:420px";
    const COULEURS = { Or: [1.0, 0.77, 0.34], Cuivre: [0.95, 0.64, 0.54], Rouge: [0.8, 0.1, 0.1], Bleu: [0.1, 0.3, 0.8], Blanc: [0.92, 0.92, 0.92] };
    const etat = { rugosite: 0.35, metal: 0, couleur: COULEURS.Rouge };
    // Le « studio » autour de la boule : un ciel sombre, un sol, et trois boîtes à lumière colorées.
    function decor(x, y, z) {
      let r = 0.05, g = 0.06, b = 0.1;
      if (y < -0.1) { r = 0.1; g = 0.09; b = 0.08; }
      const boite = (cx, cy, l, h, cr, cg, cb) => { if (z > -0.2 && Math.abs(x - cx) < l && Math.abs(y - cy) < h) { r += cr; g += cg; b += cb; } };
      boite(-0.55, 0.55, 0.22, 0.3, 6, 6, 6);
      boite(0.6, 0.25, 0.1, 0.45, 5, 0.6, 2.4);
      boite(0.1, -0.5, 0.45, 0.06, 0.4, 3.5, 5);
      return [r, g, b];
    }
    const MOYEN = [0.42, 0.36, 0.44];   // la couleur moyenne du studio, pour les reflets très flous
    function rendre() {
      const a = etat.rugosite * etat.rugosite, k = (etat.rugosite + 1) * (etat.rugosite + 1) / 8;
      const F0 = etat.couleur.map((c) => M.mix(0.04, c, etat.metal));
      const lumieres = [[-0.5, 0.6, 0.62, 3.2, 3.2, 3.2], [0.75, 0.2, 0.63, 2.2, 0.4, 1.2]];
      for (let j = 0; j < S; j++) for (let i = 0; i < S; i++) {
        const x = (i - S / 2) / (S * 0.44), y = (S / 2 - j) / (S * 0.44), o = (j * S + i) * 4, d2 = x * x + y * y;
        if (d2 > 1) { img.data[o] = 24; img.data[o + 1] = 32; img.data[o + 2] = 43; img.data[o + 3] = 255; continue; }
        const z = Math.sqrt(1 - d2), nv = Math.max(z, 0.001);
        const fres = Math.pow(1 - nv, 5), col = [0, 0, 0];
        for (const [lx, ly, lz, cr, cg, cb] of lumieres) {
          const ln = Math.hypot(lx, ly, lz), Lx = lx / ln, Ly = ly / ln, Lz = lz / ln, nl = x * Lx + y * Ly + z * Lz;
          if (nl <= 0) continue;
          let hx = Lx, hy = Ly, hz = Lz + 1; const hn = Math.hypot(hx, hy, hz); hx /= hn; hy /= hn; hz /= hn;
          const nh = Math.max(x * hx + y * hy + z * hz, 0), vh = Math.max(hz, 0);
          const den = nh * nh * (a * a - 1) + 1, D = a * a / (Math.PI * den * den);             // D : les micro-facettes
          const G = (nv / (nv * (1 - k) + k)) * (nl / (nl * (1 - k) + k));                      // G : leurs ombres
          const lum = [cr, cg, cb];
          for (let c = 0; c < 3; c++) {
            const F = F0[c] + (1 - F0[c]) * Math.pow(1 - vh, 5);                               // F : Fresnel
            col[c] += (etat.couleur[c] * (1 - etat.metal) * (1 - F) / Math.PI + D * G * F / (4 * nv * nl + 0.001)) * lum[c] * nl;
          }
        }
        // Le reflet du studio, de plus en plus flou avec la rugosité.
        const env = decor(2 * z * x, 2 * z * y, 2 * z * z - 1), net = Math.pow(1 - etat.rugosite, 2.2);
        for (let c = 0; c < 3; c++) {
          const F = F0[c] + (Math.max(1 - etat.rugosite, F0[c]) - F0[c]) * fres;
          col[c] += F * M.mix(MOYEN[c], env[c], net) + etat.couleur[c] * (1 - etat.metal) * 0.05;
          const v = col[c] / (1 + col[c]);
          img.data[o + c] = Math.pow(v, 1 / 2.2) * 255;
        }
        img.data[o + 3] = 255;
      }
      ctx.putImageData(img, 0, 0);
    }
    const sR = M.slider(droite, "Rugosité :", 0.04, 1, 0.01, etat.rugosite, (v) => v.toFixed(2).replace(".", ","), (v) => { etat.rugosite = v; rendre(); });
    const sM = M.slider(droite, "Métal :", 0, 1, 0.01, etat.metal, (v) => v.toFixed(2).replace(".", ","), (v) => { etat.metal = v; rendre(); });
    sR.style.width = sM.style.width = "400px";
    M.choice(droite, Object.keys(COULEURS), 2, (i) => { etat.couleur = Object.values(COULEURS)[i]; rendre(); });
    const presets = M.rang(droite); presets.style.justifyContent = "flex-start"; presets.style.gap = "10px";
    const regler = (r, m) => { etat.rugosite = r; etat.metal = m; sR.value = r; sM.value = m; sR.dispatchEvent(new Event("input")); sM.dispatchEvent(new Event("input")); };
    M.button(presets, "Plastique", () => regler(0.35, 0));
    M.button(presets, "Caoutchouc", () => regler(0.9, 0));
    M.button(presets, "Métal poli", () => regler(0.12, 1));
    M.button(presets, "Métal brossé", () => regler(0.5, 1));
    const lecture = M.lecture(root);
    lecture.innerHTML = "Deux curseurs, les <b>mêmes formules</b> pour toutes les matières.";
    rendre();
    return {};
  });
})();
