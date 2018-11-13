import 'dart:async';
import 'dart:convert' show Utf8Encoder;
import 'dart:html' as html;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_select/material_dropdown_select.dart';
import 'package:angular_components/material_select/material_select_item.dart';
import 'package:codemirror/codemirror.dart';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:printling/app_component.dart';
import 'package:printling/src/globals.dart' as g;

@Component(selector: 'none',
  styleUrls: const ['form_edit_component.css',
  ],
  templateUrl: 'form_edit_component.html',
  directives: const [MaterialButtonComponent, MaterialIconComponent, MaterialDropdownSelectComponent, MaterialSelectItemComponent, DeferredContentDirective, NgFor, NgIf, NgClass,
  ],
  providers: const <dynamic>[overlayBindings, materialProviders,])
class FormEditComponent extends g.AppPage
  implements AfterViewInit
{
  g.FormData data;
  CodeMirror editor = null;
  static List<String> listThemes = CodeMirror.THEMES;

  void init(g.MainApp app, g.FormData data)
  {
    setApp(app);
    this.data = data;
    activate();
  }

  @override
  void ngAfterViewInit()
  {
    if (editor == null)
    {
      Map options = {
        'theme': 'default',
        'continueComments': {'continueLineComment': false},
        'autoCloseTags': true,
        'mode': data.file.mimeType,
        // 'extraKeys': {'Ctrl-Space': 'autocomplete', 'Cmd-/': 'toggleComment', 'Ctrl-/': 'toggleComment'},
        'value': data.content,
        'lineNumbers': true,
        // 'inputStyle': 'contenteditable',
        'autofocus': true,
        'lineWrapping': true
      };
      Future.delayed(Duration(milliseconds: 5), ()
      {
        editor = CodeMirror.fromElement(html.querySelector("#editor"), options: options);
        activate();
      });
    }
  }

//  ace.Editor _editor;

  bool close()
  {
    if (editor != null && editor.getDoc().getValue() != data.content)
    {
      data.content = editor.getDoc().getValue();
      display("Sollen die Änderungen gespeichert werden?", ok: ()
      => save(), cancel: ()
      => (app as AppComponent).setCurrentPage("list"));
      return false;
    }
    return true;
  }

  void save()
  {
    gd.File request = gd.File();
    request.name = data.title + data.extension;
    request.description = data.description;
    request.properties = data.file.properties;

//    Stream s = content().transform<List<int>>(utf8.decoder);
    StreamController<String> controller = new StreamController<String>();
    controller.add(data.content);
    commons.Media media = commons.Media(controller.stream.transform(Utf8Encoder()), data.content.length, contentType: "text/javascript");
    g.drive.files.update(request, data.file.id, uploadMedia: media).catchError((error)
    {
      display("Es ist ein Fehler aufgetreten ($error)");
    }, test: (error)
    => true).then((_)
    {
      data.mode = "view";
      (app as AppComponent).currentPage = "list";
    });
    controller.close();
  }

  void setTheme(String theme)
  {
    if (theme == null || theme == "")theme = "default";
    if (editor != null)editor.setTheme(theme);
    html.window.localStorage["theme"] = theme;
  }

//  SafeResourceUrl url = null;
//  String pdfData = null;
  @override
  void activate()
  {
    setTitle(data.title, data.color);
    setTheme(html.window.localStorage["theme"]);
    showPDF();
//    url = _sanitizer.bypassSecurityTrustResourceUrl(base64.encode(utf8.encode(data.content)));
//    if (editor != null)pdfData = base64.encode(utf8.encode(editor.getDoc().getValue()));
  }

  void showPDF()
  {
    if (editor != null)
      app.createPDF(formData: data, src: editor.getDoc().getValue(), target: "pdf");
  }
}