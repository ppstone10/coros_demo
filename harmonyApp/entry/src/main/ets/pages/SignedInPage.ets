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
import { localizedAuthMessage } from '../resources/AuthLocalization';
import { healthResource } from '../resources/HealthLocalization';
import {
  APP_LANGUAGE_CHINESE,
  APP_LANGUAGE_ENGLISH,
  selectAppLanguage
} from '../resources/AppLanguage';
import lottie, { AnimationItem } from '@ohos/lottie';

interface CardEntry {
  type: string;
  titleKey: string;
  summaryKey: string;
  summaryArgs: string[];
  isRisk: boolean;
}

interface HealthSnapshot {
  scenario: string;
  dateLabelKey: string;
  steps: number;
  calories: number;
  activeMinutes: number;
  cards: CardEntry[];
  enabledTypes: string;
}

class HealthCardModel {
  id: string;
  title: ResourceStr;
  summary: ResourceStr;
  iconIndex: number;
  isRisk: boolean;

  constructor(id: string, title: ResourceStr, summary: ResourceStr, iconIndex: number, isRisk: boolean = false) {
    this.id = id;
    this.title = title;
    this.summary = summary;
    this.iconIndex = iconIndex;
    this.isRisk = isRisk;
  }
}

function createDefaultHealthCards(): HealthCardModel[] {
  return [
    new HealthCardModel('WeeklyPlan', $r('app.string.health_card_weekly_plan_title'), $r('app.string.health_summary_weekly_empty'), 0),
    new HealthCardModel('TrainingLoad', $r('app.string.health_card_training_load_title'), $r('app.string.health_summary_training_load_empty'), 1),
    new HealthCardModel('TrainingAssessment', $r('app.string.health_card_training_assessment_title'), $r('app.string.health_summary_training_assessment_empty'), 2),
    new HealthCardModel('Recovery', $r('app.string.health_card_recovery_title'), $r('app.string.health_summary_recovery_empty'), 3),
    new HealthCardModel('RunningAbility', $r('app.string.health_card_running_ability_title'), $r('app.string.health_summary_running_empty'), 4),
    new HealthCardModel('CyclingAbility', $r('app.string.health_card_cycling_ability_title'), $r('app.string.health_summary_cycling_empty'), 5),
    new HealthCardModel('HeartRate', $r('app.string.health_card_heart_rate_title'), $r('app.string.health_summary_heart_rate_empty'), 6),
    new HealthCardModel('Stress', $r('app.string.health_card_stress_title'), $r('app.string.health_summary_stress_empty'), 7),
    new HealthCardModel('Sleep', $r('app.string.health_card_sleep_title'), $r('app.string.health_summary_sleep_empty'), 8),
    new HealthCardModel('HrvAssessment', $r('app.string.health_card_hrv_assessment_title'), $r('app.string.health_summary_hrv_empty'), 9),
    new HealthCardModel('RestingHeartRate', $r('app.string.health_card_resting_heart_rate_title'), $r('app.string.health_summary_resting_hr_empty'), 10),
    new HealthCardModel('HealthCheck', $r('app.string.health_card_health_check_title'), $r('app.string.health_summary_health_check_empty'), 11),
    new HealthCardModel('BodyManagement', $r('app.string.health_card_body_management_title'), $r('app.string.health_summary_body_empty'), 12)
  ];
}

PersistentStorage.persistProp<string>('health_card_order', '');

@Entry
@Component
struct SignedInPage {
  private viewModel = getLoginViewModel();
  @State selectedTab: number = 0;
  @State healthCards: HealthCardModel[] = createDefaultHealthCards();
  @StorageLink('health_card_order') savedHealthCardOrder: string = '';
  @State editingHealthCards: HealthCardModel[] = [];
  @State editingCards: boolean = false;
  @State draggingCardId: string = '';
  @State dragStartIndex: number = -1;
  @State dragTranslation: number = 0;
  @State dragVisualOffset: number = 0;
  @State dragScrollOffset: number = 0;
  @State dragEdgeDirection: number = 0;
  @State dragEdgeSpeed: number = 0;
  @State editorViewportTop: number = 0;
  @State editorViewportHeight: number = 0;
  private cardEditorScroller: Scroller = new Scroller();
  private cardDragScrollTimer: number = -1;
  @State detailCardId: string = '';
  @State warning: string = '';
  @State refreshing: boolean = false;
  @State dragOffset: number = 0;
  @State showScenarioPicker: boolean = false;
  @State scenarioName: string = 'Normal';
  @State scenarioDisplayText: ResourceStr = $r('app.string.health_scenario_normal');
  private scenarios: string[] = ['Normal','PartialMissing','AllEmpty','Abnormal','ReadFailure'];
  @State healthSteps: string = '8769';
  @State healthCalories: string = '769';
  @State healthMinutes: string = '69';
  @State healthDateLabel: ResourceStr = $r('app.string.health_demo_date');
  @State dashboardVersion: number = 0;
  @State dashboardVisible: boolean = true;
  private lottieCanvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private lottieItem: AnimationItem | null = null;
  private lottieLoaded: boolean = false;
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

