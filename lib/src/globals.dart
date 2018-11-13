library diamant.globals;

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:googleapis/people/v1.dart' as gp;
import 'package:googleapis_auth/auth_browser.dart' as auth;

final identifier = new auth.ClientId("124738138054-kh64u3sscfeqd6rks6ma4nmoa9qgiso1.apps.googleusercontent.com", null);
final scopes = [gd.DriveApi.DriveScope, gp.PeopleApi.ContactsReadonlyScope];

// https://www.googleapis.com/auth/drive.appfolder

var client = null;
gd.DriveApi drive = null;
gp.PeopleApi people = null;

class FormData
{
  String title;
  String extension;
  String description;
  gd.File file;
  String mode;
  String color;
  String content;

  @Input("style")
  Map<String, bool> css = <String, bool>{};

  FormData(gd.File file, String mode)
  {
    if (file == null)file = gd.File();
    this.file = file;
    this.mode = mode;
    init();
  }

  showEdit(bool show)
  {
    if (show)return mode == "edit" ? "" : "none";

    return mode == "edit" ? "none" : "";
  }

  isNew()
  {
    return file.id == null || file.id == "";
  }

  setColor(value)
  {
    if (file.properties == null)file.properties = Map<String, String>();
    file.properties["color"] = value;

    color = value;
    css = <String, bool>{"mdc-card": true, color: true};
  }

  init()
  {
    if (file.properties != null && file.properties.containsKey("color"))setColor(file.properties["color"]);
    else
      setColor("red");
    description = file.description;
    title = file.name;
    extension = "";

    if (file.name != null)
    {
      var pos = file.name.lastIndexOf('.');
      if (pos > 0)
      {
        title = file.name.substring(0, pos);
        extension = file.name.substring(pos);
      }
    }
  }

  edit()
  {
    mode = "edit";
  }

  revert()
  {
    mode = "view";
    init();
  }
}

class Msg
{
  String text;
  var ok = null;
  var cancel = null;
  bool isEmpty()
  {
    return text == null || text == "";
  }

  void dismiss(call)
  {
    call();
    text = null;
  }
}

class AppPage
  implements MainApp
{
  @Input("style")
  MainApp app;
  @override
  List<VarData> listData = List<VarData>();
  @override
  FormData currentForm = FormData(null, "");

  void setApp(MainApp app)
  {
    this.app = app;
  }

  void activate()
  {
    display("activate wurde in ${this.runtimeType} nicht implementiert");
  }

  @override
  void setTitle(String title, String color)
  {
    app?.setTitle(title, color);
  }

  @override
  void display(String msg, {bool append: false, ok(), cancel()})
  {
    app?.display(msg, append: append, ok: ok, cancel: cancel);
  }

  void send(String id, FormData data)
  {
    app?.execute(id, data);
  }

  @override
  void extractData(String src)
  {
    app?.extractData(src);
  }

  @override
  void createPDF({FormData formData, String src = null, String target = "_blank"})
  {
    app?.createPDF(src: src, target: target, formData: formData);
  }

  @override
  void execute(String id, FormData data)
  {
    display("execute wurde in ${this.runtimeType} nicht implementiert");
  }

  @override
  var dlgCancel;

  @override
  var dlgOk;
}

abstract class MainApp
{
  void setTitle(String title, String color);

  void display(String msg, {bool append: false, ok(), cancel()});

  void execute(String id, FormData data);

  void extractData(String src);

  void createPDF({FormData formData, String src = null, String target = "_blank"});

  List<VarData> listData = null;
  FormData currentForm = FormData(null, "");
  var dlgOk = null;
  var dlgCancel = null;
}

class ComboData
{
  var _parent = null;
  String key;
  MainApp app;
  List<PersonData> _listPerson = null;
  List<gp.Name> _listName = null;
  List<gp.Address> _listAddress = null;

  ComboData(this.app, this.key, this._parent);

  List<PersonData> get PersonEntries
  {
    if (_listPerson == null)return List<PersonData>();

    return _listPerson;
  }

  List<gp.Name> get NameEntries
  {
    if (_listName == null)return List<gp.Name>();

    return _listName;
  }

  List<gp.Address> get AddressEntries
  {
    if (_listAddress == null)return List<gp.Address>();

    return _listAddress;
  }

