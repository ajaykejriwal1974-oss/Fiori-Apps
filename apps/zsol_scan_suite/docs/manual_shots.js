// Screenshots for the operator manual: WIP Batch, Job Card, QC Raw Material,
// QC Post Dyeing, QC Post Winding - driven against a mock of the Scan Suite
// services with plant-2002-shaped data, phone width.
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

// Serves the app from the repo root (one level up from docs/).
const DIR = fs.existsSync(path.join(__dirname, 'index.html')) ? __dirname : path.join(__dirname, '..');
const OUT = path.join(__dirname, 'shots');
const PORT = 8797;
fs.mkdirSync(OUT, { recursive: true });

// ---- plant 2002 data -------------------------------------------------------
const orders = [
  { aufnr: '1039729', werks: '2002', auart: 'KID', erdat: '20260907', matnr: 'D300072KARISHMAX01', maktx: '300/72 KARISHMA', psmng: '600', meins: 'KG', status: 'Released',
    grey_code: 'T300072BCSSNXXXXXX', grey_item: '300/72 BRIGHT GREY', lotno: 'BCT', lot_qty: '612.400', tot_batch: '298.8', batch_cnt: '1', open_qty: '301.2', reason: '', can_create: 'X' },
  { aufnr: '1039712', werks: '2002', auart: 'KID', erdat: '20260906', matnr: 'D150000XXXXXXXXX01', maktx: '150/0 POLYESTER', psmng: '1000', meins: 'KG', status: 'Released',
    grey_code: 'T150000XXXXXXXXX', grey_item: '150/0 GREY', lotno: 'BCS', lot_qty: '1020.000', tot_batch: '0', batch_cnt: '0', open_qty: '1000', reason: '', can_create: 'X' }
];
let batches = [
  { batchno: '2120017073', gjahr: '2026', werks: '2002', aufnr: '1039729', bchdate: '20260907', lotno: 'BCT', grey_code: 'T300072BCSSNXXXXXX', grey_item: '300/72 BRIGHT GREY',
    dye_code: 'D300072KARISHMAX01', dye_item: '300/72 KARISHMA', qty: '298.8', vrkme: 'KG', cheeses: '240', assigned: '', closed: '', jobno: '', schno: '', dye_arbpl: '', win_arbpl: '', ernam: 'ADMIN', erdat: '20260907', erzet: '093000' },
  { batchno: '2120017060', gjahr: '2026', werks: '2002', aufnr: '1039700', bchdate: '20260906', lotno: 'BCT', grey_code: 'T300072BCSSNXXXXXX', grey_item: '300/72 BRIGHT GREY',
    dye_code: 'D300072KARISHMAX01', dye_item: '300/72 KARISHMA', qty: '300', vrkme: 'KG', cheeses: '240', assigned: 'X', closed: '', jobno: '2120017060', schno: '2610008998', dye_arbpl: 'DYG00012', win_arbpl: 'WIN00003', ernam: 'ADMIN', erdat: '20260906', erzet: '101500' }
];
function sched(schno, sch, batched, cnt) {
  return { schno, gjahr: '2026', werks: '2002', kdno: 'A', schdt: '20260820', dyedt: '20260824', vbeln: '5126073000', posnr: '000010',
    matnr: 'D300072KARISHMAX01', maktx: '300/72 KARISHMA', sch_qty: String(sch), vrkme: 'KG', shdcd: '100274', shade: 'D-3116 RANI.', remarks: '',
    complete: '', customer: 'MADHUSUDAN SILK PRIVATE LIMITED', batched_qty: String(batched), job_cnt: String(cnt) };
}
const schedules = [sched('2610008998', 800, 300, 1), sched('2610008999', 1000, 0, 0), sched('2610010505', 500, 535.2, 1)];
const workcenters = [
  { werks: '2002', arbpl: 'DYG00012', ktext: 'SOFT FLOW DYEING 12', kind: 'D', used: '410' }, { werks: '2002', arbpl: 'DYG00007', ktext: 'JET DYEING 7', kind: 'D', used: '388' },
  { werks: '2002', arbpl: 'DYG00003', ktext: 'JIGGER 3', kind: 'D', used: '120' }, { werks: '2002', arbpl: 'WIN00003', ktext: 'WINDING 3', kind: 'W', used: '300' }, { werks: '2002', arbpl: 'WIN00005', ktext: 'WINDING 5', kind: 'W', used: '210' }
];
function job(jobno, dyed, wound, closed) {
  return { jobno, werks: '2002', batchno: jobno, gjahr: '2026', schno: '2610008998', aufnr: '1039729', dye_arbpl: 'DYG00012', dye_arbpl_txt: 'SOFT FLOW DYEING 12', win_arbpl: 'WIN00003', win_arbpl_txt: 'WINDING 3',
    bchdate: '20260907', schdt: '20260820', dyedt: '20260824', dyeing_date: dyed || '', winding_date: wound || '', dye_conf: dyed ? '1' : '0', win_conf: wound ? '1' : '0',
    lotno: 'BCT', grey_code: 'T300072BCSSNXXXXXX', grey_item: '300/72 BRIGHT GREY', dye_code: 'D300072KARISHMAX01', dye_item: '300/72 KARISHMA', shdcd: '100274', shade: 'D-3116 RANI.',
    kdno: 'A', vbeln: '5126073000', posnr: '000010', customer: 'MADHUSUDAN SILK PRIVATE LIMITED', qty: '298.8', vrkme: 'KG', cheeses: '240',
    sch_qty: '800', sch_vrkme: 'KG', assigned: 'X', closed: closed || '', complete: '', ernam: 'ADMIN', erdat: '20260907' };
}
let jobs = [job('2120017060', '20260906'), job('2120017001', '20260905', '20260906'), job('2120016990', '20260904', '20260905', 'X')];
const recipe = [
  { jobno: '', werks: '2002', grey_code: 'T300072BCSSNXXXXXX', dye_code: 'D300072KARISHMAX01', shdcd: '100274', posnr: '0010', component: 'DISP RED 60', comp_desc: 'DISPERSE RED 60', comp_type: 'DYE', ratio: '1.250', vrkme: '%', remarks: '' },
  { jobno: '', werks: '2002', grey_code: 'T300072BCSSNXXXXXX', dye_code: 'D300072KARISHMAX01', shdcd: '100274', posnr: '0020', component: 'DISP BLUE 79', comp_desc: 'DISPERSE BLUE 79', comp_type: 'DYE', ratio: '0.420', vrkme: '%', remarks: '' },
  { jobno: '', werks: '2002', grey_code: 'T300072BCSSNXXXXXX', dye_code: 'D300072KARISHMAX01', shdcd: '100274', posnr: '0030', component: 'LEVELLING AGENT', comp_desc: 'LEVELLING AGENT LA', comp_type: 'AUX', ratio: '1.000', vrkme: 'g/l', remarks: 'add at 60 C' }
];
const lots = {
  R: { itype: 'R', inspection_lot: '010000045871', plant: '2002', inspection_type: '01', material: 'T300072BCSSNXXXXXX', material_name: '300/72 BRIGHT GREY', batch: 'BCT', vendor_batch: 'RSK-2261',
    production_order: '', plant_batch: '', plant_batch_year: '', production_lot: '', job_card: '', schedule_number: '', dyeing_work_centre: '', winding_work_centre: '',
    lot_quantity: '612.400', lot_unit: 'KG', batch_quantity: '', batch_unit: '', batch_cheeses: '', created_on: '20260906', results_confirmed: '', usage_decision_made: '', is_open: 'X' },
  D: { itype: 'D', inspection_lot: '030000012207', plant: '2002', inspection_type: '03', material: 'D300072KARISHMAX01', material_name: '300/72 KARISHMA', batch: '2120017073', vendor_batch: '',
    production_order: '000001039729', plant_batch: '2120017073', plant_batch_year: '2026', production_lot: 'BCT', job_card: '2120017073', schedule_number: '2610008998',
    dyeing_work_centre: 'DYG00012', winding_work_centre: 'WIN00003', lot_quantity: '298.800', lot_unit: 'KG', batch_quantity: '298.800', batch_unit: 'KG', batch_cheeses: '240', created_on: '20260907', results_confirmed: '', usage_decision_made: '', is_open: 'X' },
  W: { itype: 'W', inspection_lot: '040000009318', plant: '2002', inspection_type: '04', material: 'D300072KARISHMAX01', material_name: '300/72 KARISHMA', batch: '2120017060', vendor_batch: '',
    production_order: '000001039700', plant_batch: '2120017060', plant_batch_year: '2026', production_lot: 'BCT', job_card: '2120017060', schedule_number: '2610008998',
    dyeing_work_centre: 'DYG00012', winding_work_centre: 'WIN00003', lot_quantity: '300.000', lot_unit: 'KG', batch_quantity: '300.000', batch_unit: 'KG', batch_cheeses: '240', created_on: '20260906', results_confirmed: '', usage_decision_made: '', is_open: 'X' }
};
const openR = [lots.R, Object.assign({}, lots.R, { inspection_lot: '010000045866', batch: 'BCS', vendor_batch: 'RSK-2255', material: 'T150000XXXXXXXXX', material_name: '150/0 GREY', lot_quantity: '1020.000', created_on: '20260905' })];
function chars(lot, op, kind) {
  const base = [
    { inspection_lot: lot, operation_number: op, characteristic_number: '0010', master_characteristic: 'MOISTURE', characteristic_name: 'Moisture %', characteristic_kind: 'QUAN', characteristic_unit: '%', decimal_places: '2',
      target_value: '0.40', target_is_initial: '', lower_limit: '0.20', lower_is_initial: '', upper_limit: '0.60', upper_is_initial: '', selected_set: '', catalog_type: '', mean_value: '', mean_is_initial: 'X', result_code: '', result_code_group: '', defect_count: '', actual_sample_size: '5', valuation: '', inspector_comment: '', result_status: '1' },
    { inspection_lot: lot, operation_number: op, characteristic_number: '0020', master_characteristic: 'DENIER', characteristic_name: 'Denier', characteristic_kind: 'QUAN', characteristic_unit: 'DEN', decimal_places: '1',
      target_value: '300.0', target_is_initial: '', lower_limit: '294.0', lower_is_initial: '', upper_limit: '306.0', upper_is_initial: '', selected_set: '', catalog_type: '', mean_value: '', mean_is_initial: 'X', result_code: '', result_code_group: '', defect_count: '', actual_sample_size: '5', valuation: '', inspector_comment: '', result_status: '1' }
  ];
  if (kind !== 'R') base.push({ inspection_lot: lot, operation_number: op, characteristic_number: '0030', master_characteristic: 'SHADE', characteristic_name: 'Shade match to standard', characteristic_kind: 'A', characteristic_unit: '', decimal_places: '',
    target_value: '', target_is_initial: 'X', lower_limit: '', lower_is_initial: 'X', upper_limit: '', upper_is_initial: 'X', selected_set: 'ZSHADE', catalog_type: '1', mean_value: '', mean_is_initial: 'X', result_code: '', result_code_group: '', defect_count: '', actual_sample_size: '3', valuation: '', inspector_comment: '', result_status: '1' });
  return base;
}
const charsByLot = { '010000045871': chars('010000045871', '0001', 'R'), '030000012207': chars('030000012207', '0010', 'D'), '040000009318': chars('040000009318', '0020', 'W') };

