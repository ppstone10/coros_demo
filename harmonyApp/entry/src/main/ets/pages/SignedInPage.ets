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
import { saveStoreSnapshot } from '../login/StorePersister';
import { AppColors, AppImages, AppSpacing, AppTypography } from '../resources/AppResources';
import {
  APP_LANGUAGE_CHINESE,
  APP_LANGUAGE_ENGLISH,
  selectAppLanguage
} from '../resources/AppLanguage';
import { HealthCardModel } from '../health/HealthDashboardTypes';
import { HealthDashboardViewModel } from '../health/HealthDashboardViewModel';
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

const PAGE_MAIN: string = 'main';
const PAGE_DETAIL: string = 'detail';
const PAGE_EDITOR: string = 'editor';
const PAGE_SCENARIO_PICKER: string = 'scenario_picker';

@Entry
@Component
struct SignedInPage {
  private viewModel = getLoginViewModel();
  @State selectedTab: number = 0;
  @State healthVM: HealthDashboardViewModel = new HealthDashboardViewModel();
  @State currentPage: string = PAGE_MAIN;
  @State detailCardId: string = '';
  @State refreshing: boolean = false;
  @State dragOffset: number = 0;
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

  private calorieArcProgress(): number {
    return Math.max(0, Math.min(800, Number(this.healthVM.healthCalories) || 0)) / 800;
  }

  private calorieArcPath(progress: number): string {
    const center: number = vp2px(58);
    const radius: number = vp2px(54);
    const startDegrees: number = 135;
    const sweepDegrees: number = 270 * Math.max(0, Math.min(1, progress));
    const endDegrees: number = startDegrees + sweepDegrees;
    const startRadians: number = startDegrees * Math.PI / 180;
    const endRadians: number = endDegrees * Math.PI / 180;
    const startX: number = center + radius * Math.cos(startRadians);
    const startY: number = center + radius * Math.sin(startRadians);
    const endX: number = center + radius * Math.cos(endRadians);
    const endY: number = center + radius * Math.sin(endRadians);
    const largeArc: number = sweepDegrees > 180 ? 1 : 0;
    return `M${startX} ${startY} A${radius} ${radius} 0 ${largeArc} 1 ${endX} ${endY}`;
  }

  aboutToAppear(): void {
    this.healthVM.load(this);
    this.syncState();
  }

  onPageShow(): void {
    this.syncState();
  }

  onBackPress(): boolean {
    if (this.currentPage !== PAGE_MAIN) {
      this.currentPage = PAGE_MAIN;
      this.detailCardId = '';
    }
    return true;
  }

