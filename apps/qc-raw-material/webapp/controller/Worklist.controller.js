sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/m/MessageToast",
    "sap/m/SelectDialog",
    "sap/m/StandardListItem"
], function (Controller, Filter, FilterOperator, MessageToast, SelectDialog, StandardListItem) {
    "use strict";

    return Controller.extend("kejriwal.qm.qcrawmaterial.controller.Worklist", {

        onInit: function () {
            // The binding is created suspended in the view. Nothing is read
            // until the technician presses Go, so opening the app never fires
            // an unfiltered read of every inspection lot in the plant.
            this._oTable = this.byId("tblLots");
            this.getOwnerComponent().getRouter()
                .getRoute("worklist").attachPatternMatched(this._onDisplay, this);
        },

        _onDisplay: function () {
            var oBinding = this._oTable.getBinding("items");
            if (oBinding && !oBinding.isSuspended()) {
                oBinding.refresh();
            }
        },

        _buildFilters: function () {
            var aF = [];

            // Inspection type is what makes one service serve three stages.
            // Shared with the value helps via _inspTypeFilter so a dropdown can
            // never offer a batch from another stage.
            aF.push(this._inspTypeFilter());

            // Filter fields differ per stage: Raw Material renders fVendorBatch,
            // Post-Dyeing and Post-Winding render fBatch, Post-Dyeing adds fOrder.
            // byId() is undefined for a field this view does not render.
            var add = function (sId, sProp) {
                var oCtl = this.byId(sId);
                if (!oCtl) { return; }
                var v = (oCtl.getValue() || "").trim();
                if (v) { aF.push(new Filter(sProp, FilterOperator.EQ, v.toUpperCase())); }
            }.bind(this);

            add("fPlant", "Plant");
            add("fBatch", "Batch");
            add("fVendorBatch", "VendorBatch");
            add("fMaterial", "Material");
            add("fOrder", "ProductionOrder");

            var sFrom = this.byId("fDateFrom").getValue();
            if (sFrom) { aF.push(new Filter("CreatedOn", FilterOperator.GE, sFrom)); }

            if (this.byId("fOpenOnly").getState()) {
                aF.push(new Filter("IsOpen", FilterOperator.EQ, "X"));
            }

            var sSearch = (this.byId("fSearch").getValue() || "").trim();
            if (sSearch) {
                aF.push(new Filter({
                    filters: [
                        new Filter("Batch", FilterOperator.Contains, sSearch.toUpperCase()),
                        new Filter("VendorBatch", FilterOperator.Contains, sSearch.toUpperCase()),
                        new Filter("Material", FilterOperator.Contains, sSearch.toUpperCase()),
                        new Filter("MaterialName", FilterOperator.Contains, sSearch)
                    ],
                    and: false
                }));
            }
            return aF;
        },

        onGo: function () {
            var oBinding = this._oTable.getBinding("items");
            oBinding.filter(this._buildFilters());
            if (oBinding.isSuspended()) { oBinding.resume(); }
            oBinding.attachEventOnce("dataReceived", this._showCount, this);
        },

        _showCount: function () {
            var oBinding = this._oTable.getBinding("items"),
                iCount = oBinding.getCount();
            this.byId("txtCount").setText(iCount === undefined ? "" : iCount + "");
        },

        onClear: function () {
            ["fSearch", "fPlant", "fBatch", "fVendorBatch", "fMaterial", "fOrder"]
                .forEach(function (s) {
                    var oCtl = this.byId(s);
                    if (oCtl) { oCtl.setValue(""); }
                }, this);
            this.byId("fDateFrom").setValue("");
            this.byId("fOpenOnly").setState(true);
            this.byId("txtCount").setText("");
        },

        /** The inspection type(s) this app reads, as a single Filter.
         *
         *  One service serves three stages and the stage is the type: Grey 01
         *  and 08, Post-Dyeing 03, Post-Winding 04. Raw Material has to accept
         *  more than one - purchased yarn arrives as a goods receipt against a
         *  purchase order, in-house greige never does - so Component.js may
         *  hold an array. A plain string still works.
         *
         *  Used by both the worklist query and the value helps. Before the
         *  value helps used it, Post-Dyeing's Batch dropdown offered raw
         *  material batches that its own worklist can never return. */
        _inspTypeFilter: function () {
            var vType = this.getOwnerComponent().getModel("ui").getProperty("/inspectionType"),
                aTypes = Array.isArray(vType) ? vType : [vType];
            return aTypes.length === 1
                ? new Filter("InspectionType", FilterOperator.EQ, aTypes[0])
                : new Filter({
                    filters: aTypes.map(function (sT) {
                        return new Filter("InspectionType", FilterOperator.EQ, sT);
                    }),
                    and: false
                });
        },

        /** F4 value help for the Plant filter (bound to /PlantVH = ZI_VH_PLANT). */
        onPlantVH: function (oEvt) {
            this._openValueHelp(oEvt.getSource(), {
                path: "/PlantVH", key: "Plant", desc: "{PlantName}",
                title: "Select Plant"
            });
        },

        /** F4 over the batches that still have an open inspection lot at THIS
         *  stage (/BatchVH = ZI_VH_QC_BATCH), scoped to the Plant filter, and
         *  filling the fields the pick settles. */
        onBatchVH: function (oEvt) {
            this._openValueHelp(oEvt.getSource(), {
                path: "/BatchVH", key: "Batch",
                desc: "{= ${MaterialCount} > 1 ? ${MaterialCount} + ' materials' : ${MaterialName} }",
                info: "OpenLotCount", scopeByPlant: true, scopeByType: true,
                title: "Select Batch",
                noData: "No batch has an open inspection lot for this stage.",
                select: ["Plant", "InspectionType", "Batch", "Material", "MaterialName",
                         "MaterialCount", "ProductionOrder", "OrderCount", "OpenLotCount"],
                fill: [
                    { prop: "Plant", ctrl: "fPlant" },
                    { prop: "Material", ctrl: "fMaterial", onlyIf: "MaterialCount" },
                    { prop: "ProductionOrder", ctrl: "fOrder", onlyIf: "OrderCount" }
                ]
            });
        },

        /** F4 over the supplier lots on open inspections at this stage
         *  (/SupplierLotVH = ZI_VH_QC_SUPPLIER_LOT, i.e. QALS-LICHN).
         *
         *  Measured 2026-08-29: LICHN is blank on all 152 inspection lots in
         *  KSD, so this list is empty until goods receipts start carrying a
         *  vendor batch. The noData text says so rather than leaving the
         *  technician staring at a blank dialog. The number people actually
         *  quote is the greige lot - that is the Batch field. */
        onSupplierLotVH: function (oEvt) {
            this._openValueHelp(oEvt.getSource(), {
                path: "/SupplierLotVH", key: "VendorBatch",
                desc: "{= ${MaterialCount} > 1 ? ${MaterialCount} + ' materials' : ${MaterialName} }",
                info: "OpenLotCount", scopeByPlant: true, scopeByType: true,
                title: "Select Supplier Lot",
                noData: "No open inspection lot carries a supplier lot number. Use Greige Lot instead.",
                select: ["Plant", "InspectionType", "VendorBatch", "Material", "MaterialName",
                         "MaterialCount", "ProductionOrder", "OrderCount", "OpenLotCount"],
                fill: [
                    { prop: "Plant", ctrl: "fPlant" },
                    { prop: "Material", ctrl: "fMaterial", onlyIf: "MaterialCount" },
                    { prop: "ProductionOrder", ctrl: "fOrder", onlyIf: "OrderCount" }
                ]
            });
        },

        /** Generic F4: open a SelectDialog over a value-help entity set on the
         *  app's OData V4 model, filter by the typed value, write the picked
         *  key back into the triggering Input and fill whatever else the picked
         *  row settles.
         *
         *  o = { path, key, desc, info, title, noData, select, fill,
         *        scopeByPlant, scopeByType }
         *
         *  scopeByPlant is the client half of the additionalBinding on Plant in
         *  ZC_QC_INSP_LOT - these are freestyle apps, so the annotation alone
         *  renders nothing and the binding has to be made here. scopeByType
         *  keeps each stage to its own lots.
         *
         *  select matters more than it looks. An OData V4 list binding derives
         *  $select from the properties actually bound in the template, so
         *  Material and ProductionOrder - shown nowhere in the list - came back
         *  undefined and the auto-fill silently did nothing. Naming them here
         *  is what puts them in the response.
         *
         *  One dialog per entity set, cached on the controller and reused. The
         *  first version built a new one on every press and never released it;
         *  the second tried to destroy it on afterClose, which sap.m.SelectDialog
         *  (1.136.18) does not have - only confirm, cancel, search, liveChange -
         *  so the handler threw before the dialog ever opened, taking the Plant
         *  dropdown down with it. Caching needs no teardown at all. The target
         *  Input is re-pointed on each open because Raw Material drives the
         *  same dialog from two different fields. */
        _openValueHelp: function (oInput, o) {
            var that = this;
            this._vhDialogs = this._vhDialogs || {};

            var fnBase = function () {
                var aBase = [];
                if (o.scopeByType) { aBase.push(that._inspTypeFilter()); }
                if (o.scopeByPlant) {
                    var oPlant = that.byId("fPlant"),
                        sPlant = oPlant ? (oPlant.getValue() || "").trim() : "";
                    if (sPlant) {
                        aBase.push(new Filter("Plant", FilterOperator.EQ, sPlant.toUpperCase()));
                    }
                }
                return aBase;
            };

            var fnFilter = function (oE) {
                var sVal = (oE.getParameter("value") || "").trim(),
                    aF = fnBase();
                if (sVal) {
                    aF.push(new Filter(o.key, FilterOperator.Contains, sVal.toUpperCase()));
                }
                oE.getSource().getBinding("items").filter(aF);
            };

            var oDialog = this._vhDialogs[o.path];
            if (!oDialog) {
                var oItems = {
                    path: o.path,
                    template: new StandardListItem({
                        title: "{" + o.key + "}",
                        description: o.desc,
                        info: o.info ? "{= ${" + o.info + "} + ' open' }" : undefined
                    })
                };
                if (o.select) { oItems.parameters = { $select: o.select.join(",") }; }

                oDialog = new SelectDialog({
                    title: o.title,
                    noDataText: o.noData,
                    growing: true,
                    growingThreshold: 50,
                    rememberSelections: false,
                    items: oItems,
                    liveChange: fnFilter,
                    search: fnFilter,
                    confirm: function (oE) {
                        var oItem = oE.getParameter("selectedItem");
                        if (!oItem || !oDialog._oTarget) { return; }
                        oDialog._oTarget.setValue(oItem.getTitle());
                        that._fillFromPick(oItem.getBindingContext(), o.fill);
                    },
                    cancel: function () { }
                });
                this.getView().addDependent(oDialog);
                oDialog.setModel(this.getView().getModel());
                this._vhDialogs[o.path] = oDialog;
            }

            oDialog._oTarget = oInput;
            var oBinding = oDialog.getBinding("items");
            if (oBinding) { oBinding.filter(fnBase()); }
            oDialog.open();
        },

        /** Carry the rest of the picked row into the other filter fields.
         *
         *  Only what the pick actually settles. Plant is a key of every value
         *  help view, so it is exactly one value and always safe. Material and
         *  Production Order are aggregates over the batch's open lots and are
         *  written only where the matching count is 1 - measured 2026-08-29,
         *  4 of the 16 batches with open lots carry more than one material
         *  (QM_TEST 3, F023000004 3, QM_TEST1 2, QM_TEST4 2), and filling
         *  Material from max() on those would silently hide most of the
         *  batch's own lots. ProductionOrder is blank on 15 of the 16, so the
         *  blank check does the work there.
         *
         *  byId() is undefined for a field the current app does not render -
         *  only Post-Dyeing has fOrder. */
        _fillFromPick: function (oCtx, aFill) {
            if (!oCtx || !aFill) { return; }
            aFill.forEach(function (f) {
                var oCtl = this.byId(f.ctrl);
                if (!oCtl) { return; }
                if (f.onlyIf && oCtx.getProperty(f.onlyIf) !== 1) { return; }
                var v = oCtx.getProperty(f.prop);
                if (v === undefined || v === null || v === "") { return; }
                oCtl.setValue(v);
            }, this);
        },

        onOpenLot: function (oEvent) {
            var oCtx = oEvent.getSource().getBindingContext();
            this.getOwnerComponent().getRouter().navTo("detail", {
                lot: oCtx.getProperty("InspectionLot")
            });
        },

        fmtQty: function (v, u) {
            if (v === undefined || v === null) { return ""; }
            return parseFloat(v).toFixed(3).replace(/\.?0+$/, "") + " " + (u || "");
        },

        fmtStatusText: function (sConfirmed) {
            return sConfirmed === "X" ? "Recorded" : "Open";
        },

        fmtStatusState: function (sConfirmed) {
            return sConfirmed === "X" ? "Success" : "Warning";
        }
    });
});
