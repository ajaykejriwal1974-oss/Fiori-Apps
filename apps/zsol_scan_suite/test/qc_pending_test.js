// QC Post-Dyeing / Post-Winding - job cards in production (07.09.2026).
// Each screen now opens with the plant's job cards waiting for its stage
// (from ZSOL_JOBCARD: no dyeing date = waiting for dyeing QC; dyed and no
// winding date = waiting for winding QC; closed batches never), and a tap
// resolves the card's open inspection lot exactly as a scan would. After a
// production confirmation the list is re-read and the card has moved on.
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const DIR = __dirname;
const PORT = 8796;

const lots = {
  R: { itype: 'R', inspection_lot: '010000045871', plant: '2002', inspection_type: '01', material: 'T300072BCSSNXXXXXX', material_name: '300/72 BRIGHT GREY',
    batch: 'BCT', vendor_batch: 'RSK-2261', production_order: '', plant_batch: '', plant_batch_year: '', production_lot: '', job_card: '', schedule_number: '',
    dyeing_work_centre: '', winding_work_centre: '', lot_quantity: '612.400', lot_unit: 'KG', batch_quantity: '612.400', batch_unit: 'KG', batch_cheeses: '',
    created_on: '20260906', results_confirmed: '', usage_decision_made: '', is_open: 'X' },
  D: { itype: 'D', inspection_lot: '100000000003', plant: '2002', inspection_type: '03', material: 'D300072KARISHMAX01', material_name: '300/72 KARISHMA',
    batch: '', vendor_batch: '', production_order: '000001039729', plant_batch: '2120017073', plant_batch_year: '2026', production_lot: 'BCT',
    job_card: '2120017073', schedule_number: '2610008998', dyeing_work_centre: 'DYG00012', winding_work_centre: '', lot_quantity: '298.800', lot_unit: 'KG',
    batch_quantity: '298.800', batch_unit: 'KG', batch_cheeses: '240', created_on: '20260907', results_confirmed: '', usage_decision_made: '', is_open: 'X' },
  W: { itype: 'W', inspection_lot: '100000000004', plant: '2002', inspection_type: '04', material: 'D300072KARISHMAX01', material_name: '300/72 KARISHMA',
    batch: '', vendor_batch: '', production_order: '000001039700', plant_batch: '2120017060', plant_batch_year: '2026', production_lot: 'BCT',
    job_card: '2120017060', schedule_number: '2610008998', dyeing_work_centre: 'DYG00012', winding_work_centre: 'WIN00003', lot_quantity: '300.000', lot_unit: 'KG',
    batch_quantity: '300.000', batch_unit: 'KG', batch_cheeses: '240', created_on: '20260906', results_confirmed: '', usage_decision_made: '', is_open: 'X' }
};
function job(jobno, dyed, wound, closed) {
  return { jobno, werks: '2002', batchno: jobno, gjahr: '2026', schno: '2610008998', aufnr: '1039729', dye_arbpl: 'DYG00012', win_arbpl: 'WIN00003',
    bchdate: '20260907', dyeing_date: dyed || '', winding_date: wound || '', dye_conf: dyed ? '1' : '0', win_conf: wound ? '1' : '0',
    lotno: 'BCT', grey_code: 'T300072BCSSNXXXXXX', dye_code: 'D300072KARISHMAX01', dye_item: '300/72 KARISHMA', shdcd: '100274', shade: 'D-3116 RANI.',
    kdno: 'A', vbeln: '5126073000', posnr: '000010', customer: 'MADHUSUDAN SILK PRIVATE LIMITED', qty: '298.8', vrkme: 'KG', cheeses: '240',
    sch_qty: '800', sch_vrkme: 'KG', assigned: 'X', closed: closed || '', complete: '', ernam: 'ADMIN', erdat: '20260907' };
}
const jobs = [job('2120017073'), job('2120017060', '20260906'), job('2120017001', '20260905', '20260906'), job('2120016999', '', '', 'X')];
const writes = [];

