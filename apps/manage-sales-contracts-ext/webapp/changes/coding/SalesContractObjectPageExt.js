/**
 * Controller extension for Manage Sales Contracts.
 *
 * Re-adds, the clean-core way, the custom contract lifecycle that used to live
 * behind ZCON_CLOSE / ZCON_CLOSE1 / ZCOREL / ZCON02:
 *  - Release / Complete / Close actions that call BACKEND actions (RAP action or
 *    a function import implemented via a released BAdI / status management) - the
 *    status transition logic lives on the backend, never in the UI, and
 *  - a client-side guard for the pending-rate field on save.
 *
 * Wired through the codeExt change file (see ../id_*_codeExt.change).
 */
sap.ui.define([
    "sap/ui/core/mvc/ControllerExtension",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (ControllerExtension, MessageToast, MessageBox) {
    "use strict";

    return ControllerExtension.extend("kejriwal.zcontract.manage.extension.changes.coding.SalesContractObjectPageExt", {

        override: {
            onBeforeSave: function (oEvent) {
                var oContext = (oEvent && oEvent.context) || this.base.getView().getBindingContext();
                var oData = (oContext && oContext.getObject()) || {};

                // Pending rate, when entered, must be positive.
                if (oData.YY1_PendingRate_CON !== undefined && oData.YY1_PendingRate_CON !== null
                    && oData.YY1_PendingRate_CON !== "" && parseFloat(oData.YY1_PendingRate_CON) <= 0) {
                    MessageBox.error(this._text("errRatePositive"));
                    return Promise.reject(new Error("Pending rate must be positive."));
                }
                return Promise.resolve();
            }
        },

        onReleaseContract: function () {
            this._runContractAction("Release", "confirmRelease");
        },

        onCompleteContract: function () {
            this._runContractAction("Complete", "confirmComplete");
        },

        onCloseContract: function () {
            this._runContractAction("Close", "confirmClose");
        },

        /**
         * Confirm, then invoke the backend action for the current contract.
         *
         * Replace the inner TODO with the real call once the backend action
         * exists. For an OData V4 RAP service use a bound action:
         *   oModel.bindContext("com.kejriwal.<Action>(...)", oContext).execute();
         * For a classic V2 Fiori Elements service use a function import:
         *   oModel.callFunction("/<Action>Contract", { method: "POST", urlParameters: {...} });
         */
        _runContractAction: function (sActionKey, sConfirmTextKey) {
            var oContext = this.base.getView().getBindingContext();
            if (!oContext) {
                MessageToast.show(this._text("noContract"));
                return;
            }
            MessageBox.confirm(this._text(sConfirmTextKey), {
                onClose: function (sResult) {
                    if (sResult !== MessageBox.Action.OK) {
                        return;
                    }
                    // TODO: call the backend RAP action / function import for sActionKey.
                    MessageToast.show(this._text("actionTodo", [sActionKey]));
                }.bind(this)
            });
        },

        _text: function (sKey, aArgs) {
            var oView = this.base.getView();
            var oBundle = oView && oView.getModel("i18n") && oView.getModel("i18n").getResourceBundle();
            return oBundle ? oBundle.getText(sKey, aArgs) : sKey;
        }
    });
});
