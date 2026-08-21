sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (Controller, MessageToast, MessageBox) {
    "use strict";

    // BAPI_INSPLOT_SETUSAGEDECISION rejects a blank UD_SELECTED_SET - the code
    // group alone does not identify a code, because the same group can appear
    // in more than one selected set. "ZQC_UD" mirrors the code group name,
    // which is the common one-selected-set-per-group customizing pattern, but
    // this has not been confirmed against QS51 in KSD. If Usage Decision
    // posting fails with a "selected set" error, correct this one constant.
    var UD_SELECTED_SET = "ZQC_UD";

    var UD_CODES = [
        { key: "A",  text: "Accept" },
        { key: "A1", text: "Accept with deviation" },
        { key: "RD", text: "Re-dye / correct" },
        { key: "ST", text: "Strip and re-dye" },
        { key: "DG", text: "Downgrade" },
        { key: "R",  text: "Reject" }
    ];

    return Controller.extend("kejriwal.qm.qcpostdyeing.controller.Detail", {

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

            // Until the dye recipe is separately identified in SAP (open
            // item 8 in the QM workbook) the app cannot tell whether this
            // is the qualifying batch. Default to requiring the battery -
            // over-testing is recoverable, silently skipping fastness on a
            // new recipe is not.
            this._setRecipeMode(true);
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
            oAction.setParameter("OperationNumber", this._currentOperationNumber());
            oAction.execute("qc").then(function () {
                MessageToast.show(this._t("msgRecorded"));
                oCtx.refresh();
            }.bind(this)).catch(function (oErr) {
                MessageBox.error(oErr.message || "Recording failed");
            });
        },

        // Every characteristic loaded for this lot belongs to the one
        // inspection operation this stage-specific app cares about (that is
        // what "one service, three stage apps" means), so any bound row's
        // OperationNumber is the right one to record against. Read it from
        // "lstOther" specifically because that list has no server-side
        // $filter - it is populated whenever the lot has any characteristics
        // at all, unlike "lstVariation" which is filtered to ZQC_GREY.
        _currentOperationNumber: function () {
            var oList = this.byId("lstOther"),
                oBinding = oList && oList.getBinding("items"),
                aCtx = oBinding && oBinding.getCurrentContexts();
            if (aCtx && aCtx.length && aCtx[0]) {
                return aCtx[0].getProperty("OperationNumber");
            }
            return "00000010"; // fallback: no characteristics loaded yet
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
            oAction.setParameter("SelectedSet", UD_SELECTED_SET);
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

        // --- Stage 2: shade readout ------------------------------------
        onDeltaEChange: function () {
            var f = parseFloat(this.byId("deInput").getValue()),
                oStatus = this.byId("deStatus"),
                oHint = this.byId("deHint");

            if (isNaN(f)) { oStatus.setText(""); oStatus.setState("None"); oHint.setText(""); return; }

            oStatus.setText("dE " + f.toFixed(2));
            if (f <= 1.0) {
                oStatus.setState("Success");
                oHint.setText("Within tolerance.");
            } else if (f <= 2.0) {
                oStatus.setState("Warning");
                oHint.setText("Outside 1.00. Correctable by topping - expect a re-dye decision.");
            } else {
                oStatus.setState("Error");
                oHint.setText("Well outside tolerance. Consider stripping rather than topping.");
            }
            this.onResultChange();
        },

        // Fastness is a property of the recipe, not the batch. The panel only
        // matters for the qualifying batch, and the technician should be told
        // which case they are in rather than left to remember.
        _setRecipeMode: function (bFirst) {
            this.getOwnerComponent().getModel("ui").setProperty("/isFirstOfRecipe", bFirst);
            var oStrip = this.byId("fastnessStrip");
            if (!oStrip) { return; }
            if (bFirst) {
                oStrip.setType("Warning");
                oStrip.setText("First batch of this recipe - the full fastness battery is required.");
            } else {
                oStrip.setType("Success");
                oStrip.setText("This recipe is already qualified. Fastness is not repeated per batch.");
            }
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
