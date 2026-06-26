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
    "sap/m/MessageBox",
    "sap/ui/model/odata/v4/ODataModel"
], function (ControllerExtension, MessageToast, MessageBox, ODataModel) {
    "use strict";

    // OData V4 binding of the side service that carries the sales-order close
    // action (backend/sales-doc-status-rap, service def ZUI_SALESDOC_STATUS -
    // consolidated contract + order status). Fill the ADT binding name (e.g.
    // ZUI_SALESDOC_STATUS_O4).
    var SERVICE_URL = "/sap/opu/odata4/sap/REPLACE_WITH_SALESDOC_STATUS_SERVICE/srvd/sap/REPLACE_WITH_SALESDOC_STATUS_SERVICE/0001/";

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

        /**
         * Close the current sales order (ZSOCLOSE). Confirms, then calls the
         * closeSalesOrder static action on the ZUI_SALES_ORDER_STATUS side
         * service by order id - the reject-open-quantity logic runs on the
         * backend (BAPI_SD_SALESDOCUMENT_CHANGE), never in the UI.
         */
        onCloseSalesOrder: function () {
            var oContext = this.base.getView().getBindingContext();
            if (!oContext) {
                MessageToast.show(this._text("noOrder"));
                return;
            }
            var sOrder = oContext.getObject().SalesOrder;
            MessageBox.confirm(this._text("confirmCloseOrder"), {
                onClose: function (sResult) {
                    if (sResult !== MessageBox.Action.OK) {
                        return;
                    }
                    var oSide = this._getStatusModel();
                    var oOperation = oSide.bindContext("/closeSalesOrder(...)");
                    oOperation.setParameter("SalesOrder", sOrder);
                    oOperation.invoke().then(function () {
                        var oRes = oOperation.getBoundContext().getObject() || {};
                        MessageToast.show(oRes.Message || this._text("orderClosed"));
                        oContext.refresh();
                    }.bind(this), function (oError) {
                        MessageBox.error((oError && oError.message) || this._text("orderCloseFailed"));
                    }.bind(this));
                }.bind(this)
            });
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

        _text: function (sKey) {
            var oView = this.base.getView();
            var oBundle = oView && oView.getModel("i18n") && oView.getModel("i18n").getResourceBundle();
            return oBundle ? oBundle.getText(sKey) : sKey;
        }
    });
});
