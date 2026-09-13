// Headless test of the Packing List "Why no boxes?" card: serves the local
// index.html, stubs the pick download, the pending list, the box check and
// the batch write with a tiny in-memory order, and drives the card through
// auto-check, assign, remove, the read-only view and the manual link.
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = __dirname;
const PORT = 8767;

// One order, one item, no batch named. Packed stock: 3 boxes under
// 1510000158 and 1 under 1940014898, all otherwise fine; 2 boxes in DFGT.
const order = {
  vbeln: '5125000098', posnr: '000010', matnr: 'D080000XXXXXXXXX01', arktx: 'POLYESTER YARN 80/BRIGHT', werks: '2002', lgort: 'DFG1',
  kwmeng: 300, dis_qty: 0, zzsize: 'IA', zzgrade: 'A', assigned: []
};
const stock = [
  { box: '9950001001', charg: '1510000158', lgort: 'DFG1', wt: 200 },
  { box: '9950001002', charg: '1510000158', lgort: 'DFG1', wt: 200 },
  { box: '9950001003', charg: '1510000158', lgort: 'DFG1', wt: 200 },
  { box: '9950001004', charg: '1940014898', lgort: 'DFG1', wt: 200 },
  { box: '9950001005', charg: '1510000158', lgort: 'DFGT', wt: 200 },
  { box: '9950001006', charg: '1510000158', lgort: 'DFGT', wt: 200 }
];
// A second order that already has boxes (item batch on VBAP).
const order2 = { vbeln: '5125000095', posnr: '000010', matnr: 'D080000XXXXXXXXX01', arktx: 'POLYESTER YARN 80/BRIGHT', werks: '2002', lgort: 'DFG1', kwmeng: 203, dis_qty: 0, zzsize: 'IA', zzgrade: 'A', charg: '1940014898' };

function matching(o) {
  const bats = o.assigned && o.assigned.length ? o.assigned : (o.charg ? [o.charg] : []);
  return stock.filter(s => s.lgort === o.lgort && bats.indexOf(s.charg) !== -1);
}
function checkRow(o) {
  const m = matching(o);
  const bats = o.assigned && o.assigned.length ? o.assigned : (o.charg ? [o.charg] : []);
  const byBatch = {};
  stock.filter(s => s.lgort === o.lgort && bats.indexOf(s.charg) === -1).forEach(s => { byBatch[s.charg] = byBatch[s.charg] || { cnt: 0, wt: 0 }; byBatch[s.charg].cnt++; byBatch[s.charg].wt += s.wt; });
  const need = Object.keys(byBatch).sort((a, b) => byBatch[b].cnt - byBatch[a].cnt).map(k => k + '×' + byBatch[k].cnt + ' (' + byBatch[k].wt.toFixed(3) + ' KG)').join('; ');
  const otherLg = {};
  stock.filter(s => s.lgort !== o.lgort).forEach(s => { otherLg[s.lgort] = (otherLg[s.lgort] || 0) + 1; });
  return {
    vbeln: o.vbeln, posnr: o.posnr, matnr: o.matnr, arktx: o.arktx, werks: o.werks, lgort: o.lgort, charg: o.charg || '',
    kwmeng: o.kwmeng.toFixed(3), vrkme: 'KG', dis_qty: o.dis_qty.toFixed(3), open_qty: (o.kwmeng - o.dis_qty).toFixed(3), abgru: '',
    zzsize: o.zzsize, zzsiz1: '', zzsiz2: '', zzgrade: o.zzgrade, zzgrad1: '', zzgrad2: '',
    so_batches: bats.join('; '), batch_src: o.assigned && o.assigned.length ? 'A' : (o.charg ? 'C' : ''),
    cand_cnt: stock.length, match_cnt: m.length, match_wt: m.reduce((s, b) => s + b.wt, 0).toFixed(3),
    need_batch: need, other_lgort: Object.keys(otherLg).map(k => k + '×' + otherLg[k]).join('; '), other_size: '', other_grade: '', other_so: '',
    on_deliv: 0, not_posted: 0,
    hint: m.length ? m.length + ' HU(s) can be picked' : (bats.length ? 'None of the packed stock carries the batch the order names - assign one of the batches listed' : 'Order names no batch; the packed stock carries batches - assign one of the batches listed')
  };
}
function pickSet(o) {
  const m = matching(o);
  return { d: {
    So_Num: o.vbeln,
    SODetails: { results: [{ Item_No: '10', Material: o.matnr, Mat_Desc: o.arktx, Plant: o.werks, Stg_Loc: o.lgort, Batch: o.charg || '', Grade: o.zzgrade, Size: o.zzsize, Bal_qty: String(o.kwmeng - o.dis_qty), Uom: 'KG', Toler: '0.0' }] },
    HUDetails: { results: m.map(s => ({ Box_No: s.box, Itemno: '000000', Material: o.matnr, Mat_Desc: o.arktx, Plant: o.werks, Stg_Loc: s.lgort, Batch: s.charg, Grade: 'A', Size: o.zzsize, Net_Wt: String(s.wt), Ext_Id: '00000000009950001001' })) }
  } };
}

