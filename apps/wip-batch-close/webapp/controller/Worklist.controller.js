sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/Dialog",
    "sap/m/Button",
    "sap/m/Label",
    "sap/m/Input",
    "sap/m/DatePicker",
    "sap/ui/layout/form/SimpleForm",
    "sap/m/SelectDialog",
    "sap/ui/model/Sorter",
    "sap/m/StandardListItem",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator"
], function (Controller, MessageToast, MessageBox, Dialog, Button, Label, Input, DatePicker, SimpleForm, SelectDialog, Sorter, StandardListItem, Filter, FilterOperator) {
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

        /** Reset every filter field and drop the result set. */
        onClearFilters: function () {
            ["inpCompanyCode","inpPlant","inpBatch","inpProductionOrder",
             "inpGreyMaterial","inpDyedMaterial","dpBatchDateFrom","dpBatchDateTo"]
                .forEach(function (sId) { this.byId(sId).setValue(""); }, this);
            this.byId("selClosed").setSelectedKey("");
            var oBinding = this.byId("table").getBinding("items");
            if (oBinding) { oBinding.filter([]); oBinding.filter([], "Control"); }
            MessageToast.show(this.oBundle.getText("clearedFilters"));
        },

        /* ---------------------------------------------------------- value helps */

        onCompanyCodeVH: function (oEvt) { this._openValueHelp(oEvt.getSource(), "/CompanyVH", "CompanyCode", "CompanyCodeName", "Select Company Code"); },
        onPlantVH:       function (oEvt) { this._openValueHelp(oEvt.getSource(), "/PlantVH",   "Plant",       "PlantName",       "Select Plant"); },
        onGreyVH:        function (oEvt) { this._openValueHelp(oEvt.getSource(), "/ProductVH", "Product",     "ProductExternalID", "Select Grey Material"); },
        onDyedVH:        function (oEvt) { this._openValueHelp(oEvt.getSource(), "/ProductVH", "Product",     "ProductExternalID", "Select Dyed Material"); },

        // Batch and order both come from purpose-built views. The description
        // line is what makes each list usable: 131k batch numbers and 836 order
        // numbers say nothing on their own.
        onBatchVH:       function (oEvt) { this._openValueHelp(oEvt.getSource(), "/BatchVH",   "Batch",           "ProductionOrder",  "Select Batch"); },
        onOrderVH: function (oEvt) {
            // OrderVH lists only the 836 orders that actually carry WIP
            // batches, newest activity first, so the list is navigable
            // without already knowing the order number.
            this._openValueHelp(oEvt.getSource(), "/OrderVH", "ProductionOrder", {
                parts: ["Plant", "BatchCount", "FirstBatchDate", "LastBatchDate"],
                formatter: function (sPlant, iCount, sFrom, sTo) {
                    // Edm.Date arrives as "2026-03-31" in the V4 model.
                    var d = function (s) { return s ? s.split("-").reverse().join(".") : ""; };
                    var sTxt = sPlant + " \u00b7 " + iCount + (iCount === 1 ? " batch" : " batches");
                    if (!sFrom || !sTo) { return sTxt; }
                    return sTxt + " \u00b7 " + (sFrom === sTo ? d(sFrom) : d(sFrom) + " \u2013 " + d(sTo));
                }
            }, "Select Production Order", { sortField: "LastBatchDate", sortDescending: true });
        },

        // vDesc is normally an element name. It may also be a full binding-info
        // object ({parts, formatter}) for a composed subtitle - the order help
        // needs one because AUFK's KTEXT is empty system-wide, so no single
        // field says anything useful about an order.
        // oOpts.sortField applies a server-side $orderby to the list.
        _openValueHelp: function (oInput, sPath, sKeyField, vDesc, sTitle, oOpts) {
            oOpts = oOpts || {};
            var oView = this.getView();
            var fnFilter = function (oE) {
                var v = oE.getParameter("value") || "";
                oE.getSource().getBinding("items").filter(v ? new Filter(sKeyField, FilterOperator.Contains, v) : []);
            };
            var vDescBinding;
            if (typeof vDesc === "string" && vDesc) { vDescBinding = "{" + vDesc + "}"; }
            else if (vDesc) { vDescBinding = vDesc; }

            var oItems = { path: sPath, template: new StandardListItem({
                title: "{" + sKeyField + "}",
                description: vDescBinding }) };
            if (oOpts.sortField) {
                oItems.sorter = new Sorter(oOpts.sortField, !!oOpts.sortDescending);
            }

            var oDialog = new SelectDialog({
                title: sTitle, growing: true, growingThreshold: 50, rememberSelections: false,
                items: oItems,
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

        /* ------------------------------------------------------------- create */

        /**
         * Create a WIP batch - the replacement for ZBATCH01N.
         *
         * This app is freestyle, not Fiori Elements, so the createBatch action
         * on ZI_WIP_BATCH_MGMT does not surface as a toolbar button on its own.
         * The dialog below collects exactly the nine fields the module pool
         * collects before it draws a number:
         *
         *     werks aufnr bchdate lotno grey_code dye_code qty vrkme cheeses
         *
         * Nothing is validated here beyond "is it filled in". Every real check -
         * order released, BOM found, quantity ceiling, lot free, number range
         * maintained - lives in the behaviour handler, so the browser and the
         * legacy screen cannot drift apart. The handler returns the refusal as
         * a message and this dialog shows it.
         */
        onCreateBatch: function () {
            var that = this;
            var oF = {};

            function field(sKey, sPlaceholder) {
                oF[sKey] = new Input({ placeholder: sPlaceholder || "" });
                return oF[sKey];
            }

            oF.BatchDate = new DatePicker({
                valueFormat: "yyyy-MM-dd",     // Edm.Date, what the action expects
                displayFormat: "medium"
            });

            var oForm = new SimpleForm({
                editable: true,
                layout: "ResponsiveGridLayout",
                content: [
                    new Label({ text: this.oBundle.getText("cbPlant"), required: true }),
                    field("Plant"),
                    new Label({ text: this.oBundle.getText("cbProductionOrder"), required: true }),
                    field("ProductionOrder"),
                    new Label({ text: this.oBundle.getText("cbBatchDate"), required: true }),
                    oF.BatchDate,
                    new Label({ text: this.oBundle.getText("cbLotNo"), required: true }),
                    field("LotNo"),
                    new Label({ text: this.oBundle.getText("cbGreyMaterial"), required: true }),
                    field("GreyMaterial"),
                    new Label({ text: this.oBundle.getText("cbDyedMaterial"), required: true }),
                    field("DyedMaterial"),
                    new Label({ text: this.oBundle.getText("cbQuantity"), required: true }),
                    field("Quantity"),
                    new Label({ text: this.oBundle.getText("cbBatchUnit"), required: true }),
                    field("BatchUnit", "KG"),
                    new Label({ text: this.oBundle.getText("cbCheeses"), required: true }),
                    field("Cheeses")
                ]
            });

            var oDialog = new Dialog({
                title: this.oBundle.getText("createBatchTitle"),
                contentWidth: "34rem",
                content: [oForm],
                beginButton: new Button({
                    text: this.oBundle.getText("createBatchGo"),
                    type: "Emphasized",
                    press: function () {
                        var oValues = {
                            Plant:           (oF.Plant.getValue() || "").trim().toUpperCase(),
                            ProductionOrder: (oF.ProductionOrder.getValue() || "").trim(),
                            BatchDate:        oF.BatchDate.getValue() || "",
                            LotNo:           (oF.LotNo.getValue() || "").trim(),
                            GreyMaterial:    (oF.GreyMaterial.getValue() || "").trim().toUpperCase(),
                            DyedMaterial:    (oF.DyedMaterial.getValue() || "").trim().toUpperCase(),
                            Quantity:        (oF.Quantity.getValue() || "").trim(),
                            BatchUnit:       (oF.BatchUnit.getValue() || "").trim().toUpperCase(),
                            Cheeses:         (oF.Cheeses.getValue() || "").trim()
                        };
                        var aMissing = Object.keys(oValues).filter(function (k) {
                            return !oValues[k];
                        });
                        if (aMissing.length) {
                            MessageBox.error(that.oBundle.getText("createBatchMissing"));
                            return;
                        }
                        oDialog.close();
                        that._invokeCreate(oValues);
                    }
                }),
                endButton: new Button({
                    text: this.oBundle.getText("cancel"),
                    press: function () { oDialog.close(); }
                }),
                afterClose: function () { oDialog.destroy(); }
            });

            this.getView().addDependent(oDialog);
            oDialog.open();
        },

        /**
         * createBatch takes nine flat parameters rather than the (Reason,
         * BatchList) pair the close actions use, so it does not go through
         * _invoke. The batch number comes back in the result message - it is
         * drawn from number range ZPP_BTH at save time, never before, so an
         * abandoned dialog does not burn one.
         */
        _invokeCreate: function (oValues) {
            var that = this;
            var oModel = this.getView().getModel();
            var oOperation = oModel.bindContext(
                "/" + ENTITY_SET + "/" + SERVICE_NS + ".createBatch(...)");

            Object.keys(oValues).forEach(function (sKey) {
                oOperation.setParameter(sKey, oValues[sKey]);
            });

            oOperation.invoke().then(function () {
                var oRes = oOperation.getBoundContext().getObject() || {};
                var sMsg = oRes.Message || that.oBundle.getText("actionDone", ["createBatch"]);
                // The handler answers refusals through the same Message field it
                // uses for success, so treat "not created" as an error box rather
                // than dressing a refusal up as a confirmation.
                if (/not created|Enter |Invalid |not released|not found|greater than|Number range/i.test(sMsg)) {
                    MessageBox.error(sMsg);
                } else {
                    MessageBox.success(sMsg);
                    that.byId("table").getBinding("items").refresh();
                }
            }, function (oError) {
                MessageBox.error((oError && oError.message) ||
                                 that.oBundle.getText("actionFailed", ["createBatch"]));
            });
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

            // BatchList is abap.char(1333). A batch/year pair runs to about 16
            // characters, so anything past ~80 rows is cut off by the backend
            // with no error - the operator would see a success message and a
            // silently partial result. This mattered less while the handler was
            // an empty stub; now that closeBatches actually writes to
            // ZPP_BATCHN it has to be caught here.
            if (sList.length > 1333) {
                MessageBox.error(this.oBundle.getText("tooManyBatches", [aRows.length]));
                return;
            }

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
