// Maquettes de la partie 3 (2016-2026) et de la conclusion.
(() => {
  "use strict";
  const { M, register } = window.Deck;

  // ------------------------------------------------------------------ La coupe : jusqu'où voit le SSR
  register("ssr", (root) => {
    const W = 1040, H = 520;
    const cv = M.canvas(root, W, H, false); cv.style.width = W + "px";
    const ctx = cv.getContext("2d");
    const SOL = 430, MUR = 960, CAM = { x: 150, y: 250 }, ENSEIGNE = [150, 250];   // l'enseigne : sur le mur, entre ces hauteurs
    const FOV = 46 * Math.PI / 180;
    const etat = { pente: 10 };   // degrés vers le bas
    function dessiner() {
      const axe = etat.pente * Math.PI / 180;
      const dansEcran = (x, y) => Math.abs(Math.atan2(y - CAM.y, x - CAM.x) - axe) < FOV / 2;
      ctx.fillStyle = "#18202b"; ctx.fillRect(0, 0, W, H);
      // Le champ de la caméra.
      ctx.fillStyle = "rgba(255, 210, 74, 0.10)"; ctx.beginPath(); ctx.moveTo(CAM.x, CAM.y);
      ctx.lineTo(CAM.x + Math.cos(axe - FOV / 2) * 1400, CAM.y + Math.sin(axe - FOV / 2) * 1400);
      ctx.lineTo(CAM.x + Math.cos(axe + FOV / 2) * 1400, CAM.y + Math.sin(axe + FOV / 2) * 1400);
      ctx.closePath(); ctx.fill();
      // Le mur, le sol mouillé, l'enseigne.
      ctx.fillStyle = "#3b475a"; ctx.fillRect(MUR, 0, W - MUR, H); ctx.fillRect(0, SOL, W, H - SOL);
      ctx.fillStyle = "#ff2f8a"; ctx.fillRect(MUR - 12, ENSEIGNE[0], 12, ENSEIGNE[1] - ENSEIGNE[0]);
      ctx.fillStyle = "#fff"; ctx.font = "700 24px sans-serif"; ctx.fillText("enseigne", MUR - 128, ENSEIGNE[0] - 12);
      const visible = dansEcran(MUR - 6, (ENSEIGNE[0] + ENSEIGNE[1]) / 2);
      // Pour chaque point du sol que la caméra voit : son reflet touche-t-il l'enseigne, et la voit-on à l'écran ?
      let trouve = 0, perdu = 0;
      for (let x = 170; x < MUR; x += 5) {
        if (!dansEcran(x, SOL)) continue;
        const pente = (SOL - CAM.y) / (x - CAM.x);                 // le rayon descend vers le sol…
        const yMur = SOL - pente * (MUR - x);                      // …et remonte jusqu'au mur, en miroir
        if (yMur < ENSEIGNE[0] || yMur > ENSEIGNE[1]) continue;
        const ok = dansEcran(MUR - 6, yMur);
        if (ok) trouve++; else perdu++;
        ctx.fillStyle = ok ? "#ff2f8a" : "#7a2f4d"; ctx.fillRect(x, SOL, 5, ok ? 16 : 6);
        if (!ok) { ctx.fillStyle = "#ffd24a"; ctx.fillRect(x, SOL + 9, 2, 6); }
      }
      // Un rayon d'exemple.
      const xr = 505, pente = (SOL - CAM.y) / (xr - CAM.x), yMur = SOL - pente * (MUR - xr);
      const ok = yMur >= ENSEIGNE[0] && yMur <= ENSEIGNE[1] && dansEcran(MUR - 6, yMur) && dansEcran(xr, SOL);
      ctx.lineWidth = 4; ctx.strokeStyle = "#fff"; ctx.beginPath(); ctx.moveTo(CAM.x, CAM.y); ctx.lineTo(xr, SOL); ctx.stroke();
      ctx.strokeStyle = ok ? "#5fe08c" : "#ff5a4f"; ctx.setLineDash(ok ? [] : [12, 9]);
      ctx.beginPath(); ctx.moveTo(xr, SOL); ctx.lineTo(MUR - 6, yMur); ctx.stroke(); ctx.setLineDash([]);
      // La caméra.
      ctx.save(); ctx.translate(CAM.x, CAM.y); ctx.rotate(axe);
      ctx.fillStyle = "#ffd24a"; ctx.fillRect(-46, -20, 60, 40); ctx.beginPath(); ctx.moveTo(14, -12); ctx.lineTo(40, -24); ctx.lineTo(40, 24); ctx.lineTo(14, 12); ctx.fill();
      ctx.restore();
      ctx.fillStyle = "#fff"; ctx.fillText("ce que l'écran affiche", CAM.x + 96, CAM.y - 76);
      ctx.fillText("sol mouillé", 420, SOL + 58);
      lecture.innerHTML = !visible
        ? "L'enseigne est <b>sortie de l'écran</b> : son reflet disparaît d'un coup. Le SSR ne peut pas l'inventer."
        : perdu ? "Une partie de l'enseigne est hors de l'écran : son reflet est <b>coupé</b>."
        : "L'enseigne est à l'écran : le SSR retrouve son reflet <b>dans l'image</b>.";
    }
    const rang = M.rang(root);
    M.slider(rang, "Pencher la caméra vers le sol :", 6, 40, 1, etat.pente, (v) => v + "°", (v) => { etat.pente = v; dessiner(); }).style.width = "420px";
    const lecture = M.lecture(root);
    dessiner();
    return {};
  });

  // ------------------------------------------------------------------ La table de billard : le lancer de rayons
  register("rayons", (root) => {
    const W = 1040, H = 520;
    const cv = M.canvas(root, W, H, false); cv.style.width = W + "px"; cv.style.cursor = "grab";
    const ctx = cv.getContext("2d");
    const OEIL = { x: 70, y: 260 }, PLAN = 190, Y0 = 90, Y1 = 430;
    const BOULES = [{ x: 520, y: 190, r: 72, c: [255, 70, 140] }, { x: 690, y: 370, r: 86, c: [60, 200, 255] }];
    const BOITE = { x0: 300, y0: 30, x1: 1010, y1: 490 };
    const etat = { rebonds: 0, pixels: 12, lampe: { x: 430, y: 100 } };
    // Premier obstacle sur le chemin d'un rayon.
    function toucher(ox, oy, dx, dy) {
      let best = 1e9, res = null;
      for (const b of BOULES) {
        const ex = ox - b.x, ey = oy - b.y, B = ex * dx + ey * dy, C = ex * ex + ey * ey - b.r * b.r, D = B * B - C;
        if (D > 0) { const t = -B - Math.sqrt(D); if (t > 0.01 && t < best) { best = t; const px = ox + dx * t, py = oy + dy * t; res = { x: px, y: py, nx: (px - b.x) / b.r, ny: (py - b.y) / b.r, c: b.c }; } }
      }
      const murs = [[(BOITE.x1 - ox) / dx, -1, 0], [(BOITE.y0 - oy) / dy, 0, 1], [(BOITE.y1 - oy) / dy, 0, -1], [(BOITE.x0 - ox) / dx, 1, 0]];
      for (const [t, nx, ny] of murs) {
        // Un mur ne compte que si le rayon va vers lui de l'intérieur (l'œil, lui, regarde de l'extérieur).
        if (t > 0.01 && t < best && dx * nx + dy * ny < 0) {
          const px = ox + dx * t, py = oy + dy * t;
          if (px >= BOITE.x0 - 1 && px <= BOITE.x1 + 1 && py >= BOITE.y0 - 1 && py <= BOITE.y1 + 1) { best = t; res = { x: px, y: py, nx, ny, c: [210, 200, 185] }; }
        }
      }
      if (res) res.t = best;
      return res;
    }
    function dessiner() {
      ctx.fillStyle = "#18202b"; ctx.fillRect(0, 0, W, H);
      ctx.strokeStyle = "#8ea0b8"; ctx.lineWidth = 4; ctx.strokeRect(BOITE.x0, BOITE.y0, BOITE.x1 - BOITE.x0, BOITE.y1 - BOITE.y0);
      for (const b of BOULES) { ctx.fillStyle = `rgb(${b.c.join(",")})`; ctx.beginPath(); ctx.arc(b.x, b.y, b.r, 0, 6.3); ctx.fill(); }
      const n = etat.pixels, hp = (Y1 - Y0) / n, L = etat.lampe;
      let lances = 0;
      for (let i = 0; i < n; i++) {
        const py = Y0 + (i + 0.5) * hp;
        let ox = OEIL.x, oy = OEIL.y, dx = PLAN - ox, dy = py - oy, d = Math.hypot(dx, dy); dx /= d; dy /= d;
        const col = [0, 0, 0]; let poids = 1;
        for (let k = 0; k <= etat.rebonds; k++) {
          const h = toucher(ox, oy, dx, dy); lances++;
          if (!h) break;
          ctx.strokeStyle = `rgba(255,255,255,${k === 0 ? 0.55 : 0.28})`; ctx.lineWidth = k === 0 ? 2 : 1.5;
          ctx.beginPath(); ctx.moveTo(ox, oy); ctx.lineTo(h.x, h.y); ctx.stroke();
          // Rayon d'ombre : ce point voit-il la lampe ?
          let lx = L.x - h.x, ly = L.y - h.y; const dl = Math.hypot(lx, ly); lx /= dl; ly /= dl;
          const obstacle = toucher(h.x + h.nx * 0.5, h.y + h.ny * 0.5, lx, ly); lances++;
          const eclaire = (!obstacle || obstacle.t > dl) && h.nx * lx + h.ny * ly > 0;
          ctx.strokeStyle = eclaire ? "rgba(255,210,74,0.8)" : "rgba(255,90,79,0.5)"; ctx.setLineDash(eclaire ? [] : [5, 7]); ctx.lineWidth = 1.5;
          ctx.beginPath(); ctx.moveTo(h.x, h.y); ctx.lineTo(eclaire ? L.x : obstacle.x, eclaire ? L.y : obstacle.y); ctx.stroke(); ctx.setLineDash([]);
          const lum = eclaire ? Math.max(0, h.nx * lx + h.ny * ly) * Math.min(1.4, 260 / dl) : 0;
          for (let c = 0; c < 3; c++) col[c] += poids * h.c[c] / 255 * (0.06 + lum);
          // Le rebond, comme une boule de billard.
          const dn = dx * h.nx + dy * h.ny; dx -= 2 * dn * h.nx; dy -= 2 * dn * h.ny;
          ox = h.x + h.nx * 0.5; oy = h.y + h.ny * 0.5; poids *= 0.55;
        }
        ctx.fillStyle = `rgb(${col.map((v) => Math.min(255, Math.sqrt(v) * 255) | 0).join(",")})`;
        ctx.fillRect(PLAN - 30, Y0 + i * hp, 30, hp);
      }
      ctx.strokeStyle = "#fff"; ctx.lineWidth = 2; ctx.strokeRect(PLAN - 30, Y0, 30, Y1 - Y0);
      ctx.fillStyle = "#ffd24a"; ctx.beginPath(); ctx.arc(OEIL.x, OEIL.y, 14, 0, 6.3); ctx.fill();
      ctx.fillStyle = "#ffe9a8"; ctx.strokeStyle = "#ffd24a"; ctx.lineWidth = 4; ctx.beginPath(); ctx.arc(L.x, L.y, 18, 0, 6.3); ctx.fill(); ctx.stroke();
      ctx.fillStyle = "#fff"; ctx.font = "700 22px sans-serif";
      ctx.fillText("œil", OEIL.x - 16, OEIL.y + 42); ctx.fillText("écran", PLAN - 66, Y0 - 14); ctx.fillText("lampe", L.x + 26, L.y + 8);
      lecture.innerHTML = `<b>${n}</b> pixels, ${etat.rebonds} rebond${etat.rebonds > 1 ? "s" : ""} → <b>${lances}</b> rayons. En 1080p : 2 millions de pixels.`;
    }
    let prise = false;
    M.drag(cv, (x, y, phase) => {
      if (phase === "down") prise = Math.hypot(x - etat.lampe.x, y - etat.lampe.y) < 60;
      if (prise && phase !== "up") { etat.lampe.x = M.clamp(x, BOITE.x0 + 20, BOITE.x1 - 20); etat.lampe.y = M.clamp(y, BOITE.y0 + 20, BOITE.y1 - 20); dessiner(); }
      if (phase === "up") prise = false;
    });
    const rang = M.rang(root);
    M.slider(rang, "Rebonds :", 0, 4, 1, etat.rebonds, null, (v) => { etat.rebonds = v; dessiner(); });
    M.slider(rang, "Pixels de l'écran :", 4, 48, 1, etat.pixels, null, (v) => { etat.pixels = v; dessiner(); });
    M.el("span", "commande", rang, "Déplacez la lampe à la souris.");
    const lecture = M.lecture(root);
    dessiner();
    return {};
  });

  // ------------------------------------------------------------------ Le sablier : le bruit, et trois façons de l'enlever
  register("bruit", (root) => {
    const W = 208, H = 117, N = W * H;
    const cv = M.canvas(root, W, H, false); cv.style.width = "1040px";
    const ctx = cv.getContext("2d"), img = ctx.createImageData(W, H);
    // La scène, calculée une fois : pour chaque pixel, le point vu, sa normale, sa couleur.
    const P = new Float32Array(N * 3), Nn = new Float32Array(N * 3), A = new Float32Array(N * 3), objet = new Int8Array(N);
    const BOULE = [0.2, 1.0, -4.2, 1.0];
    const NEON = { x0: -2.2, x1: -0.6, y: 3.1, z0: -5.0, z1: -3.4, c: [5.2, 1.6, 3.4] };
    for (let j = 0; j < H; j++) for (let i = 0; i < W; i++) {
      const k = j * W + i; let dx = (i / W - 0.5) * 1.78, dy = (0.5 - j / H) - 0.06, dz = -1; const n = Math.hypot(dx, dy, dz); dx /= n; dy /= n; dz /= n;
      const ox = 0, oy = 1.5, oz = 1.6; let best = 1e9;
      const ex = ox - BOULE[0], ey = oy - BOULE[1], ez = oz - BOULE[2], B = ex * dx + ey * dy + ez * dz, D = B * B - (ex * ex + ey * ey + ez * ez - 1);
      if (D > 0) { const t = -B - Math.sqrt(D); if (t > 0) { best = t; objet[k] = 1; const px = ox + dx * t, py = oy + dy * t, pz = oz + dz * t; P.set([px, py, pz], k * 3); Nn.set([px - BOULE[0], py - BOULE[1], pz - BOULE[2]], k * 3); A.set([0.85, 0.8, 0.7], k * 3); } }
      if (dy < 0) { const t = -oy / dy; if (t < best) { best = t; objet[k] = 2; const px = ox + dx * t, pz = oz + dz * t; P.set([px, 0, pz], k * 3); Nn.set([0, 1, 0], k * 3); const d = (Math.floor(px) + Math.floor(pz)) & 1; A.set(d ? [0.62, 0.6, 0.58] : [0.42, 0.42, 0.45], k * 3); } }
      const tm = (-8 - oz) / dz; if (tm > 0 && tm < best) { objet[k] = 3; P.set([ox + dx * tm, oy + dy * tm, -8], k * 3); Nn.set([0, 0, 1], k * 3); A.set([0.5, 0.42, 0.36], k * 3); }
    }
    const etat = { rayons: 1, accumuler: false, debruiter: false };
    const frame = new Float32Array(N * 3), cumul = new Float32Array(N * 3), sortie = new Float32Array(N * 3);
    let images = 0, depuis = 0;
    function lancer() {
      const S = etat.rayons, aire = (NEON.x1 - NEON.x0) * (NEON.z1 - NEON.z0);
      for (let k = 0; k < N; k++) {
        const o = k * 3; let r = 0, g = 0, b = 0;
        if (objet[k]) {
          const px = P[o], py = P[o + 1], pz = P[o + 2], nx = Nn[o], ny = Nn[o + 1], nz = Nn[o + 2];
          let recu = 0;
          for (let s = 0; s < S; s++) {
            // Un rayon vers un point du néon tiré au hasard : c'est ce hasard qui fait le bruit.
            let lx = NEON.x0 + Math.random() * (NEON.x1 - NEON.x0) - px, ly = NEON.y - py, lz = NEON.z0 + Math.random() * (NEON.z1 - NEON.z0) - pz;
            const d2 = lx * lx + ly * ly + lz * lz, d = Math.sqrt(d2); lx /= d; ly /= d; lz /= d;
            const cos = nx * lx + ny * ly + nz * lz; if (cos <= 0 || ly <= 0) continue;
            // La boule est-elle sur le chemin ?
            const ex = px + nx * 0.01 - BOULE[0], ey = py + ny * 0.01 - BOULE[1], ez = pz + nz * 0.01 - BOULE[2];
            const B = ex * lx + ey * ly + ez * lz, D = B * B - (ex * ex + ey * ey + ez * ez - 1);
            if (D > 0 && -B - Math.sqrt(D) > 0) continue;
            recu += cos * ly * aire / d2;
          }
          recu /= S;
          r = A[o] * (0.02 + recu * NEON.c[0]); g = A[o + 1] * (0.02 + recu * NEON.c[1]); b = A[o + 2] * (0.025 + recu * NEON.c[2]);
        }
        frame[o] = r; frame[o + 1] = g; frame[o + 2] = b;
      }
      images = etat.accumuler ? images + 1 : 1;
      const p = 1 / images;
      for (let i = 0; i < N * 3; i++) cumul[i] += (frame[i] - cumul[i]) * p;
    }
    function afficher() {
      let src = cumul;
      if (etat.debruiter) {
        // Débruiteur : chaque pixel prend la moyenne de ses voisins… du même objet, pour garder les contours.
        for (let j = 0; j < H; j++) for (let i = 0; i < W; i++) {
          const k = j * W + i; let r = 0, g = 0, b = 0, c = 0;
          for (let v = -3; v <= 3; v++) for (let u = -3; u <= 3; u++) {
            const x = i + u, y = j + v; if (x < 0 || y < 0 || x >= W || y >= H) continue;
            const q = y * W + x; if (objet[q] !== objet[k]) continue;
            // On moyenne la lumière reçue, pas la couleur du sol : on divise par elle avant, on la remet après.
            r += cumul[q * 3] / (A[q * 3] + 0.001); g += cumul[q * 3 + 1] / (A[q * 3 + 1] + 0.001); b += cumul[q * 3 + 2] / (A[q * 3 + 2] + 0.001); c++;
          }
          sortie[k * 3] = r / c * A[k * 3]; sortie[k * 3 + 1] = g / c * A[k * 3 + 1]; sortie[k * 3 + 2] = b / c * A[k * 3 + 2];
        }
        src = sortie;
      }
      for (let k = 0; k < N; k++) for (let c = 0; c < 3; c++) { const v = src[k * 3 + c]; img.data[k * 4 + c] = Math.pow(v / (1 + v), 1 / 2.2) * 255; }
      for (let k = 0; k < N; k++) img.data[k * 4 + 3] = 255;
      ctx.putImageData(img, 0, 0);
      lecture.innerHTML = `<b>${M.fr(N * etat.rayons)}</b> rayons par image` + (etat.accumuler ? ` · <b>${images}</b> images accumulées` : "") + (etat.debruiter ? " · débruité" : "");
    }
    const recommencer = () => { images = 0; depuis = 1; };
    const rang = M.rang(root);
    const PALIERS = [1, 2, 4, 8, 16, 32, 64];
    M.slider(rang, "Rayons par pixel :", 0, PALIERS.length - 1, 1, 0, (v) => String(PALIERS[v]), (v) => { etat.rayons = PALIERS[v]; recommencer(); });
    M.toggle(rang, "Accumuler les images", false, (v) => { etat.accumuler = v; recommencer(); });
    M.toggle(rang, "Débruiteur", false, (v) => { etat.debruiter = v; recommencer(); });
    const lecture = M.lecture(root);
    // Sans accumulation, on ne retire les dés que 6 fois par seconde : le grain se voit sans agresser l'œil.
    const anim = M.loop((_, dt) => { depuis += dt; if (depuis >= (etat.accumuler ? 0.05 : 0.17)) { depuis = 0; lancer(); afficher(); } });
    return { start() { recommencer(); anim.start(); }, stop: anim.stop };
  });

  // ------------------------------------------------------------------ Le triptyque de la conclusion
  function vignette(root, mode) {
    const W = 150, H = 96;
    const cv = M.canvas(root, W, H, false); cv.style.width = "480px";
    const ctx = cv.getContext("2d"), img = ctx.createImageData(W, H), cumul = new Float32Array(W * H);
    let n = 0, depuis = 0;
    const anim = M.loop((t, dt) => {
      depuis += dt; if (depuis < 0.14) return; depuis = 0;
      const cycle = (t % 7) / 7;
      if (mode === 2 && cycle < 0.04) n = 0;
      n++;
      for (let j = 0; j < H; j++) for (let i = 0; i < W; i++) {
        const k = j * W + i, u = i / W, v = j / H;
        const marbre = 0.5 + 0.5 * Math.sin(u * 9 + M.fbm(u * 4, v * 3, 0, 9) * 7);
        let val;
        if (mode === 0) val = M.mix(0.62, marbre, M.clamp(cycle * 2.2 - 0.3, 0, 1));          // on l'ajoute : du lisse au marbre
        else {
          const grain = marbre + (Math.random() - 0.5) * 1.5;
          if (mode === 1) val = grain;                                                          // on le subit
          else { cumul[k] += (grain - cumul[k]) / n; val = cumul[k]; }                          // on l'enlève : on accumule
        }
        val = M.clamp(val, 0, 1); const o = k * 4;
        img.data[o] = 60 + val * 195; img.data[o + 1] = 40 + val * 190; img.data[o + 2] = 70 + val * 175; img.data[o + 3] = 255;
      }
      ctx.putImageData(img, 0, 0);
    });
    return { start() { n = 0; anim.start(); }, stop: anim.stop };
  }
  register("trio-ajouter", (root) => vignette(root, 0));
  register("trio-subir", (root) => vignette(root, 1));
  register("trio-enlever", (root) => vignette(root, 2));
})();
