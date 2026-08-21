sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (Controller, MessageToast, MessageBox) {
    "use strict";

    var UD_CODES = [
        { key: "A",  text: "Accept" },
        { key: "A1", text: "Accept with deviation" },
        { key: "RD", text: "Re-dye / correct" },
        { key: "ST", text: "Strip and re-dye" },
        { key: "DG", text: "Downgrade" },
        { key: "R",  text: "Reject" }
    ];

    return Controller.extend("kejriwal.qm.qcrawmaterial.controller.Detail", {

        onInit: function () {
            this.getOwnerComponent().getRouter()
                .getRoute("detail").attachPatternMatched(this._onMatched, this);
        },

        _onMatched: function (oEvent) {
            var sLot = oEvent.getParameter("arguments").lot;
            this.getView().bindElement({
                path: "/InspectionLot('" + sLot + "')",
                parameters: { $expand: "_Characteristic", $$updateGroupId: "qc" }
            });
            this._sLot = sLot;
            this._aDirty = [];
            this.getOwnerComponent().getModel("ui").setProperty("/dirty", false);
        },

        onBack: function () {
            if (this.getOwnerComponent().getModel("ui").getProperty("/dirty")) {
                MessageBox.confirm("Unsaved results will be lost. Leave anyway?", {
                    onClose: function (sAction) {
                        if (sAction === MessageBox.Action.OK) { this._nav(); }
                    }.bind(this)
                });
                return;
            }
            this._nav();
        },

        _nav: function () {
            this.getOwnerComponent().getRouter().navTo("worklist");
        },

        onResultChange: function (oEvent) {
            var oCtx = oEvent && oEvent.getSource && oEvent.getSource().getBindingContext();
            if (oCtx) { this._touch(oCtx); }
            else { this.getOwnerComponent().getModel("ui").setProperty("/dirty", true); }
        },

        onCodeChange: function (oEvent) {
            var oCtx = oEvent && oEvent.getSource && oEvent.getSource().getBindingContext();
            if (oCtx) { this._touch(oCtx); }
            else { this.getOwnerComponent().getModel("ui").setProperty("/dirty", true); }
        },

        // Characteristics are read-only in RAP now, so results go through the
        // recordSingleResult action - one call per changed row, all inside a
        // single $batch. See docs/backend-notes/qm-data-model.md for why the
        // composition was removed.
        _touch: function (oCtx) {
            if (!this._aDirty) { this._aDirty = []; }
            if (this._aDirty.indexOf(oCtx) === -1) { this._aDirty.push(oCtx); }
            this.getOwnerComponent().getModel("ui").setProperty("/dirty", true);
        },

        onSave: function () {
            var aDirty = this._aDirty || [];
            if (!aDirty.length) { return; }

            var oModel = this.getView().getModel(),
                oLotCtx = this.getView().getBindingContext(),
                aCalls = [];

            aDirty.forEach(function (oCtx) {
                var oAction = oModel.bindContext(
                    "com.sap.gateway.srvd.zui_qc_inspection.v0001.recordSingleResult(...)", oLotCtx);

                oAction.setParameter("InspectionLot", this._sLot);
                oAction.setParameter("OperationNumber", oCtx.getProperty("OperationNumber"));
                oAction.setParameter("CharacteristicNumber", oCtx.getProperty("CharacteristicNumber"));
                oAction.setParameter("MeanValue", oCtx.getProperty("MeanValue") || 0);
                oAction.setParameter("ResultCode", oCtx.getProperty("ResultCode") || "");
                oAction.setParameter("ResultCodeGroup", oCtx.getProperty("ResultCodeGroup") || "");
                oAction.setParameter("DefectCount", oCtx.getProperty("DefectCount") || 0);
                oAction.setParameter("ActualSampleSize", oCtx.getProperty("ActualSampleSize") || 0);
                oAction.setParameter("ResultComment", oCtx.getProperty("InspectorComment") || "");

                aCalls.push(oAction.execute("qc"));
            }, this);

            Promise.all(aCalls).then(function () {
                this._aDirty = [];
                this.getOwnerComponent().getModel("ui").setProperty("/dirty", false);
                MessageToast.show(this._t("msgSaved"));
                if (oLotCtx) { oLotCtx.refresh(); }
            }.bind(this)).catch(function (oErr) {
                MessageBox.error(oErr.message || "Save failed");
            });
        },

        onRecord: function () {
            var oCtx = this.getView().getBindingContext();
            if (!oCtx) { return; }

            var oAction = this.getView().getModel().bindContext(
                "com.sap.gateway.srvd.zui_qc_inspection.v0001.recordResults(...)", oCtx);

            oAction.setParameter("InspectionLot", this._sLot);
            oAction.setParameter("OperationNumber", "00000010");
            oAction.execute("qc").then(function () {
                MessageToast.show(this._t("msgRecorded"));
                oCtx.refresh();
            }.bind(this)).catch(function (oErr) {
                MessageBox.error(oErr.message || "Recording failed");
            });
        },

        onUsageDecision: function () {
            var that = this;
            MessageBox.show("Select the usage decision for this inspection lot.", {
                title: this._t("usageDecision"),
                actions: UD_CODES.map(function (o) { return o.text; }).concat([MessageBox.Action.CANCEL]),
                onClose: function (sChosen) {
                    var oPick = UD_CODES.filter(function (o) { return o.text === sChosen; })[0];
                    if (!oPick) { return; }
                    that._postUd(oPick.key);
                }
            });
        },

        _postUd: function (sCode) {
            var oCtx = this.getView().getBindingContext();
            var oAction = this.getView().getModel().bindContext(
                "com.sap.gateway.srvd.zui_qc_inspection.v0001.setUsageDecision(...)", oCtx);

            oAction.setParameter("InspectionLot", this._sLot);
            oAction.setParameter("CodeGroup", "ZQC_UD");
            oAction.setParameter("Code", sCode);
            oAction.execute("qc").then(function () {
                MessageToast.show(this._t("msgUdSet"));
                // A re-dye or strip decision hands over to the existing loop.
                // The app tells the technician what to do next; it does not
                // reopen the batch for them, because that has stock effects.
                if (sCode === "RD" || sCode === "ST") {
                    MessageBox.information(this._t("msgRedye"));
                }
                oCtx.refresh();
            }.bind(this)).catch(function (oErr) {
                MessageBox.error(oErr.message || "Usage decision failed");
            });
        },

        // --- Stage 1: boiling water shrinkage spread -------------------
        // BWS is doing double duty here. The dye uniformity tube test was cut
        // from the specification, and spread of BWS across packages is the
        // accepted proxy for spread of dye affinity. The RANGE is the number
        // that predicts barre, so it is computed and judged, not just stored.
        onBwsChange: function () {
            var aVals = ["bws1","bws2","bws3","bws4","bws5"]
                .map(function (s) { return parseFloat(this.byId(s).getValue()); }, this)
                .filter(function (n) { return !isNaN(n); });

            var oMean  = this.byId("bwsMean"),
                oRange = this.byId("bwsRange");

            if (aVals.length < 2) {
                oMean.setText(""); oRange.setText(""); oRange.setState("None");
                return;
            }

            var fSum  = aVals.reduce(function (a, b) { return a + b; }, 0),
                fMean = fSum / aVals.length,
                fRange = Math.max.apply(null, aVals) - Math.min.apply(null, aVals);

            oMean.setText(fMean.toFixed(2) + " %");
            oRange.setText(fRange.toFixed(2) + " %"
                + (aVals.length < 5 ? "  (" + aVals.length + " of 5)" : ""));

            // 5.0-9.0 % absolute, range <= 1.5 % across the five
            var bMeanOk  = fMean >= 5.0 && fMean <= 9.0,
                bRangeOk = fRange <= 1.5;

            oMean.setState(bMeanOk ? "Success" : "Error");
            oRange.setState(bRangeOk ? "Success" : "Error");

            if (!bRangeOk) {
                this.byId("bwsRange").setText(fRange.toFixed(2)
                    + " %  - spread too wide, expect barre");
            }
            this.onResultChange();
        },

        _t: function (sKey) {
            return this.getView().getModel("i18n").getResourceBundle().getText(sKey);
        },

        fmtQty: function (v, u) {
            if (v === undefined || v === null) { return ""; }
            return parseFloat(v).toFixed(3).replace(/\.?0+$/, "") + " " + (u || "");
        },

        // SOLLWERT, TOLERANZUN and TOLERANZOB are FLTP and cannot distinguish
        // zero from not-maintained, so SAP carries an is-initial flag for each.
        // Render the flag, never the raw value - otherwise an unmaintained
        // limit shows as 0.00 and every result looks in tolerance.
        fmtSpec: function (sMic, fTarget, fLow, fHigh, sUnit, sLowNi, sHighNi) {
            var aParts = [sMic];
            var hasLow  = sLowNi  !== "X" && fLow  !== null && fLow  !== undefined;
            var hasHigh = sHighNi !== "X" && fHigh !== null && fHigh !== undefined;

            if (hasLow && hasHigh) {
                aParts.push(fLow + " to " + fHigh + " " + (sUnit || ""));
            } else if (hasHigh) {
                aParts.push("max " + fHigh + " " + (sUnit || ""));
            } else if (hasLow) {
                aParts.push("min " + fLow + " " + (sUnit || ""));
            } else {
                aParts.push(this._t("notMaintained"));
            }
            return aParts.join("  \u00b7  ");
        },

        fmtValText: function (sVal) {
            if (sVal === "A") { return "PASS"; }
            if (sVal === "R") { return "FAIL"; }
            return "";
        },

        fmtValState: function (sVal) {
            if (sVal === "A") { return "Success"; }
            if (sVal === "R") { return "Error"; }
            return "None";
        }
    });
});
