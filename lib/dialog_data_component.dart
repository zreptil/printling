import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/laminate/components/modal/modal.dart';
import 'package:angular_components/laminate/overlay/module.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_dialog/material_dialog.dart';
import 'package:printling/src/globals.dart' as g;
import 'package:printling/edit_data_component.dart';

@Component(selector: 'dialog-data',
  styleUrls: const ['dialog_data_component.css',],
  templateUrl: 'dialog_data_component.html',
  directives: const [EditDataComponent, ModalComponent, MaterialDialogComponent, MaterialButtonComponent, NgFor,
  ],
  providers: const <dynamic>[overlayBindings, materialProviders,])
class DialogDataComponent extends g.AppPage
  implements AfterViewInit
{
  List<g.VarData> data = List<g.VarData>();
  g.FormData currentForm = g.FormData(null, "");

  bool isVisible = false;

  @override
  void ngAfterViewInit()
  {
    activate();
  }

  void init(g.MainApp app)
  {
    setApp(app);
    data = app.listData;
    currentForm = app.currentForm;

    if (data.length == 0 && app.dlgOk != null)
    {
      app.dlgOk();
    }
    else
    {
      isVisible = true;
      activate();
    }
  }

  @override
  void activate()
  {}

  void btnClick(bool ok)
  {
    isVisible = false;
    if (ok && app.dlgOk != null)app.dlgOk();
    if (!ok && app.dlgCancel != null)app.dlgCancel();
  }
}
