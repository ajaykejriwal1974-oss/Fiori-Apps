// Job Card - picking the schedule (07.09.2026). On production the pick
// only drew a blue border on one of a hundred rows and the operator could
// not find the next step; and the newest rows were all over-batched. Now:
// fully batched schedules are hidden from the open list (the server hides
// them too; this is the screen's own guard), a tap / typed number / scan
// folds the list away behind the chosen schedule and scrolls on to the
// machines, "Change schedule" brings the list back, and a typed number not
// in the list is looked up on the server.
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const DIR = __dirname;
const PORT = 8795;

const batch = { batchno: '2120017073', gjahr: '2026', werks: '2002', aufnr: '1039729', bchdate: '20260907', lotno: 'BCT',
  grey_code: 'T300072BCSSNXXXXXX', grey_item: '300/72 GREY', dye_code: 'D300072KARISHMAX01', dye_item: '300/72 KARISHMA',
  qty: '298.8', vrkme: 'KG', cheeses: '240', assigned: '', closed: '', jobno: '', schno: '', dye_arbpl: '', win_arbpl: '', ernam: 'ADMIN', erdat: '20260907' };
function sched(schno, sch, batched, cnt, complete) {
  return { schno, gjahr: '2026', werks: '2002', kdno: 'A', schdt: '20260820', dyedt: '20260824', vbeln: '5126073000', posnr: '000010',
    matnr: 'D300072KARISHMAX01', maktx: '300/72 KARISHMA', sch_qty: String(sch), vrkme: 'KG', shdcd: '100274', shade: 'D-3116 RANI.', remarks: '',
    complete: complete || '', customer: 'MADHUSUDAN SILK PRIVATE LIMITED', batched_qty: String(batched), job_cnt: String(cnt) };
}
// What the server hands back for the open list (it already drops the
// fully batched ones since v2 of the class); the negative one is left in
// here on purpose to prove the screen hides it on its own as well.
const openList = [sched('2610010721', 1000, 1091.24, 3), sched('2610010505', 500, 535.2, 1), sched('2610008999', 1000, 0, 0), sched('2610008998', 800, 300, 1)];
const byNumber = { '2610010504': sched('2610010504', 500, 577.4, 1), '2610000001': Object.assign(sched('2610000001', 300, 0, 0), { matnr: 'D999OTHER' }) };
const posts = [];

