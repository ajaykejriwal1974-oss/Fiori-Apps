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
            this.setModel(new JSONModel({
                inspectionType: "01",
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
