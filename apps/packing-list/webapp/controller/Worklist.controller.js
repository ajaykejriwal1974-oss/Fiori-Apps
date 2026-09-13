sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/Dialog",
    "sap/m/Button",
    "sap/m/Input",
    "sap/m/Label",
    "sap/m/SelectDialog",
    "sap/m/StandardListItem",
    "sap/ui/layout/form/SimpleForm",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator"
], function (Controller, MessageToast, MessageBox, Dialog, Button, Input, Label, SelectDialog, StandardListItem, SimpleForm, Filter, FilterOperator) {
    "use strict";

    // Fully-qualified action namespace from the activated OData V4 service metadata.
    var SERVICE_NS = "com.sap.gateway.srvd.zui_packing_list.v0001";

    // Quick-search targets. MergeNumber is the batch - ZPP_PACK-MERGNO is typed
    // CHARG_D - and is what the dispatch desk reads off the box.
    var SEARCH_FIELDS = ["BoxNumber", "MergeNumber", "SalesOrder", "Material", "ShadeCode", "ShipToName"];

    return Controller.extend("kejriwal.sd.packinglist.controller.Worklist", {

        onInit: function () {
            this.oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
        },

        /* ----------------------------------------------------------- filtering */

        /** Apply the filter-bar values and resume the (suspended) table binding. */
        onFilterSearch: function () {
            var aFilters = [];
            var add = function (sId, sField, sOp) {
                var v = (this.byId(sId).getValue() || "").trim();
                if (v) { aFilters.push(new Filter(sField, FilterOperator[sOp], v)); }
            }.bind(this);

            add("inpPlant",            "Plant",           "EQ");
            add("inpMergeNumber",      "MergeNumber",     "EQ");
            add("inpSalesOrder",       "SalesOrder",      "Contains");
            add("inpProductionOrder",  "ProductionOrder", "Contains");
            add("inpMaterial",         "Material",        "Contains");
            add("inpShadeCode",        "ShadeCode",       "EQ");
            add("inpShipToParty",      "ShipToParty",     "EQ");
            add("inpPackListItem",     "PackListItem",    "EQ");

            var sLocExp = this.byId("selLocalExport").getSelectedKey();
            if (sLocExp) { aFilters.push(new Filter("LocalExport", FilterOperator.EQ, sLocExp)); }

            var sStatus = this.byId("selStatus").getSelectedKey();
            if (sStatus) { aFilters.push(new Filter("Status", FilterOperator.EQ, sStatus)); }

            var sFrom = (this.byId("dpPackingDateFrom").getValue() || "").trim();
            var sTo   = (this.byId("dpPackingDateTo").getValue() || "").trim();
            if (sFrom && sTo) {
                aFilters.push(new Filter("PackingDate", FilterOperator.BT, sFrom, sTo));
            } else if (sFrom) {
                aFilters.push(new Filter("PackingDate", FilterOperator.GE, sFrom));
            } else if (sTo) {
                aFilters.push(new Filter("PackingDate", FilterOperator.LE, sTo));
            }

            var oBinding = this.byId("table").getBinding("items");
            oBinding.filter(aFilters);
            if (oBinding.isSuspended()) { oBinding.resume(); }
        },

        /** Quick-search: OR-Contains across the text fields, applied as a Control
         *  filter so it narrows WITHIN the filter-bar (Application) filters. */
        onQuickSearch: function (oEvt) {
            var sQuery = (oEvt.getParameter("query") || oEvt.getParameter("newValue") || "").trim();
            var oBinding = this.byId("table").getBinding("items");
            if (!oBinding) { return; }
            if (!sQuery) { oBinding.filter([], "Control"); return; }
            var aOr = SEARCH_FIELDS.map(function (f) { return new Filter(f, FilterOperator.Contains, sQuery); });
            oBinding.filter(new Filter({ filters: aOr, and: false }), "Control");
        },

        /** Reset every filter field and collapse the result set back to nothing. */
        onClearFilters: function () {
            ["inpPlant","inpMergeNumber","inpSalesOrder","inpProductionOrder",
             "inpMaterial","inpShadeCode","inpShipToParty","inpPackListItem","dpPackingDateFrom","dpPackingDateTo"]
                .forEach(function (sId) { this.byId(sId).setValue(""); }, this);
            this.byId("selLocalExport").setSelectedKey("");
            this.byId("selStatus").setSelectedKey("");
            var oBinding = this.byId("table").getBinding("items");
            if (oBinding) { oBinding.filter([]); oBinding.filter([], "Control"); }
            MessageToast.show(this.oBundle.getText("clearedFilters"));
        },

        /* ---------------------------------------------------------- value helps */

        onPlantVH:    function (oEvt) { this._openValueHelp(oEvt.getSource(), "/PlantVH",   "Plant",   "PlantName",         "Select Plant"); },
        onBatchVH:    function (oEvt) { this._openValueHelp(oEvt.getSource(), "/BatchVH",   "Batch",   "ProductionOrder",   "Select Batch"); },
        onMaterialVH: function (oEvt) { this._openValueHelp(oEvt.getSource(), "/ProductVH", "Product", "ProductExternalID", "Select Material"); },

        /** Generic F4: SelectDialog over a value-help entity set on the app's
         *  OData V4 model, filter by typed value, write the picked key back. */
        _openValueHelp: function (oInput, sPath, sKeyField, sDescField, sTitle) {
            var oView = this.getView();
            var fnFilter = function (oE) {
                var v = oE.getParameter("value") || "";
                oE.getSource().getBinding("items").filter(v ? new Filter(sKeyField, FilterOperator.Contains, v) : []);
            };
            var oDialog = new SelectDialog({
                title: sTitle, growing: true, growingThreshold: 50, rememberSelections: false,
                items: { path: sPath, template: new StandardListItem({
                    title: "{" + sKeyField + "}",
                    description: sDescField ? "{" + sDescField + "}" : undefined }) },
                liveChange: fnFilter,
                search: fnFilter,
                confirm: function (oE) { var oItem = oE.getParameter("selectedItem"); if (oItem) { oInput.setValue(oItem.getTitle()); } },
                cancel: function () { }
            });
            oView.addDependent(oDialog);
            oDialog.setModel(oView.getModel());
            oDialog.open();
        },

        /* -------------------------------------------------------------- actions */

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