  build() {
    Stack() {
      Column() {
        if (this.currentPage === PAGE_SCENARIO_PICKER) {
          ScenarioPickerComp({
            selectedScenario: this.healthVM.currentScenario,
            onSelect: (name: string) => {
              this.healthVM.selectScenario(name);
              this.currentPage = PAGE_MAIN;
            },
            onDismiss: () => {
              this.currentPage = PAGE_MAIN;
            }
          })
        } else if (this.currentPage === PAGE_EDITOR) {
          CardEditorComp({
            healthCards: this.healthVM.healthCards,
            onSave: (csv: string) => { this.handleEditorSave(csv); },
            onCancel: () => { this.currentPage = PAGE_MAIN; }
          })
        } else if (this.currentPage === PAGE_DETAIL && this.detailCardId.length > 0) {
          HealthDetailComp({
            cardId: this.detailCardId,
            healthCards: this.healthVM.healthCards,
            backAction: () => { this.currentPage = PAGE_MAIN; this.detailCardId = ''; }
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

        if (this.currentPage === PAGE_MAIN) {
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
        dateLabel: this.healthVM.healthDateLabel,
        isSyncing: this.refreshing,
        onTap: () => { this.selectedTab = 3; this.syncState(); },
        onLongPress: () => { this.currentPage = PAGE_SCENARIO_PICKER; }
      })
      Refresh({ refreshing: $$this.refreshing }) {
        Scroll() {
          Column() {
            if (this.healthVM.healthDataCorrupted) {
              Text($r('app.string.health_data_corrupted'))
                .fontSize(AppTypography.SUPPORTING).fontColor(AppColors.MUTED).textAlign(TextAlign.Center)
                .width('100%').height(360).padding({ left: 20, right: 20 })
            } else {
              Column() {
                this.ArcMetrics();
              }
              .id(`arc_${this.healthVM.dashboardVersion}`)
              ForEach(this.healthVM.healthCards, (card: HealthCardModel) => {
                DashboardCardComp({
                  card: card,
                  onTap: () => { this.detailCardId = card.id; this.currentPage = PAGE_DETAIL; }
                })
              }, (card: HealthCardModel) => `${card.id}_v${this.healthVM.dashboardVersion}`)

              Text($r('app.string.health_edit_cards'))
                .fontSize(AppTypography.LABEL)
                .fontColor(AppColors.HEALTH_EDIT_TEXT)
                .padding({ left: AppSpacing.ACTION_HORIZONTAL, right: AppSpacing.ACTION_HORIZONTAL,
                  top: AppSpacing.MEDIUM, bottom: AppSpacing.MEDIUM })
                .backgroundColor(AppColors.HEALTH_CARD)
                .borderRadius(22)
                .margin({ top: AppSpacing.LARGE, bottom: 42 })
                .onClick(() => { this.currentPage = PAGE_EDITOR; })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .scrollBar(BarState.Off)
        .id(`scrollData_${this.healthVM.dashboardVersion}`)
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
      Stack({ alignContent: Alignment.Center }) {
        Path()
          .commands(this.calorieArcPath(1))
          .width(116).height(116)
          .fill(AppColors.TRANSPARENT)
          .stroke(AppColors.RANGE_TRACK)
          .strokeWidth(5)
        if (this.calorieArcProgress() > 0) {
          Path()
            .commands(this.calorieArcPath(this.calorieArcProgress()))
            .width(116).height(116)
            .fill(AppColors.TRANSPARENT)
            .stroke(this.calorieArcProgress() >= 0.75 ? AppColors.VISUAL_ORANGE : AppColors.VISUAL_YELLOW)
            .strokeWidth(5)
        }
      }
      .width(116).height(116)
      Row() {
        MetricComp({ icon: AppImages.steps(), value: String(this.healthVM.healthSteps), unit: $r('app.string.health_unit_steps') })
          .id(`metricSteps_${this.healthVM.dashboardVersion}`)
        Blank().layoutWeight(1)
        MetricComp({ icon: AppImages.calories(), value: String(this.healthVM.healthCalories), unit: $r('app.string.health_unit_calories') })
          .id(`metricCal_${this.healthVM.dashboardVersion}`)
        Blank().layoutWeight(1)
        MetricComp({ icon: AppImages.activeDuration(), value: String(this.healthVM.healthActiveMinutes), unit: $r('app.string.health_unit_minutes') })
          .id(`metricMin_${this.healthVM.dashboardVersion}`)
      }
      .width('100%')
    }
    .width('100%').height(140).padding({ left: 20, right: 20 }).margin({ top: 16 })
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
      this.healthVM.load(this);
      this.showLanguageDialog = false;
    })
  }

  // MARK: - Editor save
  private handleEditorSave(typeNamesCsv: string): void {
    const types: string[] = typeNamesCsv.split(',').map(t => t.trim()).filter(t => t.length > 0);
    this.healthVM.saveCardConfiguration(types, this);
    const msg: string | undefined = this.healthVM.consumeEffectMessage();
    if (msg !== undefined) {
      // error is handled by CardEditorComp; reload to restore original card state
      this.healthVM.load(this);
      return;
    }
    saveStoreSnapshot();
    this.currentPage = PAGE_MAIN;
  }

  // MARK: - Data
  private performRefresh(): void {
    this.healthVM.refresh(this);
    if (!this.healthVM.healthDataCorrupted) {
      saveStoreSnapshot();
    }
    this.refreshing = false;
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
