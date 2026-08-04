import router from '@ohos.router';
import { HealthDashboardViewModel } from '../health/HealthDashboardViewModel';
import { HealthDetailComp } from '../health/detail/HealthDetailComp';
import { navigate, NavOperation } from '../auth/navigation/AuthNavigator';
import { HealthDetailParams } from '../auth/navigation/AuthRoutes';

@Preview
@Entry
@Component
struct HealthDetailPage {
  @State healthVM: HealthDashboardViewModel = new HealthDashboardViewModel();
  @State cardId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as HealthDetailParams;
    this.cardId = params !== null && params !== undefined ? params.cardId : '';
    this.healthVM.load(this);
  }

  onBackPress(): boolean {
    navigate(NavOperation.Pop, '');
    return true;
  }

  build() {
    Stack() {
      HealthDetailComp({
        cardId: this.cardId,
        healthCards: this.healthVM.healthCards,
        backAction: () => { navigate(NavOperation.Pop, ''); }
      })
    }
    .width('100%')
    .height('100%')
  }
}
