/**
 * Controller extension for Confirm Production Operation (F3069).
 *
 * Re-adds, the clean-core way, the dyeing-confirmation validation that used to
 * sit behind ZCO11N / ZCO11A. This UI extension only guards the user input;
 * the authoritative dyeing-confirmation logic and the WIP batch update must run
 * on the backend through a released BAdI or a RAP determination/validation on
 * the production confirmation - never a modification.
 *
 * Wired through the codeExt change file (see ../id_*_codeExt.change).
 */
sap.ui.define([
    "sap/ui/core/mvc/ControllerExtension",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (ControllerExtension, MessageToast, MessageBox) {
    "use strict";

    return ControllerExtension.extend("kejriwal.zprodconf.dyeing.extension.changes.coding.ProductionConfirmationExt", {

        override: {
            /**
             * Hook fired before the confirmation is posted. Returning a
             * rejected promise (or throwing) cancels the post.
             * Adjust the hook name to the base app's actual extension API if
             * F3069 is freestyle (e.g. an onConfirm/onPost press handler).
             */
            onBeforeSave: function (oEvent) {
                var oView = this.base.getView();
                var oContext = (oEvent && oEvent.context) || oView.getBindingContext();
                var oData = (oContext && oContext.getObject()) || this._readFromControls(oView);

                // Guard 1: a dye-lot is mandatory once a shade is entered.
                if (oData.YY1_Shade_CONF && !oData.YY1_DyeLot_CONF) {
                    MessageBox.error(this._text("errDyeLotRequired"));
                    return Promise.reject(new Error("Dye-lot is required when a shade is entered."));
                }

                // Guard 2: dyeing temperature plausibility (textile dye range).
                var fTemp = parseFloat(oData.YY1_Temperature_CONF);
                if (!isNaN(fTemp) && (fTemp < 0 || fTemp > 200)) {
                    MessageBox.error(this._text("errTempRange"));
                    return Promise.reject(new Error("Temperature out of range (0-200 C)."));
                }
                return Promise.resolve();
            }
        },

        /**
         * Value-help for the shade field. Replace with a dialog bound to the
         * shade master (ZDD_SHADE custom business object) once it is published
         * as an OData service.
         */
        onShadeValueHelp: function () {
            MessageToast.show(this._text("shadeValueHelpTodo"));
        },

        /** Fallback read for freestyle apps where there is no bound context object. */
        _readFromControls: function (oView) {
            function val(sId) {
                var oCtrl = oView.byId(sId);
                return oCtrl && oCtrl.getValue ? oCtrl.getValue() : undefined;
            }
            return {
                YY1_Shade_CONF: val("inpShade"),
                YY1_DyeLot_CONF: val("inpDyeLot"),
                YY1_Temperature_CONF: val("inpTemperature")
            };
        },

        _text: function (sKey) {
            var oView = this.base.getView();
            var oBundle = oView && oView.getModel("i18n") && oView.getModel("i18n").getResourceBundle();
            return oBundle ? oBundle.getText(sKey) : sKey;
        }
    });
});
