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
import { AppColors, AppImages, AppText } from '../resources/AppResources';

class HealthCardModel {
  id: string;
  title: string;
  summary: string;
  iconIndex: number;

  constructor(id: string, title: string, summary: string, iconIndex: number) {
    this.id = id;
    this.title = title;
    this.summary = summary;
    this.iconIndex = iconIndex;
  }
}

function createDefaultHealthCards(): HealthCardModel[] {
  return [
    new HealthCardModel('weeklyPlan', '本周计划', '本周无计划', 0),
    new HealthCardModel('trainingLoad', '本周负荷', '本周负荷 526，建议范围 300-700', 1),
    new HealthCardModel('trainingAssessment', '训练量评估', '将在第一次运动后 7 天评估您的训练量', 2),
    new HealthCardModel('recovery', '体力恢复', '恢复评分 78，预计 14 小时后恢复', 3),
    new HealthCardModel('running', '跑步能力', '记录一笔 25min 以上的户外跑步运动', 4),
    new HealthCardModel('cycling', '骑行FTP', '连接功率计，完成一次 20min 以上稳定骑行', 5),
    new HealthCardModel('heartRate', '心率', '佩戴手表记录心率数据', 6),
    new HealthCardModel('stress', '压力', '佩戴手表或进行健康快测获取压力', 7),
    new HealthCardModel('sleep', '睡眠', '昨夜睡眠 7小时18分，质量 86', 8),
    new HealthCardModel('hrv', 'HRV评估', '睡觉时佩戴手表获取数据', 9),
    new HealthCardModel('rhr', '静息心率', '睡觉时佩戴手表或进行静息心率测试', 10),
    new HealthCardModel('healthCheck', '健康快测', '使用手表“健康快测”获取数据', 11),
    new HealthCardModel('body', '体型管理', '体重 68.2 kg · 本周主要锻炼部位', 12)
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

  aboutToAppear(): void {
    this.loadSavedCardOrder();
    this.syncState();
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BLACK)
  }

  @Builder
  HealthDashboard() {
    Scroll() {
      Column() {
        this.HealthHero();
        ForEach(this.healthCards, (card: HealthCardModel) => {
          this.DashboardCard(card);
        }, (card: HealthCardModel) => card.id)

        Text(AppText.EDIT_CARDS)
          .fontSize(13)
          .fontColor('#DDDDDD')
          .padding({ left: 28, right: 28, top: 10, bottom: 10 })
          .backgroundColor(AppColors.HEALTH_CARD)
          .borderRadius(22)
          .margin({ top: 18, bottom: 42 })
          .onClick(() => { this.beginCardEditing(); })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  HealthHero() {
    Column() {
      Row() {
        Column() {
          Text(AppText.DATE).fontSize(11).fontColor('#8C8C8C')
          Text(AppText.TODAY).fontSize(28).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image(AppImages.calendar()).width(23).height(23).objectFit(ImageFit.Contain)
        Blank().width(18)
        Image(AppImages.device()).width(23).height(23).objectFit(ImageFit.Contain)
      }
      .width('100%')
      .margin({ top: 10 })

      Blank().height(44)

      Stack({ alignContent: Alignment.Center }) {
        Progress({ value: 78, total: 100, type: ProgressType.Ring })
          .width(126).height(126)
          .color(AppColors.GAUGE)
          .style({ strokeWidth: 5 })

        Row() {
          this.Metric(AppImages.steps(), '8769', '步');
          Blank().layoutWeight(1)
          this.Metric(AppImages.calories(), '769', 'Kcal');
          Blank().layoutWeight(1)
          this.Metric(AppImages.activeDuration(), '69', 'Min');
        }
        .width('100%')
      }
      .width('100%')
      .height(128)
    }
    .width('100%')
    .height(292)
    .padding({ left: 20, right: 20, top: 36 })
  }

  @Builder
  Metric(icon: Resource, value: string, unit: string) {
    Column({ space: 3 }) {
      Image(icon).width(22).height(22).objectFit(ImageFit.Contain)
      Text(value).fontSize(28).fontColor(AppColors.WHITE)
      Text(unit).fontSize(11).fontColor('#898989')
    }
    .width(82)
  }

  @Builder
  DashboardCard(card: HealthCardModel) {
    Row() {
      Image(AppImages.healthIcon(card.iconIndex)).width(22).height(22).objectFit(ImageFit.Contain)
      Blank().width(10)
      Column({ space: 5 }) {
        Text(card.title).fontSize(16).fontColor('#E8E8E8').fontWeight(FontWeight.Medium)
        Text(card.summary).fontSize(12).fontColor(AppColors.MUTED).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›').fontSize(25).fontColor('#666666')
    }
    .width('calc(100% - 32vp)')
    .constraintSize({ minHeight: 76 })
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .margin({ left: 16, right: 16, top: 5, bottom: 5 })
    .backgroundColor(AppColors.HEALTH_CARD)
    .borderRadius(8)
    .onClick(() => { this.detailCardId = card.id; })
  }

  @Builder
  CardEditor() {
    Column() {
      Row() {
        Text('‹').fontSize(38).fontColor(AppColors.WHITE).width(64)
          .onClick(() => { this.cancelCardEditing(); })
        Text(AppText.EDIT_CARDS).fontSize(19).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text('保存').fontSize(14).fontColor(AppColors.WHITE).width(64).height(30).textAlign(TextAlign.Center)
          .backgroundColor(AppColors.ACTION).borderRadius(6)
          .onClick(() => { this.commitCardEditing(); })
      }
      .width('100%').height(64).padding({ left: 18, right: 18 }).margin({ top: 32 })
      .alignItems(VerticalAlign.Center)

      Text(AppText.MANAGE_CARDS).fontSize(13).fontColor(AppColors.MUTED)
        .width('100%').padding({ left: 22, right: 22, bottom: 10 })
      if (this.warning.length > 0) {
        Text(this.warning).fontSize(12).fontColor('#FF4B55').margin({ bottom: 8 })
      }

      Scroll(this.cardEditorScroller) {
        Column() {
          ForEach(this.editingHealthCards, (card: HealthCardModel, index: number) => {
            this.EditorRow(card, index);
          }, (card: HealthCardModel) => card.id)

          if (this.inactiveCards().length > 0) {
            Text(AppText.MORE_DATA).fontSize(13).fontColor(AppColors.MUTED)
              .width('100%').margin({ top: 24, bottom: 11, left: 6 })
            ForEach(this.inactiveCards(), (card: HealthCardModel) => {
              this.AddCardRow(card);
            }, (card: HealthCardModel) => card.id)
          }

          Text(AppText.RESTORE_DEFAULTS).fontSize(14).fontColor(AppColors.ACTION)
            .width('100%').padding({ left: 18, right: 18, top: 17, bottom: 17 })
            .margin({ top: 24, bottom: 32 })
            .backgroundColor(AppColors.HEALTH_CARD).borderRadius(8)
            .onClick(() => {
              this.editingHealthCards = createDefaultHealthCards();
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
      Text(card.title).fontSize(15).fontColor('#ECECEC').layoutWeight(1)
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
      color: '#99000000',
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
      Text(card.title).fontSize(15).fontColor('#ECECEC').layoutWeight(1)
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
        Text(this.detailCard().title).fontSize(19).fontColor(AppColors.WHITE)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(48)
      }
      .height(64).width('100%').padding({ left: 18, right: 18 }).margin({ top: 32 })
      .alignItems(VerticalAlign.Center)
      Column({ space: 20 }) {
        Image(AppImages.healthIcon(this.detailCard().iconIndex)).width(56).height(56).objectFit(ImageFit.Contain)
        Text(`${this.detailCard().title}功能后续实现`).fontSize(16).fontColor('#BBBBBB')
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center)
    }
    .width('100%').height('100%').backgroundColor(AppColors.BLACK)
  }

  @Builder
  AccountOverview() {
    Scroll() {
      Column() {
        Text(AppText.NAV_ME).fontSize(26).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
          .width('100%').margin({ top: 52, bottom: 18 })

        Row() {
          if (this.profileAvatarUri.length > 0) {
            Image(this.profileAvatarUri).width(58).height(58).borderRadius(29).clip(true).objectFit(ImageFit.Cover)
          } else {
            Stack({ alignContent: Alignment.Center }) {
              Text(this.displayName.substring(0, Math.min(1, this.displayName.length)).toUpperCase())
                .fontSize(23).fontColor(AppColors.WHITE)
            }
            .width(58).height(58).borderRadius(29).backgroundColor('#303034')
          }
          Blank().width(14)
          Column({ space: 5 }) {
            Text(this.displayName).fontSize(19).fontColor(AppColors.WHITE)
            Text(this.sessionAccount).fontSize(12).fontColor(AppColors.ACCOUNT_MUTED).maxLines(1)
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          Text(this.profileComplete ? '已完善' : '待完善').fontSize(11)
            .fontColor(this.profileComplete ? AppColors.COMPLETE : AppColors.INCOMPLETE)
        }
        .width('100%').padding(18).backgroundColor(AppColors.HEALTH_CARD).borderRadius(10)
        .onClick(() => { navigateWithParams(NavOperation.Push, AuthRoutes.toProfileEdit()); })

        this.SectionTitle(AppText.PERSONAL_INFO);
        Column() {
          this.ValueRow(AppText.USERNAME, this.displayName);
          this.ValueRow(AppText.BIRTH_DATE, this.birthDate);
          this.ValueRow(AppText.HEIGHT, this.heightText);
          this.ValueRow(AppText.WEIGHT, this.weightText);
          this.ValueRow(AppText.COUNTRY, this.countryRegion);
        }
        .width('100%').backgroundColor(AppColors.HEALTH_CARD).borderRadius(10)

        this.SectionTitle(AppText.ACCOUNT);
        Column() {
          this.ValueRow(AppText.LOGIN_ACCOUNT, this.sessionAccount);
          Text(AppText.LOGOUT).fontSize(14).fontColor(AppColors.WHITE)
            .width('100%').height(52).padding({ left: 16 }).textAlign(TextAlign.Start)
            .onClick(() => { this.logout(); })
          Text(AppText.DELETE_ACCOUNT).fontSize(14).fontColor(AppColors.DESTRUCTIVE)
            .width('100%').height(52).padding({ left: 16 }).textAlign(TextAlign.Start)
            .onClick(() => { this.showDeleteDialog = true; })
        }
        .width('100%').backgroundColor(AppColors.HEALTH_CARD).borderRadius(10)

        if (this.localError.length > 0) {
          Text(this.localError).fontSize(13).fontColor('#FF4B55').margin({ top: 18 })
        }
        Blank().height(30)
      }
      .width('100%').padding({ left: 18, right: 18 })
    }
    .layoutWeight(1).scrollBar(BarState.Off)
  }

  @Builder
  SectionTitle(title: string) {
    Text(title).fontSize(13).fontColor(AppColors.ACCOUNT_MUTED)
      .width('100%').margin({ top: 24, bottom: 10, left: 4 })
  }

  @Builder
  ValueRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor(AppColors.WHITE)
      Blank().layoutWeight(1)
      Text(value.length > 0 ? value : AppText.NOT_SET).fontSize(13).fontColor(AppColors.ACCOUNT_MUTED)
    }
    .width('100%').height(52).padding({ left: 16, right: 16 })
    .border({ width: { bottom: 1 }, color: '#2B2B2D' })
  }

  @Builder
  Placeholder() {
    Column() {
      Text(`${this.selectedTab === 1 ? AppText.NAV_RECORDS : AppText.NAV_EXPLORE} 功能将在后续版本开放`)
        .fontSize(16).fontColor('#B3B5BA').textAlign(TextAlign.Center)
    }
    .layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
  }

  @Builder
  BottomNavigation() {
    Row() {
      this.NavItem(0, AppText.NAV_FITNESS);
      this.NavItem(1, AppText.NAV_RECORDS);
      this.NavItem(2, AppText.NAV_EXPLORE);
      this.NavItem(3, AppText.NAV_ME);
    }
    .width('100%').height(66).padding({ top: 7, bottom: 5 })
    .backgroundColor(AppColors.NAV_BAR)
  }

  @Builder
  NavItem(index: number, title: string) {
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
        Text('是否确认注销账号').fontSize(18).fontColor(AppColors.WHITE).textAlign(TextAlign.Center)
        Row({ space: 14 }) {
          Button('取消', { type: ButtonType.Normal }).fontSize(16).fontColor(AppColors.WHITE)
            .layoutWeight(1).height(44).borderRadius(8).backgroundColor('#343438')
            .onClick(() => { this.showDeleteDialog = false; })
          Button('确认', { type: ButtonType.Normal }).fontSize(16).fontColor(AppColors.WHITE)
            .layoutWeight(1).height(44).borderRadius(8).backgroundColor('#B80035')
            .onClick(() => { this.confirmDeleteAccount(); })
        }
      }
      .padding({ left: 24, right: 24, top: 22, bottom: 22 })
      .backgroundColor('#202023').borderRadius(12).margin({ left: 42, right: 42 })
      Blank().layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#0000009E')
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
    this.savedHealthCardOrder = this.healthCards.map((card: HealthCardModel) => card.id).join(',');
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
      this.warning = AppText.MINIMUM_CARDS;
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
}
