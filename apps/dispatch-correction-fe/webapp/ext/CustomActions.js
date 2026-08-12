sap.ui.define([
    "sap/m/MessageToast", "sap/m/MessageBox", "sap/m/Dialog", "sap/m/Button",
    "sap/m/Input", "sap/m/Label", "sap/ui/layout/form/SimpleForm"
], function (MessageToast, MessageBox, Dialog, Button, Input, Label, SimpleForm) {
    "use strict";
    var SERVICE_NS = "com.sap.gateway.srvd.zui_dispatch_correction.v0001";
    var ENTITY_SET = "DispatchBox";
    var PARAMS = [
        { name: "NewSalesOrder", label: "New Sales Order" },
        { name: "NewSalesOrderItem", label: "New Item" },
        { name: "NewStatus", label: "New Status" }
    ];
    function invoke(oExtAPI, oParams) {
        var aCtx = oExtAPI.getSelectedContexts && oExtAPI.getSelectedContexts();
        if (!aCtx || !aCtx.length) { MessageToast.show("Select at least one row."); return; }
        var oBinding = aCtx[0].getBinding(), oModel = aCtx[0].getModel();
        var aRows = aCtx.map(function (c) { return { BoxNumber: c.getObject().BoxNumber }; });
        var oOp = oModel.bindContext("/" + ENTITY_SET + "/" + SERVICE_NS + ".correctDispatch(...)");
        Object.keys(oParams).forEach(function (k) { oOp.setParameter(k, oParams[k]); });
        oOp.setParameter("_Item", aRows);
        oOp.invoke().then(function () {
            var oRes = (oOp.getBoundContext() && oOp.getBoundContext().getObject()) || {};
            MessageToast.show(oRes.Message || "Correction completed");
            if (oBinding && oBinding.refresh) { oBinding.refresh(); }
        }, function (oError) { MessageBox.error((oError && oError.message) || "Correction failed"); });
    }
    return {
        onCorrectDispatch: function () {
            var oExtAPI = this;
            var aCtx = oExtAPI.getSelectedContexts && oExtAPI.getSelectedContexts();
            if (!aCtx || !aCtx.length) { MessageToast.show("Select at least one row."); return; }
            var oForm = new SimpleForm({ editable: true }), mInputs = {};
            PARAMS.forEach(function (p) { oForm.addContent(new Label({ text: p.label })); var oI = new Input(); mInputs[p.name] = oI; oForm.addContent(oI); });
            var oDialog = new Dialog({
                title: "Correct Dispatch", content: [oForm],
                beginButton: new Button({ text: "OK", type: "Emphasized", press: function () {
                    var oParams = {}; Object.keys(mInputs).forEach(function (k) { oParams[k] = mInputs[k].getValue(); });
                    oDialog.close(); invoke(oExtAPI, oParams);
                } }),
                endButton: new Button({ text: "Cancel", press: function () { oDialog.close(); } }),
                afterClose: function () { oDialog.destroy(); }
            });
            oDialog.open();
        }
    };
});
