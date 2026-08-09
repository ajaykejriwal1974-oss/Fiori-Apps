sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/Dialog",
    "sap/m/Button",
    "sap/m/Input",
    "sap/m/Label",
    "sap/ui/layout/form/SimpleForm"
], function (Controller, MessageToast, MessageBox, Dialog, Button, Input, Label, SimpleForm) {
    "use strict";

    // Fully-qualified action namespace from the activated OData V4 service metadata.
    var SERVICE_NS = "com.sap.gateway.srvd.zui_packing_list.v0001";

    return Controller.extend("kejriwal.sd.packinglist.controller.Worklist", {

        onInit: function () {
            this.oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
        },

        onCreate: function () { this._promptAndAssign("createPackingList"); },
        onChange: function () { this._promptAndAssign("changePackingList"); },

        onDelete: function () {
            var that = this;
            var aContexts = this._selectedContexts();
            if (!aContexts.length) { MessageToast.show(this.oBundle.getText("selectAtLeastOne")); return; }
            MessageBox.confirm(this.oBundle.getText("confirmDelete"), {
                onClose: function (sAction) {
                    if (sAction === MessageBox.Action.OK) {
                        that._runInstanceAction("deletePackingList", aContexts, {});
                    }
                }
            });
        },

        /** Selected table rows -> their OData V4 binding contexts. */
        _selectedContexts: function () {
            return this.byId("table").getSelectedItems().map(function (oItem) {
                return oItem.getBindingContext();
            });
        },

        /** Ask for the assignment values, then run the instance action on the selected boxes. */
        _promptAndAssign: function (sAction) {
            var that = this;
            var aContexts = this._selectedContexts();
            if (!aContexts.length) { MessageToast.show(this.oBundle.getText("selectAtLeastOne")); return; }

            // pre-fill from the first selected row
            var oFirst = aContexts[0].getObject();
            var oInSO   = new Input({ value: oFirst.SalesOrder });
            var oInItem = new Input({ value: oFirst.SalesOrderItem });
            var oInPkl  = new Input({ value: oFirst.PackListItem === "0" ? "" : oFirst.PackListItem });

            var oForm = new SimpleForm({ editable: true, content: [
                new Label({ text: this.oBundle.getText("colSalesOrder") }),     oInSO,
                new Label({ text: this.oBundle.getText("colSalesOrderItem") }), oInItem,
                new Label({ text: this.oBundle.getText("colPackListItem") }),   oInPkl
            ] });

            var oDialog = new Dialog({
                title: this.oBundle.getText("act" + sAction),
                content: [oForm],
                beginButton: new Button({
                    text: "OK", type: "Emphasized",
                    press: function () {
                        var oParams = {
                            SalesOrder:     oInSO.getValue(),
                            SalesOrderItem: oInItem.getValue() || "0",
                            PackListItem:   oInPkl.getValue()
                        };
                        oDialog.close();
                        that._runInstanceAction(sAction, aContexts, oParams);
                    }
                }),
                endButton: new Button({ text: "Cancel", press: function () { oDialog.close(); } }),
                afterClose: function () { oDialog.destroy(); }
            });
            this.getView().addDependent(oDialog);
            oDialog.open();
        },

        /**
         * Invoke an INSTANCE action once per selected context (bound to the box),
         * then report how many succeeded and refresh the list.
         */
        _runInstanceAction: function (sAction, aContexts, oParams) {
            var that = this;
            var oModel = this.getView().getModel();
            var aPromises = aContexts.map(function (oCtx) {
                var oOp = oModel.bindContext(SERVICE_NS + "." + sAction + "(...)", oCtx);
                Object.keys(oParams).forEach(function (k) { oOp.setParameter(k, oParams[k]); });
                return oOp.invoke().then(function () {
                    return oOp.getBoundContext().getObject() || {};
                });
            });
            Promise.all(aPromises).then(function (aResults) {
                var iOk = aResults.reduce(function (n, r) { return n + (r.BoxesAffected || 0); }, 0);
                MessageToast.show(that.oBundle.getText("actionDone", [iOk]));
                that.byId("table").getBinding("items").refresh();
            }).catch(function (oError) {
                MessageBox.error((oError && oError.message) || that.oBundle.getText("actionFailed", [sAction]));
            });
        }
    });
});
