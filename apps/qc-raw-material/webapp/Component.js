sap.ui.define([
    "sap/ui/core/UIComponent",
    "sap/ui/Device",
    "sap/ui/model/json/JSONModel"
], function (UIComponent, Device, JSONModel) {
    "use strict";

    return UIComponent.extend("kejriwal.qm.qcrawmaterial.Component", {
        metadata: { manifest: "json" },

        init: function () {
            UIComponent.prototype.init.apply(this, arguments);

            // Inspection type is fixed per app. The three QC apps share one
            // OData service and differ only by this filter, so the backend is
            // built and tested once.
            //
            // Grey QC reads BOTH 01 and 08, as PLANT-2002-QM-SETUP.md says:
            // purchased yarn arrives as a goods receipt against a purchase
            // order and raises 01; in-house greige never does and raises 08.
            // This was ["01"] alone, which hid every greige lot in plant 1000
            // - all 87 of them are type 08, and 1000 has no type 01 at all.
            // Measured in QALS on 2026-08-29: 01 -> 2002 x1, 7000 x2;
            // 08 -> 1000 x87, 7000 x12; 89 -> 1000 x49, 2002 x1.
            this.setModel(new JSONModel({
                inspectionType: ["01", "08"],
                stageTitle: "Raw Material QC",
                busy: false,
                dirty: false
            }), "ui");

            this.setModel(new JSONModel({
                isTouch: Device.support.touch,
                isPhone: Device.system.phone
            }), "device");

            this.getRouter().initialize();
        }
    });
});
