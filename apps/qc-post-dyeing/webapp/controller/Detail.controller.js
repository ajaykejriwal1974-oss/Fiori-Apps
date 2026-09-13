sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/Dialog",
    "sap/m/List",
    "sap/m/StandardListItem",
    "sap/m/Button",
    "sap/m/SelectDialog",
    "sap/m/Label",
    "sap/m/Input",
    "sap/m/Text",
    "sap/m/CheckBox",
    "sap/m/DatePicker",
    "sap/ui/layout/form/SimpleForm",
    "sap/ui/model/json/JSONModel",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/ui/model/Sorter"
], function (Controller, MessageToast, MessageBox, Dialog, List, StandardListItem, Button, SelectDialog,
             Label, Input, Text, CheckBox, DatePicker, SimpleForm, JSONModel, Filter, FilterOperator, Sorter) {
    "use strict";

    // Selected set and code group for the usage decision. ZQC-UD exists as a
    // code group (plant independent) and as a selected set in plants 1000 and
    // 2002 (V_QPAM_UD, customizing request KSDK906757). If a plant is added
    // without the set, BAPI_INSPLOT_SETUSAGEDECISION rejects the decision and
    // the error surfaces in the dialog - nothing is posted.
    var UD_SELECTED_SET = "ZQC-UD",
        UD_CODE_GROUP   = "ZQC-UD";

    // Mirrors selected set ZQC-UD as read from QPAC on 2026-08-28. A, A1 and
    // SP are valuated A (accept); the other six R (reject). RD and ST hand the
    // batch back to the dye house - see msgRedye.
    var UD_CODES = [
        { key: "A",   text: "Accept" },
        { key: "A1",  text: "Accept with deviation" },
        { key: "SP",  text: "Small Package" },
        { key: "CLQ", text: "Claim Less" },
        { key: "DG",  text: "Downgrade" },
        { key: "JL",  text: "Job Lot" },
        { key: "RD",  text: "Re-Dyeing/Correction" },
        { key: "ST",  text: "Stripping" },
        { key: "PQ",  text: "Poor Quality" }
    ];

    // Master inspection characteristic the shade panel writes into. The plant
    // 2002 plan (PLANT-2002-QM-SETUP.md, step 4) carries a "shade" result on
    // the post-dyeing plan; the quantitative delta E MIC is not created yet,
    // so every name the plant might give it is tolerated here. Until one of
    // them is in the plan the panel says so and the reading is NOT saved.
    var DE_MICS = ["DELTAE", "DELTA_E", "DE", "DE_CMC", "S2_DE", "SHADE_DE"];

    // Properties the controller reads with getProperty() but that no control
    // in the view binds. The model runs with autoExpandSelect, which derives
    // $select from the BOUND properties only - anything read here and bound
    // nowhere came back undefined, so the confirmation dialog posted a blank
    // Plant and the batch picker built a filter on "undefined" and threw.
    var LOT_SELECT = [
        "InspectionLot", "Plant", "CompanyCode", "InspectionType", "Material", "MaterialName",
        "Batch", "VendorBatch", "GreigeLot", "GreigeLotRef", "ProductionLot", "ProductionOrder", "OrderSource",
        "BatchSource", "PlantBatch", "PlantBatchYear", "JobCard",
        "DyeingWorkCentre", "WindingWorkCentre", "BatchQuantity", "BatchUnit", "BatchCheeses",
        "LotQuantity", "LotUnit", "SampleSize", "SampleUnit", "CreatedOn",
        "ResultsConfirmed", "UsageDecisionMade", "IsOpen"
    ].join(",");

    return Controller.extend("kejriwal.qm.qcpostdyeing.controller.Detail", {

        onInit: function () {
            this.getOwnerComponent().getRouter()
                .getRoute("detail").attachPatternMatched(this._onMatched, this);
            this.getView().setModel(new JSONModel({ lot: "", batch: "", chars: [], busy: false }), "rm");
        },

        // --- Raw material reference -------------------------------------
        // Which greige lot this batch came from is picked by the operator.
        // SAP knows the link through batch genealogy, but reading it needs a
        // CDS view over the order components that does not exist yet. Manual
        // selection is honest about that and puts the incoming figures in
        // front of the inspector now rather than after the next transport.

        RM_TYPES: ["01", "08"],

        // Tolerant on naming: the plant 2002 MICs are DENIER / ELONG /
        // FILAMENT (QS21, 2026-08-28); the other names cover plants that
        // named them differently.
        INCOMING_MAP: {
            denier:          ["DENIER", "Z010", "S1_DEN"],
            elongation:      ["ELONG", "Z020", "S1_ELG"],
            brokenFilaments: ["BROKENF", "BRK_FIL", "S1_BFL"]
        },

        // One dialog, built once and reused. sap.m.SelectDialog has no
        // afterClose event (checked against the 1.136 class metadata), so a
        // per-press dialog could never be released - it leaked one dialog
        // plus one list binding per press.
        onSelectRmLot: function () {
            var that = this,
                oView = this.getView();

            if (!this._oRmDialog) {
                var aTypes = this.RM_TYPES.map(function (sT) {
                    return new Filter("InspectionType", FilterOperator.EQ, sT);
                });
                this._aRmTypeFilter = [ new Filter({ filters: aTypes, and: false }) ];

                this._oRmDialog = new SelectDialog({
                    title: this._t("rmLotTitle"),
                    noDataText: this._t("rmLotNoData"),
                    growing: true,
                    growingThreshold: 50,
                    rememberSelections: false,
                    items: {
                        path: "/InspectionLot",
                        sorter: new Sorter("CreatedOn", true),
                        filters: this._aRmTypeFilter,
                        parameters: { $select: "InspectionLot,Batch,Material,MaterialName,Plant,CreatedOn" },
                        template: new StandardListItem({
                            title: "{Batch}",
                            description: "{MaterialName}",
                            info: "{InspectionLot}"
                        })
                    },
                    search:     function (oEvt) { that._filterRmDialog(oEvt); },
                    liveChange: function (oEvt) { that._filterRmDialog(oEvt); },
                    confirm: function (oEvt) {
                        var oItem = oEvt.getParameter("selectedItem");
                        if (oItem) { that._applyRmLot(oItem.getInfo(), oItem.getTitle()); }
                    },
                    cancel: function () { }
                });
                oView.addDependent(this._oRmDialog);
                this._oRmDialog.setModel(oView.getModel());
            }
            var oBinding = this._oRmDialog.getBinding("items");
            if (oBinding) { oBinding.filter(this._aRmTypeFilter); }
            this._oRmDialog.open();
        },

        _filterRmDialog: function (oEvt) {
            var sVal = (oEvt.getParameter("value") || "").trim(),
                aF = this._aRmTypeFilter.slice();
            if (sVal) {
                aF.push(new Filter({
                    filters: [
                        new Filter("Batch", FilterOperator.Contains, sVal.toUpperCase()),
                        new Filter("Material", FilterOperator.Contains, sVal.toUpperCase()),
                        new Filter("MaterialName", FilterOperator.Contains, sVal)
                    ],
                    and: false
                }));
            }
            oEvt.getSource().getBinding("items").filter(aF);
        },

        // Read once into a JSON model rather than binding the panel to OData.
        // The reference data is display-only, and a second OData list binding
        // here would be one more thing capable of queueing a PATCH.
        _applyRmLot: function (sLot, sBatch) {
            var that = this,
                oRm = this.getView().getModel("rm");

            oRm.setProperty("/lot", sLot);
            oRm.setProperty("/batch", sBatch || "");
            oRm.setProperty("/chars", []);
            oRm.setProperty("/busy", true);

            this.getView().getModel()
                .bindList("/InspectionLot('" + sLot + "')/_Characteristic", null, null, null,
                          { $select: "CharacteristicName,MasterCharacteristic,MeanValue,ResultCode,CharacteristicUnit,Valuation" })
                .requestContexts(0, 200)
                .then(function (aCtx) {
                    var aChars = aCtx.map(function (oCtx) {
                        return {
                            name:      oCtx.getProperty("CharacteristicName"),
                            master:    oCtx.getProperty("MasterCharacteristic"),
                            value:     oCtx.getProperty("MeanValue"),
                            code:      oCtx.getProperty("ResultCode"),
                            unit:      oCtx.getProperty("CharacteristicUnit"),
                            valuation: oCtx.getProperty("Valuation")
                        };
                    });
                    oRm.setProperty("/chars", aChars);
                    oRm.setProperty("/busy", false);
                    that._incoming = that._mapIncoming(aChars);
                    if (that.onPairedChange) { that.onPairedChange(); }
                })
                .catch(function (oErr) {
                    oRm.setProperty("/busy", false);
                    MessageBox.error(that._errorText(oErr, "Could not read that raw material lot"));
                });
        },

        // Find the stage 1 inspection of the greige lot behind this batch, so
        // the incoming figures arrive without anyone hunting for them.
        //
        // Inert by design as of 2026-08-28: GreigeLot is blank on in-process
        // lots because nothing in this system records which greige fed which
        // batch (ZPP_BATCHN-LOTNO stopped being a lot number in 2013). The
        // guard below returns immediately; the moment a genealogy link exists,
        // this is the hook that consumes it. Quiet about failure on purpose -
        // the manual picker is still there.
        _loadIncoming: function () {
            var oCtx = this.getView().getBindingContext();
            if (!oCtx) { return; }

            var sGreige = oCtx.getProperty("GreigeLot"),
                sPlant  = oCtx.getProperty("Plant"),
                that    = this;

            if (!sGreige || !sPlant || sGreige === oCtx.getProperty("Batch")) { return; }

            var aTypes = this.RM_TYPES.map(function (sType) {
                return new Filter("InspectionType", FilterOperator.EQ, sType);
            });

            this.getView().getModel().bindList("/InspectionLot", null,
                [ new Sorter("CreatedOn", true) ],
                [ new Filter({ filters: aTypes, and: false }),
                  new Filter("Plant", FilterOperator.EQ, sPlant),
                  new Filter("Batch", FilterOperator.EQ, sGreige) ],
                { $select: "InspectionLot,Batch,CreatedOn" }
            ).requestContexts(0, 1).then(function (aCtx) {
                if (aCtx.length) {
                    that._applyRmLot(aCtx[0].getProperty("InspectionLot"),
                                     aCtx[0].getProperty("Batch"));
                }
            }).catch(function () { /* manual picker remains */ });
        },

        _mapIncoming: function (aChars) {
            var oOut = {}, oMap = this.INCOMING_MAP;
            Object.keys(oMap).forEach(function (sKey) {
                var aNames = oMap[sKey];
                var oHit = aChars.filter(function (o) { return aNames.indexOf((o.master || "").toUpperCase()) > -1; })[0];
                if (oHit && oHit.value !== undefined && oHit.value !== null && oHit.value !== "") {
                    var f = parseFloat(oHit.value);
                    if (!isNaN(f)) { oOut[sKey] = f; }
                }
            });
            return Object.keys(oOut).length ? oOut : null;
        },

        fmtRmValue: function (vValue, sUnit, sCode) {
            if (vValue === undefined || vValue === null || vValue === "") { return sCode || ""; }
            var f = parseFloat(vValue);
            if (isNaN(f)) { return sCode || ""; }
            return f.toFixed(2).replace(/\.?0+$/, "") + " " + (sUnit || "");
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
            this._resetShadePanel();

            // A different lot means a different greige lot - never carry the
            // previous reference forward, it would silently mislead.
            var oRm = this.getView().getModel("rm");
            if (oRm) { oRm.setData({ lot: "", batch: "", chars: [], busy: false }); }
            this._incoming = null;
            // The element binding has no data yet at this point, so GreigeLot
            // cannot be read here - wait for the read to come back.
            var oElem = this.getView().getElementBinding();
            if (oElem) { oElem.attachEventOnce("dataReceived", this._loadIncoming, this); }

            // Until the dye recipe is separately identified in SAP (open
            // item 8 in the QM workbook) the app cannot tell whether this
            // is the qualifying batch. Default to requiring the battery -
            // over-testing is recoverable, silently skipping fastness on a
            // new recipe is not.
            this._setRecipeMode(true);
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
        // it can actually be saved - the shade panel therefore marks the lot
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

        // All characteristic contexts of the lot. lstOther carries no server
        // filter, so it is populated whenever the lot has a plan at all -
        // unlike lstVariation, which is filtered to the grey-scale set.
        _charContexts: function () {
            var oList = this.byId("lstOther"),
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
        // Returns "" when nothing is loaded - the caller says so instead of
        // guessing an operation the lot may not have.
        _currentOperationNumber: function () {
            var aCtx = this._charContexts();
            return aCtx.length ? (aCtx[0].getProperty("OperationNumber") || "") : "";
        },

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

        // A usage decision closes the lot; the app cannot undo it. One
        // accidental tap on a list row must not be enough to post it.
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
            oAction.setParameter("Reason", oPick.text);

            oAction.execute("$auto").then(function () {
                MessageToast.show(this._t("msgUdSet"));
                // A re-dye or strip decision hands over to the existing loop.
                // The app tells the technician what to do next; it does not
                // reopen the batch for them, because that has stock effects.
                if (oPick.key === "RD" || oPick.key === "ST") {
                    MessageBox.information(this._t("msgRedye"));
                }
                this._refreshLot();
            }.bind(this)).catch(function (oErr) {
                MessageBox.error(this._errorText(oErr, "Usage decision failed"));
            }.bind(this));
        },

        // --- Stage 2: shade readout ------------------------------------
        // Judged here, and stored: the reading goes into the lot's delta E
        // characteristic so Save carries it to QM like any other result. When
        // the plan has no such characteristic the panel says so and nothing
        // pretends to be saved.
        onDeltaEChange: function () {
            var f = parseFloat(this.byId("deInput").getValue()),
                oStatus = this.byId("deStatus"),
                oHint = this.byId("deHint"),
                oTarget = this.byId("deTarget");

            if (isNaN(f)) {
                oStatus.setText(""); oStatus.setState("None"); oHint.setText("");
                oTarget.setText(""); oTarget.setState("None");
                return;
            }

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

            var oCtx = this._findChar(DE_MICS);
            if (!oCtx) {
                oTarget.setText(this._t("msgPanelNotInPlan"));
                oTarget.setState("Warning");
                return;
            }
            // setProperty returns a promise for a PATCH that is never sent;
            // resetChanges rejects it, so swallow that.
            oCtx.setProperty("MeanValue", Math.round(f * 100) / 100).catch(function () {});
            this._touch(oCtx);
            oTarget.setText(this._t("msgPanelTarget", [oCtx.getProperty("CharacteristicName") || oCtx.getProperty("MasterCharacteristic")]));
            oTarget.setState("Information");
        },

        _resetShadePanel: function () {
            var oIn = this.byId("deInput"); if (oIn) { oIn.setValue(""); }
            ["deStatus", "deTarget"].forEach(function (s) {
                var o = this.byId(s); if (o) { o.setText(""); o.setState("None"); }
            }, this);
            var oHint = this.byId("deHint"); if (oHint) { oHint.setText(""); }
        },

        // The delta E characteristic is entered through the shade panel, not
        // as a plain number in the "Visual and chemical" list - two entry
        // points for one result would let them disagree.
        isOtherRow: function (sSet, sKind, sMic) {
            if (DE_MICS.indexOf((sMic || "").toUpperCase()) > -1) { return false; }
            return sSet === "ZQC_PF" || sKind === "QUAN";
        },

        // Fastness is a property of the recipe, not the batch. The panel only
        // matters for the qualifying batch, and the technician should be told
        // which case they are in rather than left to remember.
        _setRecipeMode: function (bFirst) {
            this._ui().setProperty("/isFirstOfRecipe", bFirst);
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

        // --- follow-on: post the dyeing confirmation ------------------------
        //
        // Operation 0010 on work centre DyeingWorkCentre, read from AFRU in
        // plant 2002 - the routing already carries both operations and both
        // are confirmed today. This posts through BAPI_PRODORDCONF_CREATE_TT,
        // the same BAPI ZCO11A calls, so the confirmation is indistinguishable
        // from one made on the shop floor except that it also leaves a row in
        // ZQC_CONF_BATCH naming the inspection lot that released it.
        //
        // A second round trip on purpose: the usage decision posts in its own
        // update task, and the backend disables this action until that
        // decision is on the database and accepting.
        onconfirmDyeing: function () {
            this._openConfirmation("0010", "DyeingWorkCentre", "confirmDyeing");
        },

        _openConfirmation: function (sDefaultOp, sWcProp, sTitleKey) {
            var oCtx = this.getView().getBindingContext();
            if (!oCtx || !this._requireSaved()) { return; }
            if (oCtx.getProperty("UsageDecisionMade") !== "X") {
                MessageBox.information(this._t("msgUdFirstConfirm"));
                return;
            }
            var that = this;

            // An order here routinely carries five or six batches, and a
            // confirmation posts quantity against exactly one of them. Where
            // the lot resolved its own batch (BatchSource 'C') this is
            // pre-filled; where it did not, it stays empty and the operator
            // picks. It is never guessed.
            var bResolved = oCtx.getProperty("BatchSource") === "C";
            var sBatch  = bResolved ? (oCtx.getProperty("PlantBatch") || "") : "";
            var oYearHolder = { year: bResolved ? (oCtx.getProperty("PlantBatchYear") || "") : "" };
            var oJobTxt = new Text({ text: sBatch ? (oCtx.getProperty("JobCard") || "") : "" });

            var oBatchIn = new Input({
                value: sBatch,
                placeholder: this._t("phPickBatch"),
                showValueHelp: true,
                valueHelpRequest: function () { that._openBatchPicker(oBatchIn, oJobTxt, oYearHolder); }
            });

            var oOp     = new Input({ value: sDefaultOp, maxLength: 4 });
            var oWc     = new Input({ value: oCtx.getProperty(sWcProp) || "", maxLength: 8 });
            var oYield  = new Input({ value: this._num(oCtx.getProperty("BatchQuantity")), type: "Number", textAlign: "End" });
            var oScrap  = new Input({ value: "0", type: "Number", textAlign: "End" });
            var oCheese = new Input({ value: this._num(oCtx.getProperty("BatchCheeses")), type: "Number", textAlign: "End" });
            var oFinal  = new CheckBox({ selected: false });
            var oDate   = new DatePicker({ dateValue: new Date(), valueFormat: "yyyy-MM-dd" });
            var oTxt    = new Input({ maxLength: 40 });

            var oForm = new SimpleForm({
                editable: true,
                layout: "ResponsiveGridLayout",
                content: [
                    new Label({ text: this._t("lblOrder") }),
                    new Text({ text: oCtx.getProperty("ProductionOrder") || "" }),
                    new Label({ text: this._t("lblPlantBatch"), required: true }),
                    oBatchIn,
                    new Label({ text: this._t("lblJobCard") }),
                    oJobTxt,
                    new Label({ text: this._t("lblOperation"), required: true }),
                    oOp,
                    new Label({ text: this._t("lblWorkCentre"), required: true }),
                    oWc,
                    new Label({ text: this._t("lblYield") }),
                    oYield,
                    new Label({ text: this._t("lblScrap") }),
                    oScrap,
                    new Label({ text: this._t("lblUnit") }),
                    new Text({ text: oCtx.getProperty("BatchUnit") || "" }),
                    new Label({ text: this._t("lblCheeses") }),
                    oCheese,
                    new Label({ text: this._t("lblFinalConf") }),
                    oFinal,
                    new Label({ text: this._t("lblPostingDate"), required: true }),
                    oDate,
                    new Label({ text: this._t("lblConfText") }),
                    oTxt
                ]
            });

            var fnInvalid = function (oCtl, sMsg) {
                oCtl.setValueState("Error");
                oCtl.setValueStateText(sMsg);
                oCtl.focus();
            };

            var oDialog = new Dialog({
                title: this._t(sTitleKey),
                contentWidth: "32rem",
                content: [ oForm ],
                beginButton: new Button({
                    text: this._t("confirm"),
                    type: "Accept",
                    press: function () {
                        [oBatchIn, oOp, oWc, oYield, oScrap, oDate].forEach(function (c) { c.setValueState("None"); });
                        if (!oBatchIn.getValue().trim()) { fnInvalid(oBatchIn, that._t("msgPickBatch")); return; }
                        if (!oOp.getValue().trim())      { fnInvalid(oOp, that._t("msgRequired")); return; }
                        if (!oWc.getValue().trim())      { fnInvalid(oWc, that._t("msgWorkCentre")); return; }
                        var fYield = parseFloat(oYield.getValue()) || 0,
                            fScrap = parseFloat(oScrap.getValue()) || 0;
                        if (fYield < 0 || fScrap < 0) { fnInvalid(fYield < 0 ? oYield : oScrap, that._t("msgQtyNotNegative")); return; }
                        if (!fYield && !fScrap) { fnInvalid(oYield, that._t("msgNeedQty")); return; }
                        if (!oDate.getValue()) { fnInvalid(oDate, that._t("msgRequired")); return; }
                        if (!oCtx.getProperty("ProductionOrder")) {
                            MessageBox.error(that._t("msgNoOrder"));
                            return;
                        }
                        oDialog.close();
                        that._postConfirmation({
                            batch:   oBatchIn.getValue().trim(),
                            year:    oYearHolder.year,
                            job:     oJobTxt.getText(),
                            op:      oOp.getValue().trim(),
                            wc:      oWc.getValue().trim().toUpperCase(),
                            yield:   fYield,
                            scrap:   fScrap,
                            cheeses: parseFloat(oCheese.getValue()) || 0,
                            final:   oFinal.getSelected() ? "X" : "",
                            date:    oDate.getValue(),
                            text:    oTxt.getValue()
                        }, sDefaultOp);
                    }
                }),
                endButton: new Button({ text: this._t("cancel"), press: function () { oDialog.close(); } }),
                afterClose: function () { oDialog.destroy(); }
            });

            this.getView().addDependent(oDialog);
            oDialog.open();
        },

        // OrderBatch is ZI_QC_BATCH_JOB on the same service. Scoped to this
        // lot's order so the operator is choosing between the batches of the
        // order in front of them, not every batch in the plant. Closed batches
        // are excluded - they have already been reconciled for gain and loss.
        // Without an order the list would be the whole plant; the dialog says
        // so instead of offering 130,000 rows.
        _openBatchPicker: function (oTargetInput, oJobTxt, oYearHolder) {
            var oCtx = this.getView().getBindingContext(),
                that = this,
                sOrder = oCtx.getProperty("ProductionOrder") || "";

            var oList = new List({ mode: "SingleSelectMaster", includeItemInSelection: true, growing: true, growingThreshold: 30 });
            var oDialog = new Dialog({
                title: this._t("pickBatch"),
                contentWidth: "30rem",
                contentHeight: "26rem",
                content: [ oList ],
                endButton: new Button({ text: this._t("cancel"), press: function () { oDialog.close(); } }),
                afterClose: function () { oDialog.destroy(); }
            });
            this.getView().addDependent(oDialog);

            if (!sOrder) {
                oList.setNoDataText(this._t("msgNoOrder"));
                oDialog.open();
                return;
            }

            var aFilters = [
                new Filter("Plant", FilterOperator.EQ, oCtx.getProperty("Plant") || ""),
                new Filter("ProductionOrder", FilterOperator.EQ, sOrder),
                new Filter("BatchClosed", FilterOperator.NE, "X")
            ];

            oList.setBusy(true);
            this.getView().getModel().bindList("/OrderBatch", null, [ new Sorter("BatchDate", true) ], aFilters, {
                $select: "BatchNumber,FiscalYear,GreigeLotRef,ProductionOrder,JobCard,BatchQuantity,BatchUnit,Cheeses,BatchDate"
            }).requestContexts(0, 200).then(function (aCtx) {
                oList.setBusy(false);
                if (!aCtx.length) { oList.setNoDataText(that._t("msgNoOpenBatches")); }
                aCtx.forEach(function (oRow) {
                    oList.addItem(new StandardListItem({
                        title: oRow.getProperty("BatchNumber"),
                        description: that._t("colGreigeLot") + " " + (oRow.getProperty("GreigeLotRef") || "")
                                   + "  ·  " + that._t("colJobCard") + " " + (oRow.getProperty("JobCard") || ""),
                        info: that.fmtQty(oRow.getProperty("BatchQuantity"), oRow.getProperty("BatchUnit")),
                        type: "Active",
                        press: function () {
                            oTargetInput.setValue(oRow.getProperty("BatchNumber"));
                            oTargetInput.setValueState("None");
                            oJobTxt.setText(oRow.getProperty("JobCard") || "");
                            oYearHolder.year = oRow.getProperty("FiscalYear") || "";
                            oDialog.close();
                        }
                    }));
                });
            }).catch(function (oErr) {
                oList.setBusy(false);
                MessageBox.error(that._errorText(oErr, "Could not read the order's batches"));
            });

            oDialog.open();
        },

        _postConfirmation: function (oIn, sDefaultOp) {
            var oCtx = this.getView().getBindingContext();
            var oAction = this.getView().getModel().bindContext(
                "com.sap.gateway.srvd.zui_qc_inspection.v0001.confirmDyeing(...)", oCtx);

            // Every action parameter is Nullable="false" in the service
            // metadata, so all fifteen must be supplied even when blank.
            oAction.setParameter("InspectionLot", this._sLot);
            oAction.setParameter("ProductionOrder", oCtx.getProperty("ProductionOrder") || "");
            oAction.setParameter("PlantBatch", oIn.batch);
            oAction.setParameter("PlantBatchYear", oIn.year || this._today().substring(0, 4));
            oAction.setParameter("JobCard", oIn.job || "");
            oAction.setParameter("Operation", oIn.op || sDefaultOp);
            oAction.setParameter("WorkCentre", oIn.wc || "");
            oAction.setParameter("Plant", oCtx.getProperty("Plant") || "");
            oAction.setParameter("YieldQuantity", oIn.yield);
            oAction.setParameter("ScrapQuantity", oIn.scrap);
            oAction.setParameter("Unit", oCtx.getProperty("BatchUnit") || oCtx.getProperty("LotUnit") || "");
            oAction.setParameter("Cheeses", oIn.cheeses);
            oAction.setParameter("FinalConfirmation", oIn.final || "");
            oAction.setParameter("PostingDate", oIn.date || this._today());
            oAction.setParameter("ConfirmationText", oIn.text || "");

            oAction.execute("$auto").then(function () {
                MessageToast.show(this._t("msgConfirmed"));
                this._refreshLot();
            }.bind(this)).catch(function (oErr) {
                MessageBox.error(this._errorText(oErr, "Confirmation failed"));
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
