sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/Dialog",
    "sap/m/Button",
    "sap/m/Input",
    "sap/m/Label",
    "sap/ui/layout/form/SimpleForm",
    "sap/m/SelectDialog",
    "sap/m/StandardListItem",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator"
], function (Controller, MessageToast, MessageBox, Dialog, Button, Input, Label, SimpleForm, SelectDialog, StandardListItem, Filter, FilterOperator) {
    "use strict";

    // Fully-qualified action namespace from the activated OData V4 service
    // metadata (e.g. "com.sap.gateway.srvd.zui_mtos_process.v0001"). Fill the
    // value once the service binding is created in ADT.
    var SERVICE_NS = "com.sap.gateway.srvd.zui_mtos_process.v0001";
    var ENTITY_SET = "MtosStock";

    // Project selected rows down to EACH action's _Item contract — convertToMts takes
    // ZD_MtoMtsItem (the full stock line), createPhysInvDoc takes ZD_PhysInvItem
    // (material; batch/HU are not carried by this worklist's rows and post as initial,
    // exactly as before). getObject() ships every column + OData annotations otherwise.
    var ITEM_PROJECT = {
        convertToMts: function (o) { return { Material: o.Material, Plant: o.Plant,
            SalesOrder: o.SalesOrder, SalesOrderItem: o.SalesOrderItem,
            Quantity: o.Quantity, BaseUnit: o.BaseUnit }; },
        createPhysInvDoc: function (o) { return { Material: o.Material }; }
    };

    var FILTER_FIELDS = [{ name: "CompanyCode", op: "EQ" }, { name: "Plant", op: "EQ" }, { name: "Material", op: "Contains" }, { name: "SalesOrder", op: "Contains" }];

    return Controller.extend("kejriwal.pp.mtosprocess.controller.Worklist", {

        /** Open a Sort dialog built generically from the table columns. */
        onOpenSort: function () {
            var oTable = this.byId("table") || this.byId("tbl");
            if (!oTable) { return; }
            var that = this;
            sap.ui.require(["sap/m/ViewSettingsDialog", "sap/m/ViewSettingsItem", "sap/ui/model/Sorter"], function (VSD, VSI, Sorter) {
                if (!that._oSortDialog) {
                    var oInfo = oTable.getBindingInfo("items");
                    var aCells = oInfo ? oInfo.template.getCells() : [];
                    var oVSD = new VSD({
                        confirm: function (oEvt) {
                            var oItem = oEvt.getParameter("sortItem"), bDesc = oEvt.getParameter("sortDescending");
                            var oBinding = oTable.getBinding("items");
                            if (oItem && oBinding) { oBinding.sort(new Sorter(oItem.getKey(), bDesc)); }
                        }
                    });
                    oTable.getColumns().forEach(function (oCol, i) {
                        var oHdr = oCol.getHeader();
                        var sLabel = (oHdr && oHdr.getText) ? oHdr.getText() : ("Column " + (i + 1));
                        var oCell = aCells[i], sPath = "";
                        if (oCell) {
                            var b = oCell.getBindingInfo("text") || oCell.getBindingInfo("number") || oCell.getBindingInfo("value");
                            if (b && b.parts && b.parts[0]) { sPath = b.parts[0].path; }
                        }
                        if (sPath) { oVSD.addSortItem(new VSI({ key: sPath, text: sLabel })); }
                    });
                    that._oSortDialog = oVSD;
                    that.getView().addDependent(oVSD);
                }
                that._oSortDialog.open();
            });
        },


        /** Export current table rows to Excel (.xlsx). Generic - reads the table's
         *  columns + cell binding paths and exports the loaded/filtered rows. */
        onExportExcel: function () {
            var oTable = this.byId("table") || this.byId("tbl");
            if (!oTable) { return; }
            var oInfo = oTable.getBindingInfo("items"), oBinding = oTable.getBinding("items");
            if (!oInfo || !oBinding) { return; }
            var aCells = oInfo.template.getCells(), aCols = [];
            oTable.getColumns().forEach(function (oCol, i) {
                var oHdr = oCol.getHeader();
                var sLabel = (oHdr && oHdr.getText) ? oHdr.getText() : ("Column " + (i + 1));
                var oCell = aCells[i], sPath = "";
                if (oCell) {
                    var b = oCell.getBindingInfo("text") || oCell.getBindingInfo("number") || oCell.getBindingInfo("value");
                    if (b && b.parts && b.parts[0]) { sPath = b.parts[0].path; }
                }
                if (sPath) { aCols.push({ label: sLabel, property: sPath, width: 18 }); }
            });
            var aData = (oBinding.getContexts() || []).map(function (c) { return c.getObject(); });
            if (!aData.length) {
                sap.ui.require(["sap/m/MessageToast"], function (MT) { MT.show("No data to export - run a search first."); });
                return;
            }
            var sName = "Export";
            try { sName = this.getOwnerComponent().getModel("i18n").getResourceBundle().getText("appTitle") || "Export"; } catch (e) {}
            var oSheet = new sap.ui.export.Spreadsheet({ workbook: { columns: aCols }, dataSource: aData, fileName: sName + ".xlsx" });
            oSheet.build().finally(function () { oSheet.destroy(); });
        },


        onInit: function () {
            this.oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
        },

        onConvertToMts: function () {
            this._runAction("convertToMts", []);
        },

        onCreatePhysInvDoc: function () {
            this._runAction("createPhysInvDoc", []);
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

        /** F4 value help for the Plant filter. */
        onCompanyCodeVH: function (oEvt) { this._openValueHelp(oEvt.getSource(), "/CompanyVH", "CompanyCode", "CompanyCodeName", "Select Company"); },

        onPlantVH: function (oEvt) { this._openValueHelp(oEvt.getSource(), "/PlantVH", "Plant", "PlantName", "Select Plant"); },

        /** F4 value help for the Material filter. */
        onMaterialVH: function (oEvt) { this._openValueHelp(oEvt.getSource(), "/ProductVH", "Product", "ProductExternalID", "Select Material"); },

        /** F4 value help for the SalesOrder filter. */
        onSalesOrderVH: function (oEvt) { this._openValueHelp(oEvt.getSource(), "/SalesOrderVH", "SalesOrder", "", "Select Sales Order"); },

        /** Generic F4: SelectDialog over a value-help entity set on the app's
         *  OData V4 model, filter by typed value, write the picked key back. */
        _openValueHelp: function (oInput, sPath, sKeyField, sDescField, sTitle) {
            var oView = this.getView();
            var oDialog = new SelectDialog({
                title: sTitle, growing: true, growingThreshold: 50, rememberSelections: false,
                items: { path: sPath, template: new StandardListItem({
                    title: "{" + sKeyField + "}",
                    description: sDescField ? "{" + sDescField + "}" : undefined }) },
                liveChange: function (oE) { var v = oE.getParameter("value") || "";
                    oE.getSource().getBinding("items").filter(v ? new Filter(sKeyField, FilterOperator.Contains, v) : []); },
                search: function (oE) { var v = oE.getParameter("value") || "";
                    oE.getSource().getBinding("items").filter(v ? new Filter(sKeyField, FilterOperator.Contains, v) : []); },
                confirm: function (oE) { var oItem = oE.getParameter("selectedItem"); if (oItem) { oInput.setValue(oItem.getTitle()); } },
                cancel: function () { }
            });
            oView.addDependent(oDialog);
            oDialog.setModel(oView.getModel());
            oDialog.open();
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
