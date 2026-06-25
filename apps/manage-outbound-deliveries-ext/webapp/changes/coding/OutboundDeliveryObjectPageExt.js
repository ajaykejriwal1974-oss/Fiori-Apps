/**
 * Controller extension for Manage Outbound Deliveries (F0867A).
 *
 * Re-adds, the clean-core way, the delivery-challan behaviour that used to live
 * behind ZDEL / ZRPT_DELIVERY_CHALLAN:
 *  - a client-side guard on the custom challan fields (onBeforeSave), and
 *  - a "Print Delivery Challan" trigger that calls the standard Output
 *    Management for the delivery. The challan FORM is an Adobe form rendered by
 *    an Output Management (BRF+) determination on the backend - it is NOT a
 *    SAPSCRIPT/Smartform reprint inside this app, and not a modification.
 *
 * Wired through the codeExt change file (see ../id_*_codeExt.change).
 */
sap.ui.define([
    "sap/ui/core/mvc/ControllerExtension",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (ControllerExtension, MessageToast, MessageBox) {
    "use strict";

    return ControllerExtension.extend("kejriwal.zdelivery.manage.extension.changes.coding.OutboundDeliveryObjectPageExt", {

        override: {
            /**
             * Guard the custom challan fields before save.
             */
            onBeforeSave: function (oEvent) {
                var oContext = (oEvent && oEvent.context) || this.base.getView().getBindingContext();
                var oData = (oContext && oContext.getObject()) || {};

                // A vehicle number is mandatory once a challan number is assigned.
                if (oData.YY1_ChallanNo_DEL && !oData.YY1_VehicleNo_DEL) {
                    MessageBox.error(this._text("errVehicleRequired"));
                    return Promise.reject(new Error("Vehicle number is required when a challan number is set."));
                }
                return Promise.resolve();
            }
        },

        /**
         * "Print Delivery Challan" handler referenced from the fragment.
         *
         * The clean-core path is to let Output Management render the challan
         * Adobe form for this delivery. Replace the body with a call to the
         * delivery's output API / OutputControl navigation once the output type
         * (e.g. ZCHALLAN) is configured in Output Management. We deliberately do
         * NOT re-implement the old ZRPT_DELIVERY_CHALLAN print logic here.
         */
        onPrintDeliveryChallan: function () {
            var oContext = this.base.getView().getBindingContext();
            if (!oContext) {
                MessageToast.show(this._text("noDeliverySelected"));
                return;
            }
            // TODO: invoke the bound output action / navigate to Output Items,
            // e.g. oContext.getModel().bindContext("OutputRequest(...)", oContext) ...
            MessageToast.show(this._text("printChallanTodo"));
        },

        _text: function (sKey) {
            var oView = this.base.getView();
            var oBundle = oView && oView.getModel("i18n") && oView.getModel("i18n").getResourceBundle();
            return oBundle ? oBundle.getText(sKey) : sKey;
        }
    });
});
