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
    var SERVICE_NS = "REPLACE_WITH_SERVICE_NAMESPACE";
    var ENTITY_SET = "/ContractItem";

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
            oModel.setProperty("/items", []);
            oModel.setProperty("/dirtyCount", 0);

            var that = this;
            var oODataModel = this.getView().getModel();   // OData V4 default model
            var oList = oODataModel.bindList(ENTITY_SET, undefined, undefined, [
                new Filter("SalesContract", FilterOperator.EQ, sContract)
            ]);
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
