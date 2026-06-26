sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (Controller, MessageToast, MessageBox) {
    "use strict";

    return Controller.extend("kejriwal.pp.packingdetails.controller.Worklist", {

        onInit: function () {
            this.oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
        },

        onPackItems: function () {
            var aItems = this.byId("table").getSelectedItems();
            if (!aItems.length) {
                MessageToast.show(this.oBundle.getText("selectAtLeastOne"));
                return;
            }
            var aKeys = aItems.map(function (oItem) {
                return oItem.getBindingContext().getObject();
            });
            var oParams = {};
            this._invokeAction("packItems", aKeys, oParams);
        },

        onRepackItems: function () {
            var aItems = this.byId("table").getSelectedItems();
            if (!aItems.length) {
                MessageToast.show(this.oBundle.getText("selectAtLeastOne"));
                return;
            }
            var aKeys = aItems.map(function (oItem) {
                return oItem.getBindingContext().getObject();
            });
            var oParams = {};
            this._invokeAction("repackItems", aKeys, oParams);
        },

        /**
         * Invoke a RAP static action exposed on the OData V4 service.
         * @param {string} sAction  the action name (packItems, repackItems)
         * @param {object[]} aKeys  selected row key objects (become the _Item lines)
         * @param {object} oParams  header parameters collected from the dialog
         */
        _invokeAction: function (sAction, aKeys, oParams) {
            var oModel = this.getView().getModel();
            // TODO (wiring): bind and execute the action operation. For a RAP
            // static action exposed in OData V4 the operation path is typically
            //   "/PackingItem/<ServiceNamespace>.<Action>(...)"
            // Build the parameter structure: header fields from oParams + the
            // selected rows as the _Item composition, then oOperation.invoke().
            //
            //   var oOperation = oModel.bindContext("/" + sAction + "(...)");
            //   oOperation.setParameter("...", ...);
            //   oOperation.invoke().then(onSuccess, onError);
            //
            MessageBox.information(
                this.oBundle.getText("actionScaffold", [sAction, aKeys.length]));
        }
    });
});
