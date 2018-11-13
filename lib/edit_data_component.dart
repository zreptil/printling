import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/content/deferred_content.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:printling/src/globals.dart' as g;

@Component(selector: 'editData',
  styleUrls: const ['edit_data_component.css',],
  templateUrl: 'edit_data_component.html',
  directives: const [
    EditDataComponent,
    MaterialFabComponent,
    MaterialInputComponent,
    MaterialMultilineInputComponent,
    materialInputDirectives,
    MaterialButtonComponent,
    MaterialIconComponent,
    DeferredContentDirective,
    MaterialDropdownSelectComponent,
    MaterialSelectItemComponent,
    NgFor,
    NgIf,
    NgClass,
  ],
  providers: const <dynamic>[overlayBindings, materialProviders, EditDataComponent])
class EditDataComponent extends g.AppPage
  implements AfterViewInit
{
  @Input()
  g.VarData data;
  
  @override
  void ngAfterViewInit()
  {
    activate();
  }

  @override
  void activate()
  {
  }
}
