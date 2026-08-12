sap.ui.define([
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (MessageToast, MessageBox) {
    "use strict";

    // Static bulk RAP actions on the entity set, taking the selected rows as _Item -
    // ported from the freestyle Batch Status app. `this` is the FE ExtensionAPI.
    var SERVICE_NS = "com.sap.gateway.srvd.zui_batch_status.v0001";
    var ENTITY_SET = "Batch";

    function project(o) { return { Material: o.Material, Plant: o.Plant, Batch: o.Batch }; }

    function run(oExtAPI, sAction) {
        var aCtx = oExtAPI.getSelectedContexts && oExtAPI.getSelectedContexts();
        if (!aCtx || !aCtx.length) { MessageToast.show("Select at least one row."); return; }
        var oBinding = aCtx[0].getBinding();
        var oModel = aCtx[0].getModel();
        var aRows = aCtx.map(function (c) { return project(c.getObject()); });
        var oOp = oModel.bindContext("/" + ENTITY_SET + "/" + SERVICE_NS + "." + sAction + "(...)");
        oOp.setParameter("_Item", aRows);
        oOp.invoke().then(function () {
            var oRes = (oOp.getBoundContext() && oOp.getBoundContext().getObject()) || {};
            MessageToast.show(oRes.Message || (sAction + " completed"));
            if (oBinding && oBinding.refresh) { oBinding.refresh(); }
        }, function (oError) {
            MessageBox.error((oError && oError.message) || (sAction + " failed"));
        });
    }

    return {
        onCloseBatch:  function () { run(this, "closeBatch"); },
        onDeleteBatch: function () { run(this, "deleteBatch"); }
    };
});
