sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (Controller, JSONModel, Filter, FilterOperator, MessageToast, MessageBox) {
    "use strict";

    // The OData V4 service namespace the bound action is qualified with. After the
    // service binding is created in ADT, set this to the service definition name
    // (e.g. "com.kejriwal.zui_contract_batch") so the action path resolves.
    var SERVICE_NS = "com.sap.gateway.srvd.zui_contract_batch.v0001";
    var ENTITY_SET = "/ContractItem";

    return Controller.extend("kejriwal.sd.contractbatchupdate.controller.Main", {

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
            this.getView().setModel(new JSONModel({
                "contract": "40000123",
                "massBatch": "",
                "dirtyCount": 0,
                "items": [
                    {
                        "ContractItem": "10",
                        "Material": "FG-YARN-3040",
                        "MaterialDescription": "Combed Yarn 30s",
                        "CurrentBatch": "B0001",
                        "NewBatch": ""
                    },
                    {
                        "ContractItem": "20",
                        "Material": "FG-YARN-3041",
                        "MaterialDescription": "Combed Yarn 30s Slub",
                        "CurrentBatch": "B0002",
                        "NewBatch": ""
                    },
                    {
                        "ContractItem": "30",
                        "Material": "FG-FABRIC-220",
                        "MaterialDescription": "Single Jersey 220 GSM",
                        "CurrentBatch": "B0107",
                        "NewBatch": ""
                    },
                    {
                        "ContractItem": "40",
                        "Material": "FG-FABRIC-180",
                        "MaterialDescription": "Pique 180 GSM",
                        "CurrentBatch": "B0112",
                        "NewBatch": ""
                    }
                ]
            }), "ui");
        },

        /**
         * Load the items of the entered sales contract.
         *
         * Replace the TODO read with an OData call to the contract-items entity
         * filtered by the contract number, mapping the rows into /items.
         */
        onLoadContract: function () {
            var oModel = this.getView().getModel("ui");
            var sContract = (oModel.getProperty("/contract") || "").trim();
            if (!sContract) {
                MessageToast.show(this._text("contractRequired"));
                return;
            }
            oModel.setProperty("/items", []);
            oModel.setProperty("/dirtyCount", 0);

            var that = this;
            var oODataModel = this.getView().getModel();   // OData V4 default model
            // Explicit $select: autoExpandSelect can't derive one for a control-less binding,
            // so without it the request returns EVERY property of every item row.
            var oList = oODataModel.bindList(ENTITY_SET, undefined, undefined, [
                new Filter("SalesContract", FilterOperator.EQ, sContract)
            ], { $select: "SalesContract,ContractItem,Material,MaterialDescription,CurrentBatch,Plant" });
            oList.requestContexts(0, 1000).then(function (aContexts) {
                if (!aContexts.length) {
                    MessageToast.show(that._text("contractEmpty", [sContract]));
                    return;
                }
                var aItems = aContexts.map(function (oCtx) {
                    var o = oCtx.getObject();
                    return {
                        SalesContract: o.SalesContract,
                        ContractItem: o.ContractItem,
                        Material: o.Material,
                        MaterialDescription: o.MaterialDescription || "",
                        CurrentBatch: o.CurrentBatch || "",
                        NewBatch: "",
                        Plant: o.Plant || ""
                    };
                });
                oModel.setProperty("/items", aItems);
                that._recalcDirty();
                MessageToast.show(that._text("contractLoaded", [aItems.length, sContract]));
            }).catch(function (oErr) {
                MessageBox.error(that._text("loadFailed", [sContract, (oErr && oErr.message) || ""]));
            });
        },

        /** Apply the mass batch value to all selected rows. */
        onApplyToSelected: function () {
            var oModel = this.getView().getModel("ui");
            var sBatch = (oModel.getProperty("/massBatch") || "").trim();
            if (!sBatch) {
                MessageToast.show(this._text("massBatchEmpty"));
                return;
            }
            var aSelected = this.byId("itemsTable").getSelectedItems();
            if (!aSelected.length) {
                MessageToast.show(this._text("noSelection"));
                return;
            }
            aSelected.forEach(function (oItem) {
                var sPath = oItem.getBindingContext("ui").getPath();
                oModel.setProperty(sPath + "/NewBatch", sBatch);
            });
            this._recalcDirty();
            MessageToast.show(this._text("appliedTo", [aSelected.length]));
        },

        onBatchChange: function () {
            this._recalcDirty();
        },

        /**
         * Persist the new batch assignments in one round trip.
         *
         * Replace the TODO with the backend update: a RAP mass-update action over
         * (contract, item, batch), or per-row PATCH submitted as one batch.
         */
        onUpdateBatches: function () {
            var aChanged = this._changedItems();
            if (!aChanged.length) {
                MessageToast.show(this._text("noChanges"));
                return;
            }
            var sContract = (this.getView().getModel("ui").getProperty("/contract") || "").trim();
            var oModel = this.getView().getModel();   // OData V4 default model
            var oAction = oModel.bindContext(ENTITY_SET + "/" + SERVICE_NS + ".updateBatches(...)");
            oAction.setParameter("SalesContract", sContract);
            oAction.setParameter("_Item", aChanged.map(function (o) {
                return {
                    ContractItem: o.ContractItem,
                    NewBatch: o.NewBatch
                };
            }));

            var that = this;
            oAction.invoke().then(function () {
                var oResult = oAction.getBoundContext().getObject();
                MessageBox.success(that._text("updateDone", [
                    (oResult && oResult.ItemsUpdated) || 0,
                    (oResult && oResult.Message) || ""
                ]));
                that.onLoadContract();   // refresh from the backend
            }).catch(function (oErr) {
                MessageBox.error(that._text("updateFailed", [(oErr && oErr.message) || ""]));
            });
        },

        _changedItems: function () {
            return this.getView().getModel("ui").getProperty("/items").filter(function (o) {
                return o.NewBatch && o.NewBatch !== o.CurrentBatch;
            });
        },

        _recalcDirty: function () {
            this.getView().getModel("ui").setProperty("/dirtyCount", this._changedItems().length);
        },

        _text: function (sKey, aArgs) {
            return this.getView().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
        }
    });
});
