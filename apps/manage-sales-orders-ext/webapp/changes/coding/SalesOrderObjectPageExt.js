/**
 * Controller extension for Manage Sales Orders (F1873).
 *
 * Re-adds, the clean-core way, the custom pricing / availability validation
 * that previously lived in the Z program SAPMZ_SO_CREATE. The UI extension
 * only guards/asses the user input; the authoritative pricing & validation
 * logic must run on the backend through a released BAdI (sales order
 * processing) or a RAP determination/validation — never a modification.
 *
 * Wired through the codeExt change file (see ../id_*_codeExt.change).
 */
sap.ui.define([
    "sap/ui/core/mvc/ControllerExtension",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (ControllerExtension, MessageToast, MessageBox) {
    "use strict";

    return ControllerExtension.extend("kejriwal.zsalesorder.manage.extension.changes.coding.SalesOrderObjectPageExt", {

        override: {
            /**
             * Standard Fiori Elements extension hook fired before the object
             * page is saved. Returning a rejected promise cancels the save.
             */
            onBeforeSave: function (oEvent) {
                var oContext = oEvent && oEvent.context ? oEvent.context : this.base.getView().getBindingContext();
                if (!oContext) {
                    return Promise.resolve();
                }
                var oData = oContext.getObject() || {};

                // Example client-side guard: shade is mandatory once a denier is entered.
                if (oData.YY1_Denier_SO && !oData.YY1_Shade_SO) {
                    MessageBox.error(this._text("errShadeRequired"));
                    return Promise.reject(new Error("Shade is required when Denier is set."));
                }
                return Promise.resolve();
            }
        },

        /**
         * Value-help handler referenced from TextileAttributes.fragment.xml.
         * Replace with a real value-help dialog bound to the shade master
         * (ZDD_SHADE custom business object) once it is published as OData.
         */
        onShadeValueHelp: function () {
            MessageToast.show(this._text("shadeValueHelpTodo"));
        },

        _text: function (sKey) {
            var oView = this.base.getView();
            var oBundle = oView && oView.getModel("i18n") && oView.getModel("i18n").getResourceBundle();
            return oBundle ? oBundle.getText(sKey) : sKey;
        }
    });
});