  Future<void> fillEntries()
  async {
    if (_listPerson == null && key == "person")
    {
      _listPerson = List<PersonData>();
      gp.ListConnectionsResponse list = await people.people.connections.list("people/me", personFields: "names", pageSize: 1000, sortOrder: "FIRST_NAME_ASCENDING");
      for (gp.Person item in list.connections)
        _listPerson.add(PersonData(item));
    }
    else if (_listName == null && key == "name")
    {
      if (_parent != null && _parent == PersonData)_listName = await (_parent as PersonData).names;
    }
    else if (_listAddress == null && key == "address")
    {
      if (_parent != null && _parent == PersonData)_listAddress = await (_parent as PersonData).addresses;
    }
  }
}

class VarData
{
  Map<String, VarData> members = Map<String, VarData>();
  String key;
  String name;
  String dataKey;
  int idx = null;
  VarData _parent;
  var data = null;
  ComboData comboData;
  var selected = null;

  void changeSelected(var value)
  {
    selected = value;
    for (VarData item in members.values)
    {
      item._parent = this;
      item.fillData();
    }
  }

  void add(List<String> parts, [VarData parent = null])
  {
    _parent = parent;
    key = parts.removeAt(0);
    name = key;
    dataKey = key;
    RegExp exp = RegExp(r"([^\d]*)(\d*)");
    var matches = exp.allMatches(key);
    if (matches.length == 2)
    {
      var list = matches.toList(growable: false);
      dataKey = list[0].group(1);
      idx = int.tryParse(list[0].group(2));
    }
    if (parts.length == 0)return;
    String member = parts[0];
    if (member == "")return;
    if (!members.containsKey(member))members[member] = VarData();
    members[member].add(parts, this);
  }

  Future<Map<String, Object>> toJson()
  async {
    if (selected == null)return Map<String, Object>();

    if (selected is PersonData)
    {
      gp.Person p = await (selected as PersonData).person;
      return p.toJson();
    }
    else if (selected is gp.Name)
    {
      return (selected as gp.Name).toJson();
    }
    else if (selected is gp.Address)
    {
      return (selected as gp.Address).toJson();
    }
    return Map<String, Object>();
  }

  Future<String> get value
  async {
    if (_parent != null)
    {
      if (_parent.selected == null)
      {
        if (_parent.comboData != null)
        {
          if (_parent.key == "name" && _parent.comboData.NameEntries.length == 1)_parent.selected = _parent.comboData.NameEntries[0];
          else if (_parent.key == "address" && _parent.comboData.AddressEntries.length == 1)_parent.selected = _parent.comboData.AddressEntries[0];
        }
      }

      if (_parent.selected != null)
      {
        Map<String, Object> nameJson = await _parent.toJson();
        for (VarData m in _parent.members.values)
        {
          if (m.key == key)return "${nameJson['$key']}";
        }
      }
    }
    return "n.v.";
  }

  String get fullPath
  {
    if (_parent == null)return key;
    return "${_parent.fullPath}.${key}";
  }

  void fillData()
  {
    if (comboData != null)comboData.fillEntries();
  }
}

class PersonData
{
  gp.Person _src;
  gp.Person _fullPerson = null;
  String key;
  String name;

  PersonData(this._src)
  {
    key = _src.resourceName;
    if (_src.names != null && _src.names.length > 0)
    {
      gp.Name name = _src.names.firstWhere((n)
      => n.metadata.primary);
      if (name == null)name = _src.names[0];
      this.name = name.displayName;
    }
  }

  Future<gp.Person> get person
  async {
    if (_fullPerson == null) _fullPerson = await people.people.get(key, personFields: "names,addresses");
    return _fullPerson;
  }

  Future<List<gp.Name>> get names
  async {
    return person.then((p)
    => p.names);
  }

  Future<List<gp.Address>> get addresses
  async {
    return person.then((p)
    => p.addresses);
  }
}

class NameData
{
  gp.Name _src;

  String familyName;
  String givenName;
  String displayName;
  String displayNameLastFirst;
  String honorificPrefix;
  String honorificSuffix;
  String middleName;

  NameData(this._src)
  {
    familyName = _src.familyName;
    givenName = _src.givenName;
    displayName = _src.displayName;
    displayNameLastFirst = _src.displayNameLastFirst;
    honorificPrefix = _src.honorificPrefix;
    honorificSuffix = _src.honorificSuffix;
    middleName = _src.middleName;
  }
}