function json(route, status, body, headers) { return route.fulfill({ status, contentType: 'application/json', headers: headers || {}, body: JSON.stringify(body) }); }
function fv(f, name) { const m = new RegExp(name + " eq '([^']*)'").exec(f); return m ? m[1] : ''; }

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
    sessionStorage.setItem('kgpl.scan.session', JSON.stringify({ username: 'QC1', fullName: 'QC Operator', isAdmin: '', token: 'tok-test', orgs: '2000|2002;', features: 'QCRAW;QCDYE;QCWIND;' }));
  });
  const jobReads = [];
  await page.route('**/sap/**', async (route) => {
    const req = route.request(); const url = new URL(req.url()); const p = url.pathname; const f = decodeURIComponent(url.searchParams.get('$filter') || '');
    if (p.endsWith('/$metadata')) return json(route, 200, {}, { 'X-CSRF-Token': 'csrf-test' });
    if (p.includes('/ZSOL_JOBCARD') && req.method() === 'GET') { jobReads.push(f); return json(route, 200, { d: { results: fv(f, 'werks') === '2002' ? jobs : [] } }); }
    if (p.includes('/QcLotSet')) {
      const itype = fv(f, 'itype'), scan = fv(f, 'scan');
      const l = lots[itype];
      if (itype === 'R' && !scan) return json(route, 200, { d: { results: [l, Object.assign({}, l, { inspection_lot: '010000045866', batch: 'BCS', vendor_batch: 'RSK-2255', lot_quantity: '1020.000', batch_quantity: '1020.000' })] } });
      return json(route, 200, { d: { results: l && (!scan || scan === l.job_card || scan === l.plant_batch || scan === l.batch) ? [l] : [] } });
    }
    if (p.includes('/QcCharSet')) return json(route, 200, { d: { results: [] } });
    if (p.includes('/QcConfirmSet') && req.method() === 'POST') {
      const b = JSON.parse(req.postData()); writes.push(b);
      const j = jobs.find(x => x.jobno === b.job_card);
      if (j) { if (b.kind === 'W') j.winding_date = '20260907'; else j.dyeing_date = '20260907'; }
      return json(route, 201, { d: Object.assign({}, b, { message: 'Production confirmed for batch ' + b.plant_batch }) });
    }
    return json(route, 200, { d: { results: [] } });
  });

  const text = (sel) => page.$eval(sel, e => e.textContent.replace(/\s+/g, ' ').trim());
  const shown = (sel) => page.$eval(sel, e => e.style.display !== 'none' && e.offsetParent !== null);
  function expect(cond, msg) { if (!cond) { console.log('FAIL ' + msg); process.exitCode = 1; } else console.log('ok   ' + msg); }

  await page.goto(`http://localhost:${PORT}/index.html`);
  await page.waitForSelector('#screen-home.active', { timeout: 10000 });

  let rows;
  // ---- QC Raw Material opens with the greige batches waiting, quantity first.
  await page.evaluate(() => document.querySelector('[data-goto="screen-qcraw"]').click());
  await page.waitForFunction(() => document.querySelectorAll('#qrOpenList .prow').length > 0, null, { timeout: 5000 });
  rows = await page.$$eval('#qrOpenList .prow .no', ns => ns.map(n => n.textContent));
  expect(rows.length === 2 && rows[0] === 'BCT' && rows[1] === 'BCS', 'raw screen lists the waiting greige batches without a tap: ' + rows.join(', '));
  expect(/612\.4 KG/.test(await text('#qrOpenList .prow:nth-child(1) .badge')), 'each row shows the quantity to test');
  expect(/2batches1632\.4kg to test/.test(await text('#qrPendSummary')), 'summary totals the greige waiting: ' + (await text('#qrPendSummary')));
  expect((await text('#qrPendBadge')) === '2', 'raw badge 2');
  await page.click('#qrOpenList .prow');
  await page.waitForFunction(() => document.getElementById('qrLotBox').style.display === 'block', null, { timeout: 5000 });
  expect(/Lot 10000045871/.test(await text('#qrLotCode')), 'tap opens the lot: ' + (await text('#qrLotCode')));
  await page.evaluate(() => document.getElementById('btnBack').click());

  // ---- QC Post-Dyeing
  await page.evaluate(() => document.querySelector('[data-goto="screen-qcdye"]').click());
  await page.waitForFunction(() => document.querySelectorAll('#qdPendList .prow').length > 0, null, { timeout: 5000 });
  expect((await page.$eval('#qdPlant', e => e.value)) === '2002', 'plant prefilled with 2002');
  expect(/werks eq '2002'/.test(jobReads[0]) && /days eq '45'/.test(jobReads[0]), 'job cards read for the plant, last 45 days: ' + jobReads[0]);
  rows = await page.$$eval('#qdPendList .prow .no', ns => ns.map(n => n.textContent));
  expect(rows.length === 1 && rows[0] === '2120017073', 'only the card with no dyeing yet is waiting for dyeing QC: ' + rows.join(', '));
  expect((await text('#qdPendBadge')) === '1', 'badge 1');
  expect(/1 batch\(es\) waiting - tap one/.test(await text('#qdPendStatus')), 'status invites the tap');
  expect(/298\.8 KG · 240 cheeses/.test(await text('#qdPendList .prow .badge')), 'row leads with the quantity to test: ' + (await text('#qdPendList .prow .badge')));
  expect(/1batches298\.8kg to test240cheeses/.test(await text('#qdPendSummary')), 'summary strip totals the quantity waiting: ' + (await text('#qdPendSummary')));
  await page.click('#qdPendList .prow');
  await page.waitForFunction(() => document.getElementById('qdLotBox').style.display === 'block', null, { timeout: 5000 });
  expect(/Lot 100000000003 · plant 2002/.test(await text('#qdLotCode')), 'tap resolved the open dyeing lot: ' + (await text('#qdLotCode')));
  expect(/Job card2120017073/.test(await text('#qdLotFacts')) || /2120017073/.test(await text('#qdLotFacts')), 'lot facts name the job card');
  expect(/op 0010/.test(await text('#qdCnfOp')), 'confirmation card is for operation 0010');

  // Confirm dyeing -> the card leaves the dyeing list.
  await page.click('#qdBtnFinal');
  await page.waitForFunction(() => /Production confirmed/.test(document.getElementById('qdFinalStatus').textContent), null, { timeout: 5000 });
  expect(writes.length === 1 && writes[0].kind === 'D' && writes[0].job_card === '2120017073' && writes[0].operation === '0010', 'dyeing confirmation posted: ' + JSON.stringify(writes[0]).slice(0, 120));
  await page.waitForFunction(() => /No batch of the last 45 days is waiting for dyeing QC/.test(document.getElementById('qdPendStatus').textContent), null, { timeout: 5000 });
  console.log('ok   dyeing list re-read after the confirmation - nothing left waiting');

  // ---- QC Post-Winding: the freshly dyed card now waits here, with the earlier one.
  await page.evaluate(() => document.getElementById('btnBack').click());
  await page.evaluate(() => document.querySelector('[data-goto="screen-qcwind"]').click());
  await page.waitForFunction(() => document.querySelectorAll('#qwPendList .prow').length > 0, null, { timeout: 5000 });
  rows = await page.$$eval('#qwPendList .prow .no', ns => ns.map(n => n.textContent));
  expect(rows.length === 2 && rows.indexOf('2120017060') !== -1 && rows.indexOf('2120017073') !== -1, 'dyed-not-wound cards wait for winding QC (wound and closed ones do not): ' + rows.join(', '));
  expect(/Dyed 06\.09\.2026/.test(await text('#qwPendList')), 'rows show the dyeing date');
  await page.click('#qwPendList .prow:nth-child(1)');
  await page.waitForFunction(() => document.getElementById('qwLotBox').style.display === 'block' || /No open lot/.test(document.getElementById('qwScanStatus').textContent), null, { timeout: 5000 });
  const first = rows[0];
  if (first === '2120017060') {
    expect(/Lot 100000000004/.test(await text('#qwLotCode')) && /op 0020/.test(await text('#qwCnfOp')), 'tap on the dyed card resolved its winding lot, op 0020');
  } else {
    expect(/No open lot for 2120017073/.test(await text('#qwScanStatus')), 'a card without a winding lot yet says so plainly: ' + (await text('#qwScanStatus')));
  }

  // Plant / days changes re-read the list.
  await page.fill('#qwPendDays', '90'); await page.press('#qwPendDays', 'Enter');
  await page.waitForFunction(() => true);
  expect(jobReads.some(f => /days eq '90'/.test(f)), 'changing the day window re-reads the cards');

  if (errors.length) { console.log('ERRORS:', errors); process.exitCode = 1; }
  await browser.close(); server.close();
  if (!process.exitCode) console.log('\nALL QC-PENDING TESTS PASSED');
})().catch(e => { console.error('FAILED: ' + e.message); process.exit(1); });
