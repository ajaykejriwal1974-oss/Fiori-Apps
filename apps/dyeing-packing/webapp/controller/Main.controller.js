sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (Controller, JSONModel, MessageToast, MessageBox) {
    "use strict";

    return Controller.extend("kejriwal.pp.dyeingpacking.controller.Main", {

        onInit: function () {
            this.getView().setModel(new JSONModel({
                header: { reference: "", material: "", batch: "", shade: "", weightUnit: "KG" },
                units: [],
                totals: { net: "0.000", gross: "0.000" }
            }), "ui");
        },

        onAddCone: function () { this._addUnit("Cone", this._text("levelCone")); },
        onAddCarton: function () { this._addUnit("Carton", this._text("levelCarton")); },
        onAddPallet: function () { this._addUnit("Pallet", this._text("levelPallet")); },

        _addUnit: function (sType, sLabel) {
            var oModel = this.getView().getModel("ui");
            var aUnits = oModel.getProperty("/units");
            aUnits.push({
                levelType: sType,
                level: sLabel,
                packingMaterial: "",
                quantity: "1",
                netWeight: "0.000",
                grossWeight: "0.000"
            });
            oModel.setProperty("/units", aUnits);
            this._recalcTotals();
        },

        onRemoveUnit: function (oEvent) {
            var oCtx = oEvent.getSource().getBindingContext("ui");
            var iIndex = parseInt(oCtx.getPath().split("/").pop(), 10);
            var oModel = this.getView().getModel("ui");
            var aUnits = oModel.getProperty("/units");
            aUnits.splice(iIndex, 1);
            oModel.setProperty("/units", aUnits);
            this._recalcTotals();
        },

        onWeightChange: function () {
            this._recalcTotals();
        },

        /**
         * Re-pack: rebuild the structure for the same reference. With a backend
         * service this re-reads the current packing of the reference; here it
         * just clears the working set so the user can re-build it.
         */
        onRepack: function () {
            MessageBox.confirm(this._text("confirmRepack"), {
                onClose: function (sAction) {
                    if (sAction === MessageBox.Action.OK) {
                        this.getView().getModel("ui").setProperty("/units", []);
                        this._recalcTotals();
                        // TODO: re-read existing HUs for the reference and repopulate.
                    }
                }.bind(this)
            });
        },

        /**
         * Create the handling-unit hierarchy (cone -> carton -> pallet) for the
         * reference. Replace the TODO with the backend create: a RAP action /
         * deep create over the packing service, or the standard HU API when HU
         * Management can model the textile structure.
         */
        onCreateHus: function () {
            var oUi = this.getView().getModel("ui").getData();
            if (!oUi.header.reference) {
                MessageBox.error(this._text("referenceRequired"));
                return;
            }
            if (!oUi.units.length) {
                MessageToast.show(this._text("noUnits"));
                return;
            }
            // TODO: create the HU structure via the packing service.
            MessageToast.show(this._text("packTodo", [oUi.units.length, oUi.header.reference]));
        },

        _recalcTotals: function () {
            var oModel = this.getView().getModel("ui");
            var aUnits = oModel.getProperty("/units");
            var fNet = 0, fGross = 0;
            aUnits.forEach(function (o) {
                fNet += parseFloat(o.netWeight) || 0;
                fGross += parseFloat(o.grossWeight) || 0;
            });
            oModel.setProperty("/totals/net", fNet.toFixed(3));
            oModel.setProperty("/totals/gross", fGross.toFixed(3));
        },

        _text: function (sKey, aArgs) {
            return this.getView().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
        }
    });
});
