#!/usr/bin/env node
// combo_pick_test.js - unit tests for the combined "Pick together" routing
// (10.09.2026). Extracts the REAL functions from ../index.html and drives
// them with stub orders, so the rules tested are the shipped ones. Run:
//   node test/combo_pick_test.js
var fs = require('fs'), path = require('path');
var src = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
var script = /<script(?![^>]*src)[^>]*>([\s\S]*?)<\/script>/.exec(src)[1];
function grab(name) {
  var i = script.indexOf('function ' + name + '(');
  if (i < 0) throw new Error('missing ' + name);
  var j = script.indexOf('{', i), depth = 0, k = j;
  for (;;) {
    var c = script[k];
    if (c === '{') depth++;
    else if (c === '}') { depth--; if (depth === 0) break; }
    k++;
  }
  return script.slice(i, k + 1);
}
var names = ['normalizeBox','num','fmtQty','matKey','batchKey','itemForBox','orderQtyFor','sochgTol','tolFor','tolIsSochg','capFor','selectedFor','selectedTotal','orderCap','orderPending','uomOf','isPieceUom','boxQtyFor','fitCheck','lotsOfCandidates','withCtx','comboOrders','comboCtxFor','comboAssignedAnywhere','comboEligible','comboAdd','comboMove','comboRemove','comboWholeLot'];
var harness = "var soItems=[],batch=[],candidates=[],whyRows=[],currentSoNum=null,combo=null;\n" +
  "var QTY_EPS=0.0005, USE_SO_TOLERANCE=true, SOCHG_HEADROOM=0.10;\n" +
  "var PIECE_UOMS={ROL:1,PC:1,PCE:1,ST:1,EA:1};\n" +
  "var lastStatus='';\n" +
  "function canChangeOrder(){return true;}\n" +
  "function setStatus(el,msg,cls){lastStatus=(msg||'');}\n" +
  "function renderCombo(){}\n" +
  "function stripZerosLocal(v){return String(v==null?'':v).trim().replace(/^0+(?=\\d)/,'');}\n" +
  "var comboScanStatus={};\n";
var m = new Function(harness + names.map(grab).join('\n') +
  "\nreturn {add:comboAdd,move:comboMove,whole:comboWholeLot,setCombo:function(c){combo=c;},status:function(){return lastStatus;}};")();

var fails = 0;
function t(name, cond) { console.log((cond ? 'PASS' : 'FAIL') + ' - ' + name); if (!cond) fails++; }
function box(no, mat, lot, wt) { return { Box_No: no, Material: mat, Batch: lot, Net_Wt: wt, Plant: '8000', Stg_Loc: 'TFG1', Itemno: '000010' }; }
function item(no, mat, bal, uom, tol) { return { Item_No: no, Material: mat, Bal_qty: bal, Uom: uom, Toler: tol || 0 }; }

// Two KG orders sharing candidates.
var A = { so: '5001', soItems: [item('000010', 'MATX', 100, 'KG')], candidates: [box('B1', 'MATX', 'L1', 60), box('B2', 'MATX', 'L1', 60), box('B3', 'MATX', 'L1', 60)], batch: [], whyRows: [] };
var B = { so: '5002', soItems: [item('000010', 'MATX', 200, 'KG')], candidates: [box('B1', 'MATX', 'L1', 60), box('B2', 'MATX', 'L1', 60), box('B4', 'MATX', 'L2', 50)], batch: [], whyRows: [] };
m.setCombo({ orders: [A, B], seq: 0 });
m.add('B1');
t('shared box routes to first queued order', A.batch.length === 1 && A.batch[0].Box_No === 'B1' && B.batch.length === 0);
t('status names the other eligible order', /other order/.test(m.status()));
m.add('B1');
t('duplicate scan refused across orders', /already scanned/.test(m.status()) && A.batch.length === 1 && B.batch.length === 0);
m.add('B4');
t('box unique to order 2 routes there', B.batch.length === 1 && B.batch[0].Box_No === 'B4');
m.add('B2');  // 60 in A (cap 110 with SOCHG headroom): B2 overflows A, must skip to B
t('box overflowing order1 skips to order2', A.batch.length === 1 && B.batch.some(function (b) { return b.Box_No === 'B2'; }));
m.move('5001', 'B1');
t('move shifts box to next eligible order', A.batch.length === 0 && B.batch.some(function (b) { return b.Box_No === 'B1'; }));
m.move('5002', 'B1');
t('move wraps back to order1', A.batch.some(function (b) { return b.Box_No === 'B1'; }));

// Rolls: each box counts as one against the order.
var R1 = { so: '6001', soItems: [item('000010', 'KCROLL', 2, 'ROL')], candidates: [box('R1', 'KCROLL', 'MR01', 30), box('R2', 'KCROLL', 'MR01', 31), box('R3', 'KCROLL', 'MR01', 29)], batch: [], whyRows: [] };
var R2 = { so: '6002', soItems: [item('000010', 'KCROLL', 5, 'ROL')], candidates: [box('R1', 'KCROLL', 'MR01', 30), box('R2', 'KCROLL', 'MR01', 31), box('R3', 'KCROLL', 'MR01', 29)], batch: [], whyRows: [] };
m.setCombo({ orders: [R1, R2], seq: 0 });
m.add('R1'); m.add('R2'); m.add('R3');
t('rolls count as one each; order caps at its quantity', R1.batch.length === 2 && R2.batch.length === 1);
m.whole('6002', 'MR01');
t('whole lot does not steal boxes from the other order', R2.batch.length === 1 && R1.batch.length === 2 && /already scanned onto another order/.test(m.status()));
R1.batch.pop();
m.whole('6002', 'MR01');
t('whole lot picks up a freed box', R2.batch.length === 2);
m.add('ZZZ');
t('unknown box refused', /not an available candidate/.test(m.status()));

console.log(fails ? fails + ' FAILURE(S)' : 'ALL PASS');
process.exit(fails ? 1 : 0);
