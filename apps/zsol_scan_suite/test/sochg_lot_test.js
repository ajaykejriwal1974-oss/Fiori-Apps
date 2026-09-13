// SOCHG headroom and whole-lot selection on the Packing List (07.09.2026).
// A user holding SOCHG gets a "Select a Whole Lot" card (one chip per
// batch among the available boxes) and a tolerance of 10% of the order
// quantity when that beats ZSDTOL; a plain picker gets neither. Route-
// mocked ZSOL_PICK_DOWNLOAD_SRV / ZSOL_PICKUPLOAD_SRV_01 / ZSOL_SCAN_READ_SRV.
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const DIR = __dirname;
const PORT = 8794;

// One order, one item: 50 KG, no ZSDTOL tolerance. Two lots available:
// A = 15 boxes of ~21.9 KG (329.140 KG), B = 2 boxes of 24 KG (48 KG).
const SO = '5126073083';
const lotA = Array.from({ length: 15 }, (_, i) => ({ Box_No: '99800000' + String(i + 1).padStart(2, '0'), Batch: '2120016918', Net_Wt: '21.943' }));
const lotB = [{ Box_No: '9980000101', Batch: '2120016853', Net_Wt: '24.000' }, { Box_No: '9980000102', Batch: '2120016853', Net_Wt: '24.000' }];
function hu(b) {
  return { Box_No: b.Box_No, Itemno: '000000', Material: 'D155072BTXXXXXXXX01', Mat_Desc: 'POLYESTER YARN 155/BRIGHT0', Plant: '2002', Stg_Loc: 'DFG1',
    Batch: b.Batch, Grade: 'A', Size: 'IA', Net_Wt: b.Net_Wt, Gross_Wt: b.Net_Wt, Tare_Wt: '0', Ext_Id: '0000000000' + b.Box_No, Pck_Typ: '01', Prod_Date: '', Spool_No: '', Loc_Exp: '' };
}
const pickSet = { d: { So_Num: SO,
  SODetails: { results: [{ Item_No: '20', Material: 'D155072BTXXXXXXXX01', Mat_Desc: 'POLYESTER YARN 155/BRIGHT0', Plant: '2002', Stg_Loc: 'DFG1', Batch: '2120016918', Grade: 'A', Size: 'IA', Bal_qty: '50.000', Uom: 'KG', Toler: '0.000' }] },
  HUDetails: { results: lotA.concat(lotB).map(hu) } } };

const uploads = [];
function json(route, status, body, headers) { return route.fulfill({ status, contentType: 'application/json', headers: headers || {}, body: JSON.stringify(body) }); }

async function run(browser, features, label, steps) {
  const page = await browser.newPage({ viewport: { width: 420, height: 900 } });
  const errors = [];
  page.on('pageerror', e => errors.push('pageerror: ' + e.message));
  page.on('console', m => { if (m.type() === 'error' && !/Failed to load resource/.test(m.text())) errors.push('console: ' + m.text()); });
  await page.addInitScript((features) => {
    sessionStorage.setItem('kgpl.scan.session', JSON.stringify({ username: 'PICK1', fullName: 'Picker', isAdmin: '', token: 'tok-test', orgs: '2000|2002;', features }));
  }, features);
  await page.route('**/sap/**', async (route) => {
    const req = route.request(); const url = new URL(req.url()); const p = url.pathname;
    if (p.endsWith('/$metadata')) return json(route, 200, {}, { 'X-CSRF-Token': 'csrf-test' });
    if (p.includes('ZSOL_PICK_DOWNLOAD_SRV/PickSet')) return json(route, 200, pickSet);
    if (p.includes('ZSOL_PICKUPLOAD_SRV_01/PickSet') && req.method() === 'POST') { const b = JSON.parse(req.postData()); uploads.push({ features, b }); return json(route, 201, { d: b }); }
    if (p.includes('ZSOL_SCAN_READ_SRV/ZSOL_SO_PICK_PEND')) return json(route, 200, { d: { results: [{ vbeln: SO, posnr: '000020', SoldToParty: 'DFG CUSTOMER', created_on: '20260907' }] } });
    if (p.includes('ZSOL_SCAN_READ_SRV/ZSOL_SO_BOXCHECK')) return json(route, 200, { d: { results: [{ vbeln: SO, posnr: '000020', matnr: 'D155072BTXXXXXXXX01', arktx: 'POLYESTER YARN 155/BRIGHT0', werks: '2002', lgort: 'DFG1', charg: '2120016918',
      kwmeng: '50.000', vrkme: 'KG', dis_qty: '0.000', open_qty: '50.000', abgru: '', zzsize: 'IA', zzsiz1: '', zzsiz2: '', zzgrade: 'A', zzgrad1: '', zzgrad2: '', so_batches: '2120016918', batch_src: 'C',
      cand_cnt: 17, match_cnt: 17, match_wt: '377.140', need_batch: '', other_lgort: '', other_size: '', other_grade: '', other_so: '', on_deliv: 0, not_posted: 0, hint: '17 HU(s) can be picked' }] } });
    return json(route, 200, { d: { results: [] } });
  });
  await page.goto(`http://localhost:${PORT}/index.html`);
  await page.waitForSelector('#screen-home.active', { timeout: 10000 });
  console.log('\n== ' + label + ' ==');
  await steps(page);
  if (errors.length) { console.log('ERRORS:', errors); process.exitCode = 1; }
  await page.close();
}

