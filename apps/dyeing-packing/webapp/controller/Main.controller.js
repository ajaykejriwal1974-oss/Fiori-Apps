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
    // (e.g. "com.kejriwal.zui_packing") so the action path resolves.
    var SERVICE_NS = "REPLACE_WITH_SERVICE_NAMESPACE";
    var ENTITY_SET = "/PackingUnit";

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
            var that = this;
            var oUiModel = this.getView().getModel("ui");
            var sRef = (oUiModel.getProperty("/header/reference") || "").trim();
            if (!sRef) {
                MessageBox.error(this._text("referenceRequired"));
                return;
            }
            MessageBox.confirm(this._text("confirmRepack"), {
                onClose: function (sAction) {
                    if (sAction !== MessageBox.Action.OK) {
                        return;
                    }
                    oUiModel.setProperty("/units", []);
                    that._recalcTotals();
                    var oModel = that.getView().getModel();   // OData V4 default model
                    var oList = oModel.bindList(ENTITY_SET, undefined, undefined, [
                        new Filter("Reference", FilterOperator.EQ, sRef)
                    ]);
                    oList.requestContexts(0, 500).then(function (aContexts) {
                        var aUnits = [];
                        aContexts.forEach(function (oCtx) {
                            var o = oCtx.getObject();
                            aUnits.push({
                                levelType: o.PackingGroup || "",
                                level: o.PackingGroup || "",
                                packingMaterial: o.PackagingMaterial,
                                quantity: "1",
                                netWeight: o.NetWeight,
                                grossWeight: o.GrossWeight
                            });
                        });
                        oUiModel.setProperty("/units", aUnits);
                        that._recalcTotals();
                        MessageToast.show(that._text("repackLoaded", [aUnits.length, sRef]));
                    }).catch(function (oErr) {
                        MessageBox.error(that._text("repackFailed", [sRef, (oErr && oErr.message) || ""]));
                    });
                }
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
            var oModel = this.getView().getModel();   // OData V4 default model
            var oAction = oModel.bindContext(ENTITY_SET + "/" + SERVICE_NS + ".createHandlingUnits(...)");
            oAction.setParameter("Reference", oUi.header.reference);
            oAction.setParameter("Material", oUi.header.material);
            oAction.setParameter("Batch", oUi.header.batch);
            oAction.setParameter("Shade", oUi.header.shade);
            oAction.setParameter("_Unit", oUi.units.map(function (o) {
                return {
                    LevelType: o.levelType,
                    PackingMaterial: o.packingMaterial,
                    Quantity: o.quantity,
                    NetWeight: o.netWeight,
                    GrossWeight: o.grossWeight
                };
            }));

            var that = this;
            oAction.invoke().then(function () {
                var oResult = oAction.getBoundContext().getObject();
                MessageBox.success(that._text("packDone", [
                    (oResult && oResult.HandlingUnitsCreated) || 0,
                    (oResult && oResult.TopHandlingUnit) || "",
                    (oResult && oResult.Message) || ""
                ]));
                that.getView().getModel("ui").setProperty("/units", []);
                that._recalcTotals();
            }).catch(function (oErr) {
                MessageBox.error(that._text("packFailed", [(oErr && oErr.message) || ""]));
            });
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