function json(route, status, body, headers) { return route.fulfill({ status, contentType: 'application/json', headers: headers || {}, body: JSON.stringify(body) }); }
function filterVal(url, prop) { const m = new RegExp(prop + "\\s+eq\\s+'([^']*)'").exec(decodeURIComponent(url)); return m ? m[1] : ''; }

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
    sessionStorage.setItem('kgpl.scan.session', JSON.stringify({ username: 'ADMIN', fullName: 'Admin', isAdmin: 'X', token: 'tok-test', orgs: '2000|2002;', features: 'JOBCARD;WIPBATCH;' }));
  });
  await page.route('**/sap/**', async (route) => {
    const req = route.request(); const url = req.url(); const p = new URL(url).pathname;
    if (p.endsWith('/$metadata')) return json(route, 200, {}, { 'X-CSRF-Token': 'csrf-test' });
    if (p.includes('/ZSOL_WIP_BATCH')) return json(route, 200, { d: { results: filterVal(url, 'batchno') === batch.batchno ? [batch] : [] } });
    if (p.includes('/ZSOL_SCHEDULE')) {
      const no = filterVal(url, 'schno');
      if (no) return json(route, 200, { d: { results: byNumber[no] ? [byNumber[no]] : openList.filter(s => s.schno === no) } });
      return json(route, 200, { d: { results: openList } });
    }
    if (p.includes('/ZSOL_WORKCENTER')) return json(route, 200, { d: { results: [{ werks: '2002', arbpl: 'DYG00012', ktext: 'DYEING 12', kind: 'D', used: '40' }, { werks: '2002', arbpl: 'WIN00003', ktext: 'WINDING 3', kind: 'W', used: '20' }] } });
    if (p.includes('/ZSOL_JOBCARD') && req.method() === 'POST') { const b = JSON.parse(req.postData()); posts.push(b); return json(route, 201, { d: { jobno: b.batchno, schno: b.schno, batchno: b.batchno, werks: '2002', dye_arbpl: b.dye_arbpl, win_arbpl: b.win_arbpl, message: 'ok' } }); }
    if (p.includes('/ZSOL_JOBCARD_RECIPE') || p.includes('/ZSOL_JOBCARD')) return json(route, 200, { d: { results: [] } });
    return json(route, 200, { d: { results: [] } });
  });

  const text = (sel) => page.$eval(sel, e => e.textContent.replace(/\s+/g, ' ').trim());
  const shown = (sel) => page.$eval(sel, e => e.style.display !== 'none' && e.offsetParent !== null);
  function expect(cond, msg) { if (!cond) { console.log('FAIL ' + msg); process.exitCode = 1; } else console.log('ok   ' + msg); }

  await page.goto(`http://localhost:${PORT}/index.html`);
  await page.waitForSelector('#screen-home.active', { timeout: 10000 });
  await page.evaluate(() => document.querySelector('[data-goto="screen-jobcard"]').click());
  await page.fill('#jcWerks', '2002');
  await page.fill('#jcBatch', batch.batchno); await page.press('#jcBatch', 'Enter');
  await page.waitForFunction(() => document.querySelectorAll('#jcSchedList .prow').length > 0, null, { timeout: 5000 });

  // 1. The open list hides the fully batched schedules.
  let rows = await page.$$eval('#jcSchedList .prow .no', ns => ns.map(n => n.textContent));
  expect(rows.length === 2 && rows.indexOf('2610008999') !== -1 && rows.indexOf('2610008998') !== -1, 'only schedules with quantity left are listed: ' + rows.join(', '));
  expect((await text('#jcSchedBadge')) === '2', 'badge counts the listed ones');
  expect(/2 fully batched schedule\(s\) not shown/.test(await text('#jcSchedList')), 'note says how many are hidden');

  // 2. Tap picks: list folds away, box shows, status points to the machines.
  await page.click('#jcSchedList .prow:nth-child(2)');
  expect(await shown('#jcSchedBox'), 'schedule box shown after the tap');
  expect(!(await shown('#jcSchedList')) && !(await shown('#jcSchedAllRow')), 'list and checkbox folded away');
  expect(/Schedule 2610008998/.test(await text('#jcSchedCode')) && /500 KG left to batch/.test(await text('#jcSchedDesc')), 'box names the schedule and what is left: ' + (await text('#jcSchedDesc')));
  expect(/selected - now choose the dyeing machine/.test(await text('#jcSchedStatus')), 'status sends the operator on');
  expect((await page.$eval('#jcSchno', e => e.value)) === '2610008998', 'input carries the number');

  // 3. Change schedule brings the list back, empty input.
  await page.click('#btnJcSchedChange');
  expect(!(await shown('#jcSchedBox')) && (await shown('#jcSchedList')), 'change schedule shows the list again');
  expect((await page.$eval('#jcSchno', e => e.value)) === '', 'input cleared');

  // 4. A typed number not in the list is looked up: over-batched, still selectable, warned.
  await page.fill('#jcSchno', '2610010504');
  await page.waitForFunction(() => document.getElementById('jcSchedBox').style.display === 'block', null, { timeout: 5000 });
  expect(/Schedule 2610010504/.test(await text('#jcSchedCode')) && /77.4 KG over the scheduled quantity/.test(await text('#jcSchedDesc')), 'typed schedule looked up and shown with the over-batch warning: ' + (await text('#jcSchedDesc')));
  expect((await page.$eval('#jcSchedBox', e => e.className)).indexOf('warnbox') !== -1, 'box flagged amber');

  // 5. A typed number for another material is refused with the reason.
  await page.click('#btnJcSchedChange');
  await page.fill('#jcSchno', '2610000001');
  await page.waitForFunction(() => /is for D999OTHER/.test(document.getElementById('jcSchedStatus').textContent), null, { timeout: 5000 });
  expect(/is for D999OTHER - this batch dyes D300072KARISHMAX01/.test(await text('#jcSchedStatus')), 'wrong-material schedule refused: ' + (await text('#jcSchedStatus')));
  expect(!(await shown('#jcSchedBox')), 'nothing selected');

  // 6. Pick one, choose a machine, create - the POST carries the schedule.
  await page.fill('#jcSchno', '2610008998');
  await page.waitForFunction(() => document.getElementById('jcSchedBox').style.display === 'block', null, { timeout: 5000 });
  await page.click('#jcDyeChips .chip');
  await page.click('#btnJcCreate');
  await page.waitForFunction(() => /Job card .* created/.test(document.getElementById('jcBatchDesc').textContent), null, { timeout: 5000 });
  expect(posts.length === 1 && posts[0].schno === '2610008998' && posts[0].dye_arbpl === 'DYG00012', 'job card posted with the picked schedule and machine: ' + JSON.stringify(posts[0]));

  if (errors.length) { console.log('ERRORS:', errors); process.exitCode = 1; }
  await browser.close(); server.close();
  if (!process.exitCode) console.log('\nALL JOBCARD-SCHEDULE TESTS PASSED');
})().catch(e => { console.error('FAILED: ' + e.message); process.exit(1); });
