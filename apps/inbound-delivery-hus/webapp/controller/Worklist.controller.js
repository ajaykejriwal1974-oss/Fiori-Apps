sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/Dialog",
    "sap/m/Button",
    "sap/m/Input",
    "sap/m/Label",
    "sap/ui/layout/form/SimpleForm",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator"
], function (Controller, MessageToast, MessageBox, Dialog, Button, Input, Label, SimpleForm, Filter, FilterOperator) {
    "use strict";

    // Fully-qualified action namespace from the activated OData V4 service
    // metadata (e.g. "com.sap.gateway.srvd.zui_hu_inbound.v0001"). Fill the
    // value once the service binding is created in ADT.
    var SERVICE_NS = "com.sap.gateway.srvd.zui_hu_inbound.v0001";
    var ENTITY_SET = "InboundHu";

    // Project selected rows down to the action's _Item contract (ZD_InbGrHu:
    // HandlingUnit only) — getObject() ships every column + OData annotations otherwise.
    var ITEM_PROJECT = {
        postInboundGr: function (o) { return { HandlingUnit: o.HandlingUnit }; }
    };

    var FILTER_FIELDS = [{ name: "InboundDelivery", op: "Contains" }, { name: "HandlingUnit", op: "Contains" }];

    return Controller.extend("kejriwal.mm.inboundhus.controller.Worklist", {

        onInit: function () {
            this.oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
        },

        onPostInboundGr: function () {
            this._runAction("postInboundGr", []);
        },

        /** Apply the filter-bar values and resume the (suspended) table binding — the
         *  worklist no longer downloads the whole entity set on first paint. */
        onFilterSearch: function () {
            var aFilters = [];
            FILTER_FIELDS.forEach(function (f) {
                var v = (this.byId("inp" + f.name).getValue() || "").trim();
                if (v) aFilters.push(new Filter(f.name, FilterOperator[f.op], v));
            }, this);
            var oBinding = this.byId("table").getBinding("items");
            oBinding.filter(aFilters);
            if (oBinding.isSuspended()) { oBinding.resume(); }
        },

        /** Read the selection, collect any header params, then invoke the action. */
        _runAction: function (sAction, aParamDefs) {
            var aItems = this.byId("table").getSelectedItems();
            if (!aItems.length) {
                MessageToast.show(this.oBundle.getText("selectAtLeastOne"));
                return;
            }
            var fnProj = ITEM_PROJECT[sAction];
            var aRows = aItems.map(function (oItem) {
                var o = oItem.getBindingContext().getObject();
                return fnProj ? fnProj(o) : o;
            });
            if (aParamDefs.length) {
                this._promptParams(sAction, aParamDefs, aRows);
            } else {
                this._invoke(sAction, {}, aRows);
            }
        },

        /** Build a small dialog to capture the action's header parameter(s). */
        _promptParams: function (sAction, aParamDefs, aRows) {
            var that = this;
            var oForm = new SimpleForm({ editable: true });
            var mInputs = {};
            aParamDefs.forEach(function (p) {
                oForm.addContent(new Label({ text: p.label }));
                var oInp = new Input();
                mInputs[p.name] = oInp;
                oForm.addContent(oInp);
            });
            var oDialog = new Dialog({
                title: that.oBundle.getText("act" + sAction),
                content: [oForm],
                beginButton: new Button({
                    text: "OK",
                    type: "Emphasized",
                    press: function () {
                        var oParams = {};
                        Object.keys(mInputs).forEach(function (k) { oParams[k] = mInputs[k].getValue(); });
                        oDialog.close();
                        that._invoke(sAction, oParams, aRows);
                    }
                }),
                endButton: new Button({ text: "Cancel", press: function () { oDialog.close(); } }),
                afterClose: function () { oDialog.destroy(); }
            });
            that.getView().addDependent(oDialog);
            oDialog.open();
        },

        /**
         * Invoke the RAP static action via OData V4: bind the operation, set the
         * header params + the selected rows as the _Item composition, execute.
         * NOTE: composition actions (pack / dispatch / GR) take _Item; a flat
         * per-row action should instead be invoked once per selected row with its
         * key fields - adjust to the activated service metadata.
         */
        _invoke: function (sAction, oParams, aRows) {
            var that = this;
            var oModel = this.getView().getModel();
            var oOperation = oModel.bindContext("/" + ENTITY_SET + "/" + SERVICE_NS + "." + sAction + "(...)");
            Object.keys(oParams).forEach(function (k) { oOperation.setParameter(k, oParams[k]); });
            oOperation.setParameter("_Item", aRows);
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
