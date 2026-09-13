// Packing List quantity rule: a roll order (VBAP-VRKME = ROL) counts one
// per box; a KG order still measures by net weight. Guards the fix for
// Mango knitted fabric, where summing kilos against a roll count made the
// second roll "not fit" a 26-roll order.
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const DIR = __dirname;
const PORT = 8792;
const F = 'PACK;PICK;SOCHG;';

function json(route, status, body, headers) {
  return route.fulfill({ status, contentType: 'application/json', headers: headers || {}, body: JSON.stringify(body) });
}

// One open item, three candidate boxes. Bal_qty / Uom come from the
// download's SODetails; Net_Wt from HUDetails - the real per-roll weights
// seen on plant 8001 (15 to 60 KG on one order).
function order(uom, balQty) {
  return {
    d: {
      So_Num: 'X',
      SODetails: { results: [{
        Item_No: '000010', Material: 'KCGRAINKNITMFK372', Mat_Desc: 'GRAIN KNIT MFK-372', Batch: 'B1',
        Plant: '8001', Stg_Loc: 'FG01', Grade: 'A', Size: '00', Bal_qty: balQty, Toler: '0', Uom: uom
      }] },
      HUDetails: { results: [
        { Box_No: '9970000001', Itemno: '000000', Material: 'KCGRAINKNITMFK372', Batch: 'B1', Plant: '8001', Stg_Loc: 'FG01', Net_Wt: '23.529', Gross_Wt: '24.0', Tare_Wt: '0.5' },
        { Box_No: '9970000002', Itemno: '000000', Material: 'KCGRAINKNITMFK372', Batch: 'B1', Plant: '8001', Stg_Loc: 'FG01', Net_Wt: '25.000', Gross_Wt: '25.5', Tare_Wt: '0.5' },
        { Box_No: '9970000003', Itemno: '000000', Material: 'KCGRAINKNITMFK372', Batch: 'B1', Plant: '8001', Stg_Loc: 'FG01', Net_Wt: '61.549', Gross_Wt: '62.0', Tare_Wt: '0.5' }
      ] }
    }
  };
}

