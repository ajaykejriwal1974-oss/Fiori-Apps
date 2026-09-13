sap.ui.define([
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (MessageToast, MessageBox) {
    "use strict";

    // Static RAP actions on the entity set. `this` is the FE ExtensionAPI.
    //
    // The signature in the activated service is FLAT - Material, Plant and Batch
    // as three scalars, one batch per call. The earlier version passed the whole
    // selection as an `_Item` collection, which the service does not declare, so
    // every call failed before it reached the handler. Now: one invocation per
    // selected row, run in sequence so a failure part-way through still reports
    // which batches went through.
    var SERVICE_NS = "com.sap.gateway.srvd.zui_batch_status.v0001";
    var ENTITY_SET = "Batch";

    function project(o) { return { Material: o.Material, Plant: o.Plant, Batch: o.Batch }; }

    function run(oExtAPI, sAction) {
        var aCtx = oExtAPI.getSelectedContexts && oExtAPI.getSelectedContexts();
        if (!aCtx || !aCtx.length) { MessageToast.show("Select at least one row."); return; }

        var oBinding = aCtx[0].getBinding();
        var oModel = aCtx[0].getModel();
        var aRows = aCtx.map(function (c) { return project(c.getObject()); });
        var iOk = 0;
        var aFailed = [];

        aRows.reduce(function (pPrev, oRow) {
            return pPrev.then(function () {
                var oOp = oModel.bindContext("/" + ENTITY_SET + "/" + SERVICE_NS + "." + sAction + "(...)");
                Object.keys(oRow).forEach(function (k) { oOp.setParameter(k, oRow[k]); });
                return oOp.invoke().then(function () {
                    iOk = iOk + 1;
                }, function (oError) {
                    aFailed.push(oRow.Batch + " - " + ((oError && oError.message) || "failed"));
                });
            });
        }, Promise.resolve()).then(function () {
            if (oBinding && oBinding.refresh) { oBinding.refresh(); }
            if (!aFailed.length) {
                MessageToast.show(sAction + ": " + iOk + " batch(es) processed.");
            } else {
                MessageBox.error(
                    sAction + ": " + iOk + " succeeded, " + aFailed.length + " failed.",
                    { details: aFailed.join("\n") });
            }
        });
    }

    // Close Batch is deliberately switched off - see the note in the freestyle
    // app's Worklist controller. It set BAPIBATCHATT-AVAILABLE, which is the
    // availability DATE (data element VERAB), not a status flag, so it wrote 'X'
    // into a date and closed nothing.
    var CLOSE_OFF = "Close Batch is switched off. It called BAPI_BATCH_CHANGE with the AVAILABLE "
        + "field, which is the batch availability date (VERAB), not a status flag - so it wrote "
        + "'X' into a date instead of closing anything. Decide what closing an MCHA batch should "
        + "mean before this is re-enabled. To close a WIP batch, use the WIP Batch Close app.";

    return {
        onCloseBatch:  function () { MessageBox.warning(CLOSE_OFF); },
        onDeleteBatch: function () { run(this, "deleteBatch"); }
    };
});
