import {
  LoginActionType,
  LoginEffect,
  LoginEffectType,
  LoginState
} from '../login/LoginState';
import { getLoginViewModel } from '../login/LoginViewModelProvider';
import { navigate, navigateWithParams, NavOperation } from '../login/AuthNavigator';
import { AuthRoutes } from '../login/AuthRoutes';
import { handleAuthEffect } from '../login/AuthEffectHandler';
import { getService } from '../login/HarmonyServiceProvider';
import { saveStoreSnapshot } from '../login/StorePersister';
import { AppColors, AppImages, AppSpacing, AppTypography } from '../resources/AppResources';
import {
  APP_LANGUAGE_CHINESE,
  APP_LANGUAGE_ENGLISH,
  selectAppLanguage
} from '../resources/AppLanguage';
import { CardEntry, HealthSnapshot, HealthCardModel, createDefaultHealthCards, cardIconIndex, localizedHealthText, resourceText } from '../health/HealthDashboardTypes';
import { AccountOverviewComp } from '../account/AccountOverviewComp';
import { RecordsPlaceholderComp } from './RecordsPlaceholderComp';
import { ExplorePlaceholderComp } from './ExplorePlaceholderComp';
import { HeroTopRowComp } from '../health/components/HeroTopRowComp';
import { ScenarioPickerComp } from '../health/components/ScenarioPickerComp';
import { HealthDetailComp } from '../health/detail/HealthDetailComp';
import { BottomNavBarComp } from './BottomNavBarComp';
import { CardEditorComp } from '../health/editor/CardEditorComp';
import { MetricComp } from '../health/components/MetricComp';
import { DashboardCardComp } from '../health/components/DashboardCardComp';

@Entry
@Component
struct SignedInPage {
  private viewModel = getLoginViewModel();
  @State selectedTab: number = 0;
  @State healthCards: HealthCardModel[] = createDefaultHealthCards();
  @State detailCardId: string = '';
  @State refreshing: boolean = false;
  @State dragOffset: number = 0;
  @State showScenarioPicker: boolean = false;
  @State scenarioName: string = 'Normal';
  @State healthSteps: string = '8769';
  @State healthCalories: string = '769';
  @State healthMinutes: string = '69';
  @State healthDateLabel: ResourceStr = $r('app.string.health_demo_date');
  @State dashboardVersion: number = 0;
  private isAtScrollTop: boolean = true;
  @State showDeleteDialog: boolean = false;
  @State localError: string = '';
  @State sessionAccount: string = '';
  @State displayName: string = '';
  @State profileAvatarUri: string = '';
  @State birthDate: string = '';
  @State heightText: string = '';
  @State weightText: string = '';
  @State countryRegion: string = '';
  @State profileComplete: boolean = false;
  @StorageLink('app_language') appLanguage: string = APP_LANGUAGE_CHINESE;
  @StorageLink('app_language_version') languageVersion: number = 0;
  @State showLanguageDialog: boolean = false;
  @State editingCards: boolean = false;

  aboutToAppear(): void {
    this.loadHealthDataFromKMP();
    this.syncState();
  }

  onPageShow(): void {
    this.syncState();
  }

  onBackPress(): boolean {
    if (this.editingCards || this.detailCardId.length > 0) {
      this.editingCards = false;
      this.detailCardId = '';
    }
    return true;
  }

