import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/app_layout/material_persistent_drawer.dart';
import 'package:angular_components/content/deferred_content.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_button/material_fab.dart';
import 'package:angular_components/material_expansionpanel/material_expansionpanel.dart';
import 'package:angular_components/material_expansionpanel/material_expansionpanel_auto_dismiss.dart';
import 'package:angular_components/material_expansionpanel/material_expansionpanel_set.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_select/material_select.dart';
import 'package:angular_components/material_select/material_select_item.dart';
import 'package:angular_components/material_slider/material_slider.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:printling/dialog_data_component.dart';
import 'package:printling/dialog_data_component.template.dart' as dlg;
import 'package:printling/form_edit_component.dart';
import 'package:printling/form_edit_component.template.dart' as fe;
import 'package:printling/form_list_component.dart';
import 'package:printling/form_list_component.template.dart' as fl;
import 'package:printling/login_component.dart' as login;
import 'package:printling/src/globals.dart' as g;

@Component(selector: 'apppanel',
  styleUrls: const ['package:angular_components/css/mdc_web/card/mdc-card.scss.css', 'app_component.css', 'package:angular_components/app_layout/layout.scss.css',
  ],
  templateUrl: 'app_component.html',
  directives: const [
    MaterialButtonComponent,
    MaterialFabComponent,
    MaterialIconComponent,
    MaterialPersistentDrawerDirective,
    MaterialSelectComponent,
    MaterialSelectItemComponent,
    MaterialToggleComponent,
    MaterialSliderComponent,
    DeferredContentDirective,
    MaterialExpansionPanel,
    MaterialExpansionPanelAutoDismiss,
    MaterialExpansionPanelSet,
    DialogDataComponent,
    NgFor,
    NgIf,
    NgClass,
    login.LoginComponent,
    FormListComponent,
  ],
  providers: const <dynamic>[overlayBindings, materialProviders,])
