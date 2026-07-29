import { CardEditorComp } from '../health/editor/CardEditorComp';
import { HealthDashboardViewModel } from '../health/HealthDashboardViewModel';
import { navigate, NavOperation } from '../login/AuthNavigator';
import { saveStoreSnapshot } from '../login/StorePersister';

@Entry
@Component
struct HealthCardEditorPage {
  @State healthVM: HealthDashboardViewModel = new HealthDashboardViewModel();

  aboutToAppear(): void {
    this.healthVM.load(this);
  }

  onBackPress(): boolean {
    navigate(NavOperation.Pop, '');
    return true;
  }

  build() {
    Stack() {
      CardEditorComp({
        healthCards: this.healthVM.healthCards,
        onSave: (typeNamesCsv: string) => { this.saveAndReturn(typeNamesCsv); },
        onCancel: () => { navigate(NavOperation.Pop, ''); }
      })
    }
    .width('100%')
    .height('100%')
  }

  private saveAndReturn(typeNamesCsv: string): void {
    const types: string[] = typeNamesCsv.split(',')
      .map((typeName: string) => typeName.trim())
      .filter((typeName: string) => typeName.length > 0);
    this.healthVM.saveCardConfiguration(types, this);
    if (this.healthVM.consumeEffectMessage() !== undefined) {
      return;
    }
    saveStoreSnapshot();
    const version: number = AppStorage.get<number>('health_cards_version') ?? 0;
    AppStorage.setOrCreate<number>('health_cards_version', version + 1);
    navigate(NavOperation.Pop, '');
  }
}
