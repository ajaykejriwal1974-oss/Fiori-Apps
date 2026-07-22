sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (Controller, MessageToast, MessageBox) {
    "use strict";

    // Fully-qualified action namespace from the activated OData V4 service
    // metadata (e.g. "com.sap.gateway.srvd.zui_packing_list.v0001"). Fill once
    // the service binding is created in ADT.
    var SERVICE_NS = "REPLACE_WITH_SERVICE_NAMESPACE";
    var ENTITY_SET = "PackingList";

    return Controller.extend("kejriwal.sd.packinglist.controller.Worklist", {

        onInit: function () {
            this.oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
        },

        onCreate: function () { this._runAction("createPackingList"); },
        onChange: function () { this._runAction("changePackingList"); },

        onDelete: function () {
            var that = this;
            MessageBox.confirm(this.oBundle.getText("confirmDelete"), {
                onClose: function (sAction) {
                    if (sAction === MessageBox.Action.OK) { that._runAction("deletePackingList"); }
                }
            });
        },

        /** Collect the selected boxes, build the flat import, invoke the action. */
        _runAction: function (sAction) {
            var aItems = this.byId("table").getSelectedItems();
            if (!aItems.length) {
                MessageToast.show(this.oBundle.getText("selectAtLeastOne"));
                return;
            }
            var aRows = aItems.map(function (oItem) { return oItem.getBindingContext().getObject(); });
            var oFirst = aRows[0];
            var oParams = {
                SalesOrder:     oFirst.SalesOrder,
                SalesOrderItem: oFirst.SalesOrderItem,
                PackListItem:   oFirst.PackListItem,
                Plant:          oFirst.Plant,
                Status:         oFirst.Status,
                // BoxList = 'BOX1;BOX2;BOX3' — same convention as dispatch-correction
                BoxList:        aRows.map(function (r) { return r.BoxNumber; }).join(";")
            };
            this._invoke(sAction, oParams);
        },

        /**
         * Invoke the RAP static action via OData V4: bind the operation on the
         * entity set, set the flat parameters, execute, surface the result Message.
         */
        _invoke: function (sAction, oParams) {
            var that = this;
            var oModel = this.getView().getModel();
            var oOperation = oModel.bindContext("/" + ENTITY_SET + "/" + SERVICE_NS + "." + sAction + "(...)");
            Object.keys(oParams).forEach(function (k) { oOperation.setParameter(k, oParams[k]); });
            oOperation.invoke().then(function () {
                var oRes = oOperation.getBoundContext().getObject() || {};
                MessageToast.show(oRes.Message || that.oBundle.getText("actionDone", [sAction]));
                that.byId("table").getBinding("items").refresh();
            }, function (oError) {
                MessageBox.error((oError && oError.message) || that.oBundle.getText("actionFailed", [sAction]));
            });
        }
    });
});
