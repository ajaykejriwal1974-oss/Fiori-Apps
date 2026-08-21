sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/m/MessageToast",
    "sap/m/SelectDialog",
    "sap/m/StandardListItem"
], function (Controller, Filter, FilterOperator, MessageToast, SelectDialog, StandardListItem) {
    "use strict";

    return Controller.extend("kejriwal.qm.qcpostwinding.controller.Worklist", {

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
            var aF = [],
                sType = this.getOwnerComponent().getModel("ui").getProperty("/inspectionType");

            // Inspection type is fixed per app - this is what makes one
            // service serve three stages.
            aF.push(new Filter("InspectionType", FilterOperator.EQ, sType));

            var add = function (sId, sProp) {
                var v = (this.byId(sId).getValue() || "").trim();
                if (v) { aF.push(new Filter(sProp, FilterOperator.EQ, v.toUpperCase())); }
            }.bind(this);

            add("fPlant", "Plant");
            add("fBatch", "Batch");
            add("fVendorBatch", "VendorBatch");
            add("fMaterial", "Material");

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
            ["fSearch", "fPlant", "fBatch", "fVendorBatch", "fMaterial"]
                .forEach(function (s) { this.byId(s).setValue(""); }, this);
            this.byId("fDateFrom").setValue("");
            this.byId("fOpenOnly").setState(true);
            this.byId("txtCount").setText("");
        },

        /** F4 value help for the Plant filter (bound to /PlantVH = ZI_VH_PLANT,
         *  exposed on the service now that PFCG/publish is done). */
        onPlantVH: function (oEvt) {
            this._openValueHelp(oEvt.getSource(), "/PlantVH", "Plant", "PlantName", "Select Plant");
        },

        /** Generic F4: open a SelectDialog over a value-help entity set on the
         *  app's OData V4 model, filter by the typed value, write the picked
         *  key back into the triggering Input. Same pattern as batch-status. */
        _openValueHelp: function (oInput, sPath, sKeyField, sDescField, sTitle) {
            var oView = this.getView();
            var oDialog = new SelectDialog({
                title: sTitle,
                growing: true,
                growingThreshold: 50,
                rememberSelections: false,
                items: {
                    path: sPath,
                    template: new StandardListItem({
                        title: "{" + sKeyField + "}",
                        description: sDescField ? "{" + sDescField + "}" : undefined
                    })
                },
                liveChange: function (oE) {
                    var sVal = oE.getParameter("value") || "";
                    oE.getSource().getBinding("items").filter(
                        sVal ? new Filter(sKeyField, FilterOperator.Contains, sVal) : []);
                },
                search: function (oE) {
                    var sVal = oE.getParameter("value") || "";
                    oE.getSource().getBinding("items").filter(
                        sVal ? new Filter(sKeyField, FilterOperator.Contains, sVal) : []);
                },
                confirm: function (oE) {
                    var oItem = oE.getParameter("selectedItem");
                    if (oItem) { oInput.setValue(oItem.getTitle()); }
                },
                cancel: function () { }
            });
            oView.addDependent(oDialog);
            oDialog.setModel(oView.getModel());
            oDialog.open();
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
