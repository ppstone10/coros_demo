import {
  LoginActionType,
  LoginEffect,
  LoginEffectType,
  LoginState
} from '../auth/logic/LoginState';
import { getLoginViewModel } from '../auth/viewmodel/LoginViewModelProvider';
import { navigate, navigateWithParams, NavOperation } from '../auth/navigation/AuthNavigator';
import { AuthRoutes } from '../auth/navigation/AuthRoutes';
import { handleAuthEffect } from '../auth/navigation/AuthEffectHandler';
import { saveStoreSnapshot } from '../core/bridge/StorePersister';
import { AppColors, AppImages, AppSpacing, AppTypography } from '../core/resources/AppResources';
import {
  APP_LANGUAGE_CHINESE,
  APP_LANGUAGE_ENGLISH,
  selectAppLanguage
} from '../core/resources/AppLanguage';
import { HealthCardModel, createDefaultHealthCards } from '../health/HealthDashboardTypes';
import { HealthDashboardViewModel, consumePendingStaleRefresh } from '../health/HealthDashboardViewModel';
import { AccountOverviewComp } from '../home/account/AccountOverviewComp';
import { RecordsPlaceholderComp } from '../home/RecordsPlaceholderComp';
import { ExplorePlaceholderComp } from '../home/ExplorePlaceholderComp';
import { HeroTopRowComp } from '../health/components/HeroTopRowComp';
import { ScenarioPickerComp } from '../health/components/ScenarioPickerComp';
import { BottomNavBarComp } from '../home/BottomNavBarComp';
import { MetricComp } from '../health/components/MetricComp';
import { DashboardCardComp } from '../health/components/DashboardCardComp';
import { HealthWeightPickerSheetComp } from '../health/components/HealthWeightPickerSheetComp';
import {
  HealthPullRefreshPhase,
  PULL_REFRESH_HOLD_OFFSET,
  PULL_REFRESH_RESISTANCE,
  PULL_REFRESH_SETTLE_DURATION,
  PULL_REFRESH_SYNC_DURATION,
  PULL_REFRESH_THRESHOLD,
  pullRefreshIndicatorTop,
  pullRefreshPhaseForOffset
} from '../health/components/PullToRefreshState';

const PAGE_MAIN: string = 'main';
const PAGE_SCENARIO_PICKER: string = 'scenario_picker';

