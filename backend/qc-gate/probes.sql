-- Run these the moment ADT answers again. Each settles a field assumption the
-- order-anchored views rest on. Nothing below writes anything.
--
-- Probes 1, 2 and 3 are the ones that decide whether Grey QC can be anchored on
-- the production order at all. If ZPP_BATCHN-AUFNR is only filled after grey
-- inspection has already happened, the anchor exists but is empty at the moment
-- the technician needs it, and Grey QC has to key on the greige lot after all.

-- 1. Does QALS-CHARG actually equal ZPP_BATCHN-LOTNO? This is the only bridge
--    a greige lot has to its order. No rows here means the bridge is not real.
SELECT lot~prueflos, lot~art, lot~werk, lot~charg, lot~matnr,
       b~batchno, b~lotno, b~aufnr, b~grey_code, b~dye_code
  FROM qals AS lot
  INNER JOIN zpp_batchn AS b ON b~werks = lot~werk AND b~lotno = lot~charg
  WHERE lot~art IN ( '01', '08' )
  UP TO 20 ROWS

-- 2. Greige lots that find no batch at all - these are the ones that would show
--    OrderSource = ' ' in the app.
SELECT lot~prueflos, lot~werk, lot~charg, lot~matnr, lot~enstehdat
  FROM qals AS lot
  WHERE lot~art IN ( '01', '08' )
    AND NOT EXISTS ( SELECT * FROM zpp_batchn AS b
                       WHERE b~werks = lot~werk AND b~lotno = lot~charg )
  UP TO 20 ROWS

-- 3. How many plant batches are sitting without a production order? A large
--    share means AUFNR is assigned late and Grey QC would often open on a batch
--    that has no order yet.
SELECT werks,
       COUNT(*) AS total,
       SUM( CASE WHEN aufnr = '' THEN 1 ELSE 0 END ) AS no_order
  FROM zpp_batchn
  WHERE delind = ''
  GROUP BY werks

-- 4. Can one production order carry more than one plant batch? This decides
--    whether BatchCount is a theoretical guard or a daily occurrence.
SELECT werks, aufnr, COUNT(*) AS batches
  FROM zpp_batchn
  WHERE delind = '' AND aufnr <> ''
  GROUP BY werks, aufnr
  HAVING COUNT(*) > 1
  UP TO 20 ROWS

-- 5. Can one greige lot be split across more than one order?
SELECT werks, lotno, COUNT(*) AS batches
  FROM zpp_batchn
  WHERE delind = '' AND lotno <> ''
  GROUP BY werks, lotno
  HAVING COUNT(*) > 1
  UP TO 20 ROWS

-- 6. Can one plant batch carry more than one job card?
SELECT werks, batchno, COUNT(*) AS jobcards
  FROM zpp_jobn
  WHERE delind = ''
  GROUP BY werks, batchno
  HAVING COUNT(*) > 1
  UP TO 20 ROWS

-- 7. Do the batches of one order ever carry different units? If they do,
--    SUM( BatchQuantity ) in ZI_QC_ORDER_CONTEXT is adding unlike things.
SELECT werks, aufnr, COUNT( DISTINCT vrkme ) AS units
  FROM zpp_batchn
  WHERE delind = '' AND aufnr <> ''
  GROUP BY werks, aufnr
  HAVING COUNT( DISTINCT vrkme ) > 1
  UP TO 20 ROWS

-- 8. Field types. CHARG is CHAR 10 and AUFNR CHAR 12; if LOTNO or ZPP_BATCHN
--    AUFNR differ in type or length the joins will not activate without a cast.
SELECT tabname, fieldname, position, datatype, leng, decimals
  FROM dd03l
  WHERE tabname IN ( 'ZPP_BATCHN', 'ZPP_JOBN' )
    AND as4local = 'A'
  ORDER BY tabname, position
  UP TO 100 ROWS

-- 9. In-process lots, to confirm the native order path has data in 2002.
SELECT lot~prueflos, lot~art, lot~werk, lot~aufnr, lot~charg, lot~stat34, lot~stat35,
       b~batchno, b~lotno, j~jobno, j~dye_arbpl, j~win_arbpl
  FROM qals AS lot
  LEFT OUTER JOIN zpp_batchn AS b ON b~werks = lot~werk AND b~aufnr = lot~aufnr
  LEFT OUTER JOIN zpp_jobn   AS j ON j~werks = b~werks  AND j~batchno = b~batchno
  WHERE lot~art IN ( '03', '04' )
  UP TO 20 ROWS

