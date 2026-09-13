// Dyeing Packing screen (07.09.2026). Scan a dyed 2002 batch -> defaults ->
// enter net/tare/cones (gross auto) -> Pack. Each carton POSTs DyePackBoxSet
// on ZSOL_SCAN_READ_SRV (folded in); the list + totals refresh. Guarded by
// DYEPACK. Backend engine draws the box number from ZHU_VEKP/40.
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const DIR = __dirname, PORT = 8798;
const batch = {
  batchno: '2120000023', gjahr: '2026', werks: '2002', aufnr: '000001008695',
  matnr: 'D310072BTDXXXXTEST', matnr_txt: '150/0 TEST', grade: 'A', psize: 'IA',
  qty: '1000.000', cheeses: '950', vrkme: 'KG', wound: 'X', valid: 'X',
  message: 'Batch 2120000023 - 150/0 TEST'
};
let nextBox = 8760000610;
const boxes = [];
const posts = [];
const pending = [
  { batchno:'2120000023', gjahr:'2026', werks:'2002', aufnr:'1008695', matnr:'D310072BTDXXXXTEST', matnr_txt:'150/0 TEST', qty:'1000.000', packed:'0.000', remaining:'1000.000', cheeses:'950', vrkme:'KG', wound:'X', bchdate:'20260907', winding_date:'20260906' },
  { batchno:'2120000021', gjahr:'2026', werks:'2002', aufnr:'1008704', matnr:'D30096NIMPTYDYED01', matnr_txt:'300/96 NIM', qty:'1100.000', packed:'200.000', remaining:'900.000', cheeses:'1000', vrkme:'KG', wound:'', bchdate:'20260907', winding_date:'' }
];

function json(route, status, body, headers) { return route.fulfill({ status, contentType: 'application/json', headers: headers || {}, body: JSON.stringify(body) }); }
function fv(f, name) { const m = new RegExp(name + "\\s+eq\\s+'([^']*)'").exec(f); return m ? m[1] : ''; }

