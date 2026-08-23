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
    // (e.g. "com.kejriwal.zui_hu_goods_movement") so the action path resolves.
    var SERVICE_NS = "com.sap.gateway.srvd.zui_hu_goods_movement.v0001";
    var ENTITY_SET = "/HandlingUnitItem";

    return Controller.extend("kejriwal.mm.goodsmovementhu.controller.Main", {

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
                "header": {
                    "movementType": "311",
                    "plant": "1010",
                    "storageLocation": "0001",
                    "moveStorageLocation": "0005"
                },
                "scan": {
                    "huNumber": ""
                },
                "items": [
                    {
                        "HandlingUnit": "HU0000045123",
                        "Material": "FG-YARN-3040",
                        "MaterialDescription": "Combed Yarn 30s",
                        "Batch": "B0001",
                        "Quantity": "480",
                        "Unit": "KG"
                    },
                    {
                        "HandlingUnit": "HU0000045124",
                        "Material": "FG-YARN-3041",
                        "MaterialDescription": "Combed Yarn 30s Slub",
                        "Batch": "B0002",
                        "Quantity": "500",
                        "Unit": "KG"
                    },
                    {
                        "HandlingUnit": "HU0000045125",
                        "Material": "FG-FABRIC-220",
                        "MaterialDescription": "Single Jersey 220 GSM",
                        "Batch": "B0107",
                        "Quantity": "320",
                        "Unit": "KG"
                    }
                ]
            }), "ui");
            // O(1) duplicate-scan lookup. /items holds one row per HU *item*, so a shift
            // scanning hundreds of HUs makes a per-scan array scan O(n²) on the scan-gun path.
            this._mScannedHus = Object.create(null);
        },

        /**
         * Add the contents of a scanned handling unit / box to the worklist.
         *
         * Reads the HU contents from the backend HU API and appends each item.
         * Replace the TODO read with a real OData call, e.g.:
         *   oModel.bindList("/HandlingUnitItem", undefined, undefined,
         *       [new Filter("HandlingUnit", "EQ", sHu)]).requestContexts()
         * then map the returned objects into the local /items array.
         */
        onScanHu: function () {
            var oUiModel = this.getView().getModel("ui");
            var sHu = (oUiModel.getProperty("/scan/huNumber") || "").trim();
            if (!sHu) {
                MessageToast.show(this._text("scanEmpty"));
                return;
            }
            if (this._huAlreadyAdded(sHu)) {
                MessageToast.show(this._text("huAlready", [sHu]));
                this._resetScan();
                return;
            }

            var oModel = this.getView().getModel();   // OData V4 default model
            // Explicit $select (control-less binding — autoExpandSelect can't infer one).
            // MaterialDescription is deliberately absent: ZC_HU_Item does not expose it.
            var oList = oModel.bindList(ENTITY_SET, undefined, undefined, [
                new Filter("HandlingUnit", FilterOperator.EQ, sHu)
            ], { $select: "HandlingUnit,HandlingUnitItem,Material,Batch,Quantity,Unit" });
            var that = this;
            oList.requestContexts(0, 200).then(function (aContexts) {
                if (!aContexts.length) {
                    MessageToast.show(that._text("huNotFound", [sHu]));
                    that._resetScan();
                    return;
                }
                var aItems = oUiModel.getProperty("/items");
                aContexts.forEach(function (oCtx) {
                    var o = oCtx.getObject();
                    aItems.push({
                        HandlingUnit: o.HandlingUnit,
                        Material: o.Material,
                        MaterialDescription: o.MaterialDescription || "",
                        Batch: o.Batch,
                        Quantity: o.Quantity,
                        Unit: o.Unit
                    });
                });
                oUiModel.setProperty("/items", aItems);
                that._mScannedHus[sHu] = true;
                that._resetScan();
                MessageToast.show(that._text("huAdded", [sHu]));
            }).catch(function (oErr) {
                MessageBox.error(that._text("huReadFailed", [sHu, (oErr && oErr.message) || ""]));
            });
        },

        onRemoveItem: function (oEvent) {
            var oCtx = oEvent.getSource().getBindingContext("ui");
            var sPath = oCtx.getPath();                 // e.g. /items/3
            var iIndex = parseInt(sPath.split("/").pop(), 10);
            var oUiModel = this.getView().getModel("ui");
            var aItems = oUiModel.getProperty("/items");
            var sHu = aItems[iIndex] && aItems[iIndex].HandlingUnit;
            aItems.splice(iIndex, 1);
            oUiModel.setProperty("/items", aItems);
            // Removing one ITEM row may leave sibling rows of the same HU — only forget the
            // HU (allowing a re-scan) once none of its rows remain.
            if (sHu && !aItems.some(function (o) { return o.HandlingUnit === sHu; })) {
                delete this._mScannedHus[sHu];
            }
        },

        onClearAll: function () {
            this.getView().getModel("ui").setProperty("/items", []);
            this._mScannedHus = Object.create(null);
        },

        /**
         * Post a single material document for all scanned HU items.
         *
         * Replace the TODO with the backend create. For a RAP/OData V4 service
         * use a create or a bound action carrying the header + items; the classic
         * backend equivalent is BAPI_GOODSMVT_CREATE behind a custom service.
         */
        onPostMovement: function () {
            var oUi = this.getView().getModel("ui").getData();
            if (!oUi.header.movementType || !oUi.header.plant) {
                MessageBox.error(this._text("headerRequired"));
                return;
            }
            if (!oUi.items.length) {
                MessageToast.show(this._text("noItems"));
                return;
            }

            var oModel = this.getView().getModel();   // OData V4 default model
            var oAction = oModel.bindContext(ENTITY_SET + "/" + SERVICE_NS + ".postGoodsMovement(...)");
            oAction.setParameter("MovementType", oUi.header.movementType);
            oAction.setParameter("Plant", oUi.header.plant);
            oAction.setParameter("StorageLocation", oUi.header.storageLocation);
            oAction.setParameter("ReceivingStorageLocation", oUi.header.moveStorageLocation);
            oAction.setParameter("_Item", oUi.items.map(function (o) {
                return {
                    Material: o.Material,
                    Batch: o.Batch,
                    Quantity: o.Quantity,
                    Unit: o.Unit
                };
            }));

            var that = this;
            oAction.invoke().then(function () {
                var oResult = oAction.getBoundContext().getObject();
                MessageBox.success(that._text("postDone", [
                    (oResult && oResult.MaterialDocument) || "",
                    (oResult && oResult.Message) || ""
                ]));
                that.getView().getModel("ui").setProperty("/items", []);
                that._mScannedHus = Object.create(null);
            }).catch(function (oErr) {
                MessageBox.error(that._text("postFailed", [(oErr && oErr.message) || ""]));
            });
        },

        _huAlreadyAdded: function (sHu) {
            return !!this._mScannedHus[sHu];
        },

        _resetScan: function () {
            this.getView().getModel("ui").setProperty("/scan/huNumber", "");
            this.byId("inpHu").focus();
        },

        _text: function (sKey, aArgs) {
            return this.getView().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
        }
    });
});