-- ============================================================
-- Added 2026-08-28, after the flow was described properly:
--   order (big qty) -> batch (small qty) -> job card -> dyeing -> winding
--   -> packing, RM consumed at packing -> close WIP batch for gain/loss
-- The greige moves from the RM storage location to the production storage
-- location before dyeing. That movement, not the consumption, is the point
-- where Grey QC has to have an answer.
-- ============================================================

-- 10. Storage locations in plant 2002. Which is raw material, which is
--     production? releaseToProduction needs both.
SELECT werks, lgort, lgobe
  FROM t001l
  WHERE werks = '2002'
  ORDER BY lgort

-- 11. What movement types actually run between storage locations in 2002, and
--     between which pairs? This names the movement releaseToProduction has to
--     post, instead of assuming 311.
SELECT m~bwart, m~werks, m~lgort, m~umlgo, COUNT(*) AS moves
  FROM mseg AS m
  WHERE m~werks = '2002' AND m~bwart IN ( '311', '313', '315', '301', '321', '343' )
  GROUP BY m~bwart, m~werks, m~lgort, m~umlgo
  ORDER BY moves DESCENDING
  UP TO 30 ROWS

-- 12. Is inspection type 01 stock relevant for the greige materials? If the
--     QM inspection setup does not post to inspection stock, the usage
--     decision has no stock to release and releaseToProduction is the ONLY
--     control there is.
SELECT s~matnr, s~werks, s~art, s~aktiv, s~kzdyn, s~apa, s~insmk
  FROM qmat AS s
  WHERE s~werks = '2002'
  UP TO 30 ROWS

-- 13. THE decisive one for Post-Dyeing and Post-Winding: does QALS-CHARG hold
--     the plant batch number on an in-process lot? If yes, every lot resolves
--     its own batch. If no, the operator has to pick from the order's batches.
SELECT lot~prueflos, lot~art, lot~werk, lot~aufnr, lot~charg,
       b~batchno, b~gjahr, b~lotno, b~aufnr AS batch_order
  FROM qals AS lot
  LEFT OUTER JOIN zpp_batchn AS b ON b~werks = lot~werk AND b~batchno = lot~charg
  WHERE lot~art IN ( '03', '04' )
  UP TO 30 ROWS

-- 14. How big is the split? Batches per order, so we know whether "pick a
--     batch" means choosing from three or from forty.
SELECT werks, aufnr, COUNT(*) AS batches, SUM( cheeses ) AS cheeses
  FROM zpp_batchn
  WHERE delind = '' AND aufnr <> '' AND werks = '2002'
  GROUP BY werks, aufnr
  ORDER BY batches DESCENDING
  UP TO 20 ROWS

-- 15. The confirmation record ZCO11A writes, so confirmDyeing and
--     confirmWinding can reproduce it exactly - including what COMPONENT holds
--     for a dyeing versus a winding confirmation.
SELECT aufnr, batchno, component, qty, erdat, erzet, ernam
  FROM zpp_confirm
  ORDER BY erdat DESCENDING, erzet DESCENDING
  UP TO 30 ROWS

-- 16. Operations on a real dyeing order - does the routing carry separate
--     operations for dyeing and winding, or only one?
SELECT a~aufnr, a~werks, v~vornr, v~ltxa1, v~arbid, v~steus
  FROM afko AS a
  INNER JOIN afvc AS v ON v~aufpl = a~aufpl
  WHERE a~werks = '2002'
  ORDER BY a~aufnr DESCENDING, v~vornr
  UP TO 40 ROWS

-- 17. Where does a UD code's accept/reject valuation live? The saver currently
--     carries a hardcoded list of accepting codes, which is the same fact
--     written down in three places (ZQC-UD catalogue, Detail.controller.js,
--     lcl_pending). Find the field and the constant can be deleted.
SELECT * FROM qpac WHERE codegruppe = 'ZQC-UD' UP TO 20 ROWS

-- 18. What QAVE actually holds for a decided lot, so is_ud_accepted reads the
--     right field rather than the one I assumed.
SELECT * FROM qave UP TO 5 ROWS