(async () => {
  const server = http.createServer((req, res) => {
    const f = path.join(DIR, req.url.split('?')[0].replace(/^\//, '') || 'index.html');
    fs.readFile(f, (e, d) => { if (e) { res.writeHead(404); return res.end(); } res.writeHead(200, { 'Content-Type': f.endsWith('.js') ? 'text/javascript' : 'text/html' }); res.end(d); });
  }).listen(PORT);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 420, height: 900 } });
  const errors = [];
  page.on('pageerror', e => errors.push('pageerror: ' + e.message));
  page.on('console', m => { if (m.type() === 'error' && !/Failed to load resource/.test(m.text())) errors.push('console: ' + m.text()); });
  await page.addInitScript(() => {
    sessionStorage.setItem('kgpl.scan.session', JSON.stringify({ username: 'PK1', fullName: 'Packer', isAdmin: '', token: 'tok', orgs: '1000|2002;', features: 'DYEPACK;' }));
  });
  await page.route('**/sap/**', async (route) => {
    const req = route.request(); const url = new URL(req.url()); const p = url.pathname;
    const f = decodeURIComponent(url.searchParams.get('$filter') || '');
    if (p.endsWith('/$metadata')) return json(route, 200, {}, { 'X-CSRF-Token': 'csrf' });
    if (p.endsWith('/DyeBatchSet') && req.method() === 'GET') {
      const b = fv(f, 'batchno');
      return json(route, 200, { d: { results: b === batch.batchno ? [batch] : [Object.assign({}, batch, { valid: '', message: 'Batch ' + b + ' was not found', batchno: b })] } });
    }
    if (p.endsWith('/DyePendingSet') && req.method() === 'GET') {
      return json(route, 200, { d: { results: pending } });
    }
    if (p.endsWith('/DyePackBoxSet') && req.method() === 'GET') {
      return json(route, 200, { d: { results: boxes.slice().reverse() } });
    }
    if (p.endsWith('/DyePackBoxSet') && req.method() === 'POST') {
      const b = JSON.parse(req.postData()); posts.push(b);
      const gross = (parseFloat(b.netwt) + parseFloat(b.tarewt)).toFixed(3);
      const row = { boxno: String(nextBox++), batchno: batch.batchno, gjahr: '2026', mergno: batch.batchno,
        matnr: batch.matnr, netwt: b.netwt, tarewt: b.tarewt, grosswt: gross, spoolno: b.spoolno,
        grade: b.grade, psize: b.psize, pdate: '20260907', success: 'X', message: 'Box ' + (nextBox - 1) + ' packed - ' + gross + ' KG gross' };
      boxes.push(row);
      return json(route, 201, { d: row });
    }
    return json(route, 200, { d: { results: [] } });
  });

  const text = (sel) => page.$eval(sel, e => e.textContent.replace(/\s+/g, ' ').trim());
  function expect(cond, msg) { if (!cond) { console.log('FAIL ' + msg); process.exitCode = 1; } else console.log('ok   ' + msg); }

  await page.goto(`http://localhost:${PORT}/index.html`);
  await page.waitForSelector('#screen-home.active', { timeout: 10000 });

  // tile visible with the grant
  expect(await page.$eval('[data-goto="screen-dyepack"]', e => e.offsetParent !== null), 'Dyeing Packing tile shown with DYEPACK grant');
  await page.evaluate(() => document.querySelector('[data-goto="screen-dyepack"]').click());
  await page.waitForSelector('#screen-dyepack.active', { timeout: 5000 });

  // the pending worklist auto-loads with quantity to pack
  await page.waitForSelector('#dpPendList .prow', { timeout: 5000 });
  expect((await text('#dpPendBadge')) === '2', 'pending badge counts the batches to pack');
  expect(/2batches/.test(await text('#dpPendSummary')) && /1900kg to pack/.test(await text('#dpPendSummary')), 'pending totals: ' + (await text('#dpPendSummary')));
  expect(/1000 KG to pack/.test(await text('#dpPendList .prow:nth-child(1) .badge')), 'row shows the quantity still to pack');
  expect(/300.96 NIM|300\/96 NIM|not wound yet/.test(await text('#dpPendList')), 'a not-yet-wound batch is flagged');

  // tap a pending batch to load it
  await page.click('#dpPendList .prow:nth-child(1)');
  await page.waitForFunction(() => document.getElementById('dpFormCard').style.display === 'block', null, { timeout: 5000 });
  expect(/Batch 2120000023 . plant 2002/.test(await text('#dpBatchCode')), 'batch card names the batch/plant: ' + (await text('#dpBatchCode')));
  expect(/D310072BTDXXXXTEST/.test(await text('#dpBatchFacts')), 'facts show the dyed material');
  expect((await page.$eval('#dpGrade', e => e.value)) === 'A', 'grade defaults to A');

  // gross auto-computes
  await page.fill('#dpNet', '30.560');
  await page.fill('#dpTare', '4.400');
  await page.dispatchEvent('#dpTare', 'input');
  expect((await text('#dpGrossVal')) === '34.96', 'gross = net + tare live: ' + (await text('#dpGrossVal')));

  // pack a carton
  await page.fill('#dpCones', '18');
  await page.click('#btnDpPack');
  await page.waitForFunction(() => /packed/.test(document.getElementById('dpPackStatus').textContent), null, { timeout: 5000 });
  expect(posts.length === 1 && posts[0].batchno === '2120000023' && posts[0].netwt === '30.56' && posts[0].spoolno === '18' && posts[0].psize === 'IA',
    'POST carried batch/net/cones/psize: ' + JSON.stringify(posts[0]));
  expect(/8760000610/.test(await text('#dpBoxList')), 'the new box appears in the list');
  expect(/1cartons/.test(await text('#dpSummary')) && /30.56net kg/.test(await text('#dpSummary')) && /34.96gross kg/.test(await text('#dpSummary')) && /18cones/.test(await text('#dpSummary')), 'totals strip: ' + (await text('#dpSummary')));

  // net + cones cleared for the next carton; tare + grade kept
  expect((await page.$eval('#dpNet', e => e.value)) === '' && (await page.$eval('#dpCones', e => e.value)) === '', 'net + cones cleared for the next carton');
  expect((await page.$eval('#dpTare', e => e.value)) === '4.400' && (await page.$eval('#dpGrade', e => e.value)) === 'A', 'tare + grade kept');

  // pack a second carton -> totals accumulate
  await page.fill('#dpNet', '33.550'); await page.dispatchEvent('#dpNet', 'input');
  await page.fill('#dpCones', '18');
  await page.click('#btnDpPack');
  await page.waitForFunction(() => document.querySelectorAll('#dpBoxList .prow').length === 2, null, { timeout: 5000 });
  expect(/2cartons/.test(await text('#dpSummary')), 'two cartons in totals: ' + (await text('#dpSummary')));
  expect(posts.length === 2, 'second carton posted');

  // a batch that cannot be packed shows the reason, no form
  await page.click('#btnDpChange');
  await page.fill('#dpScan', '9999999999');
  await page.click('#btnDpLoad');
  await page.waitForFunction(() => /not be packed|not found/.test(document.getElementById('dpScanStatus').textContent), null, { timeout: 5000 });
  expect((await page.$eval('#dpFormCard', e => e.style.display)) === 'none', 'no form for an invalid batch');

  if (errors.length) { console.log('ERRORS:', errors); process.exitCode = 1; }
  await browser.close(); server.close();
  if (!process.exitCode) console.log('\nALL DYEING-PACKING TESTS PASSED');
})().catch(e => { console.error('FAILED: ' + e.message); process.exit(1); });
