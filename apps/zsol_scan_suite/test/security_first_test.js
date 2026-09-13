// Security confirms before the Challan (07.09.2026): Packing List ->
// Security Loading Scan -> Create Challan. Guards the inverted flow end to
// end against a mocked ZSOL_CHALLAN_PACK_SRV_SRV / ZSOL_DISPATCH_ISCAN_SRV:
//   - Security Loading reads PackingListSet with Mode eq 'LOAD', shows the
//     list's cartons Pending / Confirmed, submits IscanSet for the scanned
//     ones, and re-reads the cartons and the dropdown afterwards;
//   - Create Challan reads Mode eq 'CHALLAN' (a list with nothing confirmed
//     is not offered), shows which cartons will go and which stay, and
//     posts App 'D' for the packing list; a 'W' carton in the answer is
//     reported as "left on the packing list", not as a failure.
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const DIR = __dirname;
const PORT = 8793;
const F = 'PACK;PICK;SOCHG;DISPATCH;CHALLAN;';

function json(route, status, body, headers) {
  return route.fulfill({ status, contentType: 'application/json', headers: headers || {}, body: JSON.stringify(body) });
}

// ---- the mocked SAP state --------------------------------------------------
// Two packing lists. List A: three cartons, none confirmed at the start.
// List B: two cartons, none confirmed, never touched - it must show on the
// Security screen and must NOT show on Create Challan.
const listA = { So: '5126072798', SoItem: '000010', Pklst: '000001', PlDate: '20260907', Plant: '8001',
  Material: 'KCGRAINKNITMFK372', MatDesc: 'GRAIN KNIT MFK-372', Customer: '0000100200', CustName: 'MANGO CUSTOMER' };
const listB = { So: '5126072799', SoItem: '000010', Pklst: '000001', PlDate: '20260907', Plant: '8001',
  Material: 'KCGRAINKNITMFK372', MatDesc: 'GRAIN KNIT MFK-372', Customer: '0000100201', CustName: 'OTHER CUSTOMER' };
const boxes = {
  '5126072798|000010|000001': [
    { Boxno: '9970000001', Exidv: '00000000009970000001', Ptype: '01', PtypeText: 'CARTON', NetWt: '23.529', Mergno: '', HuStatus: '0020', Loaded: '', LoadDate: '', LoadTime: '' },
    { Boxno: '9970000002', Exidv: '00000000009970000002', Ptype: '01', PtypeText: 'CARTON', NetWt: '25.000', Mergno: '', HuStatus: '0020', Loaded: '', LoadDate: '', LoadTime: '' },
    { Boxno: '9970000003', Exidv: '00000000009970000003', Ptype: '01', PtypeText: 'CARTON', NetWt: '61.549', Mergno: '', HuStatus: '0020', Loaded: '', LoadDate: '', LoadTime: '' }
  ],
  '5126072799|000010|000001': [
    { Boxno: '9970000011', Exidv: '00000000009970000011', Ptype: '01', PtypeText: 'CARTON', NetWt: '20.000', Mergno: '', HuStatus: '0020', Loaded: '', LoadDate: '', LoadTime: '' },
    { Boxno: '9970000012', Exidv: '00000000009970000012', Ptype: '01', PtypeText: 'CARTON', NetWt: '21.000', Mergno: '', HuStatus: '0020', Loaded: '', LoadDate: '', LoadTime: '' }
  ]
};
function key(l) { return l.So + '|' + l.SoItem + '|' + l.Pklst; }
function withCounts(l, mode) {
  const b = boxes[key(l)];
  const loaded = b.filter(x => x.Loaded === 'X').length;
  return Object.assign({}, l, { BoxCount: b.length, LoadedCount: loaded, NetWt: b.reduce((s, x) => s + parseFloat(x.NetWt), 0).toFixed(3), Mode: mode });
}
// The server's Mode rule, as ZCL_ZSOL_CHALLAN_PACK__DPC_EXT applies it.
function packingLists(mode, so) {
  return [listA, listB].filter(l => !so || l.So === so).map(l => withCounts(l, mode)).filter(r => {
    if (mode === 'LOAD') return r.LoadedCount < r.BoxCount;
    if (mode === 'CHALLAN') return r.LoadedCount > 0;
    return true;
  });
}
function filterVal(url, prop) {
  const m = new RegExp(prop + "\\s+eq\\s+'([^']*)'").exec(decodeURIComponent(url));
  return m ? m[1] : '';
}

