sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (Controller, JSONModel, Filter, FilterOperator, MessageToast, MessageBox) {
    "use strict";

    return Controller.extend("kejriwal.qm.inspectionresultmass.controller.Worklist", {

        onInit: function () {
            // UI state model: filter values + dirty-row tracking.
            this.getView().setModel(new JSONModel({
                filter: { plant: "", workCenter: "", inspectionLot: "" },
                dirtyCount: 0
            }), "ui");
            this._dirty = {}; // context path -> bound context of edited rows
        },

        /**
         * Rebind the table with the chosen filters. Mass entry across many lots
         * is the whole point of this app, so filters are broad (plant / work
         * center / lot) and the table returns every open characteristic.
         */
        onSearch: function () {
            var oUi = this.getView().getModel("ui").getData();
            var aFilters = [];
            if (oUi.filter.plant) {
                aFilters.push(new Filter("Plant", FilterOperator.EQ, oUi.filter.plant));
            }
            if (oUi.filter.workCenter) {
                aFilters.push(new Filter("WorkCenter", FilterOperator.EQ, oUi.filter.workCenter));
            }
            if (oUi.filter.inspectionLot) {
                aFilters.push(new Filter("InspectionLot", FilterOperator.EQ, oUi.filter.inspectionLot));
            }
            this.byId("resultsTable").getBinding("items").filter(aFilters);
            this._resetDirty();
        },

        /** Track which rows the user has edited so we can post only those. */
        onResultChange: function (oEvent) {
            var oCtx = oEvent.getSource().getBindingContext();
            if (oCtx) {
                this._dirty[oCtx.getPath()] = oCtx;
                this.getView().getModel("ui").setProperty("/dirtyCount", Object.keys(this._dirty).length);
            }
        },

        /**
         * Post all edited results in one round trip.
         *
         * With an OData V4 model the edits are already pending changes on the
         * bound contexts; submitting the batch group sends them together. If the
         * backend exposes a dedicated mass-post action instead, replace the
         * submitBatch call with bound-action invocation over the selected/edited
         * contexts.
         */
        onPostResults: function () {
            var oModel = this.getView().getModel();
            var iCount = Object.keys(this._dirty).length;
            if (!iCount) {
                MessageToast.show(this.getText("noChanges"));
                return;
            }

            oModel.submitBatch("$auto").then(function () {
                MessageToast.show(this.getText("postSuccess", [iCount]));
                this._resetDirty();
            }.bind(this)).catch(function (oError) {
                MessageBox.error(this.getText("postError") + "\n" + (oError && oError.message ? oError.message : ""));
            }.bind(this));
        },

        _resetDirty: function () {
            this._dirty = {};
            this.getView().getModel("ui").setProperty("/dirtyCount", 0);
        },

        getText: function (sKey, aArgs) {
            return this.getView().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
        }
    });
});
