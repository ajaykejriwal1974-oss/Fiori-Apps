sap.ui.define([], function () {
    "use strict";

    var formatter = {

        /** ObjectStatus state for a maintenance-plan status. */
        planStatusState: function (sStatus) {
            switch (sStatus) {
                case "Due": return "Warning";
                case "Active": return "Success";
                case "Inactive": return "None";
                default: return "None";
            }
        },

        /** ObjectStatus state for a breakdown status. */
        breakdownStatusState: function (sStatus) {
            switch (sStatus) {
                case "New": return "Error";
                case "In Process": return "Warning";
                case "Completed": return "Success";
                default: return "None";
            }
        },

        /** ObjectStatus state derived from a textual priority (e.g. "1-Very High"). */
        priorityState: function (sPriority) {
            if (!sPriority) { return "None"; }
            var sRank = String(sPriority).charAt(0);
            if (sRank === "1") { return "Error"; }
            if (sRank === "2") { return "Warning"; }
            return "None";
        },

        /** "30 DAY" from length + unit. */
        cycleText: function (iLen, sUnit) {
            if (!iLen) { return ""; }
            return iLen + " " + (sUnit || "");
        },

        /** Downtime with unit, e.g. "6.5 H"; blank while zero/open. */
        downtimeText: function (fHours, sUnit) {
            if (!fHours) { return ""; }
            return fHours + " " + (sUnit || "H");
        },

        /** Substitute the row count into an i18n pattern like "Plans ({0})". */
        countTitle: function (sPattern, aRows) {
            var iLen = Array.isArray(aRows) ? aRows.length : 0;
            return (sPattern || "").replace("{0}", iLen);
        },

        /** Amount with currency, e.g. "5,000 INR". */
        amountText: function (vAmount, sCurrency) {
            if (vAmount === undefined || vAmount === null || vAmount === "") { return ""; }
            var fAmt = Number(vAmount);
            if (isNaN(fAmt)) { return String(vAmount); }
            return fAmt.toLocaleString("en-IN") + (sCurrency ? " " + sCurrency : "");
        },

        /** ObjectStatus state for a machine (work center) running status. */
        machineStatusState: function (sStatus) {
            switch (sStatus) {
                case "Running": return "Success";
                case "Idle": return "Warning";
                case "Down": return "Error";
                case "Maintenance": return "Information";
                default: return "None";
            }
        },

        /** ObjectStatus state for an ISO 14224 criticality class (A/B/C). */
        criticalityState: function (sClass) {
            switch (String(sClass).toUpperCase()) {
                case "A": return "Error";
                case "B": return "Warning";
                case "C": return "Success";
                default: return "None";
            }
        },

        /** ObjectStatus state for a spare-part availability. */
        availabilityState: function (sAvail) {
            switch (sAvail) {
                case "In Stock": return "Success";
                case "Low Stock": return "Warning";
                case "Out of Stock": return "Error";
                default: return "None";
            }
        },

        /** Budget utilization %: >100 over budget (red), >85 amber, else green. */
        utilizationState: function (vPct) {
            var f = Number(vPct);
            if (isNaN(f)) { return "None"; }
            if (f > 100) { return "Error"; }
            if (f > 85) { return "Warning"; }
            return "Success";
        },

        utilizationText: function (vPct) {
            var f = Number(vPct);
            if (isNaN(f)) { return ""; }
            return f + " %";
        },

        /** On-hand stock value = qty × unit price, with currency. */
        stockValueText: function (vQty, vPrice, sCurrency) {
            var f = (Number(vQty) || 0) * (Number(vPrice) || 0);
            return f.toLocaleString("en-IN") + (sCurrency ? " " + sCurrency : "");
        }
    };

    return formatter;
});