const dispatchPosts = [];
const challanPosts = [];

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
      username: 'SEC1', fullName: 'Security', isAdmin: '', token: 'tok-test', orgs: '8000|8001;', features: features
    }));
  }, F);

  const listRequests = [];
  await page.route('**/sap/**', async (route) => {
    const req = route.request();
    const url = req.url();
    const p = new URL(url).pathname;
    if (p.endsWith('/$metadata')) return json(route, 200, {}, { 'X-CSRF-Token': 'csrf-test' });

    if (p.includes('ZSOL_CHALLAN_PACK_SRV_SRV')) {
      if (p.endsWith('/PackingListSet')) {
        const mode = filterVal(url, 'Mode'), so = filterVal(url, 'So');
        listRequests.push({ mode, so });
        return json(route, 200, { d: { results: packingLists(mode, so) } });
      }
      if (p.endsWith('/PackingListBoxSet')) {
        const k = filterVal(url, 'So') + '|' + filterVal(url, 'SoItem') + '|' + filterVal(url, 'Pklst');
        return json(route, 200, { d: { results: boxes[k] || [] } });
      }
      if (p.endsWith('/TruckSet')) return json(route, 200, { d: { results: [{ Trckno: 'MH12AB1234', Trcode: 'TR01', TrName: 'ROADWAYS' }] } });
      if (p.endsWith('/ChallanPackSet') && req.method() === 'POST') {
        const body = JSON.parse(req.postData());
        challanPosts.push(body);
        // What ZCL_ZSOL_OBD_CREATE answers for list A with two confirmed
        // cartons and one not: delivery for the two, 'W' for the third.
        const k = body.BoxData.split('|').slice(0, 3).join('|');
        const b = boxes[k] || [];
        const went = b.filter(x => x.Loaded === 'X'), stayed = b.filter(x => x.Loaded !== 'X');
        const kg = went.reduce((s, x) => s + parseFloat(x.NetWt), 0).toFixed(3);
        const msg = 'Challan 80012345 created: ' + went.length + ' carton(s), ' + kg + ' KG, goods issue posted' +
          (stayed.length ? ' - ' + stayed.length + ' unconfirmed carton(s) left on the list' : '');
        return json(route, 201, { d: {
          App: 'D',
          BoxData: 'R|S|' + msg + ';D|0080012345|S|' + msg + ';',
          SoItemList: went.map(x => 'B|' + x.Boxno + '|S|Delivery 80012345 - goods issue posted;').join('') +
            stayed.map(x => 'B|' + x.Boxno + '|W|Not confirmed by Security Loading - left on the packing list;').join('') +
            'L|S VL 311: Delivery 80012345 has been saved;'
        } });
      }
    }

    if (p.includes('ZSOL_DISPATCH_ISCAN_SRV') && p.endsWith('/IscanSet') && req.method() === 'POST') {
      const body = JSON.parse(req.postData());
      dispatchPosts.push(body);
      // ZCL_ZSOL_DISPATCH_ISCA_DPC_EXT writes one ZSOL_HUDISPATCH row per box,
      // stamped now; the read service then reports the box Loaded.
      body.IscanToDispatch.forEach(r => {
        Object.keys(boxes).forEach(k => boxes[k].forEach(x => {
          if (x.Boxno === r.Boxno && k.startsWith(r.So + '|' + r.So_Item + '|' + r.Pck_lst)) { x.Loaded = 'X'; x.LoadDate = '20260907'; x.LoadTime = '143210'; }
        }));
      });
      return json(route, 201, { d: body });
    }

    return json(route, 200, { d: { results: [] } });
  });

  await page.goto(`http://localhost:${PORT}/index.html`);
  await page.waitForTimeout(400);

  const text = (id) => page.evaluate((i) => document.getElementById(i).textContent, id);
  const opts = (id) => page.evaluate((i) => Array.from(document.getElementById(i).querySelectorAll('option')).map(o => o.textContent), id);
  async function fill(id, v) {
    await page.evaluate(([i, val]) => { const el = document.getElementById(i); el.value = val; el.dispatchEvent(new Event('scan-fill')); }, [id, v]);
    await page.waitForTimeout(150);
  }
  function expect(cond, msg) { if (!cond) throw new Error(msg); console.log('ok  ' + msg); }

  // ================= 1. Security Loading Scan =================
  await page.evaluate(() => document.querySelector('[data-goto="screen-dispatch"]').click());
  await page.waitForFunction(() => document.querySelectorAll('#dispPlSelect option').length >= 3, null, { timeout: 5000 });
  expect(listRequests.some(r => r.mode === 'LOAD' && !r.so), 'Security dropdown asked the server with Mode eq LOAD');
  let o = await opts('dispPlSelect');
  expect(o.some(t => /PL 1 · Item 10 · 3 of 3 to confirm/.test(t)), 'list A offered as "3 of 3 to confirm": ' + o.filter(t => /PL/.test(t)).join(' | '));
  expect(o.some(t => /2 of 2 to confirm/.test(t)), 'list B (nothing confirmed) offered on the Security screen too');
  const groups = await page.evaluate(() => Array.from(document.querySelectorAll('#dispPlSelect optgroup')).map(g => g.label));
  expect(groups.some(g => /SO 5126072798 — MANGO CUSTOMER/.test(g)), 'options grouped by sales order: ' + groups.join(' | '));

  // Pick list A through the typed / scanned order path (one list -> straight in).
  await fill('dispSoInput', '5126072798');
  await page.waitForFunction(() => document.querySelectorAll('#dispPendList .listrow').length === 3, null, { timeout: 5000 });
  expect(/SO 5126072798 \/ 10\s+·\s+Packing List 1/.test(await text('dispSoCode')), 'list A selected: ' + (await text('dispSoCode')));
  expect((await text('dispPendBadge')) === '3 pending / 3 total', 'carton badge "3 pending / 3 total"');
  let rows = await page.evaluate(() => Array.from(document.querySelectorAll('#dispPendList .listrow')).map(r => r.textContent));
  expect(rows.every(r => /Pending/.test(r)) && rows.some(r => /9970000003.*61\.549 KG/.test(r)), 'every carton Pending, with weight: ' + rows[2]);

  // Scan two: one by 10-digit box number, one by 20-digit HU label.
  await fill('dispBoxInput', '9970000001');
  await fill('dispBoxInput', '00000000009970000002');
  expect((await page.evaluate(() => document.querySelectorAll('#dispBatchList .listrow').length)) === 2, 'two cartons scanned (box number and HU label both accepted)');
  await fill('dispBoxInput', '9970000001');
  expect(/Already scanned/.test(await text('dispScanStatus')), 'a repeat scan is refused');
  await fill('dispBoxInput', '9999999999');
  expect(/not on this packing list/.test(await text('dispScanStatus')), 'a carton off the list is refused');
  expect(/Confirm Loading \(2\)/.test(await text('btnSubmitDisp')), 'button counts the batch');

  // Confirm Loading.
  await page.evaluate(() => document.getElementById('btnSubmitDisp').click());
  await page.waitForFunction(() => /confirmed loaded/.test(document.getElementById('dispStatus').textContent), null, { timeout: 5000 });
  expect(dispatchPosts.length === 1, 'one IscanSet POST');
  const rowsSent = dispatchPosts[0].IscanToDispatch;
  expect(rowsSent.length === 2 && rowsSent[0].Boxno === '9970000001' && rowsSent[1].Boxno === '9970000002', 'both cartons in the payload');
  expect(rowsSent.every(r => r.So === '5126072798' && r.So_Item === '000010' && r.Pck_lst === '000001' && r.Status === 'S'), 'payload carries SO, item, packing list (padded) and Status S');
  expect(/Create Challan screen/.test(await text('dispStatus')), 'operator is sent on to Create Challan: ' + (await text('dispStatus')));

  // The cartons are re-read from SAP and the dropdown re-counted.
  await page.waitForFunction(() => document.getElementById('dispPendBadge').textContent === '1 pending / 3 total', null, { timeout: 5000 });
  rows = await page.evaluate(() => Array.from(document.querySelectorAll('#dispPendList .listrow')).map(r => r.textContent));
  expect(rows.filter(r => /Confirmed 07\.09\.2026 14:32/.test(r)).length === 2 && rows.filter(r => /Pending/.test(r)).length === 1, 'two Confirmed (with time), one Pending');
  await page.waitForFunction(() => Array.from(document.querySelectorAll('#dispPlSelect option')).some(o => /1 of 3 to confirm/.test(o.textContent)), null, { timeout: 5000 });
  console.log('ok  dropdown re-read: list A now "1 of 3 to confirm"');
  await fill('dispBoxInput', '9970000002');
  expect(/already confirmed loaded/.test(await text('dispScanStatus')), 'a confirmed carton cannot be scanned again');
  expect((await page.evaluate(() => document.querySelectorAll('#dispBatchList .listrow').length)) === 0, 'batch cleared after submit');

  // ================= 2. Create Challan =================
  await page.evaluate(() => document.getElementById('btnBack').click());
  await page.evaluate(() => document.querySelector('[data-goto="screen-challan"]').click());
  await page.waitForFunction(() => document.querySelectorAll('#chSoSelect option').length >= 2, null, { timeout: 5000 });
  expect(listRequests.some(r => r.mode === 'CHALLAN' && !r.so), 'Create Challan asked the server with Mode eq CHALLAN');
  o = await opts('chSoSelect');
  expect(o.some(t => /5126072798 — MANGO CUSTOMER · 1 list, 2 cartons confirmed/.test(t)), 'order A offered with its confirmed count: ' + o.join(' | '));
  expect(!o.some(t => /5126072799/.test(t)), 'order B (nothing confirmed) is NOT offered for a Challan');

  await page.evaluate(() => { const s = document.getElementById('chSoSelect'); s.value = '5126072798'; s.dispatchEvent(new Event('change')); });
  await page.waitForFunction(() => document.querySelectorAll('#chBoxList .listrow').length === 3, null, { timeout: 5000 });
  o = await opts('chPlSelect');
  expect(o.some(t => /PL 1 · Item 10 · 2 of 3 cartons confirmed/.test(t)), 'the one packing list auto-selected, "2 of 3 cartons confirmed"');
  rows = await page.evaluate(() => Array.from(document.querySelectorAll('#chBoxList .listrow')).map(r => r.textContent));
  expect(rows.filter(r => /Confirmed 07\.09\.2026/.test(r)).length === 2, 'two cartons shown Confirmed');
  expect(rows.filter(r => /Not confirmed - stays on list/.test(r)).length === 1 && /9970000003/.test(rows.find(r => /Not confirmed/.test(r))), 'the unconfirmed 61.5 KG carton is marked "stays on list"');
  expect((await text('chBoxBadge')) === '2 of 3 confirmed · 48.529 KG', 'badge counts and weighs the confirmed cartons only: ' + (await text('chBoxBadge')));
  expect(/1 carton not confirmed by Security - the Challan takes the 2 confirmed cartons only/.test(await text('chBoxStatus')), 'status explains what goes and what stays');
  expect(!(await page.evaluate(() => document.getElementById('btnSubmitChallan').disabled)), 'Create Challan enabled');

  // First press arms, second posts.
  await page.evaluate(() => document.getElementById('btnSubmitChallan').click());
  let st = await text('chStatus');
  expect(/goods issue for the 2 confirmed cartons \(48\.529 KG\) on SO 5126072798; 1 unconfirmed carton stays on the packing list/.test(st), 'arm message names the confirmed cartons and the one left behind: ' + st);
  await page.evaluate(() => document.getElementById('btnSubmitChallan').click());
  await page.waitForFunction(() => /Challan 80012345/.test(document.getElementById('chStatus').textContent), null, { timeout: 5000 });
  expect(challanPosts.length === 1 && challanPosts[0].App === 'D', 'one ChallanPackSet POST with App D');
  const today = new Date(); const y = today.getFullYear(), m = String(today.getMonth() + 1).padStart(2, '0'), d = String(today.getDate()).padStart(2, '0');
  expect(challanPosts[0].BoxData === '5126072798|000010|000001|' + y + m + d + '||', 'BoxData = So|SoItem|Pklst|GiDate|Trcode|Trckno: ' + challanPosts[0].BoxData);
  st = await text('chStatus');
  expect(/2 carton\(s\), 48\.529 KG.*1 unconfirmed carton\(s\) left on the list.*Challan 80012345/.test(st), 'success message: ' + st);
  const log = await page.evaluate(() => Array.from(document.querySelectorAll('#chLog .log-entry')).map(e => e.className + ' :: ' + e.textContent));
  expect(log.some(l => /^log-entry ok/.test(l) && /1 carton left on the packing list/.test(l) && /9970000003/.test(l)), 'the W carton is logged as left on the list, not as a failure: ' + log.join(' || '));
  expect(!log.some(l => /^log-entry err/.test(l)), 'no failure entries in the log');

  // After the posting the screen reloads: list A is gone from CHALLAN mode
  // (the mock has no further confirmed cartons on it? it still has 2 - so
  // it stays; what matters is the reload asked the server again).
  expect(listRequests.filter(r => r.mode === 'CHALLAN' && !r.so).length >= 2, 'packing lists re-read after the posting');

  if (errors.length) throw new Error('page/console errors:\n' + errors.join('\n'));
  console.log('ok  zero page/console errors');
  console.log('\nALL SECURITY-FIRST TESTS PASSED');

  await browser.close();
  server.close();
})().catch(e => { console.error('FAILED: ' + e.message); process.exit(1); });
