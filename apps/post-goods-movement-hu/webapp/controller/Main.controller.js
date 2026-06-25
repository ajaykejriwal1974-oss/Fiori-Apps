sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (Controller, JSONModel, MessageToast, MessageBox) {
    "use strict";

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

            // TODO: read HU contents from the backend and append the real rows.
            // The line below is a placeholder marker row so the flow is visible
            // until the HU service is wired; remove it once the read is in place.
            var aItems = oUiModel.getProperty("/items");
            aItems.push({
                HandlingUnit: sHu,
                Material: "",
                MaterialDescription: this._text("pendingHuRead"),
                Batch: "",
                Quantity: "0",
                Unit: ""
            });
            oUiModel.setProperty("/items", aItems);
            this._resetScan();
            MessageToast.show(this._text("huAdded", [sHu]));
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

            // TODO: create the material document via the goods-movement service.
            MessageToast.show(this._text("postTodo", [oUi.items.length, oUi.header.movementType]));
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