const text = (page, sel) => page.$eval(sel, e => e.textContent.replace(/\s+/g, ' ').trim());
const shown = (page, sel) => page.$eval(sel, e => e.style.display !== 'none' && e.offsetParent !== null);
function expect(cond, msg) { if (!cond) { console.log('FAIL ' + msg); process.exitCode = 1; } else console.log('ok   ' + msg); }

(async () => {
  const server = http.createServer((req, res) => {
    const f = path.join(DIR, req.url.split('?')[0].replace(/^\//, '') || 'index.html');
    fs.readFile(f, (e, d) => { if (e) { res.writeHead(404); return res.end(); } res.writeHead(200, { 'Content-Type': f.endsWith('.js') ? 'text/javascript' : 'text/html' }); res.end(d); });
  }).listen(PORT);
  const browser = await chromium.launch();

  await run(browser, 'PICK;SOCHG;', 'picker WITH SOCHG', async (page) => {
    await page.click('[data-goto="screen-pick"]');
    await page.fill('#pickSoInput', SO); await page.press('#pickSoInput', 'Enter');
    await page.waitForFunction(() => /17 box\(es\) available/.test(document.querySelector('#pickSoDesc').textContent));
    expect(await shown(page, '#pickLotCard'), 'lot card shown to a SOCHG user');
    const chips = await page.$$eval('#pickLotList .sobatch', cs => cs.map(c => c.textContent));
    expect(chips.length === 2 && /2120016918 · 15 boxes · 329.145 KG/.test(chips[0]) && /2120016853 · 2 boxes · 48 KG/.test(chips[1]), 'one chip per lot, biggest first: ' + chips.join(' | '));
    expect(/tol\. 5 \(10% · SOCHG\)/.test(await text(page, '#pickBalList')), 'tolerance badge shows 10% of the order quantity: ' + (await text(page, '#pickBalList')));

    // Lot B (48 KG) fits whole under the 55 KG cap.
    await page.click('#pickLotList .sobatch[data-lot="2120016853"]');
    expect(/Whole lot 2120016853 selected - 2 boxes/.test(await text(page, '#pickLotStatus')), 'whole lot B selected: ' + (await text(page, '#pickLotStatus')));
    expect((await page.$$('#pickBatchList .listrow')).length === 2, 'two boxes in the packing list');
    expect(/2120016853 .* 2 selected/.test(await text(page, '#pickLotList .sobatch.assigned')), 'lot B chip marked selected');
    // Now lot A on top: nothing fits any more (48 + 21.9 > 55).
    await page.click('#pickLotList .sobatch[data-lot="2120016918"]');
    expect(/0 of 15 boxes of lot 2120016918 selected; the rest does not fit/.test(await text(page, '#pickLotStatus')), 'lot A refused on top of B with the reason: ' + (await text(page, '#pickLotStatus')));
    // Clear and take lot A alone: 2 boxes fit (43.886), the third (65.8) does not.
    // (one x at a time - each removal re-renders the list)
    await page.click('#pickBatchList .rm'); await page.click('#pickBatchList .rm');
    expect((await page.$$('#pickBatchList .listrow')).length === 0, 'list cleared');
    await page.click('#pickLotList .sobatch[data-lot="2120016918"]');
    expect(/2 of 15 boxes of lot 2120016918 selected/.test(await text(page, '#pickLotStatus')), 'lot A alone: two boxes fit within 110% of the order: ' + (await text(page, '#pickLotStatus')));
    expect(/Selected 43.886 of 50 KG/.test(await text(page, '#pickBalList')), 'quantity line: ' + (await text(page, '#pickBalList')));
    // Submit posts what was selected.
    await page.click('#btnSubmitPick');
    await page.waitForFunction(() => /Packing list updated/.test(document.querySelector('#pickStatus').textContent));
    expect(uploads.length === 1 && uploads[0].b.PickToDetails.length === 2, 'upload carries the two boxes');
  });

  await run(browser, 'PICK;', 'picker WITHOUT SOCHG', async (page) => {
    await page.click('[data-goto="screen-pick"]');
    await page.fill('#pickSoInput', SO); await page.press('#pickSoInput', 'Enter');
    await page.waitForFunction(() => /17 box\(es\) available/.test(document.querySelector('#pickSoDesc').textContent));
    expect(!(await shown(page, '#pickLotCard')), 'no lot card without SOCHG');
    expect(!/tol\./.test(await text(page, '#pickBalList')), 'no tolerance badge without SOCHG (ZSDTOL is 0 here)');
    // 2 x 24 = 48 fits, a 21.9 box on top (69.9 > 50) does not.
    await page.fill('#pickBoxInput', '9980000101'); await page.press('#pickBoxInput', 'Enter');
    await page.fill('#pickBoxInput', '9980000102'); await page.press('#pickBoxInput', 'Enter');
    await page.fill('#pickBoxInput', '9980000001'); await page.press('#pickBoxInput', 'Enter');
    expect(/does not fit item 20/.test(await text(page, '#pickScanStatus')), 'plain picker stops at the order quantity: ' + (await text(page, '#pickScanStatus')));
    expect((await page.$$('#pickBatchList .listrow')).length === 2, 'two boxes selected');
  });

  await browser.close(); server.close();
  if (!process.exitCode) console.log('\nALL SOCHG-LOT TESTS PASSED');
})().catch(e => { console.error('FAILED: ' + e.message); process.exit(1); });
