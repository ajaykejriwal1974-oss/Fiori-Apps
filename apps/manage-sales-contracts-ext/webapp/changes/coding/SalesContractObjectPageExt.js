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
    "sap/m/MessageBox",
    "sap/ui/model/odata/v4/ODataModel"
], function (ControllerExtension, MessageToast, MessageBox, ODataModel) {
    "use strict";

    // OData V4 binding of the side service that carries the contract lifecycle
    // actions (backend/contract-status-rap, service def ZUI_CONTRACT_STATUS).
    // Fill the binding name created in ADT (e.g. ZUI_CONTRACT_STATUS_O4).
    var SERVICE_URL = "/sap/opu/odata4/sap/REPLACE_WITH_CONTRACT_STATUS_SERVICE/srvd/sap/REPLACE_WITH_CONTRACT_STATUS_SERVICE/0001/";
    // UI action key -> backend static action name on ZC_SalesContract.
    var ACTION_NAME = {
        Release:  "releaseContract",
        Complete: "completeContract",
        Close:    "closeContract"
    };

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
         * Confirm, then invoke the backend RAP action for the current contract.
         * Calls the static action on the ZUI_CONTRACT_STATUS side service with
         * the contract id as a parameter (the action is decoupled from the
         * standard app's own OData context - clean core).
         */
        _runContractAction: function (sActionKey, sConfirmTextKey) {
            var oContext = this.base.getView().getBindingContext();
            if (!oContext) {
                MessageToast.show(this._text("noContract"));
                return;
            }
            var sContract = oContext.getObject().SalesContract;
            MessageBox.confirm(this._text(sConfirmTextKey), {
                onClose: function (sResult) {
                    if (sResult !== MessageBox.Action.OK) {
                        return;
                    }
                    this._invokeStatusAction(ACTION_NAME[sActionKey], { SalesContract: sContract }, sActionKey);
                }.bind(this)
            });
        },

        /** Update the pending rate (ZCON02) on the current contract's open items. */
        onUpdatePendingRate: function () {
            var oContext = this.base.getView().getBindingContext();
            if (!oContext) {
                MessageToast.show(this._text("noContract"));
                return;
            }
            var oData = oContext.getObject() || {};
            this._invokeStatusAction("updatePendingRate", {
                SalesContract: oData.SalesContract,
                SalesContractItem: "000000",            // 0 = all open items
                NewRate: oData.YY1_PendingRate_CON
            }, "Rate");
        },

        /**
         * Bind and execute a static action on the side service, then surface the
         * returned message. The exact operation path is created with the OData V4
         * service binding in ADT; adjust if the service namespace differs.
         */
        _invokeStatusAction: function (sAction, oParams, sActionKey) {
            var oSide = this._getStatusModel();
            var oOperation = oSide.bindContext("/" + sAction + "(...)");
            Object.keys(oParams).forEach(function (sKey) {
                oOperation.setParameter(sKey, oParams[sKey]);
            });
            oOperation.invoke().then(function () {
                var oResult = oOperation.getBoundContext().getObject() || {};
                MessageToast.show(oResult.Message || this._text("actionDone", [sActionKey]));
                this.base.getView().getBindingContext().refresh();
            }.bind(this), function (oError) {
                MessageBox.error((oError && oError.message) || this._text("actionFailed", [sActionKey]));
            }.bind(this));
        },

        /** Lazily create/cache the OData V4 model for the status side service. */
        _getStatusModel: function () {
            if (!this._oStatusModel) {
                this._oStatusModel = new ODataModel({
                    serviceUrl: SERVICE_URL,
                    synchronizationMode: "None",
                    operationMode: "Server"
                });
            }
            return this._oStatusModel;
        },

        _text: function (sKey, aArgs) {
            var oView = this.base.getView();
            var oBundle = oView && oView.getModel("i18n") && oView.getModel("i18n").getResourceBundle();
            return oBundle ? oBundle.getText(sKey, aArgs) : sKey;
        }
    });
});
