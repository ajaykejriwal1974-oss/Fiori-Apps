sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/Dialog",
    "sap/m/List",
    "sap/m/StandardListItem",
    "sap/m/Button",
    "sap/m/Label",
    "sap/m/Input",
    "sap/m/Text",
    "sap/m/DatePicker",
    "sap/ui/layout/form/SimpleForm",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/ui/model/Sorter"
], function (Controller, MessageToast, MessageBox, Dialog, List, StandardListItem, Button,
             Label, Input, Text, DatePicker, SimpleForm, Filter, FilterOperator, Sorter) {
    "use strict";

    // Selected set and code group for the usage decision. ZQC-UD exists as a
    // code group (plant independent) and as a selected set in plants 1000 and
    // 2002 (V_QPAM_UD, customizing request KSDK906757). If a plant is added
    // without the set, BAPI_INSPLOT_SETUSAGEDECISION rejects the decision and
    // the error surfaces in the dialog - nothing is posted.
    var UD_SELECTED_SET = "ZQC-UD",
        UD_CODE_GROUP   = "ZQC-UD";

    // Mirrors selected set ZQC-UD as read from QPAC on 2026-08-28. A, A1 and
    // SP are valuated A (accept); the other six are valuated R (reject). RD
    // and ST belong to the in-process stages - a greige delivery is not
    // re-dyed or stripped - so this app offers the codes that make sense for
    // incoming yarn.
    var UD_CODES = [
        { key: "A",   text: "Accept" },
        { key: "A1",  text: "Accept with deviation" },
        { key: "SP",  text: "Small Package" },
        { key: "CLQ", text: "Claim Less" },
        { key: "DG",  text: "Downgrade" },
        { key: "JL",  text: "Job Lot" },
        { key: "PQ",  text: "Poor Quality" }
    ];

    // Verified against MSEG in plant 2002 on 2026-08-28, not assumed. The
    // transfer that puts greige on the dyeing floor is movement 301 from DRM1
    // "RM Dyg Main St-1" to DPR1 "Dyg Prod RM St-1" - 18 documents this year,
    // against six uses of 311 in the plant's entire history.
    var MOVE_TYPE = "301",
        SLOC_FROM = "DRM1",
        SLOC_TO   = "DPR1";

    // Master inspection characteristic that the boiling-water-shrinkage panel
    // writes into. The panel takes five package readings and judges the
    // spread; QM stores one summarised result per characteristic, so the MEAN
    // goes into MeanValue and the five readings plus the range go into the
    // inspector comment (QAMR-PRUEFBEMKT, 40 characters). The MIC created in
    // plant 2002 is "BWS" (QS21, 2026-08-28); the other names are tolerated
    // for plants that named it differently.
    var BWS_MICS = ["BWS", "S1_BWS", "BWS_MEAN", "BOILSHRINK"];

    // Properties the controller reads with getProperty() but that no control
    // in the view binds. The model runs with autoExpandSelect, which derives
    // $select from the BOUND properties only - anything read here and bound
    // nowhere came back undefined, so the release dialog posted a blank Plant
    // and the batch picker built a filter on "undefined" and threw. Naming
    // them here puts them in the read.
    var LOT_SELECT = [
        "InspectionLot", "Plant", "CompanyCode", "InspectionType", "Material", "MaterialName",
        "Batch", "VendorBatch", "GreigeLot", "ProductionLot", "ProductionOrder", "OrderSource",
        "BatchSource", "PlantBatch", "PlantBatchYear", "JobCard",
        "LotQuantity", "LotUnit", "SampleSize", "SampleUnit", "CreatedOn",
        "ResultsConfirmed", "UsageDecisionMade", "IsOpen"
    ].join(",");

    return Controller.extend("kejriwal.qm.qcrawmaterial.controller.Detail", {

        onInit: function () {
            this.getOwnerComponent().getRouter()
                .getRoute("detail").attachPatternMatched(this._onMatched, this);
        },

        _onMatched: function (oEvent) {
            var sLot = oEvent.getParameter("arguments").lot;
            // Leaving a lot with unsaved edits: drop them, or the next lot's
            // refresh() is refused for pending changes that belong to the old one.
            this._discardEdits();
            this.getView().bindElement({
                path: "/InspectionLot('" + sLot + "')",
                parameters: { $select: LOT_SELECT, $expand: "_Characteristic", $$updateGroupId: "qc" }
            });
            this._sLot = sLot;
            this._resetBwsPanel();
        },

        onBack: function () {
            if (this._isDirty()) {
                MessageBox.confirm(this._t("msgLeaveUnsaved"), {
                    onClose: function (sAction) {
                        if (sAction === MessageBox.Action.OK) {
                            this._discardEdits();
                            this._nav();
                        }
                    }.bind(this)
                });
                return;
            }
            this._nav();
        },

        _nav: function () {
            this.getOwnerComponent().getRouter().navTo("worklist");
        },

        // ------------------------------------------------------------------
        // Dirty tracking. Every edit is a characteristic context; Save turns
        // each one into a recordSingleResult call. Nothing is "dirty" unless
        // it can actually be saved - the BWS panel therefore marks the lot
        // dirty only when it found a characteristic to write into.
        // ------------------------------------------------------------------
        _ui: function () { return this.getOwnerComponent().getModel("ui"); },
        _isDirty: function () { return !!this._ui().getProperty("/dirty"); },

        onResultChange: function (oEvent) {
            var oCtx = oEvent && oEvent.getSource && oEvent.getSource().getBindingContext();
            if (oCtx) { this._touch(oCtx); }
        },

        onCodeChange: function (oEvent) {
            this.onResultChange(oEvent);
        },

        _touch: function (oCtx) {
            if (!this._aDirty) { this._aDirty = []; }
            if (this._aDirty.indexOf(oCtx) === -1) { this._aDirty.push(oCtx); }
            this._ui().setProperty("/dirty", true);
        },

        // Throw away every pending PATCH in the "qc" group and forget the
        // touched rows. The characteristic entity is read-only in RAP, so the
        // PATCHes could never be accepted anyway; they exist only to hold the
        // typed values until Save copies them into action parameters.
        _discardEdits: function () {
            var oModel = this.getView().getModel();
            if (oModel && oModel.hasPendingChanges("qc")) { oModel.resetChanges("qc"); }
            this._aDirty = [];
            this._ui().setProperty("/dirty", false);
        },

        // Record Results, Usage Decision and Release each refresh the lot
        // afterwards, and refresh() is refused while edits are pending. The
        // buttons are disabled while dirty; this is the belt to that brace.
        _requireSaved: function () {
            if (this._isDirty()) {
                MessageBox.information(this._t("msgSaveFirst"));
                return false;
            }
            return true;
        },

        _refreshLot: function () {
            var oCtx = this.getView().getBindingContext();
            this._discardEdits();
            if (oCtx) { oCtx.refresh(); }
        },

        // All characteristic contexts of the lot. lstChars carries no server
        // filter, so it is populated whenever the lot has a plan at all.
        _charContexts: function () {
            var oList = this.byId("lstChars"),
                oBinding = oList && oList.getBinding("items");
            if (!oBinding) { return []; }
            return (oBinding.getAllCurrentContexts ? oBinding.getAllCurrentContexts()
                                                   : oBinding.getCurrentContexts()).filter(Boolean);
        },

        _findChar: function (aMics) {
            return this._charContexts().filter(function (oCtx) {
                var s = (oCtx.getProperty("MasterCharacteristic") || "").toUpperCase();
                return aMics.indexOf(s) > -1;
            })[0] || null;
        },

        // ------------------------------------------------------------------
        // Save: one recordSingleResult per touched row, all in one $batch.
        // Characteristics are read-only in RAP, so results go through the
        // action. See docs/backend-notes/qm-data-model.md for why the
        // composition was removed.
        // ------------------------------------------------------------------
        onSave: function () {
            var aDirty = this._aDirty || [];
            if (!aDirty.length) {
                MessageToast.show(this._t("msgNothingToSave"));
                return;
            }

            var oModel = this.getView().getModel(),
                oLotCtx = this.getView().getBindingContext(),
                aBindings = [];

            aDirty.forEach(function (oCtx) {
                var oAction = oModel.bindContext(
                    "com.sap.gateway.srvd.zui_qc_inspection.v0001.recordSingleResult(...)", oLotCtx);

                oAction.setParameter("InspectionLot", this._sLot);
                oAction.setParameter("OperationNumber", oCtx.getProperty("OperationNumber"));
                oAction.setParameter("CharacteristicNumber", oCtx.getProperty("CharacteristicNumber"));
                oAction.setParameter("MeanValue", parseFloat(oCtx.getProperty("MeanValue")) || 0);
                oAction.setParameter("ResultCode", oCtx.getProperty("ResultCode") || "");
                oAction.setParameter("ResultCodeGroup", oCtx.getProperty("ResultCodeGroup") || "");
                oAction.setParameter("DefectCount", parseInt(oCtx.getProperty("DefectCount"), 10) || 0);
                oAction.setParameter("ActualSampleSize", parseInt(oCtx.getProperty("ActualSampleSize"), 10) || 0);
                oAction.setParameter("ResultComment", oCtx.getProperty("InspectorComment") || "");

                aBindings.push(oAction);
            }, this);

            // "qc" holds the typed values as pending PATCHes; it is an API
            // group and is never submitted. "qcAct" carries the actions. The
            // PATCHes are kept until the actions have SUCCEEDED, so a failed
            // save leaves the technician's numbers on the screen to correct
            // and retry instead of snapping them back to the server values.
            var aCalls = aBindings.map(function (oBinding) { return oBinding.execute("qcAct"); });
            var pSent  = oModel.submitBatch("qcAct");

            Promise.all(aCalls.concat([ pSent ])).then(function () {
                MessageToast.show(this._t("msgSaved"));
                this._refreshLot();
            }.bind(this)).catch(function (oErr) {
                MessageBox.error(this._errorText(oErr, "Save failed"));
            }.bind(this));
        },

        onRecord: function () {
            var oCtx = this.getView().getBindingContext();
            if (!oCtx || !this._requireSaved()) { return; }

            var sOp = this._currentOperationNumber();
            if (!sOp) {
                MessageBox.information(this._t("msgNoChars"));
                return;
            }

            var oAction = this.getView().getModel().bindContext(
                "com.sap.gateway.srvd.zui_qc_inspection.v0001.recordResults(...)", oCtx);

            oAction.setParameter("InspectionLot", this._sLot);
            oAction.setParameter("OperationNumber", sOp);
            // Every action parameter is Nullable="false" in the service metadata,
            // so all of them must be supplied even when there is nothing to say.
            oAction.setParameter("ResultComment", "");

            // One call with nothing to batch alongside it - $auto sends it now
            // rather than parking it in the deferred group.
            oAction.execute("$auto").then(function () {
                MessageToast.show(this._t("msgRecorded"));
                this._refreshLot();
            }.bind(this)).catch(function (oErr) {
                MessageBox.error(this._errorText(oErr, "Recording failed"));
            }.bind(this));
        },

        // Every characteristic loaded for this lot belongs to the one
        // inspection operation this stage-specific app cares about, so any
        // bound row's OperationNumber is the right one to record against.
        // Returns "" when the lot has no characteristics loaded - the caller
        // says so instead of guessing an operation the lot may not have.
        _currentOperationNumber: function () {
            var aCtx = this._charContexts();
            return aCtx.length ? (aCtx[0].getProperty("OperationNumber") || "") : "";
        },

        // One button per code stopped laying out sensibly past about four.
        // A list scales and reads better on a tablet, which is where this runs.
        onUsageDecision: function () {
            if (!this._requireSaved()) { return; }
            var that = this;
            var oList = new List({ mode: "SingleSelectMaster", includeItemInSelection: true });
            var oDialog = new Dialog({
                title: this._t("usageDecision"),
                contentWidth: "24rem",
                content: [ oList ],
                endButton: new Button({
                    text: this._t("cancel"),
                    press: function () { oDialog.close(); }
                }),
                afterClose: function () { oDialog.destroy(); }
            });
            UD_CODES.forEach(function (oCode) {
                oList.addItem(new StandardListItem({
                    title: oCode.text,
                    info: oCode.key,
                    type: "Active",
                    press: function () {
                        oDialog.close();
                        that._confirmUd(oCode);
                    }
                }));
            });
            this.getView().addDependent(oDialog);
            oDialog.open();
        },

        // A usage decision closes the lot and moves stock; the app cannot undo
        // it. One accidental tap on a list row must not be enough to post it.
        _confirmUd: function (oPick) {
            var that = this;
            MessageBox.confirm(this._t("msgUdConfirm", [oPick.text, oPick.key, this._sLot]), {
                title: this._t("usageDecision"),
                actions: [MessageBox.Action.OK, MessageBox.Action.CANCEL],
                emphasizedAction: MessageBox.Action.OK,
                onClose: function (sAction) {
                    if (sAction === MessageBox.Action.OK) { that._postUd(oPick); }
                }
            });
        },

        _postUd: function (oPick) {
            var oCtx = this.getView().getBindingContext();
            var oAction = this.getView().getModel().bindContext(
                "com.sap.gateway.srvd.zui_qc_inspection.v0001.setUsageDecision(...)", oCtx);

            oAction.setParameter("InspectionLot", this._sLot);
            oAction.setParameter("SelectedSet", UD_SELECTED_SET);
            oAction.setParameter("CodeGroup", UD_CODE_GROUP);
            oAction.setParameter("Code", oPick.key);
            // Reason is Nullable="false"; a blank would post a decision with
            // no description.
            oAction.setParameter("Reason", oPick.text);

            oAction.execute("$auto").then(function () {
                MessageToast.show(this._t("msgUdSet"));
                this._refreshLot();
            }.bind(this)).catch(function (oErr) {
                MessageBox.error(this._errorText(oErr, "Usage decision failed"));
            }.bind(this));
        },

        // --- Stage 1: boiling water shrinkage spread -------------------
        // BWS is doing double duty here. The dye uniformity tube test was cut
        // from the specification, and spread of BWS across packages is the
        // accepted proxy for spread of dye affinity. The RANGE is the number
        // that predicts barre, so it is computed and judged, not just stored.
        //
        // Stored, too: the mean goes into the lot's BWS characteristic and the
        // five readings with the range into its inspector comment, so Save
        // carries them to QM like any other result. When the plan has no BWS
        // characteristic the panel says so and nothing pretends to be saved.
        onBwsChange: function () {
            var aVals = ["bws1","bws2","bws3","bws4","bws5"]
                .map(function (s) { return parseFloat(this.byId(s).getValue()); }, this)
                .filter(function (n) { return !isNaN(n); });

            var oMean   = this.byId("bwsMean"),
                oRange  = this.byId("bwsRange"),
                oTarget = this.byId("bwsTarget");

            if (aVals.length < 2) {
                oMean.setText(""); oRange.setText(""); oRange.setState("None");
                oTarget.setText(""); oTarget.setState("None");
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
                oRange.setText(fRange.toFixed(2) + " %  - spread too wide, expect barre");
            }

            var oCtx = this._findChar(BWS_MICS);
            if (!oCtx) {
                oTarget.setText(this._t("msgPanelNotInPlan"));
                oTarget.setState("Warning");
                return;
            }
            // QAMR-PRUEFBEMKT is 40 characters: "6.10/6.30/6.20/7.00/6.50 R1.20" fits.
            var sComment = (aVals.map(function (n) { return n.toFixed(2); }).join("/")
                            + " R" + fRange.toFixed(2)).substring(0, 40);
            // setProperty returns a promise for a PATCH that is never sent;
            // resetChanges rejects it, so swallow that or the console fills
            // with "uncaught in promise" every time a lot is left.
            oCtx.setProperty("MeanValue", Math.round(fMean * 100) / 100).catch(function () {});
            oCtx.setProperty("InspectorComment", sComment).catch(function () {});
            this._touch(oCtx);
            oTarget.setText(this._t("msgPanelTarget", [oCtx.getProperty("CharacteristicName") || oCtx.getProperty("MasterCharacteristic")]));
            oTarget.setState("Information");
        },

        _resetBwsPanel: function () {
            ["bws1","bws2","bws3","bws4","bws5"].forEach(function (s) {
                var o = this.byId(s); if (o) { o.setValue(""); }
            }, this);
            ["bwsMean","bwsRange","bwsTarget"].forEach(function (s) {
                var o = this.byId(s); if (o) { o.setText(""); o.setState("None"); }
            }, this);
        },

        // The BWS characteristic is entered through the panel above, not as a
        // single number in the list - two entry points for one result would
        // let them disagree.
        isListRow: function (sMic) {
            return BWS_MICS.indexOf((sMic || "").toUpperCase()) === -1;
        },

        // --- Grey QC follow-on: release the greige to the dyeing floor ------
        //
        // The transfer does not only move the yarn, it renames it: the supplier
        // batch in DRM1 becomes the production greige lot in DPR1, and that lot
        // is what ZPP_BATCHN carries and dyeing consumes.
        //
        //   T11072BCXXXXXXXXXX / AT1-5547  ->  T11072BCXXXXXXXXXX / BCT
        //
        // So the target lot is CHOSEN, not derived. The inspection lot sits on
        // the supplier batch and nothing on it knows which production lot this
        // delivery is destined to become - the operator picks from the plant's
        // open batches. Defaulting it from GreigeLot would prefill the supplier
        // batch, which is the one value guaranteed to be wrong.
        onReleaseToProduction: function () {
            var oCtx = this.getView().getBindingContext();
            if (!oCtx || !this._requireSaved()) { return; }
            if (oCtx.getProperty("UsageDecisionMade") !== "X") {
                MessageBox.information(this._t("msgUdFirst"));
                return;
            }
            var that = this;

            var oOrderText = new Text({ text: oCtx.getProperty("ProductionOrder") || "" });
            // If a plant batch record already links to this lot, ProductionLot
            // carries the answer and there is nothing to choose. Where it does
            // not, this stays empty and the operator picks - it is never
            // defaulted from Batch, which at goods receipt is the supplier's
            // number and the one value guaranteed to be wrong.
            var oToBatch = new Input({
                value: oCtx.getProperty("ProductionLot") || "",
                placeholder: this._t("phGreigeLot"),
                showValueHelp: true,
                valueHelpRequest: function () { that._openGreigeLotPicker(oToBatch, oOrderText); }
            });
            var oQty   = new Input({ value: this._num(oCtx.getProperty("LotQuantity")), type: "Number", textAlign: "End" });
            var oFrom  = new Input({ value: SLOC_FROM, maxLength: 4 });
            var oTo    = new Input({ value: SLOC_TO, maxLength: 4 });
            var oMove  = new Input({ value: MOVE_TYPE, maxLength: 3 });
            var oDate  = new DatePicker({ dateValue: new Date(), valueFormat: "yyyy-MM-dd" });
            var oTxt   = new Input({ maxLength: 25 });

            var oForm = new SimpleForm({
                editable: true,
                layout: "ResponsiveGridLayout",
                content: [
                    new Label({ text: this._t("lblMaterial") }),
                    new Text({ text: oCtx.getProperty("Material") + "  " + (oCtx.getProperty("MaterialName") || "") }),
                    new Label({ text: this._t("lblGreigeLot") }),
                    new Text({ text: oCtx.getProperty("Batch") || "" }),
                    new Label({ text: this._t("lblSupplierBatch") }),
                    new Text({ text: oCtx.getProperty("VendorBatch") || "" }),
                    new Label({ text: this._t("lblGreigeLotNew"), required: true }),
                    oToBatch,
                    new Label({ text: this._t("lblForOrder") }),
                    oOrderText,
                    new Label({ text: this._t("lblQuantity"), required: true }),
                    oQty,
                    new Label({ text: this._t("lblMovement"), required: true }),
                    oMove,
                    new Label({ text: this._t("lblFromSloc"), required: true }),
                    oFrom,
                    new Label({ text: this._t("lblToSloc"), required: true }),
                    oTo,
                    new Label({ text: this._t("lblPostingDate"), required: true }),
                    oDate,
                    new Label({ text: this._t("lblHeaderText") }),
                    oTxt
                ]
            });

            var fnInvalid = function (oCtl, sMsg) {
                oCtl.setValueState("Error");
                oCtl.setValueStateText(sMsg);
                oCtl.focus();
            };

            var oDialog = new Dialog({
                title: this._t("releaseToProduction"),
                contentWidth: "32rem",
                content: [ oForm ],
                beginButton: new Button({
                    text: this._t("release"),
                    type: "Accept",
                    press: function () {
                        [oToBatch, oQty, oMove, oFrom, oTo, oDate].forEach(function (c) { c.setValueState("None"); });
                        var fQty = parseFloat(oQty.getValue());
                        if (!oToBatch.getValue().trim()) {
                            fnInvalid(oToBatch, that._t("msgPickGreigeLot")); return;
                        }
                        if (isNaN(fQty) || fQty <= 0) {
                            fnInvalid(oQty, that._t("msgQtyPositive")); return;
                        }
                        if (!oMove.getValue().trim()) { fnInvalid(oMove, that._t("msgRequired")); return; }
                        if (!oFrom.getValue().trim()) { fnInvalid(oFrom, that._t("msgRequired")); return; }
                        if (!oTo.getValue().trim())   { fnInvalid(oTo,   that._t("msgRequired")); return; }
                        if (!oDate.getValue())        { fnInvalid(oDate, that._t("msgRequired")); return; }
                        oDialog.close();
                        that._postRelease({
                            toBatch: oToBatch.getValue().trim().toUpperCase(),
                            qty:     fQty,
                            move:    oMove.getValue().trim(),
                            from:    oFrom.getValue().trim().toUpperCase(),
                            to:      oTo.getValue().trim().toUpperCase(),
                            date:    oDate.getValue(),
                            text:    oTxt.getValue()
                        });
                    }
                }),
                endButton: new Button({ text: this._t("cancel"), press: function () { oDialog.close(); } }),
                afterClose: function () { oDialog.destroy(); }
            });

            this.getView().addDependent(oDialog);
            oDialog.open();
        },

        // OrderBatch is ZI_QC_BATCH_JOB, exposed read-only on the same service.
        //
        // The destination batch is the DPR1 batch this material is issued
        // under - in this plant that is the standing bucket ZPP_BATCHN-LOTNO
        // names (BCT, TEX, ...), the same on every open batch of the same
        // greige material. So the list is scoped to the lot's own material,
        // only open batches are offered (a closed batch has been reconciled
        // for gain and loss and must not take more yarn), and it is collapsed
        // to one row per destination batch with a count of the open plant
        // batches behind it. Unscoped, plant 2002 would return 130,000 rows
        // and show an arbitrary 200 of them.
        _openGreigeLotPicker: function (oTargetInput, oOrderText) {
            var oCtx = this.getView().getBindingContext(),
                that = this,
                sMaterial = oCtx.getProperty("Material") || "";

            var oList = new List({ mode: "SingleSelectMaster", includeItemInSelection: true, growing: true, growingThreshold: 30 });
            var oDialog = new Dialog({
                title: this._t("pickGreigeLot"),
                contentWidth: "30rem",
                contentHeight: "26rem",
                content: [ oList ],
                endButton: new Button({ text: this._t("cancel"), press: function () { oDialog.close(); } }),
                afterClose: function () { oDialog.destroy(); }
            });

            var aFilters = [
                new Filter("Plant", FilterOperator.EQ, oCtx.getProperty("Plant") || ""),
                new Filter("BatchClosed", FilterOperator.NE, "X"),
                new Filter("GreigeLotRef", FilterOperator.NE, "")
            ];
            if (sMaterial) { aFilters.push(new Filter("GreigeMaterial", FilterOperator.EQ, sMaterial)); }

            var oBinding = this.getView().getModel().bindList("/OrderBatch", null,
                [ new Sorter("BatchDate", true) ], aFilters,
                { $select: "BatchNumber,FiscalYear,GreigeLotRef,GreigeMaterial,ProductionOrder,JobCard,BatchQuantity,BatchUnit,BatchDate" });

            oList.setBusy(true);
            oBinding.requestContexts(0, 500).then(function (aCtx) {
                oList.setBusy(false);
                var oSeen = {}, aRows = [];
                aCtx.forEach(function (oRow) {
                    var sRef = (oRow.getProperty("GreigeLotRef") || "").trim();
                    if (!sRef) { return; }
                    if (!oSeen[sRef]) {
                        oSeen[sRef] = { ref: sRef, count: 0,
                                        order: oRow.getProperty("ProductionOrder") || "",
                                        batch: oRow.getProperty("BatchNumber") || "",
                                        material: oRow.getProperty("GreigeMaterial") || "" };
                        aRows.push(oSeen[sRef]);
                    }
                    oSeen[sRef].count += 1;
                });
                if (!aRows.length) {
                    oList.setNoDataText(that._t("msgNoOpenBatches"));
                }
                aRows.forEach(function (o) {
                    oList.addItem(new StandardListItem({
                        title: o.ref,
                        description: that._t("msgOpenBatchesBehind", [o.count, o.batch, o.order]),
                        info: o.material,
                        type: "Active",
                        press: function () {
                            oTargetInput.setValue(o.ref);
                            oTargetInput.setValueState("None");
                            if (oOrderText && o.count === 1) { oOrderText.setText(o.order); }
                            oDialog.close();
                        }
                    }));
                });
            }).catch(function (oErr) {
                oList.setBusy(false);
                MessageBox.error(that._errorText(oErr, "Could not read the plant's batches"));
            });

            this.getView().addDependent(oDialog);
            oDialog.open();
        },

        // A second round trip on purpose. The usage decision posts its stock
        // movement in its own update task; a transfer issued in that same LUW
        // would read stock that has not moved yet and fail on a deficit. That
        // is why this is a button and not part of Save.
        _postRelease: function (oIn) {
            var oCtx = this.getView().getBindingContext();
            var oAction = this.getView().getModel().bindContext(
                "com.sap.gateway.srvd.zui_qc_inspection.v0001.releaseToProduction(...)", oCtx);

            // Every action parameter is Nullable="false" in the service
            // metadata, so all twelve must be supplied even when blank.
            oAction.setParameter("InspectionLot", this._sLot);
            oAction.setParameter("Material", oCtx.getProperty("Material") || "");
            oAction.setParameter("Batch", oCtx.getProperty("Batch") || "");
            oAction.setParameter("ToBatch", oIn.toBatch);
            oAction.setParameter("Plant", oCtx.getProperty("Plant") || "");
            oAction.setParameter("MovementType", oIn.move || MOVE_TYPE);
            oAction.setParameter("FromStorageLocation", oIn.from || SLOC_FROM);
            oAction.setParameter("ToStorageLocation", oIn.to || SLOC_TO);
            oAction.setParameter("Quantity", oIn.qty);
            oAction.setParameter("Unit", oCtx.getProperty("LotUnit") || "");
            oAction.setParameter("PostingDate", oIn.date || this._today());
            oAction.setParameter("HeaderText", oIn.text || "");

            oAction.execute("$auto").then(function () {
                MessageToast.show(this._t("msgReleased"));
                this._refreshLot();
            }.bind(this)).catch(function (oErr) {
                MessageBox.error(this._errorText(oErr, "Release failed"));
            }.bind(this));
        },

        // ------------------------------------------------------------------
        // helpers and formatters
        // ------------------------------------------------------------------
        _t: function (sKey, aArgs) {
            return this.getView().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
        },

        _today: function () {
            return new Date().toISOString().substring(0, 10);
        },

        _num: function (v) {
            if (v === undefined || v === null || v === "") { return ""; }
            var f = parseFloat(v);
            return isNaN(f) ? "" : String(f);
        },

        // The V4 model wraps backend messages in an Error whose message is the
        // first message text; RAP validation errors arrive the same way.
        _errorText: function (oErr, sFallback) {
            if (!oErr) { return sFallback; }
            if (oErr.error && oErr.error.message) { return oErr.error.message; }
            return oErr.message || sFallback;
        },

        fmtQty: function (v, u) {
            if (v === undefined || v === null || v === "") { return ""; }
            var f = parseFloat(v);
            if (isNaN(f)) { return ""; }
            return f.toFixed(3).replace(/\.?0+$/, "") + " " + (u || "");
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
            return aParts.join("  ·  ");
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
