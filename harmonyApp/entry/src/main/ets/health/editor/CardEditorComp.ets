import { AppColors, AppImages, AppSpacing, AppTypography } from '../../resources/AppResources';
import { HealthCardModel, createDefaultHealthCards, localizedHealthText } from '../HealthDashboardTypes';

@Component
export struct CardEditorComp {
  @Prop healthCards: HealthCardModel[];
  onSave?: (typeNamesCsv: string) => void;
  onCancel?: () => void;

  @State editingHealthCards: HealthCardModel[] = [];
  @State warning: string = '';
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

  aboutToAppear(): void {
    this.editingHealthCards = this.healthCards.slice();
    this.warning = '';
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.common_back')).fontSize(38).fontColor(AppColors.WHITE).width(64)
          .onClick(() => { this.cancelEditing(); })
        Text($r('app.string.health_edit_cards')).fontSize(AppTypography.SECTION_TITLE).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text($r('app.string.common_save')).fontSize(AppTypography.ACTION).fontColor(AppColors.WHITE).width(64).height(30).textAlign(TextAlign.Center)
          .backgroundColor(AppColors.ACTION).borderRadius(6)
          .onClick(() => { this.commitEditing(); })
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
              this.editingHealthCards = createDefaultHealthCards();
              this.warning = '';
              this.endDrag();
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
      Image(AppImages.healthCardIcon(card.id)).width(22).height(22).objectFit(ImageFit.Contain)
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
      radius: 12, color: AppColors.OVERLAY_60, offsetY: 5
    } : { radius: 0 })
    .opacity(this.draggingCardId === card.id ? 0.94 : 1)
    .zIndex(this.draggingCardId === card.id ? 10 : 0)
    .border({ width: { bottom: 1 }, color: AppColors.DIVIDER })
    .gesture(
      GestureGroup(
        GestureMode.Sequence,
        LongPressGesture({ repeat: false, duration: 350 })
          .onAction((_event: GestureEvent) => { this.startDrag(card.id); }),
        PanGesture({ direction: PanDirection.Vertical, distance: 1 })
          .onActionUpdate((event: GestureEvent) => {
            let globalY: number = event.fingerList.length > 0 ? event.fingerList[0].globalY :
              this.editorViewportTop + this.editorViewportHeight / 2;
            this.updateDrag(card.id, event.offsetY, globalY);
          })
          .onActionEnd((_event: GestureEvent) => { this.endDrag(); })
          .onActionCancel(() => { this.endDrag(); })
      ).onCancel(() => { this.endDrag(); })
    )
  }

  @Builder
  AddCardRow(card: HealthCardModel) {
    Row() {
      Image(AppImages.healthCardIcon(card.id)).width(22).height(22).objectFit(ImageFit.Contain)
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

  // MARK: - Editing flow
  private cancelEditing(): void {
    this.editingHealthCards = [];
    this.warning = '';
    this.endDrag();
    if (this.onCancel) this.onCancel();
  }

  private commitEditing(): void {
    let typeNamesCsv: string = this.editingHealthCards.map((card: HealthCardModel) => card.id).join(',');
    if (this.onSave) this.onSave(typeNamesCsv);
  }

  // MARK: - Card management
  private inactiveCards(): HealthCardModel[] {
    let defaults: HealthCardModel[] = createDefaultHealthCards();
    return defaults.filter((candidate: HealthCardModel) => {
      return this.editingHealthCards.findIndex((active: HealthCardModel) => active.id === candidate.id) < 0;
    });
  }

  private removeCard(id: string): void {
    if (this.editingHealthCards.length <= 3) {
      this.warning = localizedHealthText(this, 'health_minimum_cards', []);
      return;
    }
    this.editingHealthCards = this.editingHealthCards.filter((card: HealthCardModel) => card.id !== id);
    this.warning = '';
  }

  private moveCard(from: number, to: number): void {
    if (to < 0 || to >= this.editingHealthCards.length || from === to) return;
    let copy: HealthCardModel[] = this.editingHealthCards.slice();
    let moving: HealthCardModel = copy[from];
    copy.splice(from, 1);
    copy.splice(to, 0, moving);
    this.editingHealthCards = copy;
  }

  // MARK: - Drag logic
  private startDrag(id: string): void {
    this.draggingCardId = id;
    this.dragStartIndex = this.editingHealthCards.findIndex((card: HealthCardModel) => card.id === id);
    this.dragTranslation = 0;
    this.dragVisualOffset = 0;
    this.dragScrollOffset = 0;
    this.dragEdgeDirection = 0;
    this.dragEdgeSpeed = 0;
    this.startAutoScroll();
  }

  private updateDrag(id: string, offsetY: number, globalY: number): void {
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
    this.reconcileDrag(id);
  }

  private reconcileDrag(id: string): void {
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

  private startAutoScroll(): void {
    if (this.cardDragScrollTimer >= 0) return;
    this.cardDragScrollTimer = setInterval(() => {
      this.performAutoScroll();
    }, 24);
  }

  private performAutoScroll(): void {
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
    this.reconcileDrag(this.draggingCardId);
  }

  private stopAutoScroll(): void {
    if (this.cardDragScrollTimer >= 0) {
      clearInterval(this.cardDragScrollTimer);
      this.cardDragScrollTimer = -1;
    }
  }

  private endDrag(): void {
    this.stopAutoScroll();
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
}
