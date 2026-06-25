sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (Controller, JSONModel, MessageToast, MessageBox) {
    "use strict";

    return Controller.extend("kejriwal.sd.contractbatchupdate.controller.Main", {

        onInit: function () {
            this.getView().setModel(new JSONModel({
                contract: "",
                massBatch: "",
                items: [],
                dirtyCount: 0
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
            // TODO: read the contract items from the backend and fill /items.
            oModel.setProperty("/items", []);
            oModel.setProperty("/dirtyCount", 0);
            MessageToast.show(this._text("loadTodo", [sContract]));
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
            // TODO: call the backend mass-update action with aChanged.
            MessageToast.show(this._text("updateTodo", [aChanged.length]));
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
