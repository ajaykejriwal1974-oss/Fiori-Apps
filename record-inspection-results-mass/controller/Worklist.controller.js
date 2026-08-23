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

        /** Open a Sort dialog built generically from the table columns. */
        onOpenSort: function () {
            var oTable = this.byId("table") || this.byId("tbl");
            if (!oTable) { return; }
            var that = this;
            sap.ui.require(["sap/m/ViewSettingsDialog", "sap/m/ViewSettingsItem", "sap/ui/model/Sorter"], function (VSD, VSI, Sorter) {
                if (!that._oSortDialog) {
                    var oInfo = oTable.getBindingInfo("items");
                    var aCells = oInfo ? oInfo.template.getCells() : [];
                    var oVSD = new VSD({
                        confirm: function (oEvt) {
                            var oItem = oEvt.getParameter("sortItem"), bDesc = oEvt.getParameter("sortDescending");
                            var oBinding = oTable.getBinding("items");
                            if (oItem && oBinding) { oBinding.sort(new Sorter(oItem.getKey(), bDesc)); }
                        }
                    });
                    oTable.getColumns().forEach(function (oCol, i) {
                        var oHdr = oCol.getHeader();
                        var sLabel = (oHdr && oHdr.getText) ? oHdr.getText() : ("Column " + (i + 1));
                        var oCell = aCells[i], sPath = "";
                        if (oCell) {
                            var b = oCell.getBindingInfo("text") || oCell.getBindingInfo("number") || oCell.getBindingInfo("value");
                            if (b && b.parts && b.parts[0]) { sPath = b.parts[0].path; }
                        }
                        if (sPath) { oVSD.addSortItem(new VSI({ key: sPath, text: sLabel })); }
                    });
                    that._oSortDialog = oVSD;
                    that.getView().addDependent(oVSD);
                }
                that._oSortDialog.open();
            });
        },


        /** Export current table rows to Excel (.xlsx). Generic - reads the table's
         *  columns + cell binding paths and exports the loaded/filtered rows. */
        onExportExcel: function () {
            var oTable = this.byId("table") || this.byId("tbl");
            if (!oTable) { return; }
            var oInfo = oTable.getBindingInfo("items"), oBinding = oTable.getBinding("items");
            if (!oInfo || !oBinding) { return; }
            var aCells = oInfo.template.getCells(), aCols = [];
            oTable.getColumns().forEach(function (oCol, i) {
                var oHdr = oCol.getHeader();
                var sLabel = (oHdr && oHdr.getText) ? oHdr.getText() : ("Column " + (i + 1));
                var oCell = aCells[i], sPath = "";
                if (oCell) {
                    var b = oCell.getBindingInfo("text") || oCell.getBindingInfo("number") || oCell.getBindingInfo("value");
                    if (b && b.parts && b.parts[0]) { sPath = b.parts[0].path; }
                }
                if (sPath) { aCols.push({ label: sLabel, property: sPath, width: 18 }); }
            });
            var aData = (oBinding.getContexts() || []).map(function (c) { return c.getObject(); });
            if (!aData.length) {
                sap.ui.require(["sap/m/MessageToast"], function (MT) { MT.show("No data to export - run a search first."); });
                return;
            }
            var sName = "Export";
            try { sName = this.getOwnerComponent().getModel("i18n").getResourceBundle().getText("appTitle") || "Export"; } catch (e) {}
            var oSheet = new sap.ui.export.Spreadsheet({ workbook: { columns: aCols }, dataSource: aData, fileName: sName + ".xlsx" });
            oSheet.build().finally(function () { oSheet.destroy(); });
        },


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
                // A purely-numeric entry is treated as the INTERNAL work-center id and
                // filtered on the base-table column (oper.arbid) — no pre-join of the
                // whole open-characteristics set through the _WorkCenter association.
                // A name still filters on WorkCenter for usability.
                if (/^\d+$/.test(oUi.filter.workCenter)) {
                    aFilters.push(new Filter("WorkCenterInternalID", FilterOperator.EQ, oUi.filter.workCenter));
                } else {
                    aFilters.push(new Filter("WorkCenter", FilterOperator.EQ, oUi.filter.workCenter));
                }
            }
            if (oUi.filter.inspectionLot) {
                aFilters.push(new Filter("InspectionLot", FilterOperator.EQ, oUi.filter.inspectionLot));
            }
            this.byId("resultsTable").getBinding("items").filter(aFilters);
            this._resetDirty(true);   // discard unsent massEdit changes from the previous result set
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

            // "massEdit" is a DEFERRED update group (manifest updateGroupId): edited cells
            // accumulate client-side and this really is one $batch. With the previous "$auto"
            // inheritance every cell edit auto-submitted its own PATCH — a 300-characteristic
            // mass entry became 300 sequential round trips and this submitBatch was a no-op.
            oModel.submitBatch("massEdit").then(function () {
                MessageToast.show(this.getText("postSuccess", [iCount]));
                this._resetDirty();
            }.bind(this)).catch(function (oError) {
                MessageBox.error(this.getText("postError") + "\n" + (oError && oError.message ? oError.message : ""));
            }.bind(this));
        },

        _resetDirty: function (bDiscardPending) {
            // With the deferred "massEdit" group, edits not yet posted are pending on the
            // model — when the user rebinds (new filters) those stale PATCHes must be
            // dropped, or they'd ride along with the NEXT post.
            if (bDiscardPending) {
                try { this.getView().getModel().resetChanges("massEdit"); } catch (e) { /* none pending */ }
            }
            this._dirty = {};
            this.getView().getModel("ui").setProperty("/dirtyCount", 0);
        },

        getText: function (sKey, aArgs) {
            return this.getView().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
        }
    });
});