@Preview
@Entry
@Component
struct SignedInPage {
  private viewModel = getLoginViewModel();
  @State selectedTab: number = 0;
  @State healthVM: HealthDashboardViewModel = new HealthDashboardViewModel();
  @State currentPage: string = PAGE_MAIN;
  @State refreshing: boolean = false;
  @State dragOffset: number = 0;
  @State refreshPhase: HealthPullRefreshPhase = HealthPullRefreshPhase.Idle;
  @State healthHeroHeight: number = 0;
  @State refreshIndicatorHeight: number = 0;
  private refreshGestureActive: boolean = false;
  private nativeRefreshDragging: boolean = false;
  private releaseShouldRefresh: boolean = false;
  private isAtScrollTop: boolean = true;
  @State showDeleteDialog: boolean = false;
  @State showKickedDialog: boolean = false;
  private foregroundTimer: number = -1;
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
  @StorageLink('health_cards_version') healthCardsVersion: number = 0;
  @State showLanguageDialog: boolean = false;
  @State showHealthWeightPicker: boolean = false;
  @State healthWeightPickerValue: number = 60.0;
  private appliedHealthCardsVersion: number = 0;

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
    if (consumePendingStaleRefresh()) {
      this.healthVM.refreshing = true;
      this.healthVM.healthCards = createDefaultHealthCards();
      this.healthVM.healthSteps = 0;
      this.healthVM.healthCalories = 0;
      this.healthVM.healthActiveMinutes = 0;
      this.healthVM.healthDateLabel = '';
      this.healthVM.loadScenarioCatalogOnly();
      this.beginHarmonyRefresh();
    } else {
      this.healthVM.load(this);
    }
    this.appliedHealthCardsVersion = this.healthCardsVersion;
    this.syncState();
    this.syncKickedDialogState();
    // MSRV-019：前台周期性会话校验，被顶即弹窗（3s 间隔）
    this.foregroundTimer = setInterval(() => {
      this.viewModel.checkSessionOnForeground();
      this.syncKickedDialogState();
    }, 3000);
  }

  aboutToDisappear(): void {
    if (this.foregroundTimer >= 0) {
      clearInterval(this.foregroundTimer);
      this.foregroundTimer = -1;
    }
  }

  onPageShow(): void {
    if (this.appliedHealthCardsVersion !== this.healthCardsVersion) {
      this.healthVM.load(this);
      this.appliedHealthCardsVersion = this.healthCardsVersion;
    }
    this.syncState();
    this.syncKickedDialogState();
  }

  private syncKickedDialogState(): void {
    if (this.viewModel.state.kickedDialogShown) {
      this.showKickedDialog = true;
    }
  }

  onBackPress(): boolean {
    if (this.currentPage === PAGE_SCENARIO_PICKER) {
      this.currentPage = PAGE_MAIN;
      return true;
    }
    return false;
  }

  build() {
    Stack() {
      Column() {
        if (this.currentPage === PAGE_SCENARIO_PICKER) {
          ScenarioPickerComp({
            selectedScenario: this.healthVM.currentScenario,
            scenarios: this.healthVM.scenarios,
            onSelect: (name: string) => {
              this.healthVM.selectScenario(name);
              this.currentPage = PAGE_MAIN;
              if (name === 'Normal') {
                navigate(NavOperation.Push, AuthRoutes.health.NORMAL_DATA_EDITOR);
              }
            },
            onDismiss: () => {
              this.currentPage = PAGE_MAIN;
            }
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
      if (this.showKickedDialog) {
        this.KickedDialog();
      }
      if (this.showLanguageDialog) {
        this.LanguageDialog();
      }
      if (this.showHealthWeightPicker) {
        HealthWeightPickerSheetComp({
          current: this.healthWeightPickerValue,
          onDismiss: () => { this.showHealthWeightPicker = false; },
          onConfirm: (weightKg: number) => {
            this.healthVM.saveBodyWeight(weightKg, this);
            if (this.healthVM.consumeEffectMessage() === undefined) {
              saveStoreSnapshot();
            }
            this.showHealthWeightPicker = false;
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BLACK)
  }

  @Builder
  HealthDashboard() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        HeroTopRowComp({
          dateLabel: this.healthVM.healthDateLabel,
          isSyncing: this.refreshing,
          onTap: () => { this.selectedTab = 3; this.syncState(); },
          onLongPress: () => { this.currentPage = PAGE_SCENARIO_PICKER; }
        })
          .onAreaChange((_oldValue: Area, newValue: Area) => {
            this.healthHeroHeight = this.lengthValue(newValue.height);
          })
        Refresh({
          refreshing: $$this.refreshing,
          builder: this.EmptyRefreshIndicator
        }) {
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
                    onBodyWeightTap: () => {
                      this.healthWeightPickerValue = Number(card.visual.primaryValue || '60.0');
                      this.showHealthWeightPicker = true;
                    },
                    onTap: () => {
                      navigateWithParams(NavOperation.Push, AuthRoutes.toHealthDetail(card.id));
                    }
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
                  .onClick(() => { navigate(NavOperation.Push, AuthRoutes.health.EDITOR); })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
          .scrollBar(BarState.Off)
          .id(`scrollData_${this.healthVM.dashboardVersion}`)
        }
        .layoutWeight(1)
        .refreshOffset(PULL_REFRESH_HOLD_OFFSET)
        .pullToRefresh(false)
        .pullDownRatio(PULL_REFRESH_RESISTANCE)
        .onOffsetChange((offset: number) => {
          this.handleRefreshOffset(offset);
        })
        .onStateChange((status: RefreshStatus) => {
          this.updateRefreshPhase(status);
        })
      }
      .width('100%')
      .height('100%')

      if (this.refreshPhase !== HealthPullRefreshPhase.Idle) {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color(AppColors.STEPS)
            .rotate({
              angle: this.refreshPhase === HealthPullRefreshPhase.Dragging ||
                this.refreshPhase === HealthPullRefreshPhase.Armed ?
                this.pullRefreshProgress() * 45 : 0
            })
          Text(this.refreshPrompt())
            .fontSize(AppTypography.SUPPORTING)
            .fontColor(AppColors.MUTED)
        }
        .onAreaChange((_oldValue: Area, newValue: Area) => {
          this.refreshIndicatorHeight = this.lengthValue(newValue.height);
        })
        .translate({
          y: pullRefreshIndicatorTop(
            this.healthHeroHeight + this.dragOffset,
            this.refreshIndicatorHeight
          )
        })
        .opacity(this.refreshIndicatorOpacity())
        .scale({
          x: 0.94 + 0.06 * this.refreshIndicatorOpacity(),
          y: 0.94 + 0.06 * this.refreshIndicatorOpacity()
        })
        .zIndex(4)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  EmptyRefreshIndicator() {
    Blank().width(0).height(0)
  }

  private updateRefreshPhase(status: RefreshStatus): void {
    if (status === RefreshStatus.Drag || status === RefreshStatus.OverDrag) {
      this.nativeRefreshDragging = true;
      this.refreshGestureActive = true;
    } else if (status === RefreshStatus.Refresh) {
      this.nativeRefreshDragging = false;
      this.refreshPhase = HealthPullRefreshPhase.Refreshing;
    } else if (status === RefreshStatus.Done) {
      this.nativeRefreshDragging = false;
      this.refreshPhase = HealthPullRefreshPhase.Resetting;
    } else if (status === RefreshStatus.Inactive) {
      this.nativeRefreshDragging = false;
      if (this.refreshGestureActive && !this.refreshing) {
        this.finishRefreshGesture();
      }
    }
  }

  private handleRefreshOffset(offset: number): void {
    this.dragOffset = Math.max(0, offset);
    if (this.refreshing) {
      this.refreshPhase = HealthPullRefreshPhase.Refreshing;
      return;
    }
    if (this.nativeRefreshDragging && this.dragOffset > 0) {
      this.refreshGestureActive = true;
      this.releaseShouldRefresh = this.dragOffset >= PULL_REFRESH_THRESHOLD;
      this.refreshPhase = pullRefreshPhaseForOffset(this.dragOffset);
    }
  }

  private finishRefreshGesture(): void {
    const shouldRefresh: boolean = this.releaseShouldRefresh;
    this.refreshGestureActive = false;
    this.releaseShouldRefresh = false;
    if (shouldRefresh) {
      this.beginHarmonyRefresh();
    } else {
      this.beginHarmonyReset();
    }
  }

  private beginHarmonyRefresh(): void {
    this.refreshing = true;
    this.refreshPhase = HealthPullRefreshPhase.Refreshing;
    setTimeout(() => { this.performRefresh(); }, PULL_REFRESH_SYNC_DURATION);
  }

  private beginHarmonyReset(): void {
    this.refreshPhase = HealthPullRefreshPhase.Resetting;
    setTimeout(() => {
      if (!this.refreshing) {
        this.dragOffset = 0;
        this.refreshPhase = HealthPullRefreshPhase.Idle;
      }
    }, PULL_REFRESH_SETTLE_DURATION);
  }

  private pullRefreshProgress(): number {
    return Math.max(0, Math.min(1, this.dragOffset / PULL_REFRESH_THRESHOLD));
  }

  private refreshIndicatorOpacity(): number {
    if (this.refreshPhase === HealthPullRefreshPhase.Idle) return 0;
    if (this.refreshPhase === HealthPullRefreshPhase.Dragging) {
      return Math.min(1, this.pullRefreshProgress() / 0.4);
    }
    if (this.refreshPhase === HealthPullRefreshPhase.Resetting) {
      return Math.max(0, Math.min(1, this.dragOffset / PULL_REFRESH_HOLD_OFFSET));
    }
    return 1;
  }

  private refreshPrompt(): ResourceStr {
    if (this.refreshPhase === HealthPullRefreshPhase.Dragging) {
      return $r('app.string.health_pull_to_refresh');
    }
    if (this.refreshPhase === HealthPullRefreshPhase.Armed) {
      return $r('app.string.health_release_to_refresh');
    }
    return $r('app.string.health_data_syncing');
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
  KickedDialog() {
    Column() {
      Blank().layoutWeight(1)
      Column({ space: 24 }) {
        Text($r('app.string.auth_error_session_expired_elsewhere'))
          .fontSize(18).fontColor(AppColors.WHITE).textAlign(TextAlign.Center)
        Button($r('app.string.common_confirm'), { type: ButtonType.Normal })
          .fontSize(16).fontColor(AppColors.WHITE)
          .layoutWeight(1).height(44).borderRadius(8).backgroundColor(AppColors.ACTION)
          .onClick(() => {
            this.showKickedDialog = false;
            this.viewModel.confirmKickedDialog();
          })
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

  // MARK: - Data
  private performRefresh(): void {
    this.healthVM.refresh(this);
    if (!this.healthVM.healthDataCorrupted) {
      saveStoreSnapshot();
    }
    this.refreshPhase = HealthPullRefreshPhase.Resetting;
    this.refreshing = false;
    setTimeout(() => {
      if (!this.refreshing) {
        this.dragOffset = 0;
        this.refreshPhase = HealthPullRefreshPhase.Idle;
      }
    }, PULL_REFRESH_SETTLE_DURATION);
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

  private lengthValue(value: Length | undefined): number {
    if (typeof value === 'number') return value;
    if (typeof value === 'string') {
      let parsed: number = parseFloat(value);
      return Number.isNaN(parsed) ? 0 : parsed;
    }
    return 0;
  }
}
