sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/core/Messaging",
    "sap/ui/model/json/JSONModel",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/ui/model/Sorter",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (Controller, Messaging, JSONModel, Filter, FilterOperator, Sorter, MessageToast, MessageBox) {
    "use strict";

    // The deferred update group declared in manifest.json (updateGroupId).
    // Every cell edit becomes a pending PATCH in this group and nothing is
    // sent until Post Results submits the group as one $batch.
    var GROUP = "massEdit";

    return Controller.extend("kejriwal.qm.inspectionresultmass.controller.Worklist", {

        onInit: function () {
            // UI state model: filter values + dirty-row tracking.
            this.getView().setModel(new JSONModel({
                filter: { plant: "", material: "", inspectionLot: "", inspectionType: "" },
                dirtyCount: 0,
                hasResult: false
            }), "ui");
            this._dirty = {}; // context path -> bound context of edited rows
        },

        _table: function () { return this.byId("resultsTable"); },
        _ui: function () { return this.getView().getModel("ui"); },

        /**
         * Rebind the table with the chosen filters. Mass entry across many lots
         * is the whole point of this app, so filters are broad (plant / material
         * / lot / inspection type) and the table returns every characteristic
         * of every lot that has no usage decision yet - the view carries that
         * "open" condition, so the app never has to.
         *
         * The binding is created suspended in the view: nothing is read until
         * Go is pressed, so opening the app does not fetch every open
         * characteristic in the system.
         *
         * A V4 list binding refuses to filter while it has pending changes, and
         * pending edits from the previous result set must not ride along with
         * the next post - so unsent edits are discarded first, after asking.
         */
        onSearch: function () {
            var oModel = this.getView().getModel();
            if (oModel.hasPendingChanges(GROUP)) {
                MessageBox.confirm(this.getText("discardConfirm", [Object.keys(this._dirty).length]), {
                    onClose: function (sAction) {
                        if (sAction === MessageBox.Action.OK) {
                            this._resetDirty(true);
                            this._applyFilters();
                        }
                    }.bind(this)
                });
                return;
            }
            this._resetDirty(false);
            this._applyFilters();
        },

        _applyFilters: function () {
            var oF = this._ui().getProperty("/filter"),
                aFilters = [],
                add = function (sProp, sVal, bUpper) {
                    var v = (sVal || "").trim();
                    if (v) { aFilters.push(new Filter(sProp, FilterOperator.EQ, bUpper ? v.toUpperCase() : v)); }
                };

            add("Plant", oF.plant, true);
            add("Material", oF.material, true);
            add("InspectionType", oF.inspectionType, false);
            // Inspection lot numbers are NUMC 12 - pad what the operator typed
            // so "890000000100" and "100" mean the same lot.
            var sLot = (oF.inspectionLot || "").trim();
            if (sLot) {
                if (/^\d+$/.test(sLot)) { sLot = ("000000000000" + sLot).slice(-12); }
                aFilters.push(new Filter("InspectionLot", FilterOperator.EQ, sLot));
            }

            var oBinding = this._table().getBinding("items");
            oBinding.filter(aFilters);
            if (oBinding.isSuspended()) { oBinding.resume(); }
            oBinding.attachEventOnce("dataReceived", function () {
                this._ui().setProperty("/hasResult", true);
            }, this);
        },

        /** Track which rows the user has edited so we can post only those. */
        onResultChange: function (oEvent) {
            var oCtx = oEvent.getSource().getBindingContext();
            if (oCtx) {
                this._dirty[oCtx.getPath()] = oCtx;
                this._ui().setProperty("/dirtyCount", Object.keys(this._dirty).length);
            }
        },

        /**
         * Post all edited results in one round trip.
         *
         * submitBatch resolves when the $batch has been answered - not when
         * every request in it succeeded. A row the backend rejected keeps its
         * PATCH pending on the model and its message lands in the message
         * model, so both are checked before anything is called "posted".
         */
        onPostResults: function () {
            var oModel = this.getView().getModel(),
                aPaths = Object.keys(this._dirty),
                iCount = aPaths.length;
            if (!iCount) {
                MessageToast.show(this.getText("noChanges"));
                return;
            }

            // Every validation error the backend reports is targeted at the
            // row it belongs to; clear the previous round's messages first so
            // a stale one is not counted against this post.
            this._clearRowMessages(aPaths);
            this.getView().setBusy(true);

            oModel.submitBatch(GROUP).then(function () {
                this.getView().setBusy(false);

                var aFailed = aPaths.filter(function (sPath) {
                    var oCtx = this._dirty[sPath];
                    return oCtx && oCtx.hasPendingChanges();
                }, this);
                var aErrors = this._rowErrorTexts(aPaths);

                if (!aFailed.length && !aErrors.length) {
                    MessageToast.show(this.getText("postSuccess", [iCount]));
                    this._resetDirty(false);
                    this._table().getBinding("items").refresh();
                    return;
                }

                // Keep the failed rows dirty so the operator can correct and
                // post again; forget the ones that went through.
                aPaths.forEach(function (sPath) {
                    if (aFailed.indexOf(sPath) === -1) { delete this._dirty[sPath]; }
                }, this);
                this._ui().setProperty("/dirtyCount", Object.keys(this._dirty).length);

                var iOk = iCount - aFailed.length;
                MessageBox.error(this.getText("postPartial", [iOk, aFailed.length]) +
                    (aErrors.length ? "\n\n" + aErrors.join("\n") : ""));
            }.bind(this)).catch(function (oError) {
                this.getView().setBusy(false);
                MessageBox.error(this.getText("postError") + "\n" + (oError && oError.message ? oError.message : ""));
            }.bind(this));
        },

        _rowErrorTexts: function (aPaths) {
            var aOut = [];
            (Messaging.getMessageModel().getData() || []).forEach(function (oMsg) {
                if (oMsg.getType() !== "Error") { return; }
                var aTargets = oMsg.getTargets ? oMsg.getTargets() : [oMsg.getTarget()];
                var bMine = !aTargets.length || aTargets.some(function (sT) {
                    return aPaths.some(function (sP) { return sT && sT.indexOf(sP) === 0; });
                });
                if (bMine && aOut.indexOf(oMsg.getMessage()) === -1) { aOut.push(oMsg.getMessage()); }
            });
            return aOut;
        },

        _clearRowMessages: function (aPaths) {
            var aOld = (Messaging.getMessageModel().getData() || []).filter(function (oMsg) {
                var aTargets = oMsg.getTargets ? oMsg.getTargets() : [oMsg.getTarget()];
                return aTargets.some(function (sT) {
                    return aPaths.some(function (sP) { return sT && sT.indexOf(sP) === 0; });
                });
            });
            if (aOld.length) { Messaging.removeMessages(aOld); }
        },

        _resetDirty: function (bDiscardPending) {
            // With the deferred "massEdit" group, edits not yet posted are pending
            // on the model - when the user rebinds (new filters) those stale
            // PATCHes must be dropped, or they'd ride along with the NEXT post.
            if (bDiscardPending) {
                var oModel = this.getView().getModel();
                if (oModel.hasPendingChanges(GROUP)) { oModel.resetChanges(GROUP); }
            }
            this._dirty = {};
            this._ui().setProperty("/dirtyCount", 0);
        },

        /** Open a Sort dialog built generically from the table columns. */
        onOpenSort: function () {
            var oTable = this._table(), that = this;
            sap.ui.require(["sap/m/ViewSettingsDialog", "sap/m/ViewSettingsItem"], function (VSD, VSI) {
                if (!that._oSortDialog) {
                    var oVSD = new VSD({
                        confirm: function (oEvt) {
                            var oItem = oEvt.getParameter("sortItem"), bDesc = oEvt.getParameter("sortDescending");
                            var oBinding = oTable.getBinding("items");
                            if (!oItem || !oBinding) { return; }
                            if (oBinding.hasPendingChanges()) {
                                MessageToast.show(that.getText("postOrDiscardFirst"));
                                return;
                            }
                            oBinding.sort(new Sorter(oItem.getKey(), bDesc));
                        }
                    });
                    that._columnPaths().forEach(function (o) {
                        oVSD.addSortItem(new VSI({ key: o.path, text: o.label }));
                    });
                    that._oSortDialog = oVSD;
                    that.getView().addDependent(oVSD);
                }
                that._oSortDialog.open();
            });
        },

        /** Column label + bound property for every column that binds one. */
        _columnPaths: function () {
            var oTable = this._table(),
                oInfo = oTable.getBindingInfo("items"),
                aCells = oInfo && oInfo.template ? oInfo.template.getCells() : [],
                aOut = [];
            oTable.getColumns().forEach(function (oCol, i) {
                var oHdr = oCol.getHeader();
                var sLabel = (oHdr && oHdr.getText) ? oHdr.getText() : ("Column " + (i + 1));
                var oCell = aCells[i], sPath = "";
                if (oCell) {
                    var b = oCell.getBindingInfo("text") || oCell.getBindingInfo("value") || oCell.getBindingInfo("selectedKey");
                    if (b && b.parts && b.parts[0]) { sPath = b.parts[0].path; }
                }
                if (sPath) { aOut.push({ label: sLabel, path: sPath }); }
            });
            return aOut;
        },

        /** Export the loaded rows to Excel (.xlsx). */
        onExportExcel: function () {
            var oBinding = this._table().getBinding("items"),
                that = this;
            if (!oBinding) { return; }
            var aCtx = oBinding.getAllCurrentContexts ? oBinding.getAllCurrentContexts() : oBinding.getCurrentContexts();
            var aData = aCtx.filter(Boolean).map(function (c) { return c.getObject(); });
            if (!aData.length) {
                MessageToast.show(this.getText("noExport"));
                return;
            }
            var aCols = this._columnPaths().map(function (o) { return { label: o.label, property: o.path, width: 18 }; });
            sap.ui.require(["sap/ui/export/Spreadsheet"], function (Spreadsheet) {
                var oSheet = new Spreadsheet({
                    workbook: { columns: aCols },
                    dataSource: aData,
                    fileName: that.getText("appTitle") + ".xlsx"
                });
                oSheet.build().finally(function () { oSheet.destroy(); });
            });
        },

        getText: function (sKey, aArgs) {
            return this.getView().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
        }
    });
});