function json(route, status, body, headers) { return route.fulfill({ status, contentType: 'application/json', headers: headers || {}, body: JSON.stringify(body) }); }
function fv(f, name) { const m = new RegExp(name + " eq '([^']*)'").exec(f); return m ? m[1] : ''; }

(async () => {
  const server = http.createServer((req, res) => {
    const f = path.join(DIR, req.url.split('?')[0].replace(/^\//, '') || 'index.html');
    fs.readFile(f, (e, d) => { if (e) { res.writeHead(404); return res.end(); } res.writeHead(200, { 'Content-Type': f.endsWith('.js') ? 'text/javascript' : 'text/html' }); res.end(d); });
  }).listen(PORT);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 420, height: 860 }, deviceScaleFactor: 2 });
  await page.addInitScript(() => {
    sessionStorage.setItem('kgpl.scan.session', JSON.stringify({ username: 'DYEING1', fullName: 'Dyeing Supervisor', isAdmin: '', token: 'tok', orgs: '2000|2002;', features: 'WIPBATCH;JOBCARD;QCRAW;QCDYE;QCWIND;QCINSP;' }));
  });
  await page.route('**/sap/**', async (route) => {
    const req = route.request(); const url = new URL(req.url()); const p = url.pathname; const f = decodeURIComponent(url.searchParams.get('$filter') || '');
    if (p.endsWith('/$metadata')) return json(route, 200, {}, { 'X-CSRF-Token': 'csrf' });
    const set = (p.split('ZSOL_SCAN_READ_SRV/')[1] || '').split('(')[0].split('?')[0];
    if (req.method() === 'GET') {
      if (set === 'ZSOL_PROD_ORDER') { const a = fv(f, 'aufnr'); return json(route, 200, { d: { results: a ? orders.filter(o => o.aufnr === a.replace(/^0+/, '')) : orders } }); }
      if (set === 'ZSOL_WIP_BATCH') { const b = fv(f, 'batchno'); const open = fv(f, 'closed'); let rows = batches; if (b) rows = rows.filter(x => x.batchno === b); if (open === 'OPEN') rows = rows.filter(x => x.closed !== 'X'); return json(route, 200, { d: { results: rows } }); }
      if (set === 'ZSOL_SCHEDULE') { const no = fv(f, 'schno'); return json(route, 200, { d: { results: no ? schedules.filter(s => s.schno === no) : schedules.filter(s => Number(s.batched_qty) < Number(s.sch_qty)) } }); }
      if (set === 'ZSOL_WORKCENTER') return json(route, 200, { d: { results: workcenters } });
      if (set === 'ZSOL_JOBCARD') { const no = fv(f, 'jobno'); return json(route, 200, { d: { results: no ? jobs.filter(j => j.jobno === no) : jobs } }); }
      if (set === 'ZSOL_JOBCARD_RECIPE') return json(route, 200, { d: { results: recipe.map(r => Object.assign({}, r, { jobno: fv(f, 'jobno') })) } });
      if (set === 'QcLotSet') { const it = fv(f, 'itype'), scan = fv(f, 'scan'); if (!scan) return json(route, 200, { d: { results: it === 'R' ? openR : [lots[it]] } }); const l = lots[it]; return json(route, 200, { d: { results: l && [l.batch, l.job_card, l.plant_batch, l.vendor_batch].indexOf(scan) !== -1 ? [l] : [] } }); }
      if (set === 'QcCharSet') return json(route, 200, { d: { results: charsByLot[fv(f, 'inspection_lot')] || [] } });
      return json(route, 200, { d: { results: [] } });
    }
    const b = JSON.parse(req.postData() || '{}');
    if (set === 'ZSOL_WIP_BATCH') { const nb = Object.assign({}, batches[0], { batchno: '2120017074', aufnr: b.aufnr, qty: b.qty, cheeses: b.cheeses, lotno: b.lotno, dye_code: b.dye_code, werks: b.werks }); batches.unshift(nb); return json(route, 201, { d: nb }); }
    if (set === 'ZSOL_JOBCARD') { const j = job(b.batchno); j.dye_arbpl = b.dye_arbpl; j.win_arbpl = b.win_arbpl; j.schno = b.schno; jobs.unshift(j); return json(route, 201, { d: Object.assign({}, j, { message: 'Job card created' }) }); }
    if (set === 'QcResultSet') return json(route, 201, { d: Object.assign({}, b, { message: 'Result saved' }) });
    if (set === 'QcRecordSet') return json(route, 201, { d: Object.assign({}, b, { message: 'Results recorded for the operation' }) });
    if (set === 'QcUdSet') return json(route, 201, { d: Object.assign({}, b, { message: 'Usage decision ' + b.code + ' posted' }) });
    if (set === 'QcReleaseSet') return json(route, 201, { d: Object.assign({}, b, { message: 'Greige released to the production floor: 612.400 KG DRM1 -> DPR1' }) });
    if (set === 'QcConfirmSet') { jobs.filter(x => x.jobno === b.job_card).forEach(x => { if (b.kind === 'W') { x.winding_date = '20260907'; x.win_conf = '1'; } else { x.dyeing_date = '20260907'; x.dye_conf = '1'; } }); return json(route, 201, { d: Object.assign({}, b, { message: 'Production confirmed for batch ' + b.plant_batch }) }); }
    return json(route, 201, { d: b });
  });

  const shot = async (name, opts) => { await page.waitForTimeout(250); await page.evaluate(() => { window.scrollTo(0, 0); document.querySelectorAll('.screen.active, .scroll, main').forEach(function (e) { e.scrollTop = 0; }); }); await page.waitForTimeout(150); await page.screenshot(Object.assign({ path: path.join(OUT, name + '.png'), fullPage: true }, opts || {})); console.log('shot', name); };
  const crop = async (name, sel) => { await page.waitForTimeout(150); const el = await page.$(sel); if (!el) { console.log('no element', sel); return; } await page.evaluate(() => { document.querySelectorAll('header.appbar').forEach(h => h.style.visibility = 'hidden'); }); await el.screenshot({ path: path.join(OUT, name + '.png') }); await page.evaluate(() => { document.querySelectorAll('header.appbar').forEach(h => h.style.visibility = ''); }); console.log('crop', name); };
  const clickTile = (sel) => page.evaluate((s) => document.querySelector(s).click(), sel);
  const setVal = (id, v) => page.evaluate(([i, val]) => { const el = document.getElementById(i); el.value = val; el.dispatchEvent(new Event('input')); el.dispatchEvent(new Event('change')); }, [id, v]);

  await page.goto(`http://localhost:${PORT}/index.html`);
  await page.waitForSelector('#screen-home.active');
  await shot('01_home', { fullPage: false });

  // ---- WIP Batch
  await clickTile('[data-goto="screen-wipbatch"]');
  await page.evaluate(() => { document.getElementById('wbWerks').value = '2002'; });
  await page.click('#btnWbOrders');
  await page.waitForSelector('#wbOrderList .prow');
  await shot('02_wb_orders');
  await page.click('#wbOrderList .prow');
  await page.waitForSelector('#wbFormCard', { state: 'visible' });
  await setVal('wbQty', '301.2'); await setVal('wbCheeses', '240');
  await shot('03_wb_form');
  await crop('03a_wb_orderbox', '#wbOrderBox'); await crop('03b_wb_formcard', '#wbFormCard');
  await page.click('#btnWbCreate');
  await page.waitForSelector('#wbDoneBox', { state: 'visible' });
  await shot('04_wb_done');
  await crop('04a_wb_donebox', '#wbDoneBox');
  await page.click('[data-wbtab="list"]');
  await page.evaluate(() => { document.getElementById('wbListWerks').value = '2002'; });
  await page.click('#btnWbList');
  await page.waitForSelector('#wbList .prow');
  await shot('05_wb_list');
  await page.click('[data-wbtab="new"]');

  // ---- Job Card
  await page.evaluate(() => document.getElementById('btnBack').click());
  await clickTile('[data-goto="screen-jobcard"]');
  await page.evaluate(() => { document.getElementById('jcWerks').value = '2002'; });
  await page.click('#btnJcFree');
  await page.waitForSelector('#jcFreeList .prow');
  await shot('06_jc_free');
  await page.click('#jcFreeList .prow');
  await page.waitForSelector('#jcSchedList .prow');
  await shot('07_jc_schedules');
  await crop('07a_jc_batchbox', '#jcBatchBox'); await crop('07b_jc_schedcard', '#jcSchedCard');
  await page.click('#jcSchedList .prow');
  await page.waitForSelector('#jcSchedBox', { state: 'visible' });
  await page.click('#jcDyeChips .chip');
  await page.click('#jcWinChips .chip');
  await shot('08_jc_picked');
  await crop('08a_jc_schedbox', '#jcSchedCard'); await crop('08b_jc_machcard', '#jcMachCard');
  await page.click('#btnJcCreate');
  await page.waitForFunction(() => /Job card .* created/.test(document.getElementById('jcBatchDesc').textContent));
  await page.waitForTimeout(600);
  await shot('09_jc_created');
  await crop('09a_jc_createdbox', '#jcBatchBox');
  await page.click('[data-jctab="list"]');
  await page.evaluate(() => { document.getElementById('jcListWerks').value = '2002'; });
  await page.click('#btnJcList');
  await page.waitForSelector('#jcList .prow');
  await shot('10_jc_list');
  await page.click('#jcList .prow');
  await page.waitForFunction(() => document.getElementById('jcPreview').innerHTML.length > 200);
  await page.waitForTimeout(600);
  await shot('11_jc_preview');
  await crop('11a_jc_printcard', '#jcPrintCard');
  await page.click('[data-jctab="new"]');

  // ---- QC Raw Material
  await page.evaluate(() => document.getElementById('btnBack').click());
  await clickTile('[data-goto="screen-qcraw"]');
  await page.waitForSelector('#qrOpenList .lotpick');
  await shot('12_qr_open');
  await crop('12a_qr_pendcard', '#qrPendCard');
  await page.click('#qrOpenList .lotpick');
  await page.waitForSelector('#qrChars .qcrow');
  await page.evaluate(() => { const rows = document.querySelectorAll('#qrChars .qcrow'); rows[0].querySelector('.qcval').value = '0.38'; rows[1].querySelector('.qcval').value = '299.6'; });
  await page.click('#qrChars .qcrow:nth-child(1) .qcsave');
  await page.click('#qrChars .qcrow:nth-child(2) .qcsave');
  await page.waitForFunction(() => document.querySelectorAll('#qrChars .qcrow.done').length === 2);
  await page.evaluate(() => { const c = document.querySelector('#qrUdChips .chip'); c.click(); });
  await shot('13_qr_lot');
  await crop('13a_qr_lotbox', '#qrLotBox'); await crop('13b_qr_charcard', '#qrCharCard'); await crop('13c_qr_udcard', '#qrUdCard');
  await page.click('#qrBtnUd');
  await page.waitForFunction(() => /posted/.test(document.getElementById('qrUdStatus').textContent));
  await page.click('#qrBtnFinal');
  await page.waitForFunction(() => /released/i.test(document.getElementById('qrFinalStatus').textContent));
  await shot('14_qr_released');
  await crop('14a_qr_finalcard', '#qrFinalCard'); await crop('14b_qr_log', '#qrLog');

  // ---- QC Post Dyeing
  await page.evaluate(() => document.getElementById('btnBack').click());
  jobs.unshift(job('2120017073'));
  await clickTile('[data-goto="screen-qcdye"]');
  await page.waitForSelector('#qdPendList .prow');
  await shot('15_qd_pending');
  await crop('15a_qd_pendcard', '#qdPendCard');
  await page.click('#qdPendList .prow');
  await page.waitForSelector('#qdChars .qcrow');
  await page.evaluate(() => { const rows = document.querySelectorAll('#qdChars .qcrow'); rows[0].querySelector('.qcval').value = '0.41'; rows[1].querySelector('.qcval').value = '300.2'; rows[2].querySelector('.qcval').value = 'OK'; rows[2].querySelector('.qcgrp').value = 'ZSHADE'; });
  await page.evaluate(() => { document.querySelector('#qdUdChips .chip').click(); });
  await shot('16_qd_lot');
  await crop('16a_qd_lotbox', '#qdLotBox'); await crop('16b_qd_charcard', '#qdCharCard'); await crop('16c_qd_udcard', '#qdUdCard'); await crop('16d_qd_finalcard', '#qdFinalCard');
  await page.click('#qdBtnFinal');
  await page.waitForFunction(() => /confirmed/i.test(document.getElementById('qdFinalStatus').textContent));
  await page.waitForFunction(() => !/2120017073/.test(document.getElementById('qdPendList').textContent));
  await shot('17_qd_confirmed');
  await crop('17a_qd_finalcard', '#qdFinalCard'); await crop('17b_qd_pendcard', '#qdPendCard');

  // ---- QC Post Winding
  await page.evaluate(() => document.getElementById('btnBack').click());
  await clickTile('[data-goto="screen-qcwind"]');
  await page.waitForSelector('#qwPendList .prow');
  await shot('18_qw_pending');
  await crop('18a_qw_pendcard', '#qwPendCard');
  await page.evaluate(() => { const r = Array.from(document.querySelectorAll('#qwPendList .prow')).find(p => /2120017060/.test(p.textContent)); r.click(); });
  await page.waitForSelector('#qwChars .qcrow');
  await page.evaluate(() => { document.querySelector('#qwUdChips .chip').click(); });
  await shot('19_qw_lot');
  await crop('19a_qw_lotbox', '#qwLotBox'); await crop('19b_qw_finalcard', '#qwFinalCard');

  await browser.close(); server.close();
  console.log('done');
})().catch(e => { console.error('FAILED: ' + e.message); process.exit(1); });
