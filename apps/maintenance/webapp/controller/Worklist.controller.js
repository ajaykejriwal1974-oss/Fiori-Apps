sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "kejriwal/pm/maintenance/model/formatter",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/Dialog",
    "sap/m/Button",
    "sap/m/Input",
    "sap/m/DatePicker",
    "sap/m/Select",
    "sap/ui/core/Item",
    "sap/m/Label",
    "sap/ui/layout/form/SimpleForm",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/ui/model/json/JSONModel"
], function (Controller, formatter, MessageToast, MessageBox, Dialog, Button, Input,
             DatePicker, Select, Item, Label, SimpleForm, Filter, FilterOperator, JSONModel) {
    "use strict";

    // In demo mode the app reads/writes the local JSON model "pm". To switch to
    // the live RAP service, bind the tables to the ZUI_MAINTENANCE OData V4
    // entity sets (MaintenancePlan / BreakdownReport) and invoke the bound
    // actions instead of the local _apply* helpers (see README).
    var UNITS = ["DAY", "WEEK", "MONTH", "YEAR", "HOUR"];
    var PRIORITIES = ["1-Very High", "2-High", "3-Medium", "4-Low"];
    var TYPES = ["Preventive", "Condition-based", "Statutory", "Corrective"];
    var MALFUNCTIONS = ["Mechanical", "Electrical", "Instrumentation", "Hydraulic", "Other"];
    var CURRENCIES = ["INR", "USD", "EUR", "GBP", "AED"];
    var MACHINE_CATEGORIES = ["Production", "Utility", "Power", "Material Handling", "Instrumentation"];
    var MACHINE_STATUS = ["Running", "Idle", "Down", "Maintenance"];
    var CRITICALITY = ["A", "B", "C"];
    var PART_UNITS = ["EA", "M", "L", "KG", "SET"];
    var BUDGET_CATEGORIES = ["Preventive", "Breakdown", "Overhaul", "Shutdown"];

    return Controller.extend("kejriwal.pm.maintenance.controller.Worklist", {

        formatter: formatter,

        onInit: function () {
            this.oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
            // View model drives which section (table) is visible.
            this.getView().setModel(new JSONModel({ section: "schedule" }), "view");
        },

        /** Section switch from the SegmentedButton in the sub-header. */
        onSection: function (oEvent) {
            var sKey = oEvent.getParameter("item").getKey();
            this.getView().getModel("view").setProperty("/section", sKey);
        },

        /* ------------------------------------------------------------------ *
         *  Hand-off to standard S/4HANA 2025 Fiori apps (clean-core reuse).   *
         *  Resolves only inside a Fiori Launchpad; offline it is a no-op.     *
         * ------------------------------------------------------------------ */
        onStdReportMalfunction: function () { this._openIntent("MaintenanceProcessing", "reportMalfunction"); },
        onStdMaintenancePlan: function () { this._openIntent("MaintenancePlan", "manage"); },
        onStdTechnicalObject: function () { this._openIntent("TechnicalObject", "manage"); },
        onStdManageStock: function () { this._openIntent("Material", "manageStock"); },

        _openIntent: function (sSemanticObject, sAction) {
            var that = this;
            var fnFallback = function () { MessageToast.show(that.oBundle.getText("stdOnlyInFlp")); };
            try {
                if (!(sap.ushell && sap.ushell.Container)) { return fnFallback(); }
                sap.ushell.Container.getServiceAsync("CrossApplicationNavigation").then(function (oNav) {
                    oNav.toExternal({ target: { semanticObject: sSemanticObject, action: sAction } });
                }).catch(fnFallback);
            } catch (e) {
                fnFallback();
            }
        },

        /* ------------------------------------------------------------------ *
         *  Search                                                            *
         * ------------------------------------------------------------------ */
        onSearchPlans: function (oEvent) {
            this._filterTable("planTable", oEvent, ["PlanId", "Equipment", "EquipmentDesc", "MaintenanceType"]);
        },

        onSearchBreakdowns: function (oEvent) {
            this._filterTable("breakdownTable", oEvent, ["NotificationId", "Equipment", "EquipmentDesc", "Description"]);
        },

        _filterTable: function (sTableId, oEvent, aFields) {
            var sQuery = oEvent.getParameter("query");
            if (sQuery === undefined) { sQuery = oEvent.getParameter("newValue"); }
            var aFilters = [];
            if (sQuery) {
                aFilters.push(new Filter(aFields.map(function (s) {
                    return new Filter(s, FilterOperator.Contains, sQuery);
                }), false));
            }
            this.byId(sTableId).getBinding("items").filter(aFilters);
        },

        /* ------------------------------------------------------------------ *
         *  Schedule (preventive) maintenance                                 *
         * ------------------------------------------------------------------ */
        onCreatePlan: function () {
            var that = this;
            this._openForm(this.oBundle.getText("dlgCreatePlan"), this._planFields(), {
                MaintenanceType: "Preventive", CycleUnit: "DAY", CycleLength: "30", Priority: "3-Medium", Plant: "1000"
            }, function (oVals) {
                oVals.PlanId = oVals.PlanId || that._nextId("maintenancePlans", "PlanId", "MP-");
                oVals.CycleLength = parseInt(oVals.CycleLength, 10) || 0;
                oVals.ActiveFlag = true;
                oVals.LastPerformedDate = that._today();
                oVals.NextDueDate = oVals.NextDueDate || that._addCycle(that._today(), oVals.CycleLength, oVals.CycleUnit);
                oVals.PlanStatus = that._derivePlanStatus(oVals);
                that._unshift("maintenancePlans", oVals);
                MessageToast.show(that.oBundle.getText("created", [oVals.PlanId]));
            });
        },

        onEditPlan: function () {
            var that = this;
            var oSel = this._single("planTable");
            if (!oSel) { return; }
            this._openForm(this.oBundle.getText("dlgEditPlan"), this._planFields(), Object.assign({}, oSel.data), function (oVals) {
                oVals.CycleLength = parseInt(oVals.CycleLength, 10) || 0;
                var oRow = Object.assign({}, oSel.data, oVals);
                oRow.PlanStatus = that._derivePlanStatus(oRow);
                that._set(oSel.path, oRow);
                MessageToast.show(that.oBundle.getText("actionDone"));
            });
        },

        onScheduleNow: function () {
            var that = this;
            var aSel = this._selected("planTable");
            if (!aSel.length) { return; }
            aSel.forEach(function (oSel) {
                var oRow = Object.assign({}, oSel.data);
                oRow.LastPerformedDate = that._today();
                oRow.ActiveFlag = true;
                oRow.NextDueDate = that._addCycle(that._today(), oRow.CycleLength, oRow.CycleUnit);
                oRow.PlanStatus = that._derivePlanStatus(oRow);
                that._set(oSel.path, oRow);
                if (aSel.length === 1) {
                    MessageToast.show(that.oBundle.getText("scheduledMsg", [oRow.PlanId, oRow.NextDueDate]));
                }
            });
            if (aSel.length > 1) { MessageToast.show(this.oBundle.getText("actionDone")); }
            this.byId("planTable").removeSelections(true);
        },

        onSetActive: function () { this._toggleActive(true); },
        onSetInactive: function () { this._toggleActive(false); },

        _toggleActive: function (bActive) {
            var that = this;
            var aSel = this._selected("planTable");
            if (!aSel.length) { return; }
            aSel.forEach(function (oSel) {
                var oRow = Object.assign({}, oSel.data, { ActiveFlag: bActive });
                oRow.PlanStatus = that._derivePlanStatus(oRow);
                that._set(oSel.path, oRow);
            });
            MessageToast.show(this.oBundle.getText("actionDone"));
            this.byId("planTable").removeSelections(true);
        },

        onDeletePlans: function () { this._deleteSelected("planTable", "maintenancePlans"); },

        /* ------------------------------------------------------------------ *
         *  Breakdown (corrective) maintenance                                *
         * ------------------------------------------------------------------ */
        onReportBreakdown: function () {
            var that = this;
            this._openForm(this.oBundle.getText("dlgReportBreakdown"), this._breakdownFields(), {
                MalfunctionType: "Mechanical", Priority: "2-High", Plant: "1000", BreakdownStart: this._now()
            }, function (oVals) {
                oVals.NotificationId = oVals.NotificationId || that._nextId("breakdownReports", "NotificationId", "BD-");
                oVals.BreakdownEnd = "";
                oVals.DowntimeHours = 0;
                oVals.DowntimeUnit = "H";
                oVals.WorkOrder = oVals.WorkOrder || "";
                oVals.BreakdownStatus = "New";
                that._recalcBreakdownCost(oVals);
                that._unshift("breakdownReports", oVals);
                MessageToast.show(that.oBundle.getText("created", [oVals.NotificationId]));
            });
        },

        onAcknowledge: function () {
            var that = this;
            var aSel = this._selected("breakdownTable");
            if (!aSel.length) { return; }
            aSel.forEach(function (oSel) {
                var fnApply = function (sWO) {
                    var oRow = Object.assign({}, oSel.data, { BreakdownStatus: "In Process", WorkOrder: sWO });
                    that._set(oSel.path, oRow);
                    MessageToast.show(that.oBundle.getText("acknowledgedMsg", [oRow.NotificationId]));
                };
                if (oSel.data.WorkOrder) {
                    fnApply(oSel.data.WorkOrder);
                } else {
                    that._prompt(that.oBundle.getText("btnAcknowledge"), that.oBundle.getText("lblWorkOrder"), "WO-", function (sWO) {
                        if (!sWO) { MessageToast.show(that.oBundle.getText("needWorkOrder")); return; }
                        fnApply(sWO);
                    });
                }
            });
            this.byId("breakdownTable").removeSelections(true);
        },

        onComplete: function () {
            var that = this;
            var aSel = this._selected("breakdownTable");
            if (!aSel.length) { return; }
            aSel.forEach(function (oSel) {
                var oRow = Object.assign({}, oSel.data);
                var sEnd = that._now();
                oRow.BreakdownEnd = sEnd;
                oRow.DowntimeHours = that._hoursBetween(oRow.BreakdownStart, sEnd);
                oRow.BreakdownStatus = "Completed";
                if (oRow.WorkOrder === "") { oRow.WorkOrder = that._nextId("breakdownReports", "WorkOrder", "WO-9"); }
                that._recalcBreakdownCost(oRow);
                that._set(oSel.path, oRow);
                if (aSel.length === 1) {
                    MessageToast.show(that.oBundle.getText("completedMsg", [oRow.NotificationId, oRow.DowntimeHours]));
                }
            });
            if (aSel.length > 1) { MessageToast.show(this.oBundle.getText("actionDone")); }
            this.byId("breakdownTable").removeSelections(true);
        },

        onDeleteBreakdowns: function () { this._deleteSelected("breakdownTable", "breakdownReports"); },

        /* ------------------------------------------------------------------ *
         *  Machines / Work Centers                                            *
         * ------------------------------------------------------------------ */
        onSearchMachines: function (oEvent) {
            this._filterTable("machineTable", oEvent, ["MachineId", "Description", "Category", "MachineStatus"]);
        },

        onCreateMachine: function () {
            var that = this;
            this._openForm(this.oBundle.getText("dlgCreateMachine"), this._machineFields(), {
                Category: "Production", Criticality: "B", MachineStatus: "Running", Plant: "1000", Currency: "INR"
            }, function (oVals) {
                oVals.MachineId = oVals.MachineId || that._nextId("machines", "MachineId", "WC-");
                oVals.CapacityPerDay = parseFloat(oVals.CapacityPerDay) || 0;
                oVals.HourlyRate = parseFloat(oVals.HourlyRate) || 0;
                that._unshift("machines", oVals);
                MessageToast.show(that.oBundle.getText("created", [oVals.MachineId]));
            });
        },

        onEditMachine: function () {
            var that = this;
            var oSel = this._single("machineTable");
            if (!oSel) { return; }
            this._openForm(this.oBundle.getText("dlgEditMachine"), this._machineFields(), Object.assign({}, oSel.data), function (oVals) {
                oVals.CapacityPerDay = parseFloat(oVals.CapacityPerDay) || 0;
                oVals.HourlyRate = parseFloat(oVals.HourlyRate) || 0;
                that._set(oSel.path, Object.assign({}, oSel.data, oVals));
                MessageToast.show(that.oBundle.getText("actionDone"));
            });
        },

        onDeleteMachines: function () { this._deleteSelected("machineTable", "machines"); },

        /* ------------------------------------------------------------------ *
         *  Spare Parts / Inventory                                            *
         * ------------------------------------------------------------------ */
        onSearchParts: function (oEvent) {
            this._filterTable("partTable", oEvent, ["PartNumber", "Description", "Machine", "Vendor", "Availability"]);
        },

        onCreatePart: function () {
            var that = this;
            this._openForm(this.oBundle.getText("dlgCreatePart"), this._partFields(), {
                BaseUnit: "EA", Plant: "1000", Currency: "INR", StockQty: "0", MinStock: "0", ReorderPoint: "0"
            }, function (oVals) {
                oVals.PartNumber = oVals.PartNumber || that._nextId("spareParts", "PartNumber", "SP-");
                that._recalcPart(oVals);
                that._unshift("spareParts", oVals);
                MessageToast.show(that.oBundle.getText("created", [oVals.PartNumber]));
            });
        },

        onEditPart: function () {
            var that = this;
            var oSel = this._single("partTable");
            if (!oSel) { return; }
            this._openForm(this.oBundle.getText("dlgEditPart"), this._partFields(), Object.assign({}, oSel.data), function (oVals) {
                var oRow = Object.assign({}, oSel.data, oVals);
                that._recalcPart(oRow);
                that._set(oSel.path, oRow);
                MessageToast.show(that.oBundle.getText("actionDone"));
            });
        },

        onIssueStock: function () { this._moveStock(-1, "issuedMsg"); },
        onReceiveStock: function () { this._moveStock(1, "receivedMsg"); },

        _moveStock: function (iSign, sMsgKey) {
            var that = this;
            var oSel = this._single("partTable");
            if (!oSel) { return; }
            this._prompt(this.oBundle.getText(iSign < 0 ? "btnIssueStock" : "btnReceiveStock"),
                this.oBundle.getText("qtyToMove"), "1", function (sQty) {
                var iQty = parseFloat(sQty) || 0;
                if (iQty <= 0) { return; }
                var oRow = Object.assign({}, oSel.data);
                oRow.StockQty = Math.max(0, (parseFloat(oRow.StockQty) || 0) + iSign * iQty);
                that._recalcPart(oRow);
                that._set(oSel.path, oRow);
                MessageToast.show(that.oBundle.getText(sMsgKey, [iQty, oRow.BaseUnit, oRow.PartNumber, oRow.StockQty]));
            });
        },

        onDeleteParts: function () { this._deleteSelected("partTable", "spareParts"); },

        /* ------------------------------------------------------------------ *
         *  Maintenance Budget                                                 *
         * ------------------------------------------------------------------ */
        onSearchBudgets: function (oEvent) {
            this._filterTable("budgetTable", oEvent, ["BudgetId", "CostCenter", "Category", "FiscalYear"]);
        },

        onCreateBudget: function () {
            var that = this;
            this._openForm(this.oBundle.getText("dlgCreateBudget"), this._budgetFields(), {
                FiscalYear: String(new Date().getFullYear()), Category: "Preventive", Plant: "1000",
                Currency: "INR", PlannedAmount: "0", ActualAmount: "0"
            }, function (oVals) {
                oVals.BudgetId = oVals.BudgetId || that._nextId("budgets", "BudgetId", "BG-");
                that._recalcBudget(oVals);
                that._unshift("budgets", oVals);
                MessageToast.show(that.oBundle.getText("created", [oVals.BudgetId]));
            });
        },

        onEditBudget: function () {
            var that = this;
            var oSel = this._single("budgetTable");
            if (!oSel) { return; }
            this._openForm(this.oBundle.getText("dlgEditBudget"), this._budgetFields(), Object.assign({}, oSel.data), function (oVals) {
                var oRow = Object.assign({}, oSel.data, oVals);
                that._recalcBudget(oRow);
                that._set(oSel.path, oRow);
                MessageToast.show(that.oBundle.getText("actionDone"));
            });
        },

        onPostActual: function () {
            var that = this;
            var oSel = this._single("budgetTable");
            if (!oSel) { return; }
            this._prompt(this.oBundle.getText("btnPostActual"), this.oBundle.getText("amountToPost"), "0", function (sAmt) {
                var fAmt = parseFloat(sAmt) || 0;
                if (!fAmt) { return; }
                var oRow = Object.assign({}, oSel.data);
                oRow.ActualAmount = (parseFloat(oRow.ActualAmount) || 0) + fAmt;
                that._recalcBudget(oRow);
                that._set(oSel.path, oRow);
                MessageToast.show(that.oBundle.getText("postedMsg", [fAmt, oRow.BudgetId, oRow.ActualAmount]));
            });
        },

        onDeleteBudgets: function () { this._deleteSelected("budgetTable", "budgets"); },

        /* ------------------------------------------------------------------ *
         *  Field definitions for the create/edit forms                        *
         * ------------------------------------------------------------------ */
        _planFields: function () {
            return [
                { name: "PlanId", label: this.oBundle.getText("lblPlanId"), placeholder: "auto" },
                { name: "Equipment", label: this.oBundle.getText("lblEquipment"), req: true },
                { name: "EquipmentDesc", label: this.oBundle.getText("lblEquipmentDesc") },
                { name: "FunctionalLocation", label: this.oBundle.getText("lblFuncLoc") },
                { name: "MaintenanceType", label: this.oBundle.getText("lblMaintType"), options: TYPES },
                { name: "Strategy", label: this.oBundle.getText("lblStrategy") },
                { name: "CycleLength", label: this.oBundle.getText("lblCycleLength") },
                { name: "CycleUnit", label: this.oBundle.getText("lblCycleUnit"), options: UNITS },
                { name: "TaskDescription", label: this.oBundle.getText("lblTask") },
                { name: "PlannerGroup", label: this.oBundle.getText("lblPlannerGroup") },
                { name: "WorkCenter", label: this.oBundle.getText("lblWorkCenter") },
                { name: "Plant", label: this.oBundle.getText("lblPlant") },
                { name: "Priority", label: this.oBundle.getText("lblPriority"), options: PRIORITIES },
                { name: "CostCenter", label: this.oBundle.getText("lblCostCenter") },
                { name: "EstimatedCost", label: this.oBundle.getText("lblEstCost") },
                { name: "EstLaborHours", label: this.oBundle.getText("lblEstLaborHours") },
                { name: "Currency", label: this.oBundle.getText("lblCurrency"), options: CURRENCIES },
                { name: "NextDueDate", label: this.oBundle.getText("lblNextDue"), type: "date", placeholder: "auto" }
            ];
        },

        _breakdownFields: function () {
            return [
                { name: "NotificationId", label: this.oBundle.getText("lblPlanId").replace("Plan ID", "Notification"), placeholder: "auto" },
                { name: "Equipment", label: this.oBundle.getText("lblEquipment"), req: true },
                { name: "EquipmentDesc", label: this.oBundle.getText("lblEquipmentDesc") },
                { name: "FunctionalLocation", label: this.oBundle.getText("lblFuncLoc") },
                { name: "Description", label: this.oBundle.getText("lblDescription") },
                { name: "MalfunctionType", label: this.oBundle.getText("lblMalfunction"), options: MALFUNCTIONS },
                { name: "Priority", label: this.oBundle.getText("lblPriority"), options: PRIORITIES },
                { name: "Plant", label: this.oBundle.getText("lblPlant") },
                { name: "WorkCenter", label: this.oBundle.getText("lblWorkCenter") },
                { name: "ReportedBy", label: this.oBundle.getText("lblReportedBy") },
                { name: "BreakdownStart", label: this.oBundle.getText("lblBreakdownStart") },
                { name: "WorkOrder", label: this.oBundle.getText("lblWorkOrder") },
                { name: "FailureMode", label: this.oBundle.getText("lblFailureMode") },
                { name: "RootCause", label: this.oBundle.getText("lblRootCause") },
                { name: "CostCenter", label: this.oBundle.getText("lblCostCenter") },
                { name: "LaborHours", label: this.oBundle.getText("lblLaborHours") },
                { name: "LaborCost", label: this.oBundle.getText("lblLaborCost") },
                { name: "SparePartsCost", label: this.oBundle.getText("lblSparePartsCost") },
                { name: "Currency", label: this.oBundle.getText("lblCurrency"), options: CURRENCIES }
            ];
        },

        _machineFields: function () {
            return [
                { name: "MachineId", label: this.oBundle.getText("lblMachineId"), placeholder: "auto" },
                { name: "Description", label: this.oBundle.getText("lblDescription2"), req: true },
                { name: "WorkCenter", label: this.oBundle.getText("lblWorkCenterCode") },
                { name: "Plant", label: this.oBundle.getText("lblPlant") },
                { name: "FunctionalLocation", label: this.oBundle.getText("lblFuncLoc") },
                { name: "Category", label: this.oBundle.getText("lblCategory"), options: MACHINE_CATEGORIES },
                { name: "CapacityPerDay", label: this.oBundle.getText("lblCapacity") },
                { name: "CostCenter", label: this.oBundle.getText("lblCostCenter") },
                { name: "Criticality", label: this.oBundle.getText("lblCriticality"), options: CRITICALITY },
                { name: "MachineStatus", label: this.oBundle.getText("lblMachineStatus"), options: MACHINE_STATUS },
                { name: "HourlyRate", label: this.oBundle.getText("lblHourlyRate") },
                { name: "Currency", label: this.oBundle.getText("lblCurrency"), options: CURRENCIES }
            ];
        },

        _partFields: function () {
            return [
                { name: "PartNumber", label: this.oBundle.getText("lblPartNumber"), placeholder: "auto" },
                { name: "Description", label: this.oBundle.getText("lblDescription2"), req: true },
                { name: "Machine", label: this.oBundle.getText("lblMachine") },
                { name: "Plant", label: this.oBundle.getText("lblPlant") },
                { name: "StorageBin", label: this.oBundle.getText("lblStorageBin") },
                { name: "StockQty", label: this.oBundle.getText("lblStockQty") },
                { name: "MinStock", label: this.oBundle.getText("lblMinStock") },
                { name: "ReorderPoint", label: this.oBundle.getText("lblReorderPoint") },
                { name: "BaseUnit", label: this.oBundle.getText("lblBaseUnit"), options: PART_UNITS },
                { name: "UnitPrice", label: this.oBundle.getText("lblUnitPrice") },
                { name: "LeadTimeDays", label: this.oBundle.getText("lblLeadTime") },
                { name: "Vendor", label: this.oBundle.getText("lblVendor") },
                { name: "Currency", label: this.oBundle.getText("lblCurrency"), options: CURRENCIES }
            ];
        },

        _budgetFields: function () {
            return [
                { name: "BudgetId", label: this.oBundle.getText("lblBudgetId"), placeholder: "auto" },
                { name: "CostCenter", label: this.oBundle.getText("lblCostCenter"), req: true },
                { name: "FiscalYear", label: this.oBundle.getText("lblFiscalYear") },
                { name: "Category", label: this.oBundle.getText("lblCategory"), options: BUDGET_CATEGORIES },
                { name: "Plant", label: this.oBundle.getText("lblPlant") },
                { name: "PlannedAmount", label: this.oBundle.getText("lblPlanned") },
                { name: "ActualAmount", label: this.oBundle.getText("lblActual") },
                { name: "Currency", label: this.oBundle.getText("lblCurrency"), options: CURRENCIES }
            ];
        },

        /* ------------------------------------------------------------------ *
         *  Generic form / prompt dialogs                                      *
         * ------------------------------------------------------------------ */
        _openForm: function (sTitle, aFields, oValues, fnSubmit) {
            var that = this;
            var oForm = new SimpleForm({ editable: true, layout: "ResponsiveGridLayout" });
            var mControls = {};
            aFields.forEach(function (f) {
                oForm.addContent(new Label({ text: f.label, required: !f.placeholder && !f.options ? false : false }));
                var oCtrl;
                if (f.options) {
                    oCtrl = new Select({ width: "100%" });
                    f.options.forEach(function (s) { oCtrl.addItem(new Item({ key: s, text: s })); });
                    oCtrl.setSelectedKey(oValues[f.name] !== undefined ? oValues[f.name] : f.options[0]);
                } else if (f.type === "date") {
                    oCtrl = new DatePicker({ valueFormat: "yyyy-MM-dd", displayFormat: "yyyy-MM-dd",
                        value: oValues[f.name] || "", placeholder: f.placeholder || "" });
                } else {
                    oCtrl = new Input({ value: oValues[f.name] !== undefined ? oValues[f.name] : "",
                        placeholder: f.placeholder || "" });
                }
                mControls[f.name] = oCtrl;
                oForm.addContent(oCtrl);
            });
            var oDialog = new Dialog({
                title: sTitle,
                contentWidth: "36rem",
                content: [oForm],
                beginButton: new Button({
                    text: that.oBundle.getText("save"),
                    type: "Emphasized",
                    press: function () {
                        var oOut = {};
                        Object.keys(mControls).forEach(function (k) {
                            var c = mControls[k];
                            oOut[k] = c.getSelectedKey ? c.getSelectedKey() : c.getValue();
                        });
                        // Required = first field, plus any not auto-generated key/desc field.
                        var oMissing = aFields.filter(function (f) {
                            return f.req && !oOut[f.name];
                        })[0];
                        if (oMissing) {
                            MessageBox.error(oMissing.label + " is required");
                            return;
                        }
                        oDialog.close();
                        fnSubmit(oOut);
                    }
                }),
                endButton: new Button({ text: that.oBundle.getText("cancel"), press: function () { oDialog.close(); } }),
                afterClose: function () { oDialog.destroy(); }
            });
            this.getView().addDependent(oDialog);
            oDialog.open();
        },

        _prompt: function (sTitle, sLabel, sDefault, fnOk) {
            var that = this;
            var oInput = new Input({ value: sDefault || "" });
            var oDialog = new Dialog({
                title: sTitle,
                contentWidth: "24rem",
                content: [new SimpleForm({ editable: true, content: [new Label({ text: sLabel }), oInput] })],
                beginButton: new Button({
                    text: that.oBundle.getText("ok"), type: "Emphasized",
                    press: function () { var v = oInput.getValue(); oDialog.close(); fnOk(v); }
                }),
                endButton: new Button({ text: that.oBundle.getText("cancel"), press: function () { oDialog.close(); } }),
                afterClose: function () { oDialog.destroy(); }
            });
            this.getView().addDependent(oDialog);
            oDialog.open();
        },

        /* ------------------------------------------------------------------ *
         *  Selection + model helpers (JSON "pm" model — demo persistence)     *
         * ------------------------------------------------------------------ */
        _model: function () { return this.getView().getModel("pm"); },

        _selected: function (sTableId) {
            return this.byId(sTableId).getSelectedItems().map(function (oItem) {
                var oCtx = oItem.getBindingContext("pm");
                return { path: oCtx.getPath(), data: oCtx.getObject() };
            });
        },

        _single: function (sTableId) {
            var a = this._selected(sTableId);
            if (a.length !== 1) {
                MessageToast.show(this.oBundle.getText("selectExactlyOne"));
                return null;
            }
            return a[0];
        },

        _set: function (sPath, oRow) { this._model().setProperty(sPath, oRow); },

        _unshift: function (sCollection, oRow) {
            var oModel = this._model();
            var a = oModel.getProperty("/" + sCollection).slice();
            a.unshift(oRow);
            oModel.setProperty("/" + sCollection, a);
        },

        _deleteSelected: function (sTableId, sCollection) {
            var that = this;
            var aSel = this._selected(sTableId);
            if (!aSel.length) {
                MessageToast.show(this.oBundle.getText("selectAtLeastOne"));
                return;
            }
            MessageBox.confirm(this.oBundle.getText("confirmDelete", [aSel.length]), {
                onClose: function (sAction) {
                    if (sAction !== MessageBox.Action.OK) { return; }
                    var oModel = that._model();
                    var aKeep = oModel.getProperty("/" + sCollection).filter(function (oRow) {
                        return !aSel.some(function (s) { return s.data === oRow; });
                    });
                    oModel.setProperty("/" + sCollection, aKeep);
                    that.byId(sTableId).removeSelections(true);
                    MessageToast.show(that.oBundle.getText("deleted", [aSel.length]));
                }
            });
        },

        /* ------------------------------------------------------------------ *
         *  Domain helpers                                                     *
         * ------------------------------------------------------------------ */
        _derivePlanStatus: function (oRow) {
            if (!oRow.ActiveFlag) { return "Inactive"; }
            if (oRow.NextDueDate && oRow.NextDueDate < this._today()) { return "Due"; }
            return "Active";
        },

        /** Recompute a spare part's derived stock value + availability. */
        _recalcPart: function (oRow) {
            var iQty = parseFloat(oRow.StockQty) || 0;
            var iReorder = parseFloat(oRow.ReorderPoint) || 0;
            oRow.StockQty = iQty;
            oRow.MinStock = parseFloat(oRow.MinStock) || 0;
            oRow.ReorderPoint = iReorder;
            oRow.UnitPrice = parseFloat(oRow.UnitPrice) || 0;
            oRow.LeadTimeDays = parseFloat(oRow.LeadTimeDays) || 0;
            oRow.StockValue = Math.round(iQty * oRow.UnitPrice * 100) / 100;
            oRow.Availability = iQty <= 0 ? "Out of Stock" : (iQty <= iReorder ? "Low Stock" : "In Stock");
        },

        /** Recompute a budget line's derived variance + utilization. */
        _recalcBudget: function (oRow) {
            var fPlanned = parseFloat(oRow.PlannedAmount) || 0;
            var fActual = parseFloat(oRow.ActualAmount) || 0;
            oRow.PlannedAmount = fPlanned;
            oRow.ActualAmount = fActual;
            oRow.Variance = Math.round((fPlanned - fActual) * 100) / 100;
            oRow.UtilizationPct = fPlanned === 0 ? 0 : Math.round((fActual / fPlanned) * 1000) / 10;
        },

        /** Coerce a breakdown's cost fields to numbers and total them. */
        _recalcBreakdownCost: function (oRow) {
            oRow.LaborHours = parseFloat(oRow.LaborHours) || 0;
            oRow.LaborCost = parseFloat(oRow.LaborCost) || 0;
            oRow.SparePartsCost = parseFloat(oRow.SparePartsCost) || 0;
            oRow.TotalCost = Math.round((oRow.LaborCost + oRow.SparePartsCost) * 100) / 100;
        },

        _nextId: function (sCollection, sField, sPrefix) {
            var a = this._model().getProperty("/" + sCollection) || [];
            var iMax = 0;
            a.forEach(function (oRow) {
                var m = /(\d+)\s*$/.exec(oRow[sField] || "");
                if (m) { iMax = Math.max(iMax, parseInt(m[1], 10)); }
            });
            return sPrefix + (iMax + 1);
        },

        _today: function () { return new Date().toISOString().slice(0, 10); },

        _now: function () { return new Date().toISOString().slice(0, 19); },

        _addCycle: function (sDate, iLen, sUnit) {
            var d = new Date(sDate + "T00:00:00");
            iLen = parseInt(iLen, 10) || 0;
            switch (sUnit) {
                case "WEEK": d.setDate(d.getDate() + iLen * 7); break;
                case "MONTH": d.setMonth(d.getMonth() + iLen); break;
                case "YEAR": d.setFullYear(d.getFullYear() + iLen); break;
                case "HOUR": d.setDate(d.getDate() + Math.round(iLen / 24)); break;
                default: d.setDate(d.getDate() + iLen);
            }
            return d.toISOString().slice(0, 10);
        },

        _hoursBetween: function (sStart, sEnd) {
            var t0 = new Date(sStart).getTime();
            var t1 = new Date(sEnd).getTime();
            if (isNaN(t0) || isNaN(t1) || t1 < t0) { return 0; }
            return Math.round((t1 - t0) / 36000) / 100;
        }
    });
});
