sap.ui.define(["sap/m/MessageToast", "sap/m/MessageBox"], function (MessageToast, MessageBox) {
    "use strict";
    var SERVICE_NS = "com.sap.gateway.srvd.zui_packing_detail.v0001";
    var ENTITY_SET = "PackingItem";
    var PROJECT = {
        packItems: function (o) { return { Material: o.Material, Batch: o.Batch, Quantity: o.Quantity, Unit: o.Unit }; },
        repackItems: function (o) { return { HandlingUnitItem: o.HandlingUnitItem, Quantity: o.Quantity }; }
    };
    function run(oExtAPI, sAction) {
        var aCtx = oExtAPI.getSelectedContexts && oExtAPI.getSelectedContexts();
        if (!aCtx || !aCtx.length) { MessageToast.show("Select at least one row."); return; }
        var oBinding = aCtx[0].getBinding(), oModel = aCtx[0].getModel();
        var aRows = aCtx.map(function (c) { return PROJECT[sAction](c.getObject()); });
        var oOp = oModel.bindContext("/" + ENTITY_SET + "/" + SERVICE_NS + "." + sAction + "(...)");
        oOp.setParameter("_Item", aRows);
        oOp.invoke().then(function () {
            var oRes = (oOp.getBoundContext() && oOp.getBoundContext().getObject()) || {};
            MessageToast.show(oRes.Message || (sAction + " completed"));
            if (oBinding && oBinding.refresh) { oBinding.refresh(); }
        }, function (oError) { MessageBox.error((oError && oError.message) || (sAction + " failed")); });
    }
    return { onPackItems: function () { run(this, "packItems"); }, onRepackItems: function () { run(this, "repackItems"); } };
});
