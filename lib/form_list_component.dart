import 'dart:async';
import 'dart:convert';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/content/deferred_content.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:printling/src/globals.dart' as g;

@Component(selector: 'none',
  styleUrls: const [
    'package:angular_components/css/mdc_web/card/mdc-card.scss.css',
    'form_list_component.css',
  ],
  templateUrl: 'form_list_component.html',
  directives: const [
    MaterialFabComponent,
    MaterialInputComponent,
    MaterialMultilineInputComponent,
    materialInputDirectives,
    MaterialButtonComponent,
    MaterialIconComponent,
    DeferredContentDirective,
    NgFor,
    NgIf,
    NgClass,
  ],
  providers: const <dynamic>[overlayBindings, materialProviders,])
class FormListComponent extends g.AppPage
  implements AfterViewInit
{
  bool showAdd = true;
  List fileData = List();
  static const List listColors = [
    "red", "blue", "green", "purple", "yellow", "black", "white"];

  @override
  void ngAfterViewInit()
  {
    activate();
  }

  @override
  void activate()
  {
    setTitle("Printling", "");
    var query = "properties has { key='createdBy' and value='printling' } and not trashed";
    searchDocuments(1000, query).then((List<drive.File>files)
    {
      fileData.clear();
//      for (var i = 0; i < 10; i++)
      for (var file in files)
      {
        if (file.mimeType == "text/plain")file.mimeType = "text/javascript";
        fileData.add(g.FormData(file, "view"));
      }
    }).catchError((error)
    {
//      display('An error occured: $error');
    });
  }

  void setColor(data, color)
  {
    data.setColor(color);
  }

  void editMeta(data)
  {
    data.edit();
  }

  void saveMeta(data)
  {
    drive.File request = drive.File();
    request.name = data.title + data.extension;
    request.mimeType = "text/javascript";
    request.description = data.description;
    request.properties = data.file.properties;
    if (data.isNew())
    {
      g.drive.files.create(request).catchError((error)
      {
        display("Es ist ein Fehler aufgetreten ($error)");
      }, test: (error)
      => true).then((_)
      {
        data.mode = "view";
        activate();
      });
    }
    else
    {
      g.drive.files.update(request, data.file.id).catchError((error)
      {
        display("Es ist ein Fehler aufgetreten ($error)");
      }, test: (error)
      => true).then((_)
      {
        data.mode = "view";
        activate();
      });
    }
    showAdd = true;
  }

  Future<void> _loadFile(data, cmd)
  async {
    display("Lade Datei herunter...");
    g.drive.files.get(data.file.id, $fields: "*",
      downloadOptions: commons.DownloadOptions.FullMedia).catchError((error)
    {
      display("Es ist ein Fehler aufgetreten ($error)");
    }, test: (error)
    => true).then((response)
    {
      var media = response as commons.Media;
      if (media.contentType.startsWith("text/"))
      {
        Stream strm = media.stream.transform(Utf8Decoder(allowMalformed: true));
        strm.join().then((s)
        {
          data.content = s;
          if(cmd is String)
            send(cmd, data);
          else
            cmd(data, data.content);
        });
      }
      else
      {
        display("Eine Datei der Art \"${media
          .contentType}\" kann nicht verarbeitet werden. ");
      }
    });
  }

  void cancelMeta(data)
  {
    if (data.isNew())fileData.remove(data);
    else
      data.revert();
    showAdd = true;
  }

  void editForm(data)
  {
    _loadFile(data, "edit");
  }

  void print(data)
  {
    _loadFile(data, (d, s)
    {
      app.createPDF(formData: d, src: s);
//      pdfData = base64.encode(utf8.encode(s));
//      Future.delayed(Duration(milliseconds: 1), () => (html.querySelector("#postForm") as html.FormElement).submit() );
    });

  }

  Future<List<drive.File>> searchDocuments(int max, String query)
  {
    List<drive.File> docs = [];
    Future<List<drive.File>> next(String token)
    {
      // The API call returns only a subset of the results. It is possible
      // to query through the whole result set via "paging".
      return g.drive.files.list(
        q: query, pageToken: token, $fields: "*", orderBy: "name").then((
        results)
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

  /// if one of the cards is in editmode, this method returns "none"
  /// for every card that is not $self.
  hideEditOther(self)
  {
    var data = fileData.firstWhere((d)
    => d.mode == "edit", orElse: ()
    => null);
    if (data == null)return "";

    return self == data ? "" : "none";
  }

  deleteForm(data)
  {
    if (data.isNew())return;

    display("Soll die Datei wirklich gelöscht werden?", ok: ()
    {
      g.drive.files.delete(data.file.id).catchError((error)
      {
        display("Es ist ein Fehler aufgetreten ($error)");
      }, test: (error)
      => true).then((_)
      {
        fileData.remove(data);
        activate();
      });
    }, cancel: ()
    {
    });
    showAdd = true;
  }

  void addForm()
  {
    drive.File file = drive.File();
    file.properties = Map<String, String>();
    file.properties["createdBy"] = "printling";
    file.name = "unknown.js";
    fileData.add(g.FormData(file, "edit"));
    showAdd = false;
  }
}