(async () => {
  const server = http.createServer((req, res) => {
    const f = path.join(DIR, req.url.split('?')[0].replace(/^\//, '') || 'index.html');
    fs.readFile(f, (e, d) => {
      if (e) { res.writeHead(404); return res.end('nf'); }
      const ct = f.endsWith('.js') ? 'text/javascript' : f.endsWith('.json') ? 'application/json' : 'text/html';
      res.writeHead(200, { 'Content-Type': ct }); res.end(d);
    });
  }).listen(PORT);

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 420, height: 900 } });
  const errors = [];
  page.on('pageerror', e => errors.push('pageerror: ' + e.message));
  page.on('console', m => { if (m.type() === 'error' && !/html5-qrcode|favicon|404|net::ERR/.test(m.text())) errors.push('console: ' + m.text()); });

  await page.addInitScript((features) => {
    sessionStorage.setItem('kgpl.scan.session', JSON.stringify({
      username: 'OP1', fullName: 'Operator', isAdmin: '', token: 'tok-test', orgs: '8000|8001;', features: features
    }));
  }, F);

  let current = order('ROL', '26');
  await page.route('**/sap/**', async (route) => {
    const p = new URL(route.request().url()).pathname;
    if (p.endsWith('/$metadata')) return json(route, 200, {}, { 'X-CSRF-Token': 'csrf-test' });
    if (p.includes('ZSOL_PICK_DOWNLOAD_SRV') && p.includes('PickSet')) return json(route, 200, current);
    return json(route, 200, { d: { results: [] } });
  });

  await page.goto(`http://localhost:${PORT}/index.html`);
  await page.waitForTimeout(400);
  await page.evaluate(() => document.querySelector('[data-goto="screen-pick"]').click());
  await page.waitForTimeout(300);

  async function loadSo(num) {
    await page.evaluate((n) => {
      const el = document.getElementById('pickSoInput');
      el.value = n; el.dispatchEvent(new Event('scan-fill'));
    }, num);
    await page.waitForFunction(() => /Selected/.test(document.getElementById('pickQty_0').textContent), null, { timeout: 5000 });
  }
  async function scan(box) {
    await page.evaluate((b) => {
      const el = document.getElementById('pickBoxInput');
      el.value = b; el.dispatchEvent(new Event('scan-fill'));
    }, box);
    await page.waitForTimeout(150);
  }
  const qtyText = () => page.evaluate(() => document.getElementById('pickQty_0').textContent);
  const balText = () => page.evaluate(() => document.getElementById('pickBal_0').textContent);
  const scanStatus = () => page.evaluate(() => document.getElementById('pickScanStatus').textContent);
  const batchBadge = () => page.evaluate(() => document.getElementById('pickBatchBadge').textContent);
  const rowBadges = () => page.evaluate(() => Array.from(document.querySelectorAll('#pickBatchList .badge')).map(b => b.textContent));

  // ---- 1. Roll order: each box is one roll, weight is not the measure ----
  await loadSo('ROL1');
  let t = await qtyText();
  if (!/Selected 0 of 26 ROL/.test(t)) throw new Error('roll order not loaded as 26 ROL: ' + t);
  if ((await balText()).trim() !== '26 ROL') throw new Error('balance badge wrong: ' + await balText());
  console.log('ok  roll order loads: ' + t.trim());

  // Before the fix the 61.5 KG roll was pre-marked "does not fit" 26 ROL.
  const nofitBefore = await page.evaluate(() => document.querySelectorAll('#pickLocList .pickbox.nofit').length);
  if (nofitBefore !== 0) throw new Error('a roll was marked nofit on a 26-roll order (weight leaking into the count): ' + nofitBefore);
  console.log('ok  no roll pre-marked "does not fit" (heavy 61.5 KG roll included)');

  await scan('9970000001');
  t = await qtyText();
  if (!/Selected 1 of 26 ROL/.test(t) || !/25 left to pick/.test(t)) throw new Error('first roll not counted as 1: ' + t);
  await scan('9970000002');
  t = await qtyText();
  if (!/Selected 2 of 26 ROL/.test(t) || !/24 left to pick/.test(t)) throw new Error('second roll refused or miscounted: ' + t + ' | ' + await scanStatus());
  await scan('9970000003');   // the 61.5 KG roll - must be accepted as roll #3
  t = await qtyText();
  if (!/Selected 3 of 26 ROL/.test(t) || !/23 left to pick/.test(t)) throw new Error('heavy roll refused: ' + t + ' | ' + await scanStatus());
  console.log('ok  three rolls scanned: ' + t.trim());

  if (!/3 box\(es\) · 3 ROL/.test(await batchBadge())) throw new Error('batch badge not in rolls: ' + await batchBadge());
  const badges = await rowBadges();
  if (!badges.some(b => /1 ROL · 23\.529 KG/.test(b))) throw new Error('row badge should read "1 ROL · 23.529 KG", got: ' + badges.join(' | '));
  console.log('ok  badges count rolls and still show the weight: ' + badges.filter(b => /ROL/.test(b)).join(', '));

  // ---- 2. KG order: weight is still the measure, and the cap still bites ----
  current = order('KG', '100');
  await page.evaluate(() => document.getElementById('btnChangePickSo').click());
  await page.waitForTimeout(200);
  await loadSo('KG1');
  t = await qtyText();
  if (!/Selected 0 of 100 KG/.test(t)) throw new Error('kg order not loaded: ' + t);
  await scan('9970000003');   // 61.549 KG
  t = await qtyText();
  if (!/Selected 61\.549 of 100 KG/.test(t)) throw new Error('kg box not weighed: ' + t);
  await scan('9970000002');   // +25 = 86.549, fits
  t = await qtyText();
  if (!/Selected 86\.549 of 100 KG/.test(t)) throw new Error('second kg box wrong: ' + t);
  await scan('9970000001');   // +23.529 = 110.078 > 100, must be refused
  t = await qtyText();
  const st = await scanStatus();
  if (!/Selected 86\.549 of 100 KG/.test(t) || !/does not fit/.test(st)) throw new Error('kg cap no longer enforced: ' + t + ' | ' + st);
  console.log('ok  kg order still measures by weight and refuses the box past the cap');

  if (errors.length) throw new Error('page/console errors:\n' + errors.join('\n'));
  console.log('ok  zero page/console errors');
  console.log('\nALL ROLL-COUNT TESTS PASSED');

  await browser.close();
  server.close();
})().catch(e => { console.error('FAILED: ' + e.message); process.exit(1); });