  aboutToAppear(): void {
    this.loadSavedCardOrder();
    this.loadHealthDataFromKMP();
    this.syncState();
  }

  aboutToDisappear(): void {
    lottie.destroy();
    this.lottieLoaded = false;
  }

  onPageShow(): void {
    this.syncState();
  }

  onBackPress(): boolean {
    if (this.editingCards || this.detailCardId.length > 0) {
      this.cancelCardEditing();
      this.detailCardId = '';
    }
    return true;
  }

  build() {
    Stack() {
      Column() {
        if (this.editingCards) {
          this.CardEditor();
        } else if (this.detailCardId.length > 0) {
          this.HealthDetail();
        } else {
          if (this.selectedTab === 0) {
            this.HealthDashboard();
          } else if (this.selectedTab === 3) {
            this.AccountOverview();
          } else {
            this.Placeholder();
          }
        }

        if (!this.editingCards && this.detailCardId.length === 0) {
          this.BottomNavigation();
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BLACK)

      if (this.showDeleteDialog) {
        this.DeleteAccountDialog();
      }
      if (this.showScenarioPicker) {
        this.ScenarioPicker();
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
      this.HeroTopRow();
      Refresh({ refreshing: $$this.refreshing }) {
        Scroll() {
          Column() {
            Column() {
              this.ArcMetrics();
            }
            .id(`arc_${this.dashboardVersion}`)
            ForEach(this.healthCards, (card: HealthCardModel) => {
              this.DashboardCard(card);
            }, (card: HealthCardModel) => `${card.id}_v${this.dashboardVersion}`)

            Text($r('app.string.health_edit_cards'))
              .fontSize(AppTypography.LABEL)
              .fontColor(AppColors.HEALTH_EDIT_TEXT)
              .padding({ left: AppSpacing.ACTION_HORIZONTAL, right: AppSpacing.ACTION_HORIZONTAL,
                top: AppSpacing.MEDIUM, bottom: AppSpacing.MEDIUM })
              .backgroundColor(AppColors.HEALTH_CARD)
              .borderRadius(22)
              .margin({ top: AppSpacing.LARGE, bottom: 42 })
              .onClick(() => { this.beginCardEditing(); })
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
        this.lottieItem?.goToAndPlay(0, true);
        setTimeout(() => {
          this.performRefresh();
        }, 4460);
      })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  HeroTopRow() {
    Row() {
      Column() {
        Text(this.healthDateLabel).fontSize(AppTypography.CAPTION).fontColor(AppColors.HEALTH_DATE)
        Text($r('app.string.health_today')).fontSize(AppTypography.HERO_TITLE).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Image(AppImages.calendar()).width(23).height(23).objectFit(ImageFit.Contain)
      Blank().width(18)
      Canvas(this.lottieCanvasCtx)
        .width(30).height(30)
        .backgroundColor(AppColors.TRANSPARENT)
        .onReady(() => {
          if (this.lottieItem !== null) {
            this.lottieItem.destroy('lottieWatch');
          }
          this.lottieCanvasCtx.imageSmoothingEnabled = true;
          this.lottieCanvasCtx.imageSmoothingQuality = 'medium';
          this.lottieItem = lottie.loadAnimation({
            container: this.lottieCanvasCtx,
            renderer: 'canvas',
            loop: false,
            autoplay: false,
            name: 'lottieWatch',
            path: 'common/watch_status.json',
          });
          this.lottieItem.addEventListener('DOMLoaded', () => {
            this.lottieLoaded = true;
          });
          this.lottieItem.addEventListener('complete', () => {
            this.lottieItem?.goToAndStop(0, true);
          });
        })
        .gesture(LongPressGesture().onAction(() => { this.showScenarioPicker = true; }))
    }
    .width('100%').padding({ left: 20, right: 20, top: 32 })
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
  Metric(icon: Resource, value: string, unit: string) {
    MetricComp({ icon: icon, value: value, unit: unit })
  }

  @Builder
  DashboardCard(card: HealthCardModel) {
    DashboardCardComp({
      card: card,
      onTap: () => { this.detailCardId = card.id; }
    })
  }

  @Builder
  CardEditor() {
    Column() {
      Row() {
        Text($r('app.string.common_back')).fontSize(38).fontColor(AppColors.WHITE).width(64)
          .onClick(() => { this.cancelCardEditing(); })
        Text($r('app.string.health_edit_cards')).fontSize(AppTypography.SECTION_TITLE).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text($r('app.string.common_save')).fontSize(AppTypography.ACTION).fontColor(AppColors.WHITE).width(64).height(30).textAlign(TextAlign.Center)
          .backgroundColor(AppColors.ACTION).borderRadius(6)
          .onClick(() => { this.commitCardEditing(); })
      }
      .width('100%').height(64).padding({ left: 18, right: 18 }).margin({ top: 32 })
      .alignItems(VerticalAlign.Center)

      Text($r('app.string.health_manage_cards')).fontSize(AppTypography.LABEL).fontColor(AppColors.MUTED)
        .width('100%').padding({ left: 22, right: 22, bottom: 10 })
      if (this.warning.length > 0) {
        Text(this.warning).fontSize(AppTypography.SUPPORTING).fontColor(AppColors.HEALTH_WARNING).margin({ bottom: AppSpacing.SMALL })
      }

      Scroll(this.cardEditorScroller) {
        Column() {
          ForEach(this.editingHealthCards, (card: HealthCardModel, index: number) => {
            this.EditorRow(card, index);
          }, (card: HealthCardModel) => card.id)

          if (this.inactiveCards().length > 0) {
            Text($r('app.string.health_more_daily_data')).fontSize(AppTypography.LABEL).fontColor(AppColors.MUTED)
              .width('100%').margin({ top: 24, bottom: 11, left: 6 })
            ForEach(this.inactiveCards(), (card: HealthCardModel) => {
              this.AddCardRow(card);
            }, (card: HealthCardModel) => card.id)
          }

          Text($r('app.string.health_restore_defaults')).fontSize(AppTypography.ACTION).fontColor(AppColors.ACTION)
            .width('100%').padding({ left: 18, right: 18, top: 17, bottom: 17 })
            .margin({ top: 24, bottom: 32 })
            .backgroundColor(AppColors.HEALTH_CARD).borderRadius(8)
            .onClick(() => {
              this.loadHealthDataFromKMP();
              this.warning = '';
            })
        }
        .width('100%').padding({ left: 18, right: 18 })
      }
      .layoutWeight(1).scrollBar(BarState.Off)
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        this.editorViewportTop = this.lengthValue(newValue.globalPosition.y);
        this.editorViewportHeight = this.lengthValue(newValue.height);
      })
    }
    .width('100%').height('100%').backgroundColor(AppColors.BLACK)
  }

  @Builder
  EditorRow(card: HealthCardModel, index: number) {
    Row() {
      Text('⠿').fontSize(18).fontColor(AppColors.MUTED).padding({ top: 12, bottom: 12, right: 4 })
      Blank().width(10)
      Image(AppImages.healthIcon(card.iconIndex)).width(22).height(22).objectFit(ImageFit.Contain)
      Blank().width(10)
      Text(card.title).fontSize(AppTypography.EDITOR_ROW).fontColor(AppColors.HEALTH_EDITOR_TITLE).layoutWeight(1)
      Image(AppImages.editorRemove()).width(30).height(30).objectFit(ImageFit.Contain)
        .onClick(() => { this.removeCard(card.id); })
    }
    .width('100%').height(56).padding({ left: 18, right: 12 })
    .backgroundColor(AppColors.HEALTH_CARD)
    .translate({ y: this.draggingCardId === card.id ? this.dragVisualOffset : 0 })
    .scale({
      x: this.draggingCardId === card.id ? 1.015 : 1,
      y: this.draggingCardId === card.id ? 1.015 : 1
    })
    .shadow(this.draggingCardId === card.id ? {
      radius: 12,
      color: AppColors.OVERLAY_60,
      offsetY: 5
    } : { radius: 0 })
    .opacity(this.draggingCardId === card.id ? 0.94 : 1)
    .zIndex(this.draggingCardId === card.id ? 10 : 0)
    .border({ width: { bottom: 1 }, color: AppColors.DIVIDER })
    .gesture(
      GestureGroup(
        GestureMode.Sequence,
        LongPressGesture({ repeat: false, duration: 350 })
          .onAction((_event: GestureEvent) => { this.startCardDrag(card.id); }),
        PanGesture({ direction: PanDirection.Vertical, distance: 1 })
          .onActionUpdate((event: GestureEvent) => {
            let globalY: number = event.fingerList.length > 0 ? event.fingerList[0].globalY :
              this.editorViewportTop + this.editorViewportHeight / 2;
            this.updateCardDrag(card.id, event.offsetY, globalY);
          })
          .onActionEnd((_event: GestureEvent) => { this.endCardDrag(); })
          .onActionCancel(() => { this.endCardDrag(); })
      ).onCancel(() => { this.endCardDrag(); })
    )
  }

  @Builder
  AddCardRow(card: HealthCardModel) {
    Row() {
      Image(AppImages.healthIcon(card.iconIndex)).width(22).height(22).objectFit(ImageFit.Contain)
      Blank().width(10)
      Text(card.title).fontSize(AppTypography.EDITOR_ROW).fontColor(AppColors.HEALTH_EDITOR_TITLE).layoutWeight(1)
      Stack({ alignContent: Alignment.Center }) {
        Text('+').fontSize(24).fontColor(AppColors.WHITE).fontWeight(FontWeight.Lighter)
      }
      .width(30).height(30).borderRadius(15).backgroundColor(AppColors.ADD_ACTION)
    }
    .width('100%').height(56).padding({ left: 18, right: 12 })
    .backgroundColor(AppColors.HEALTH_CARD)
    .border({ width: { bottom: 1 }, color: AppColors.DIVIDER })
    .onClick(() => {
      this.editingHealthCards = this.editingHealthCards.concat([card]);
      this.warning = '';
    })
  }

  @Builder
  HealthDetail() {
    Column() {
      Row() {
        Text('‹').fontSize(38).fontColor(AppColors.WHITE).width(48)
          .onClick(() => { this.detailCardId = ''; })
        Text(this.detailCard().title).fontSize(AppTypography.SECTION_TITLE).fontColor(AppColors.WHITE)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(48)
      }
      .height(64).width('100%').padding({ left: 18, right: 18 }).margin({ top: 32 })
      .alignItems(VerticalAlign.Center)
      Column({ space: 20 }) {
        Image(AppImages.healthIcon(this.detailCard().iconIndex)).width(56).height(56).objectFit(ImageFit.Contain)
        Text(this.localizedHealthText('health_pending_feature', [this.resourceText(this.detailCard().title)]))
          .fontSize(AppTypography.CARD_TITLE).fontColor(AppColors.HEALTH_PLACEHOLDER)
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center)
    }
    .width('100%').height('100%').backgroundColor(AppColors.BLACK)
  }

  @Builder
  AccountOverview() {
    Scroll() {
      Column() {
        Row() {
          Text($r('app.string.account_title')).fontSize(26).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
          Blank().layoutWeight(1)
          SymbolGlyph($r('sys.symbol.worldclock'))
            .fontSize(26).fontColor([AppColors.WHITE]).width(44).height(44)
            .accessibilityText($r('app.string.language_switch'))
            .onClick(() => { this.showLanguageDialog = true; })
        }
        .width('100%').margin({ top: 42, bottom: 8 })

        Row() {
          if (this.profileAvatarUri.length > 0) {
            Image(this.profileAvatarUri).width(58).height(58).borderRadius(29).clip(true).objectFit(ImageFit.Cover)
          } else {
            Stack({ alignContent: Alignment.Center }) {
              Text(this.displayName.substring(0, Math.min(1, this.displayName.length)).toUpperCase())
                .fontSize(23).fontColor(AppColors.WHITE)
            }
            .width(58).height(58).borderRadius(29).backgroundColor(AppColors.ACCOUNT_AVATAR)
          }
          Blank().width(14)
          Column({ space: 5 }) {
            Text(this.displayName).fontSize(19).fontColor(AppColors.WHITE)
            Text(this.sessionAccount).fontSize(12).fontColor(AppColors.ACCOUNT_MUTED).maxLines(1)
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          Text(this.profileComplete ? $r('app.string.account_profile_complete') : $r('app.string.account_profile_incomplete')).fontSize(11)
            .fontColor(this.profileComplete ? AppColors.COMPLETE : AppColors.INCOMPLETE)
        }
        .width('100%').padding(18).backgroundColor(AppColors.HEALTH_CARD).borderRadius(10)
        .onClick(() => { navigateWithParams(NavOperation.Push, AuthRoutes.toProfileEdit()); })

        this.SectionTitle($r('app.string.account_personal_info'));
        Column() {
          this.ValueRow($r('app.string.profile_username'), this.displayName);
          this.ValueRow($r('app.string.profile_birth_date'), this.birthDate);
          this.ValueRow($r('app.string.profile_height'), this.heightText);
          this.ValueRow($r('app.string.profile_weight'), this.weightText);
          this.ValueRow($r('app.string.profile_country_region'), this.localizedCountryName(this.countryRegion));
        }
        .width('100%').backgroundColor(AppColors.HEALTH_CARD).borderRadius(10)

        this.SectionTitle($r('app.string.account_section'));
        Column() {
          this.ValueRow($r('app.string.account_login_account'), this.sessionAccount);
          Text($r('app.string.account_logout')).fontSize(14).fontColor(AppColors.WHITE)
            .width('100%').height(52).padding({ left: 16 }).textAlign(TextAlign.Start)
            .onClick(() => { this.logout(); })
          Text($r('app.string.account_delete')).fontSize(14).fontColor(AppColors.DESTRUCTIVE)
            .width('100%').height(52).padding({ left: 16 }).textAlign(TextAlign.Start)
            .onClick(() => { this.showDeleteDialog = true; })
        }
        .width('100%').backgroundColor(AppColors.HEALTH_CARD).borderRadius(10)

        if (this.localError.length > 0) {
          Text(localizedAuthMessage(this.localError)).fontSize(AppTypography.LABEL).fontColor(AppColors.HEALTH_WARNING).margin({ top: AppSpacing.LARGE })
        }
        Blank().height(30)
      }
      .width('100%').padding({ left: 18, right: 18 })
    }
    .layoutWeight(1).scrollBar(BarState.Off)
  }

  @Builder
  SectionTitle(title: ResourceStr) {
    Text(title).fontSize(13).fontColor(AppColors.ACCOUNT_MUTED)
      .width('100%').margin({ top: 24, bottom: 10, left: 4 })
  }

  @Builder
  ValueRow(label: ResourceStr, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor(AppColors.WHITE)
      Blank().layoutWeight(1)
      Text(value.length > 0 ? value : $r('app.string.common_not_set')).fontSize(13).fontColor(AppColors.ACCOUNT_MUTED)
    }
    .width('100%').height(52).padding({ left: 16, right: 16 })
    .border({ width: { bottom: 1 }, color: AppColors.ACCOUNT_DIVIDER })
  }

  @Builder
  Placeholder() {
    Column() {
      Text($r('app.string.nav_unavailable', this.selectedTab === 1 ? $r('app.string.nav_records') : $r('app.string.nav_explore')))
        .fontSize(16).fontColor(AppColors.NAV_PLACEHOLDER).textAlign(TextAlign.Center)
    }
    .layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
  }

  @Builder
  BottomNavigation() {
    Row() {
      this.NavItem(0, $r('app.string.nav_fitness'));
      this.NavItem(1, $r('app.string.nav_records'));
      this.NavItem(2, $r('app.string.nav_explore'));
      this.NavItem(3, $r('app.string.nav_me'));
    }
    .width('100%').height(66).padding({ top: 7, bottom: 5 })
    .backgroundColor(AppColors.NAV_BAR)
  }

  @Builder
  NavItem(index: number, title: ResourceStr) {
    Column({ space: 2 }) {
      if (this.selectedTab === index) {
        Image(AppImages.navigationSelected(index)).width(27).height(27).objectFit(ImageFit.Contain)
          .renderMode(ImageRenderMode.Template).fillColor(AppColors.WHITE)
      } else {
        Image(AppImages.navigationNormal(index)).width(27).height(27).objectFit(ImageFit.Contain)
          .renderMode(ImageRenderMode.Template).fillColor(AppColors.NAV_UNSELECTED)
      }
      Text(title).fontSize(11).fontColor(this.selectedTab === index ? AppColors.WHITE : AppColors.NAV_UNSELECTED)
        .fontWeight(this.selectedTab === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.selectedTab = index;
      if (index === 3) this.syncState();
    })
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

  @Builder
  ScenarioPicker() {
    Column() {
      Column({ space: 8 }) {
        ForEach(this.scenarios, (scenario: string) => {
          Row() {
            Text(this.scenarioLabel(scenario)).fontSize(15).fontColor(AppColors.WHITE)
            Blank().layoutWeight(1)
            if (scenario === this.scenarioName) {
              Text('✓').fontSize(16).fontColor(AppColors.STEPS)
            }
          }
          .width('100%').padding(14)
          .onClick(() => {
            this.scenarioName = scenario;
            getService().selectHealthScene(scenario);
            this.showScenarioPicker = false;
          })
        }, (scenario: string) => scenario)
      }
      .borderRadius(10).backgroundColor(AppColors.DIALOG_ALT).padding(12).margin({ left: 24, right: 24 })
    }
    .width('100%').height('100%').backgroundColor(AppColors.OVERLAY_62).justifyContent(FlexAlign.Center)
    .onClick(() => { this.showScenarioPicker = false; })
  }

  private performRefresh(): void {
    this.loadHealthDataFromKMP();
    this.refreshing = false;
    this.dashboardVersion++;
    this.lottieItem?.goToAndStop(0, true);
  }

  private scenarioLabel(name: string): ResourceStr {
    switch (name) {
      case 'Normal': return $r('app.string.health_scenario_normal');
      case 'PartialMissing': return $r('app.string.health_scenario_partial_missing');
      case 'AllEmpty': return $r('app.string.health_scenario_all_empty');
      case 'Abnormal': return $r('app.string.health_scenario_abnormal');
      case 'ReadFailure': return $r('app.string.health_scenario_read_failure');
      default: return name;
    }
  }

  private loadHealthDataFromKMP(): void {
    try {
      let json: string = getService().loadHealthSnapshot();
      if (!json || json === '{}') return;
      let data: HealthSnapshot = JSON.parse(json) as HealthSnapshot;
      if (!data || !data.cards || data.cards.length === 0) return;
      this.scenarioName = data.scenario || 'Normal';
      this.healthDateLabel = this.localizedHealthText(data.dateLabelKey || 'health_demo_date', []);
      this.healthSteps = String(data.steps || 0);
      this.healthCalories = String(data.calories || 0);
      this.healthMinutes = String(data.activeMinutes || 0);
      let cards: HealthCardModel[] = [];
      for (let i = 0; i < data.cards.length; i++) {
        let c: CardEntry = data.cards[i];
        let idx: number = this.cardIconIndex(c.type);
        cards.push(new HealthCardModel(
          c.type,
          this.localizedHealthText(c.titleKey, []),
          this.localizedHealthText(c.summaryKey, c.summaryArgs || []),
          idx,
          c.isRisk
        ));
      }
      this.healthCards = cards;
    } catch (e) {
      // keep defaults
    }
  }

  private cardIconIndex(typeName: string): number {
    switch (typeName) {
      case 'WeeklyPlan': return 0;
      case 'TrainingLoad': return 1;
      case 'TrainingAssessment': return 2;
      case 'Recovery': return 3;
      case 'RunningAbility': return 4;
      case 'CyclingAbility': return 5;
      case 'HeartRate': return 6;
      case 'Stress': return 7;
      case 'Sleep': return 8;
      case 'HrvAssessment': return 9;
      case 'RestingHeartRate': return 10;
      case 'HealthCheck': return 11;
      case 'BodyManagement': return 12;
      case 'TodayActivity': return 6;
      default: return 6;
    }
  }

  private localizedHealthText(key: string, args: string[]): string {
    let resource: Resource = healthResource(key);
    let manager = getContext(this).resourceManager;
    if (args.length === 0) return manager.getStringSync(resource.id);
    if (args.length === 1) return manager.getStringSync(resource.id, args[0]);
    if (args.length === 2) return manager.getStringSync(resource.id, args[0], args[1]);
    return manager.getStringSync(resource.id, args[0], args[1], args[2]);
  }

  private resourceText(value: ResourceStr): string {
    if (typeof value === 'string') return value;
    return getContext(this).resourceManager.getStringSync(value.id);
  }

  private beginCardEditing(): void {
    this.editingHealthCards = this.healthCards.slice();
    this.warning = '';
    this.editingCards = true;
  }

  private cancelCardEditing(): void {
    this.editingCards = false;
    this.editingHealthCards = [];
    this.warning = '';
    this.endCardDrag();
  }

  private commitCardEditing(): void {
    this.healthCards = this.editingHealthCards.slice();
    let typeNamesCsv: string = this.healthCards.map((card: HealthCardModel) => card.id).join(',');
    this.savedHealthCardOrder = typeNamesCsv;
    getService().saveCardConfig(typeNamesCsv);
    saveStoreSnapshot();
    this.loadHealthDataFromKMP();
    this.editingCards = false;
    this.editingHealthCards = [];
    this.warning = '';
    this.endCardDrag();
  }

  private startCardDrag(id: string): void {
    this.draggingCardId = id;
    this.dragStartIndex = this.editingHealthCards.findIndex((card: HealthCardModel) => card.id === id);
    this.dragTranslation = 0;
    this.dragVisualOffset = 0;
    this.dragScrollOffset = 0;
    this.dragEdgeDirection = 0;
    this.dragEdgeSpeed = 0;
    this.startCardAutoScroll();
  }

  private updateCardDrag(id: string, offsetY: number, globalY: number): void {
    if (this.draggingCardId !== id || this.dragStartIndex < 0) return;
    this.dragTranslation = offsetY;
    let edgeInset: number = 64;
    if (this.editorViewportHeight > 0 && globalY < this.editorViewportTop + edgeInset) {
      this.dragEdgeDirection = -1;
      let penetration: number = Math.max(0, Math.min(1,
        (this.editorViewportTop + edgeInset - globalY) / edgeInset));
      this.dragEdgeSpeed = 3 + penetration * 9;
    } else if (this.editorViewportHeight > 0 &&
      globalY > this.editorViewportTop + this.editorViewportHeight - edgeInset) {
      this.dragEdgeDirection = 1;
      let penetration: number = Math.max(0, Math.min(1,
        (globalY - (this.editorViewportTop + this.editorViewportHeight - edgeInset)) / edgeInset));
      this.dragEdgeSpeed = 3 + penetration * 9;
    } else {
      this.dragEdgeDirection = 0;
      this.dragEdgeSpeed = 0;
    }
    this.reconcileCardDrag(id);
  }

  private reconcileCardDrag(id: string): void {
    let effectiveOffset: number = this.dragTranslation + this.dragScrollOffset;
    let shift: number = effectiveOffset >= 0 ? Math.floor((effectiveOffset + 28) / 56) :
      Math.ceil((effectiveOffset - 28) / 56);
    let target: number = Math.max(0, Math.min(this.editingHealthCards.length - 1, this.dragStartIndex + shift));
    let current: number = this.editingHealthCards.findIndex((card: HealthCardModel) => card.id === id);
    let nextVisualOffset: number = effectiveOffset - (target - this.dragStartIndex) * 56;
    if (current >= 0 && current !== target) {
      this.getUIContext().animateTo({ duration: 140, curve: Curve.EaseOut }, () => {
        this.dragVisualOffset = nextVisualOffset;
        this.moveCard(current, target);
      });
    } else {
      this.dragVisualOffset = nextVisualOffset;
    }
  }

  private startCardAutoScroll(): void {
    if (this.cardDragScrollTimer >= 0) return;
    this.cardDragScrollTimer = setInterval(() => {
      this.performCardAutoScroll();
    }, 24);
  }

  private performCardAutoScroll(): void {
    if (this.draggingCardId.length === 0 || this.dragEdgeDirection === 0) return;
    let current: number = this.editingHealthCards.findIndex((card: HealthCardModel) =>
      card.id === this.draggingCardId);
    if (current < 0 || current + this.dragEdgeDirection < 0 ||
      current + this.dragEdgeDirection >= this.editingHealthCards.length) {
      this.dragEdgeDirection = 0;
      this.dragEdgeSpeed = 0;
      return;
    }
    let step: number = this.dragEdgeDirection * this.dragEdgeSpeed;
    this.cardEditorScroller.scrollBy(0, step);
    this.dragScrollOffset += step;
    this.reconcileCardDrag(this.draggingCardId);
  }

  private stopCardAutoScroll(): void {
    if (this.cardDragScrollTimer >= 0) {
      clearInterval(this.cardDragScrollTimer);
      this.cardDragScrollTimer = -1;
    }
  }

  private endCardDrag(): void {
    this.stopCardAutoScroll();
    this.draggingCardId = '';
    this.dragStartIndex = -1;
    this.dragTranslation = 0;
    this.dragVisualOffset = 0;
    this.dragScrollOffset = 0;
    this.dragEdgeDirection = 0;
    this.dragEdgeSpeed = 0;
  }

  private lengthValue(value: Length | undefined): number {
    if (typeof value === 'number') return value;
    if (typeof value === 'string') {
      let parsed: number = parseFloat(value);
      return Number.isNaN(parsed) ? 0 : parsed;
    }
    return 0;
  }

  private loadSavedCardOrder(): void {
    if (this.savedHealthCardOrder.length === 0) return;
    let ids: string[] = this.savedHealthCardOrder.split(',');
    let defaults: HealthCardModel[] = createDefaultHealthCards();
    let restored: HealthCardModel[] = [];
    ids.forEach((id: string) => {
      let found: HealthCardModel | undefined = defaults.find((card: HealthCardModel) => card.id === id);
      if (found !== undefined) restored.push(found);
    });
    if (restored.length >= 3) this.healthCards = restored;
  }

  private inactiveCards(): HealthCardModel[] {
    let defaults: HealthCardModel[] = createDefaultHealthCards();
    return defaults.filter((candidate: HealthCardModel) => {
      return this.editingHealthCards.findIndex((active: HealthCardModel) => active.id === candidate.id) < 0;
    });
  }

  private detailCard(): HealthCardModel {
    let found: HealthCardModel | undefined = this.healthCards.find((card: HealthCardModel) => card.id === this.detailCardId);
    return found === undefined ? this.healthCards[0] : found;
  }

  private moveCard(from: number, to: number): void {
    if (to < 0 || to >= this.editingHealthCards.length || from === to) return;
    let copy: HealthCardModel[] = this.editingHealthCards.slice();
    let moving: HealthCardModel = copy[from];
    copy.splice(from, 1);
    copy.splice(to, 0, moving);
    this.editingHealthCards = copy;
  }

  private removeCard(id: string): void {
    if (this.editingHealthCards.length <= 3) {
      this.warning = this.localizedHealthText('health_minimum_cards', []);
      return;
    }
    this.editingHealthCards = this.editingHealthCards.filter((card: HealthCardModel) => card.id !== id);
    this.warning = '';
  }

  private confirmDeleteAccount(): void {
    let message: string = this.viewModel.deleteCurrentAccountMessage();
    this.showDeleteDialog = false;
    if (message.length > 0) {
      this.localError = message;
      return;
    }
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

@Component
struct MetricComp {
  @Prop icon: Resource;
  @Prop value: string;
  @Prop unit: ResourceStr;

  build() {
    Column({ space: 3 }) {
      Image(this.icon).width(22).height(22).objectFit(ImageFit.Contain)
      Text(this.value).fontSize(AppTypography.HERO_TITLE).fontColor(AppColors.WHITE)
      Text(this.unit).fontSize(AppTypography.CAPTION).fontColor(AppColors.HEALTH_METRIC_UNIT)
    }
    .width(82)
  }
}

@Component
struct DashboardCardComp {
  @Prop card: HealthCardModel;
  onTap?: () => void;

  build() {
    Row() {
      Image(AppImages.healthIcon(this.card.iconIndex)).width(22).height(22).objectFit(ImageFit.Contain)
      Blank().width(10)
      Column({ space: 5 }) {
        Text(this.card.title).fontSize(AppTypography.CARD_TITLE).fontColor(AppColors.HEALTH_CARD_TITLE).fontWeight(FontWeight.Medium)
        Text(this.card.summary).fontSize(AppTypography.SUPPORTING).fontColor(this.card.isRisk ? AppColors.RISK : AppColors.MUTED)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text('›').fontSize(25).fontColor(AppColors.HEALTH_CHEVRON)
    }
    .width('calc(100% - 32vp)')
    .constraintSize({ minHeight: 76 })
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .margin({ left: 16, right: 16, top: 5, bottom: 5 })
    .backgroundColor(AppColors.HEALTH_CARD)
    .borderRadius(8)
    .onClick(() => {
      if (this.onTap) { this.onTap(); }
    })
  }
}
