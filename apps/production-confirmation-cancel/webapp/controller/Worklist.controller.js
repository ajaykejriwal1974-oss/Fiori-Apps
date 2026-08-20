sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/Dialog",
    "sap/m/Button",
    "sap/m/Label",
    "sap/m/DatePicker",
    "sap/ui/layout/form/SimpleForm",
    "sap/m/SelectDialog",
    "sap/m/StandardListItem",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator"
], function (Controller, MessageToast, MessageBox, Dialog, Button, Label, DatePicker, SimpleForm, SelectDialog, StandardListItem, Filter, FilterOperator) {
    "use strict";

    // Fully-qualified action namespace from the activated OData V4 service
    // metadata. Derived from the service definition name ZUI_PROD_CONFIRMATION
    // and version 0001 - verify against /$metadata after the binding is
    // published in ADT.
    var SERVICE_NS = "com.sap.gateway.srvd.zui_prod_confirmation.v0001";
    var ENTITY_SET = "ProdConfirmation";
    var ACTION     = "cancelConfirmations";

    var SEARCH_FIELDS = ["OrderNumber", "Material", "ConfirmationNumber"];

    return Controller.extend("kejriwal.pp.prodconfcancel.controller.Worklist", {

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

            add("inpCompanyCode",     "CompanyCode",     "EQ");
            add("inpPlant",           "Plant",           "EQ");
            add("inpOrderNumber",     "OrderNumber",     "Contains");
            add("inpOperationNumber", "OperationNumber", "EQ");
            add("inpMaterial",        "Material",        "Contains");
            add("inpCreatedBy",       "CreatedBy",       "EQ");

            var sFrom = (this.byId("dpPostingDateFrom").getValue() || "").trim();
            var sTo   = (this.byId("dpPostingDateTo").getValue() || "").trim();
            if (sFrom && sTo) {
                aFilters.push(new Filter("PostingDate", FilterOperator.BT, sFrom, sTo));
            } else if (sFrom) {
                aFilters.push(new Filter("PostingDate", FilterOperator.GE, sFrom));
            } else if (sTo) {
                aFilters.push(new Filter("PostingDate", FilterOperator.LE, sTo));
            }

            if (this.byId("cbHideCancelled").getSelected()) {
                aFilters.push(new Filter("IsCancelled", FilterOperator.EQ, ""));
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
            ["inpCompanyCode","inpPlant","inpOrderNumber","inpOperationNumber",
             "inpMaterial","inpCreatedBy","dpPostingDateFrom","dpPostingDateTo"]
                .forEach(function (sId) { this.byId(sId).setValue(""); }, this);
            this.byId("cbHideCancelled").setSelected(true);
            var oBinding = this.byId("table").getBinding("items");
            if (oBinding) { oBinding.filter([]); oBinding.filter([], "Control"); }
            MessageToast.show(this.oBundle.getText("clearedFilters"));
        },

        /* ---------------------------------------------------------- value helps */

        onCompanyCodeVH: function (oEvt) { this._openValueHelp(oEvt.getSource(), "/CompanyVH", "CompanyCode", "CompanyCodeName", "Select Company Code"); },
        onPlantVH:       function (oEvt) { this._openValueHelp(oEvt.getSource(), "/PlantVH",   "Plant",       "PlantName",       "Select Plant"); },
        onMaterialVH:    function (oEvt) { this._openValueHelp(oEvt.getSource(), "/ProductVH", "Product",     "ProductExternalID", "Select Material"); },
        onCreatedByVH:   function (oEvt) { this._openValueHelp(oEvt.getSource(), "/UserVH",    "UserID",      null,              "Select User"); },

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
            if (!aData.length) {
                MessageToast.show(this.oBundle.getText("noDataToExport"));
                return;
            }
            var sName = this.oBundle.getText("appTitle") || "Export";
            var oSheet = new sap.ui.export.Spreadsheet({ workbook: { columns: aCols }, dataSource: aData, fileName: sName + ".xlsx" });
            oSheet.build().finally(function () { oSheet.destroy(); });
        },

        /* --------------------------------------------------------------- action */

        /**
         * Cancel the selected confirmations. Already-cancelled rows are dropped
         * client-side (the backend guards them too), the user confirms the
         * destructive step, then picks an optional posting date.
         */
        onCancelConfirmations: function () {
            var aItems = this.byId("table").getSelectedItems();
            if (!aItems.length) {
                MessageToast.show(this.oBundle.getText("selectAtLeastOne"));
                return;
            }
            var aAll = aItems.map(function (oItem) { return oItem.getBindingContext().getObject(); });
            var aRows = aAll.filter(function (o) { return o.IsCancelled !== "X"; });
            var iSkipped = aAll.length - aRows.length;

            if (!aRows.length) {
                MessageBox.information(this.oBundle.getText("allAlreadyCancelled"));
                return;
            }

            var that = this;
            var sText = this.oBundle.getText("confirmText", [aRows.length]);
            if (iSkipped) { sText += "\n" + this.oBundle.getText("skippedCancelled", [iSkipped]); }

            MessageBox.confirm(sText, {
                title: this.oBundle.getText("confirmTitle"),
                icon: MessageBox.Icon.WARNING,
                emphasizedAction: MessageBox.Action.OK,
                onClose: function (sAction) {
                    if (sAction === MessageBox.Action.OK) { that._promptPostingDate(aRows); }
                }
            });
        },

        /** Small dialog for the optional posting date (blank = today on the server). */
        _promptPostingDate: function (aRows) {
            var that = this;
            var oDP = new DatePicker({ valueFormat: "yyyy-MM-dd", displayFormat: "short" });
            var oForm = new SimpleForm({ editable: true, content: [
                new Label({ text: this.oBundle.getText("postingDateLabel") }), oDP
            ] });
            var oDialog = new Dialog({
                title: this.oBundle.getText("actcancelConfirmations"),
                content: [oForm],
                beginButton: new Button({
                    text: "OK", type: "Emphasized",
                    press: function () {
                        var sDate = oDP.getValue();
                        oDialog.close();
                        that._invoke(sDate, aRows);
                    }
                }),
                endButton: new Button({ text: "Cancel", press: function () { oDialog.close(); } }),
                afterClose: function () { oDialog.destroy(); }
            });
            this.getView().addDependent(oDialog);
            oDialog.open();
        },

        /**
         * Invoke the RAP static action via OData V4.
         * The live behaviour definition takes a FLAT parameter pair
         * (PostingDate, ConfirmationList) - ConfirmationList carries
         * 'RUECK=RMZHL;RUECK=RMZHL;...'. This deliberately matches what
         * actually deploys rather than a composition (_Item) contract.
         */
        _invoke: function (sPostingDate, aRows) {
            var that = this;
            var oModel = this.getView().getModel();
            var sList = aRows.map(function (o) {
                return o.ConfirmationNumber + "=" + o.ConfirmationCounter;
            }).join(";");

            var oOperation = oModel.bindContext("/" + ENTITY_SET + "/" + SERVICE_NS + "." + ACTION + "(...)");
            oOperation.setParameter("PostingDate", sPostingDate || null);
            oOperation.setParameter("ConfirmationList", sList);
            oOperation.invoke().then(function () {
                var oRes = oOperation.getBoundContext().getObject() || {};
                MessageBox.information(oRes.Message || that.oBundle.getText("actionDone", [ACTION]));
                that.byId("table").getBinding("items").refresh();
            }, function (oError) {
                MessageBox.error((oError && oError.message) || that.oBundle.getText("actionFailed", [ACTION]));
            });
        }
    });
});
