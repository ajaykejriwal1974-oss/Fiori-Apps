sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/ui/model/odata/v4/ODataModel",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator"
], function (Controller, JSONModel, ODataModel, Filter, FilterOperator) {
    "use strict";

    // Each KPI reads a live $count from its RAP OData V4 service (the same services
    // the individual apps use). `filter` narrows the count (e.g. low stock); no filter
    // = total records. `intent` is the SemanticObject-action to drill into on tap.
    // Any service that isn't reachable degrades gracefully to "-" (never crashes).
    var KPIS = [
        { key: "openBatches",      url: "/sap/opu/odata4/sap/zui_batch_status_o4/srvd/sap/zui_batch_status/0001/",        path: "/Batch",                   intent: "BatchStatus-manageKejriwal" },
        { key: "packingItems",     url: "/sap/opu/odata4/sap/zui_packing_detail_04/srvd/sap/zui_packing_detail/0001/",    path: "/PackingItem",             intent: "PackingDetail-manageKejriwal" },
        { key: "pallets",          url: "/sap/opu/odata4/sap/zui_palletization_04/srvd/sap/zui_palletization/0001/",      path: "/Pallet",                  intent: "Palletization-manageKejriwal" },
        { key: "pendingContracts", url: "/sap/opu/odata4/sap/zui_contract_batch_04/srvd/sap/zui_contract_batch/0001/",    path: "/SalesContract",           intent: "SalesContract-updateBatchKejriwal" },
        { key: "dispatchBacklog",  url: "/sap/opu/odata4/sap/zui_dispatch_04/srvd/sap/zui_dispatch_correction/0001/",     path: "/DispatchBox",             intent: "DispatchCorrection-manageKejriwal" },
        { key: "lowStock",         url: "/sap/opu/odata4/sap/zui_mtos_process_04/srvd/sap/zui_mtos_process/0001/",        path: "/MtosStock",               intent: "MtosProcess-manageKejriwal",
          filter: { property: "Quantity", op: "LT", value1: 100 } },
        { key: "husToUnpack",      url: "/sap/opu/odata4/sap/zui_hu_unpack_04/srvd/sap/zui_hu_unpack/0001/",              path: "/HuUnpack",                intent: "HuUnpack-manageKejriwal" },
        { key: "inboundHus",       url: "/sap/opu/odata4/sap/zui_hu_inbond_04/srvd/sap/zui_hu_inbound/0001/",             path: "/InboundHu",               intent: "InboundDeliveryHu-manageKejriwal" },
        { key: "inspections",      url: "/sap/opu/odata4/sap/zui_qm_inspectionchar_04/srvd/sap/zui_qm_inspectionchar/0001/", path: "/InspectionCharacteristic", intent: "InspectionResult-recordMassKejriwal" }
    ];

    return Controller.extend("kejriwal.plant.dashboard.controller.Dashboard", {

        onInit: function () {
            var oInit = {};
            KPIS.forEach(function (k) { oInit[k.key] = "…"; }); // ellipsis while loading
            this.getView().setModel(new JSONModel(oInit), "kpi");
            this._models = {};
            this._loadKpis();
        },

        onRefresh: function () {
            this._loadKpis();
        },

        /** Fire a live $count per KPI; each resolves independently so one bad service
         *  never blocks the rest. */
        _loadKpis: function () {
            var oKpi = this.getView().getModel("kpi"), that = this;
            KPIS.forEach(function (c) {
                try {
                    if (!that._models[c.key]) {
                        that._models[c.key] = new ODataModel({ serviceUrl: c.url, operationMode: "Server" });
                    }
                    var aFilters = c.filter ? [new Filter(c.filter.property, FilterOperator[c.filter.op], c.filter.value1)] : [];
                    var oBinding = that._models[c.key].bindList(c.path, null, [], aFilters, { "$count": true });
                    oBinding.requestContexts(0, 1).then(function () {
                        var n = oBinding.getCount();
                        oKpi.setProperty("/" + c.key, (n === undefined || n === null) ? "–" : n);
                    }, function () {
                        oKpi.setProperty("/" + c.key, "–");
                    });
                } catch (e) {
                    oKpi.setProperty("/" + c.key, "–");
                }
            });
        },

        /** Drill into the app behind the tapped KPI via cross-app navigation. */
        onOpenApp: function (oEvt) {
            var sIntent = oEvt.getSource().data("intent");
            if (!sIntent) { return; }
            var aParts = sIntent.split("-");
            if (sap.ushell && sap.ushell.Container && sap.ushell.Container.getServiceAsync) {
                sap.ushell.Container.getServiceAsync("CrossApplicationNavigation").then(function (oNav) {
                    oNav.toExternal({ target: { semanticObject: aParts[0], action: aParts[1] } });
                });
            }
        }
    });
});
