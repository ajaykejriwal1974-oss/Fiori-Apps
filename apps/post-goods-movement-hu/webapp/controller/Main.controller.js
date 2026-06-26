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
    var SERVICE_NS = "REPLACE_WITH_SERVICE_NAMESPACE";
    var ENTITY_SET = "/HandlingUnitItem";

    return Controller.extend("kejriwal.mm.goodsmovementhu.controller.Main", {

        onInit: function () {
            this.getView().setModel(new JSONModel({
                header: { movementType: "", plant: "", storageLocation: "", moveStorageLocation: "" },
                scan: { huNumber: "" },
                items: []
            }), "ui");
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
            var oList = oModel.bindList(ENTITY_SET, undefined, undefined, [
                new Filter("HandlingUnit", FilterOperator.EQ, sHu)
            ]);
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
            aItems.splice(iIndex, 1);
            oUiModel.setProperty("/items", aItems);
        },

        onClearAll: function () {
            this.getView().getModel("ui").setProperty("/items", []);
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
            }).catch(function (oErr) {
                MessageBox.error(that._text("postFailed", [(oErr && oErr.message) || ""]));
            });
        },

        _huAlreadyAdded: function (sHu) {
            return this.getView().getModel("ui").getProperty("/items").some(function (o) {
                return o.HandlingUnit === sHu;
            });
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
