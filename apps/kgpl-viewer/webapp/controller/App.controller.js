sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel",
  "sap/m/Column", "sap/m/Text", "sap/m/Label", "sap/m/ColumnListItem"
], function (Controller, JSONModel, Column, Text, Label, ColumnListItem) {
  "use strict";
  return Controller.extend("kgpl.viewer.controller.App", {

        /** Export current table rows to Excel (.xlsx). Generic - reads the table's
         *  columns + cell binding paths and exports the loaded/filtered rows. */
        onExportExcel: function () {
            var oTable = this.byId("table") || this.byId("tbl");
            if (!oTable) { return; }
            var oInfo = oTable.getBindingInfo("items"), oBinding = oTable.getBinding("items");
            if (!oInfo || !oBinding) { return; }
            var aCells = oInfo.template.getCells(), aCols = [];
            oTable.getColumns().forEach(function (oCol, i) {
                var oHdr = oCol.getHeader();
                var sLabel = (oHdr && oHdr.getText) ? oHdr.getText() : ("Column " + (i + 1));
                var oCell = aCells[i], sPath = "";
                if (oCell) {
                    var b = oCell.getBindingInfo("text") || oCell.getBindingInfo("number") || oCell.getBindingInfo("value");
                    if (b && b.parts && b.parts[0]) { sPath = b.parts[0].path; }
                }
                if (sPath) { aCols.push({ label: sLabel, property: sPath, width: 18 }); }
            });
            var aData = (oBinding.getContexts() || []).map(function (c) { return c.getObject(); });
            if (!aData.length) {
                sap.ui.require(["sap/m/MessageToast"], function (MT) { MT.show("No data to export - run a search first."); });
                return;
            }
            var sName = "Export";
            try { sName = this.getOwnerComponent().getModel("i18n").getResourceBundle().getText("appTitle") || "Export"; } catch (e) {}
            var oSheet = new sap.ui.export.Spreadsheet({ workbook: { columns: aCols }, dataSource: aData, fileName: sName + ".xlsx" });
            oSheet.build().finally(function () { oSheet.destroy(); });
        },

    onInit: function () {
      var oModel = new JSONModel();
      this.getView().setModel(oModel);
      var that = this;
      fetch("catalog.json").then(function (r) { return r.json(); }).then(function (cat) {
        var p = new URLSearchParams(window.location.search);
        var key = p.get("e") || Object.keys(cat.entities)[0];
        var ent = cat.entities[key] || { title: key, columns: [], rows: [] };
        that._cat = cat; that._ent = ent; that._all = ent.rows || [];
        oModel.setData({
          title: ent.title || key, subtitle: (ent.note || "Live KSD data"),
          columns: ent.columns || [], rows: that._all, count: that._all.length,
          pickers: cat.pickers || {}
        });
        that._buildColumns(ent.columns || []);
        that._togglePickers(ent);
      });
    },
    _buildColumns: function (cols) {
      var oTable = this.byId("tbl");
      oTable.removeAllColumns();
      cols.forEach(function (c) {
        oTable.addColumn(new Column({ header: new Label({ text: c.label, design: "Bold" }),
          width: c.w || "auto", hAlign: c.num ? "End" : "Begin" }));
      });
      var cells = cols.map(function (c) { return new Text({ text: "{" + c.prop + "}", wrapping: false }); });
      oTable.bindItems({ path: "/rows", template: new ColumnListItem({ cells: cells }) });
    },
    _togglePickers: function (ent) {
      // only show CC / Plant selectors when the entity actually has those fields
      var props = (ent.columns || []).map(function (c) { return c.prop; });
      var hasCC = props.indexOf("bukrs") >= 0 || props.indexOf("CompanyCode") >= 0;
      var hasPl = props.indexOf("werks") >= 0 || props.indexOf("Plant") >= 0;
      this.byId("ccLbl").setVisible(hasCC); this.byId("ccSel").setVisible(hasCC);
      this.byId("plLbl").setVisible(hasPl); this.byId("plSel").setVisible(hasPl);
    },
    _apply: function () {
      var cc = this.byId("ccSel").getSelectedKey();
      var pl = this.byId("plSel").getSelectedKey();
      var q = (this.byId("sf").getValue() || "").toLowerCase();
      var rows = this._all.filter(function (r) {
        if (cc && String(r.bukrs || r.CompanyCode || "") !== cc) return false;
        if (pl && String(r.werks || r.Plant || "") !== pl) return false;
        if (q && !Object.keys(r).some(function (k) { return String(r[k]).toLowerCase().indexOf(q) >= 0; })) return false;
        return true;
      });
      var m = this.getView().getModel();
      m.setProperty("/rows", rows); m.setProperty("/count", rows.length);
    },
    onFilterChange: function () { this._apply(); },
    onSearch: function () { this._apply(); }
  });
});
