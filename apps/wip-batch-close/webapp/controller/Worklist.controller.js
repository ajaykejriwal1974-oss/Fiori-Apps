sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/Dialog",
    "sap/m/Button",
    "sap/m/Label",
    "sap/m/Input",
    "sap/ui/layout/form/SimpleForm",
    "sap/m/SelectDialog",
    "sap/m/StandardListItem",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator"
], function (Controller, MessageToast, MessageBox, Dialog, Button, Label, Input, SimpleForm, SelectDialog, StandardListItem, Filter, FilterOperator) {
    "use strict";

    // Fully-qualified action namespace from the activated OData V4 service
    // metadata. Derived from the service definition ZUI_WIP_BATCH_MGMT
    // version 0001 - verify against /$metadata once the binding is published.
    var SERVICE_NS = "com.sap.gateway.srvd.zui_wip_batch_mgmt.v0001";
    var ENTITY_SET = "WipBatch";

    var SEARCH_FIELDS = ["Batch", "ProductionOrder", "GreyMaterial", "DyedMaterial"];

    return Controller.extend("kejriwal.pp.wipbatchclose.controller.Worklist", {

        onInit: function () {
            this.oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
        },

        /* ----------------------------------------------------------- filtering */

        onFilterSearch: function () {
            var aFilters = [];
            var add = function (sId, sField, sOp) {
                var v = (this.byId(sId).getValue() || "").trim();
                if (v) { aFilters.push(new Filter(sField, FilterOperator[sOp], v)); }
            }.bind(this);

            add("inpCompanyCode",     "CompanyCode",     "EQ");
            add("inpPlant",           "Plant",           "EQ");
            add("inpBatch",           "Batch",           "Contains");
            add("inpProductionOrder", "ProductionOrder", "Contains");
            add("inpGreyMaterial",    "GreyMaterial",    "Contains");
            add("inpDyedMaterial",    "DyedMaterial",    "Contains");

            var sFrom = (this.byId("dpBatchDateFrom").getValue() || "").trim();
            var sTo   = (this.byId("dpBatchDateTo").getValue() || "").trim();
            if (sFrom && sTo) {
                aFilters.push(new Filter("BatchDate", FilterOperator.BT, sFrom, sTo));
            } else if (sFrom) {
                aFilters.push(new Filter("BatchDate", FilterOperator.GE, sFrom));
            } else if (sTo) {
                aFilters.push(new Filter("BatchDate", FilterOperator.LE, sTo));
            }

            var sStatus = this.byId("selClosed").getSelectedKey();
            if (sStatus === "OPEN") {
                aFilters.push(new Filter("Closed", FilterOperator.NE, "X"));
            } else if (sStatus === "CLOSED") {
                aFilters.push(new Filter("Closed", FilterOperator.EQ, "X"));
            }

            var oBinding = this.byId("table").getBinding("items");
            oBinding.filter(aFilters);
            if (oBinding.isSuspended()) { oBinding.resume(); }
        },

        onQuickSearch: function (oEvt) {
            var sQuery = (oEvt.getParameter("query") || oEvt.getParameter("newValue") || "").trim();
            var oBinding = this.byId("table").getBinding("items");
            if (!oBinding) { return; }
            if (!sQuery) { oBinding.filter([], "Control"); return; }
            var aOr = SEARCH_FIELDS.map(function (f) { return new Filter(f, FilterOperator.Contains, sQuery); });
            oBinding.filter(new Filter({ filters: aOr, and: false }), "Control");
        },

        /* ---------------------------------------------------------- value helps */

        onCompanyCodeVH: function (oEvt) { this._openValueHelp(oEvt.getSource(), "/CompanyVH", "CompanyCode", "CompanyCodeName", "Select Company Code"); },
        onPlantVH:       function (oEvt) { this._openValueHelp(oEvt.getSource(), "/PlantVH",   "Plant",       "PlantName",       "Select Plant"); },
        onGreyVH:        function (oEvt) { this._openValueHelp(oEvt.getSource(), "/ProductVH", "Product",     "ProductExternalID", "Select Grey Material"); },
        onDyedVH:        function (oEvt) { this._openValueHelp(oEvt.getSource(), "/ProductVH", "Product",     "ProductExternalID", "Select Dyed Material"); },

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

        /* -------------------------------------------------------------- sorting */

        onOpenSort: function () {
            var oTable = this.byId("table");
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

        /* --------------------------------------------------------------- export */

        onExportExcel: function () {
            var oTable = this.byId("table");
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
            if (!aData.length) { MessageToast.show(this.oBundle.getText("noDataToExport")); return; }
            var sName = this.oBundle.getText("appTitle") || "Export";
            var oSheet = new sap.ui.export.Spreadsheet({ workbook: { columns: aCols }, dataSource: aData, fileName: sName + ".xlsx" });
            oSheet.build().finally(function () { oSheet.destroy(); });
        },

        /* --------------------------------------------------------------- actions */

        /** Close: skip rows already closed, confirm, then invoke. No reason needed. */
        onCloseBatches: function () {
            var aRows = this._selection(function (o) { return o.Closed !== "X"; },
                                        "allAlreadyClosed", "skippedClosed");
            if (!aRows) { return; }
            var that = this;
            MessageBox.confirm(this.oBundle.getText("confirmCloseText", [aRows.rows.length]) + aRows.note, {
                title: this.oBundle.getText("confirmCloseTitle"),
                emphasizedAction: MessageBox.Action.OK,
                onClose: function (sAction) {
                    if (sAction === MessageBox.Action.OK) { that._invoke("closeBatches", "", aRows.rows); }
                }
            });
        },

        /**
         * Reopen: the destructive direction. Reopening a batch is what lets a
         * confirmation be cancelled or deducted afterwards, so the backend
         * requires a reason and so does this dialog.
         */
        onReopenBatches: function () {
            var aRows = this._selection(function (o) { return o.Closed === "X"; },
                                        "allAlreadyOpen", "skippedOpen");
            if (!aRows) { return; }
            var that = this;
            MessageBox.confirm(this.oBundle.getText("confirmReopenText", [aRows.rows.length]) + aRows.note, {
                title: this.oBundle.getText("confirmReopenTitle"),
                icon: MessageBox.Icon.WARNING,
                emphasizedAction: MessageBox.Action.OK,
                onClose: function (sAction) {
                    if (sAction === MessageBox.Action.OK) { that._promptReason(aRows.rows); }
                }
            });
        },

        /** Read the selection and drop rows the action would reject anyway. */
        _selection: function (fnKeep, sAllSkippedKey, sSkippedKey) {
            var aItems = this.byId("table").getSelectedItems();
            if (!aItems.length) {
                MessageToast.show(this.oBundle.getText("selectAtLeastOne"));
                return null;
            }
            var aAll = aItems.map(function (oItem) { return oItem.getBindingContext().getObject(); });
            var aRows = aAll.filter(fnKeep);
            if (!aRows.length) {
                MessageBox.information(this.oBundle.getText(sAllSkippedKey));
                return null;
            }
            var iSkipped = aAll.length - aRows.length;
            return {
                rows: aRows,
                note: iSkipped ? "\n" + this.oBundle.getText(sSkippedKey, [iSkipped]) : ""
            };
        },

        _promptReason: function (aRows) {
            var that = this;
            var oInp = new Input({ maxLength: 80 });
            var oForm = new SimpleForm({ editable: true, content: [
                new Label({ text: this.oBundle.getText("reasonLabel") }), oInp
            ] });
            var oDialog = new Dialog({
                title: this.oBundle.getText("actreopenBatches"),
                content: [oForm],
                beginButton: new Button({
                    text: "OK", type: "Emphasized",
                    press: function () {
                        var sReason = (oInp.getValue() || "").trim();
                        if (!sReason) {
                            oInp.setValueState("Error");
                            oInp.setValueStateText(that.oBundle.getText("reasonMissing"));
                            return;
                        }
                        oDialog.close();
                        that._invoke("reopenBatches", sReason, aRows);
                    }
                }),
                endButton: new Button({ text: "Cancel", press: function () { oDialog.close(); } }),
                afterClose: function () { oDialog.destroy(); }
            });
            this.getView().addDependent(oDialog);
            oDialog.open();
        },

        /**
         * Invoke a RAP static action via OData V4. The behaviour definition takes
         * a flat (Reason, BatchList) pair; BatchList carries 'BATCH=YEAR;...'.
         */
        _invoke: function (sAction, sReason, aRows) {
            var that = this;
            var oModel = this.getView().getModel();
            var sList = aRows.map(function (o) {
                return o.Batch + "=" + o.FiscalYear;
            }).join(";");

            var oOperation = oModel.bindContext("/" + ENTITY_SET + "/" + SERVICE_NS + "." + sAction + "(...)");
            oOperation.setParameter("Reason", sReason);
            oOperation.setParameter("BatchList", sList);
            oOperation.invoke().then(function () {
                var oRes = oOperation.getBoundContext().getObject() || {};
                MessageBox.information(oRes.Message || that.oBundle.getText("actionDone", [sAction]));
                that.byId("table").getBinding("items").refresh();
            }, function (oError) {
                MessageBox.error((oError && oError.message) || that.oBundle.getText("actionFailed", [sAction]));
            });
        }
    });
});
