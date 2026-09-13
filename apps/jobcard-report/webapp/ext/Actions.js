sap.ui.define([
  "sap/m/MessageToast",
  "sap/m/MessageBox"
], function (MessageToast, MessageBox) {
  "use strict";

  // Custom toolbar actions for the Job Card Report (Fiori Elements V4 List
  // Report). Referenced from manifest.json under the LineItem
  // controlConfiguration; Fiori elements loads this module and calls each
  // handler with the ExtensionAPI as `this`, so getSelectedContexts() and
  // the routing service are reached through it.
  //
  //   Create Job Card - opens the Job Master app (JobMaster-manage) in
  //                     create mode, where a card is made against a batch
  //                     and a schedule. This report is read-only, so making
  //                     a card belongs in Job Master, not here.
  //   Print Job Card  - hands the selected card's number to the Scan Suite,
  //                     which draws it with a Code 128 of the batch number
  //                     and prints (index.html#jobcard=<no>). Needs exactly
  //                     one row.

  function client() {
    var m = /[?&]sap-client=(\d{3})/.exec(window.location.search) ||
            /[?&]sap-client=(\d{3})/.exec(window.location.href);
    return m ? m[1] : "";
  }

  function crossNav(oTarget, oParams) {
    // FLP is not always present (standalone run); fall back to a plain hash
    // change so the action still does something sensible.
    if (window.sap && sap.ushell && sap.ushell.Container) {
      sap.ushell.Container.getServiceAsync("CrossApplicationNavigation").then(function (oNav) {
        oNav.toExternal({ target: oTarget, params: oParams });
      });
    } else {
      MessageToast.show("Open the Job Master app to create a job card.");
    }
  }

  return {
    // Global action - no selection required.
    onCreateJobCard: function () {
      crossNav(
        { semanticObject: "JobMaster", action: "manage" },
        { preferredMode: "create" }
      );
    },

    // requiresSelection: exactly one card. `this` is the ExtensionAPI.
    onPrintJobCard: function () {
      var aContexts = this.getSelectedContexts ? this.getSelectedContexts() : [];
      if (!aContexts || aContexts.length === 0) {
        MessageToast.show("Select a job card first.");
        return;
      }
      if (aContexts.length > 1) {
        MessageToast.show("Select a single job card to print.");
        return;
      }
      var oCtx = aContexts[0];
      var sJob = oCtx.getProperty("JobCard") || oCtx.getProperty("Jobno") ||
                 oCtx.getProperty("JobNumber");
      if (!sJob) {
        MessageBox.error("This row carries no job card number.");
        return;
      }
      var c = client();
      var sUrl = "/sap/bc/ui5_ui5/sap/zsol_scan_suite/index.html" +
                 (c ? "?sap-client=" + c : "") + "#jobcard=" + encodeURIComponent(sJob);
      // A new tab keeps the report open behind the printable card.
      var w = window.open(sUrl, "_blank");
      if (!w) {
        MessageBox.information(
          "Allow pop-ups for this site, or open the Scan Suite and scan job card " +
          sJob + " to print it."
        );
      }
    }
  };
});