class AppComponent
  implements OnInit, g.MainApp
{
  final ComponentLoader _loader = ComponentLoader();
  @override
  List<g.VarData> listData = List<g.VarData>();
  g.FormData currentForm = g.FormData(null, "");

  Map<String, bool> appTheme = <String, bool>{};
  String title = "Printling";
  String lastPage = "help";
  String currentPage = "list";
  bool drawerVisible = false;
  bool isLoggedIn = false;
  g.Msg message = g.Msg();
  String pdfData = null;
  bool dataDialogVisible = false;

  ComponentRef _listRef = null;
  ComponentRef _editRef = null;
  ComponentRef _dlgRef = null;

  @ViewChild("listContent", read: ViewContainerRef)
  ViewContainerRef listContent;
  @ViewChild("editContent", read: ViewContainerRef)
  ViewContainerRef editContent;
  @ViewChild("dlgContent", read: ViewContainerRef)
  ViewContainerRef dlgContent;

  @override
  void setTitle(String title, String color)
  {
    this.title = title;
    this.appTheme = <String, bool>{color: true};
  }

  void result(html.UIEvent evt)
  {
    display(evt.type);
  }

  void loginResult(html.UIEvent evt)
  {
    if (evt.detail != 0)
    {
      isLoggedIn = false;
      display(evt.type);
      return;
    }

    isLoggedIn = true;
    currentPage = "list";

    _listRef = _loader.loadNextToLocation(fl.FormListComponentNgFactory, listContent);
    _listRef.instance.setApp(this);
  }

  @override
  Future<Null> ngOnInit()
  async {}

  void clickData(data)
  {}

  void toggleHelp()
  {
    if (currentPage == "help")
    {
      currentPage = lastPage;
    }
    else
    {
      lastPage = currentPage;
      currentPage = "help";
    }
    html.window.localStorage["lastPage"] = "${lastPage}";
    html.window.localStorage["currentPage"] = "${currentPage}";
  }

  Future<List<gd.File>> searchTextDocuments(gd.DriveApi api, int max, String query)
  {
    List<gd.File> docs = [];
    Future<List<gd.File>> next(String token)
    {
      // The API call returns only a subset of the results. It is possible
      // to query through the whole result set via "paging".
      return api.files.list(q: query, pageToken: token).then((results)
      {
        docs.addAll(results.files);
        // If we would like to have more documents, we iterate.
        if (docs.length < max && results.nextPageToken != null)
        {
          return next(results.nextPageToken);
        }
        return docs;
      });
    }
    return next(null);
  }

  void navigate(String url)
  {
    html.window.open(url, "_blank");
  }

  @override
  void display(String msg, {bool append: false, ok() = null, cancel() = null})
  {
    if (append)message.text = "${message.isEmpty() ? '' : '\n'}$msg";
    else
      message.text = msg;
    message.ok = ok;
    message.cancel = cancel;
  }

  @override
  void execute(String id, g.FormData data)
  {
    switch (id)
    {
      case "edit":
        display("");
        if (_editRef != null)_editRef.destroy();
        _editRef = _loader.loadNextToLocation(fe.FormEditComponentNgFactory, editContent);
        FormEditComponent component = _editRef.instance;
        component.init(this, data);
        currentPage = "edit";
        break;
      case "print":
        break;
      default:
        display("Diese Funktion ist noch nicht implementiert.");
    }
  }

  void setCurrentPage(String page)
  {
    currentPage = "list";
    _listRef.instance.activate();
  }

  void cancelEdit()
  {
    if (_editRef != null)
    {
      if (!_editRef.instance.close())return;
    }
    setCurrentPage("list");
  }

  @override
  void extractData(String src)
  {
    if (src == null)return;

    listData = List<g.VarData>();
    Map<String, g.ComboData> dataLists = Map<String, g.ComboData>();
    RegExp exp = RegExp(r"@[^@]*@");
    var matches = exp.allMatches(src);
    for (var match in matches)
    {
      String src = match.group(0).substring(1, match
        .group(0)
        .length - 1);
      List<String> parts = src.split('.');
      if (parts.length == 1 && parts[0] == "")continue;

      String name = parts[0];
      g.VarData d = listData.firstWhere((v)
      => v.key == name, orElse: ()
      {
        g.VarData ret = g.VarData();
        listData.add(ret);
        return ret;
      });
      d.add(parts);
      if (!dataLists.containsKey(d.dataKey))
      {
        dataLists[d.dataKey] = g.ComboData(this, d.dataKey, d);
        dataLists[d.dataKey].fillEntries();
      }
      d.comboData = dataLists[d.dataKey];
//      display("${d.dataKey}", append: true);
    }

//    for (g.ComboData item in dataLists.values)
//      item.fillEntries();
  }

  Future<String> _fillVarData(String src, g.VarData data)
  async {
    if (data.members.length > 0)
    {
      for (g.VarData item in data.members.values)
        src = await _fillVarData(src, item);
      return src;
    }

    String path = "@${data.fullPath}@";
    src = src.replaceAll(path, await data.value);

    return src;
  }

  Future<String> _fillData(String src)
  async {
    if (src == null)return null;

    if (listData == null || listData.length == 0)extractData(src);

    for (g.VarData item in listData)
      src = await _fillVarData(src, item);

    return src.replaceAll("@@", "@");
  }

  void showDataDialog(g.FormData formData, {ok() = null, cancel() = null})
  {
    if (formData == null)
    {
      if (cancel != null)cancel();
      return;
    }
    currentForm = formData;
    dlgOk = ok;
    dlgCancel = cancel;
    dataDialogVisible = true;

    if (_dlgRef != null)_dlgRef.destroy();
    _dlgRef = _loader.loadNextToLocation(dlg.DialogDataComponentNgFactory, dlgContent);
    DialogDataComponent component = _dlgRef.instance;
    component.init(this);
  }

  @override
  void createPDF({g.FormData formData, String src = null, String target = "_blank"})
  async {
    display(null);
    if (src == null)return;

    extractData(src);
    showDataDialog(formData, ok: ()
    async {
      src = await _fillData(src);
      pdfData = base64.encode(utf8.encode(src));
      Future.delayed(Duration(milliseconds: 1), ()
      {
        var form = html.querySelector("#postForm") as html.FormElement;
        form.target = target;
        form.submit();
      });
    }, cancel: ()
    => dataDialogVisible = false);

/*
    g.people.people.getBatchGet(resourceNames: ["people/me"], personFields: "names,addresses").then((gp.GetPeopleResponse list)
    {
      if (list.responses.length == 1)
      {
        var me = list.responses[0].person;
        gp.Name name = me.names != null ? me.names[0] : gp.Name();
        Map<String, Object> nameJson = name.toJson();
        String s = "givenName";
        src = src.replaceAll("@contact1\.$s", "${nameJson['$s']}");
        src = src.replaceAll("@contact1\.nachname", "${name.familyName}");
        gp.Address adr = me.addresses != null ? me.addresses[0] : gp.Address();
        src = src.replaceAll("@sender\.strasse", "${adr.streetAddress}");
        src = src.replaceAll("@sender\.plz", "${adr.postalCode}");
        src = src.replaceAll("@sender\.ort", "${adr.city}");
      }
*/
//    });
  }

  @override
  var dlgCancel;

  @override
  var dlgOk;
}

class NullTreeSanitizer
  implements html.NodeTreeSanitizer
{
  static final Instance = new NullTreeSanitizer();
  void sanitizeTree(node)
  {}
}