const writes = [];
function json(route, status, body, headers) {
  return route.fulfill({ status, contentType: 'application/json', headers: headers || {}, body: JSON.stringify(body) });
}
function busi(route, msg) { return json(route, 400, { error: { code: 'X', message: { lang: 'en', value: msg } } }); }

async function run(browser, features, label, steps) {
  const page = await browser.newPage({ viewport: { width: 420, height: 900 } });
  const errors = [];
  page.on('pageerror', e => errors.push('pageerror: ' + e.message));
  // Resource-load failures are the served folder lacking manifest.json /
  // html5-qrcode.min.js and the mock's deliberate 400s - not app errors.
  page.on('console', m => { if (m.type() === 'error' && !/Failed to load resource/.test(m.text())) errors.push('console: ' + m.text()); });
  await page.addInitScript((features) => {
    sessionStorage.setItem('kgpl.scan.session', JSON.stringify({
      username: 'PICK1', fullName: 'Picker', isAdmin: '', token: 'tok-test', orgs: '2000|2002;', features: features
    }));
  }, features);

  await page.route('**/sap/**', async (route) => {
    const req = route.request();
    const url = new URL(req.url());
    const q = url.searchParams;
    const p = url.pathname;
    const f = q.get('$filter') || '';
    if (p.endsWith('/$metadata')) return json(route, 200, {}, { 'X-CSRF-Token': 'csrf-test' });
    if (!req.headers()['x-scan-token']) return busi(route, 'Not signed in');
    if (p.includes('ZSOL_PICK_DOWNLOAD_SRV/PickSet')) {
      const m = /PickSet\('(\d+)'\)/.exec(decodeURIComponent(p));
      const so = m && m[1];
      if (so === order.vbeln) return json(route, 200, pickSet(order));
      if (so === order2.vbeln) return json(route, 200, pickSet(order2));
      return busi(route, 'Sales order ' + so + ' not found');
    }
    if (p.includes('ZSOL_SCAN_READ_SRV/')) {
      const set = p.split('ZSOL_SCAN_READ_SRV/')[1].split('(')[0];
      if (set === 'ZSOL_SO_PICK_PEND') return json(route, 200, { d: { results: [
        { vbeln: order.vbeln, posnr: '000010', SoldToParty: 'DFG CUSTOMER', created_on: '20260901' },
        { vbeln: order2.vbeln, posnr: '000010', SoldToParty: 'OTHER CUSTOMER', created_on: '20260901' }
      ] } });
      if (set === 'ZSOL_SO_BOXCHECK') {
        const m = /vbeln eq '(\d+)'/.exec(f);
        if (!m) return busi(route, 'Select a sales order first');
        const so = m[1].replace(/^0+/, '');
        const o = so === order.vbeln ? order : so === order2.vbeln ? order2 : null;
        if (!o) return busi(route, 'Sales Order ' + m[1] + ' not found');
        return json(route, 200, { d: { results: [checkRow(o)] } });
      }
      if (set === 'ZSOL_SO_BATCH' && req.method() === 'POST') {
        const b = JSON.parse(req.postData());
        writes.push({ op: 'POST', b, feature: features });
        if (!features.includes('SOCHG')) return busi(route, 'You do not have access to SOCHG');
        if (!stock.some(s => s.charg === b.charg)) return busi(route, 'Batch ' + b.charg + ' is not packed stock of ' + order.matnr + ' in plant 2002');
        const o = b.vbeln.replace(/^0+/, '') === order2.vbeln ? order2 : order;
        // v5: an item with a single batch (VBAP-CHARG) gets it REPLACED
        // (BAPI_SALESORDER_CHANGE on the server); a list item gets a row.
        if (o.charg) {
          if (o.charg === b.charg) return busi(route, 'Item 10 already carries batch ' + b.charg);
          o.charg = b.charg;
        } else {
          o.assigned = o.assigned || [];
          if (o.assigned.indexOf(b.charg) === -1) o.assigned.push(b.charg);
        }
        return json(route, 201, { d: { vbeln: b.vbeln, posnr: b.posnr, charg: b.charg, message: 'Batch ' + b.charg + ' assigned to item 10 of order ' + o.vbeln + ' by PICK1' } });
      }
      if (set === 'ZSOL_SO_BATCH' && req.method() === 'DELETE') {
        const m = /charg='([^']+)'/.exec(decodeURIComponent(p));
        const dv = /vbeln='(\d+)'/.exec(decodeURIComponent(p));
        const od = dv && dv[1].replace(/^0+/, '') === order2.vbeln ? order2 : order;
        writes.push({ op: 'DELETE', vbeln: dv && dv[1], charg: m && m[1], feature: features });
        if (od.charg && od.charg === (m && m[1])) od.charg = '';   // v5: the single batch is cleared
        else od.assigned = (od.assigned || []).filter(c => c !== (m && m[1]));
        return route.fulfill({ status: 204, body: '' });
      }
      return json(route, 404, { error: { message: { value: 'unstubbed ' + p } } });
    }
    // box locations and anything else: empty
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

async function main() {
  const server = http.createServer((req, res) => {
    const file = req.url.split('?')[0] === '/' ? '/index.html' : req.url.split('?')[0];
    const p = path.join(ROOT, file);
    if (!fs.existsSync(p)) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': file.endsWith('.js') ? 'application/javascript' : file.endsWith('.json') ? 'application/json' : 'text/html' });
    res.end(fs.readFileSync(p));
  }).listen(PORT);
  const browser = await chromium.launch();

  // A. user with SOCHG: auto check on 0 boxes, assign by tap, remove by x
  await run(browser, 'PICK;SOCHG;', 'operator with SOCHG', async (page) => {
    await page.click('[data-goto="screen-pick"]');
    await page.waitForSelector('#screen-pick.active');
    await page.waitForFunction(() => document.querySelectorAll('#pickSoSelect option').length === 3);
    await page.selectOption('#pickSoSelect', order.vbeln);
    await page.waitForFunction(() => document.querySelectorAll('#pickWhyList .whyrow').length === 1);
    console.log('order desc:', await text(page, '#pickSoDesc'));
    console.log('why badge:', await text(page, '#pickWhyBadge'), '| status:', await text(page, '#pickWhyStatus'));
    console.log('row class:', await page.$eval('#pickWhyList .whyrow', e => e.className));
    console.log('verdict:', await text(page, '#pickWhyList .verdict'));
    console.log('facts:', await text(page, '#pickWhyList .whyrow > .facts'));
    console.log('batch chips:', await page.$$eval('#pickWhyList .sobatch', cs => cs.map(c => c.className.replace('badge sobatch', '').trim() + ':' + c.textContent.trim())));
    console.log('assign row present:', !!(await page.$('#pickWhyList [data-assign-input]')), '| check link hidden:', !(await shown(page, '#btnCheckPickSo')));
    await page.screenshot({ path: 'whybox_nobox.png', fullPage: true });

    // tap the big batch -> POST -> reload shows 3 boxes, card re-run says ok
    await page.click('#pickWhyList .sobatch.cando');
    await page.waitForFunction(() => /3 box\(es\) available/.test(document.querySelector('#pickSoDesc').textContent));
    await page.waitForFunction(() => document.querySelector('#pickWhyList .whyrow.ok'));
    console.log('POST:', JSON.stringify(writes[writes.length - 1].b));
    console.log('after assign desc:', await text(page, '#pickSoDesc'));
    console.log('after assign verdict:', await text(page, '#pickWhyList .verdict'), '| badge:', await text(page, '#pickWhyBadge'));
    console.log('assigned chips:', await page.$$eval('#pickWhyList .sobatch[data-assigned]', cs => cs.map(c => c.textContent.trim())));
    console.log('rack chips:', await page.$$eval('#pickLocList .pickbox', cs => cs.map(c => c.textContent.trim())));
    console.log('log:', await page.$$eval('#pickLog .log-entry', ls => ls.map(l => l.textContent.replace(/\s+/g, ' ').trim())));
    await page.screenshot({ path: 'whybox_assigned.png', fullPage: true });

    // manual entry of a batch that is not stock -> server refusal shown
    await page.fill('#pickWhyList [data-assign-input]', 'nope1');
    await page.click('#pickWhyList [data-assign-btn]');
    await page.waitForFunction(() => /not packed stock/.test(document.querySelector('#pickWhyStatus').textContent));
    console.log('bad batch:', await text(page, '#pickWhyStatus'), '| sent as:', writes[writes.length - 1].b.charg);

    // remove via x -> DELETE -> 0 boxes again, card back to bad
    await page.click('#pickWhyList .sobatch[data-assigned] .rm');
    await page.waitForFunction(() => /0 box\(es\) available/.test(document.querySelector('#pickSoDesc').textContent));
    await page.waitForFunction(() => document.querySelector('#pickWhyList .whyrow.bad'));
    console.log('DELETE:', JSON.stringify(writes[writes.length - 1]));
    console.log('after remove desc:', await text(page, '#pickSoDesc'), '| verdict:', await text(page, '#pickWhyList .verdict'));

    // change order clears the card
    await page.click('#btnChangePickSo');
    console.log('card hidden after change:', !(await shown(page, '#pickWhyCard')));
  });

  // B. plain picker: same diagnosis, nothing to tap
  await run(browser, 'PICK;', 'operator without SOCHG', async (page) => {
    await page.click('[data-goto="screen-pick"]');
    await page.waitForSelector('#screen-pick.active');
    await page.fill('#pickSoInput', order.vbeln);
    await page.press('#pickSoInput', 'Enter');
    await page.waitForFunction(() => document.querySelectorAll('#pickWhyList .whyrow').length === 1);
    console.log('status:', await text(page, '#pickWhyStatus'));
    console.log('chips:', await page.$$eval('#pickWhyList .sobatch', cs => cs.map(c => c.className)));
    console.log('assign row present:', !!(await page.$('#pickWhyList [data-assign-input]')), '| rm present:', !!(await page.$('#pickWhyList .rm')));
    await page.click('#pickWhyList .sobatch');
    await page.waitForTimeout(300);
    console.log('tap did nothing (no write):', writes.filter(w => w.feature === 'PICK;').length === 0);

    // an order WITH boxes: card hidden, "Check order" offered, click shows it
    await page.click('#btnChangePickSo');
    await page.fill('#pickSoInput', order2.vbeln);
    await page.press('#pickSoInput', 'Enter');
    await page.waitForFunction(() => /1 box\(es\) available/.test(document.querySelector('#pickSoDesc').textContent));
    console.log('order2 card hidden:', !(await shown(page, '#pickWhyCard')), '| link:', await text(page, '#btnCheckPickSo'), await shown(page, '#btnCheckPickSo'));
    await page.click('#btnCheckPickSo');
    await page.waitForFunction(() => document.querySelector('#pickWhyList .whyrow.ok'));
    console.log('order2 verdict:', await text(page, '#pickWhyList .verdict'), '| batch shown:', await text(page, '#pickWhyList .whyrow > .facts'));
    await page.screenshot({ path: 'whybox_readonly.png', fullPage: true });
  });

  // C. SOCHG user on an item that carries its own single batch (v5): the
  //    lots are tappable, a tap arms, the second tap replaces the item's
  //    batch; the single batch has a x that clears it, after which the
  //    item takes a list.
  function expect(cond, msg) { if (!cond) { console.log('FAIL ' + msg); process.exitCode = 1; } else console.log('ok   ' + msg); }
  await run(browser, 'PICK;SOCHG;', 'operator with SOCHG on a single-batch item', async (page) => {
    // order2 names 1940014898 - one box; make that lot sold out so the
    // card has a reason to offer the others.
    const sold = stock.splice(stock.findIndex(s => s.charg === '1940014898'), 1)[0];
    await page.click('[data-goto="screen-pick"]');
    await page.waitForSelector('#screen-pick.active');
    await page.fill('#pickSoInput', order2.vbeln);
    await page.press('#pickSoInput', 'Enter');
    await page.waitForFunction(() => document.querySelectorAll('#pickWhyList .whyrow').length === 1);
    expect((await page.$$('#pickWhyList .sobatch.cando')).length === 1, 'the other lot is offered as tappable on a single-batch item');
    expect(/in place of 1940014898/.test(await text(page, '#pickWhyList .whyrow')), 'card says the tap puts the lot on the item in place of the single batch');
    expect(!!(await page.$('#pickWhyList .sobatch[data-assigned="1940014898"] .rm')), 'the single batch is shown with a x to clear it');
    expect((await text(page, '#pickWhyList [data-assign-btn]')) === 'Replace', 'typed path is labelled Replace');

    // first tap arms, writes nothing
    const before = writes.length;
    await page.click('#pickWhyList .sobatch.cando');
    await page.waitForTimeout(200);
    expect(writes.length === before, 'first tap writes nothing');
    expect(/Tap again to put 1510000158 on item 10/.test(await text(page, '#pickWhyList .sobatch.cando')), 'chip asks for a second tap: ' + (await text(page, '#pickWhyList .sobatch.cando')));
    expect(/Tap 1510000158 again .* in place of 1940014898/.test(await text(page, '#pickWhyStatus')), 'status explains the replace');
    await page.screenshot({ path: 'whybox_single_armed.png', fullPage: true });

    // second tap -> POST -> server replaced VBAP-CHARG -> order reloads with the lot's 3 boxes
    await page.click('#pickWhyList .sobatch.cando');
    await page.waitForFunction(() => /3 box\(es\) available/.test(document.querySelector('#pickSoDesc').textContent));
    expect(writes[writes.length - 1].op === 'POST' && writes[writes.length - 1].b.charg === '1510000158', 'second tap POSTed the lot');
    expect(order2.charg === '1510000158', 'server replaced the single batch');
    const log = await page.$$eval('#pickLog .log-entry', ls => ls.map(l => l.textContent.replace(/\s+/g, ' ').trim()));
    expect(log.some(l => /Batch 1510000158 is now on item 10 of SO 5125000095 in place of 1940014898/.test(l)), 'log says replaced, not assigned: ' + log[0]);
    await page.waitForFunction(() => document.querySelector('#pickWhyList .whyrow.ok'));
    expect(/1510000158/.test(await text(page, '#pickWhyList .sobatch[data-assigned]')), 'card now shows the new single batch');

    // x on the single batch -> DELETE -> cleared -> item names no batch, lots become plain assign
    await page.click('#pickWhyList .sobatch[data-assigned] .rm');
    await page.waitForFunction(() => /0 box\(es\) available/.test(document.querySelector('#pickSoDesc').textContent));
    const del = writes[writes.length - 1];
    expect(del.op === 'DELETE' && del.charg === '1510000158', 'x sent DELETE for the single batch');
    expect(order2.charg === '', 'server cleared VBAP-CHARG');
    await page.waitForFunction(() => document.querySelector('#pickWhyList .whyrow.bad'));
    expect(/Order names no batch/.test(await text(page, '#pickWhyList .verdict')), 'item now names no batch: ' + (await text(page, '#pickWhyList .verdict')));
    expect((await text(page, '#pickWhyList [data-assign-btn]')) === 'Assign', 'typed path back to Assign (list mode)');
    const chipBefore = writes.length;
    await page.click('#pickWhyList .sobatch.cando');
    await page.waitForFunction((n) => true, chipBefore);
    await page.waitForFunction(() => /3 box\(es\) available/.test(document.querySelector('#pickSoDesc').textContent));
    expect(writes.length === chipBefore + 1 && writes[writes.length - 1].op === 'POST', 'in list mode one tap assigns (no arming)');
    expect(order2.assigned && order2.assigned.indexOf('1510000158') !== -1, 'server added a list row');
    await page.screenshot({ path: 'whybox_single.png', fullPage: true });
    stock.push(sold);
  });

  // D. plain picker on a single-batch item: nothing to tap, no x
  await run(browser, 'PICK;', 'operator without SOCHG on a single-batch item', async (page) => {
    order2.charg = '1940014898'; order2.assigned = [];
    await page.click('[data-goto="screen-pick"]');
    await page.waitForSelector('#screen-pick.active');
    await page.fill('#pickSoInput', order2.vbeln);
    await page.press('#pickSoInput', 'Enter');
    await page.waitForFunction(() => /1 box\(es\) available/.test(document.querySelector('#pickSoDesc').textContent));
    await page.click('#btnCheckPickSo');
    await page.waitForFunction(() => document.querySelectorAll('#pickWhyList .whyrow').length === 1);
    expect((await page.$$('#pickWhyList .sobatch.cando')).length === 0, 'no tappable chips without SOCHG');
    expect(!(await page.$('#pickWhyList .rm')) && !(await page.$('#pickWhyList [data-assign-input]')), 'no x and no input without SOCHG');
  });

  await browser.close();
  server.close();
}
main().catch(e => { console.error(e); process.exit(1); });