  build() {
    Stack() {
      Column() {
        if (this.editingCards) {
          CardEditorComp({
            healthCards: this.healthCards,
            onSave: (csv: string) => { this.handleEditorSave(csv); },
            onCancel: () => { this.editingCards = false; }
          })
        } else if (this.detailCardId.length > 0) {
          HealthDetailComp({
            cardId: this.detailCardId,
            healthCards: this.healthCards,
            backAction: () => { this.detailCardId = ''; }
          })
        } else {
          if (this.selectedTab === 0) {
            this.HealthDashboard();
          } else if (this.selectedTab === 3) {
            AccountOverviewComp({
              displayName: this.displayName,
              sessionAccount: this.sessionAccount,
              profileAvatarUri: this.profileAvatarUri,
              profileComplete: this.profileComplete,
              birthDate: this.birthDate,
              heightText: this.heightText,
              weightText: this.weightText,
              countryRegion: this.localizedCountryName(this.countryRegion),
              localError: this.localError,
              onLanguageClick: () => { this.showLanguageDialog = true; },
              onProfileClick: () => { navigateWithParams(NavOperation.Push, AuthRoutes.toProfileEdit()); },
              onLogout: () => { this.logout(); },
              onDelete: () => { this.showDeleteDialog = true; }
            })
          } else if (this.selectedTab === 1) {
            RecordsPlaceholderComp()
          } else {
            ExplorePlaceholderComp()
          }
        }

        if (!this.editingCards && this.detailCardId.length === 0) {
          BottomNavBarComp({
            selectedTab: this.selectedTab,
            onTabClick: (index: number) => {
              this.selectedTab = index;
              if (index === 3) this.syncState();
            }
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BLACK)

      if (this.showDeleteDialog) {
        this.DeleteAccountDialog();
      }
      if (this.showScenarioPicker) {
        ScenarioPickerComp({
          selectedScenario: this.scenarioName,
          onSelect: (name: string) => {
            getService().selectHealthScene(name);
            this.loadHealthDataFromKMP();
            saveStoreSnapshot();
            this.showScenarioPicker = false;
          }
        })
      }
      if (this.showLanguageDialog) {
        this.LanguageDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BLACK)
  }

  @Builder
  HealthDashboard() {
    Column() {
      HeroTopRowComp({
        dateLabel: this.healthDateLabel,
        onLongPress: () => { this.showScenarioPicker = true; }
      })
      Refresh({ refreshing: $$this.refreshing }) {
        Scroll() {
          Column() {
            Column() {
              this.ArcMetrics();
            }
            .id(`arc_${this.dashboardVersion}`)
            ForEach(this.healthCards, (card: HealthCardModel) => {
              DashboardCardComp({
                card: card,
                onTap: () => { this.detailCardId = card.id; }
              })
            }, (card: HealthCardModel) => `${card.id}_v${this.dashboardVersion}`)

            Text($r('app.string.health_edit_cards'))
              .fontSize(AppTypography.LABEL)
              .fontColor(AppColors.HEALTH_EDIT_TEXT)
              .padding({ left: AppSpacing.ACTION_HORIZONTAL, right: AppSpacing.ACTION_HORIZONTAL,
                top: AppSpacing.MEDIUM, bottom: AppSpacing.MEDIUM })
              .backgroundColor(AppColors.HEALTH_CARD)
              .borderRadius(22)
              .margin({ top: AppSpacing.LARGE, bottom: 42 })
              .onClick(() => { this.editingCards = true; })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .scrollBar(BarState.Off)
        .id(`scrollData_${this.dashboardVersion}`)
      }
      .layoutWeight(1)
      .onRefreshing(() => {
        this.refreshing = true;
        setTimeout(() => { this.performRefresh(); }, 4460);
      })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  ArcMetrics() {
    Stack({ alignContent: Alignment.Center }) {
      Progress({ value: 78, total: 100, type: ProgressType.Ring })
        .width(126).height(126).color(AppColors.GAUGE).style({ strokeWidth: 5 })
      Row() {
        MetricComp({ icon: AppImages.steps(), value: this.healthSteps, unit: $r('app.string.health_unit_steps') })
          .id(`metricSteps_${this.dashboardVersion}`)
        Blank().layoutWeight(1)
        MetricComp({ icon: AppImages.calories(), value: this.healthCalories, unit: $r('app.string.health_unit_calories') })
          .id(`metricCal_${this.dashboardVersion}`)
        Blank().layoutWeight(1)
        MetricComp({ icon: AppImages.activeDuration(), value: this.healthMinutes, unit: $r('app.string.health_unit_minutes') })
          .id(`metricMin_${this.dashboardVersion}`)
      }
      .width('100%')
    }
    .width('100%').height(128).padding({ left: 20, right: 20 }).margin({ top: 16 })
  }

  @Builder
  DeleteAccountDialog() {
    Column() {
      Blank().layoutWeight(1)
      Column({ space: 24 }) {
        Text($r('app.string.account_delete_confirmation')).fontSize(18).fontColor(AppColors.WHITE).textAlign(TextAlign.Center)
        Row({ space: 14 }) {
          Button($r('app.string.common_cancel'), { type: ButtonType.Normal }).fontSize(16).fontColor(AppColors.WHITE)
            .layoutWeight(1).height(44).borderRadius(8).backgroundColor(AppColors.ACCOUNT_DIALOG_SECONDARY)
            .onClick(() => { this.showDeleteDialog = false; })
          Button($r('app.string.common_confirm'), { type: ButtonType.Normal }).fontSize(16).fontColor(AppColors.WHITE)
            .layoutWeight(1).height(44).borderRadius(8).backgroundColor(AppColors.ACTION)
            .onClick(() => { this.confirmDeleteAccount(); })
        }
      }
      .padding({ left: 24, right: 24, top: 22, bottom: 22 })
      .backgroundColor(AppColors.ACCOUNT_DIALOG).borderRadius(12).margin({ left: 42, right: 42 })
      Blank().layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(AppColors.OVERLAY_62)
  }

  @Builder
  LanguageDialog() {
    Column() {
      Column({ space: 4 }) {
        Text($r('app.string.language_select_title'))
          .fontSize(19).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
          .width('100%').padding({ left: 20, right: 20, top: 16, bottom: 10 })
        this.LanguageOption($r('app.string.language_chinese'), APP_LANGUAGE_CHINESE);
        this.LanguageOption($r('app.string.language_english'), APP_LANGUAGE_ENGLISH);
      }
      .width('84%').padding({ bottom: 12 }).backgroundColor(AppColors.ACCOUNT_DIALOG).borderRadius(14)
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor(AppColors.OVERLAY_62)
  }

  @Builder
  LanguageOption(label: ResourceStr, language: string) {
    Row() {
      Text(label).fontSize(16).fontColor(AppColors.WHITE)
      Blank().layoutWeight(1)
      if (this.appLanguage === language) {
        Text('✓').fontSize(18).fontColor(AppColors.COMPLETE)
      }
    }
    .width('100%').height(52).padding({ left: 22, right: 22 })
    .onClick(() => {
      selectAppLanguage(language);
      this.loadHealthDataFromKMP();
      this.dashboardVersion++;
      this.showLanguageDialog = false;
    })
  }

  // MARK: - Editor save
  private handleEditorSave(typeNamesCsv: string): void {
    let json: string = getService().saveCardConfig(typeNamesCsv);
    let parsed: object = JSON.parse(json);
    if (parsed && parsed['error']) {
      // error is shown inside CardEditorComp via its own warning state
      // but CardEditorComp committed already; handle error by reloading
      return;
    }
    saveStoreSnapshot();
    this.loadHealthDataFromKMP();
    this.editingCards = false;
  }

  // MARK: - Data
  private performRefresh(): void {
    this.loadHealthDataFromKMP();
    this.refreshing = false;
    this.dashboardVersion++;
  }

  private loadHealthDataFromKMP(): void {
    try {
      let json: string = getService().loadHealthSnapshot();
      if (!json || json === '{}') return;
      let data: HealthSnapshot = JSON.parse(json) as HealthSnapshot;
      if (!data || !data.cards || data.cards.length === 0) return;
      this.scenarioName = data.scenario || 'Normal';
      this.healthDateLabel = localizedHealthText(this, data.dateLabelKey || 'health_demo_date', []);
      this.healthSteps = String(data.steps || 0);
      this.healthCalories = String(data.calories || 0);
      this.healthMinutes = String(data.activeMinutes || 0);
      let cards: HealthCardModel[] = [];
      for (let i = 0; i < data.cards.length; i++) {
        let c: CardEntry = data.cards[i];
        let idx: number = cardIconIndex(c.type);
        cards.push(new HealthCardModel(
          c.type,
          localizedHealthText(this, c.titleKey, []),
          localizedHealthText(this, c.summaryKey, c.summaryArgs || []),
          idx,
          c.isRisk,
          c.visual
        ));
      }
      this.healthCards = cards;
    } catch (e) {
      // keep defaults
    }
  }

  private confirmDeleteAccount(): void {
    let message: string = this.viewModel.deleteCurrentAccountMessage();
    this.showDeleteDialog = false;
    if (message.length > 0) { this.localError = message; return; }
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect !== null && effect.type === LoginEffectType.AccountDeleted) handleAuthEffect(effect);
  }

  private async logout(): Promise<void> {
    this.viewModel.dispatch({
      type: LoginActionType.LogoutClicked, mode: 0, username: '', password: '',
      verifyCode: '', displayName: '', region: 'CN'
    });
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect !== null && effect.type === LoginEffectType.LoggedOut) handleAuthEffect(effect);
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    if (state.currentSession === null) return;
    this.sessionAccount = state.currentSession.account;
    this.displayName = state.currentSession.displayName.length > 0 ? state.currentSession.displayName : state.currentSession.account;
    this.profileAvatarUri = state.currentSession.avatarUri;
    this.birthDate = state.currentSession.birthDate;
    this.heightText = state.currentSession.heightCm > 0 ? `${state.currentSession.heightCm} cm` : '';
    this.weightText = state.currentSession.weightKg > 0 ? `${state.currentSession.weightKg.toFixed(1)} kg` : '';
    this.countryRegion = state.currentSession.countryRegion;
    this.profileComplete = state.currentSession.isProfileComplete;
  }

  private localizedCountryName(code: string): string {
    switch (code.trim().toUpperCase()) {
      case 'US': return getContext(this).resourceManager.getStringSync($r('app.string.common_united_states').id);
      case 'GB':
      case 'UK': return getContext(this).resourceManager.getStringSync($r('app.string.common_united_kingdom').id);
      case 'JP': return getContext(this).resourceManager.getStringSync($r('app.string.common_japan').id);
      default: return getContext(this).resourceManager.getStringSync($r('app.string.common_china').id);
    }
  }
}
