import { AppColors, AppImages, AppTypography } from '../../core/resources/AppResources';
import { healthResource } from '../../core/resources/HealthLocalization';

export interface NormalEditOption {
  value: string;
  labelKey: string;
}

export interface NormalEditField {
  id: string;
  labelKey: string;
  value: string;
  type: string;
  minimum?: number;
  maximum?: number;
  options: NormalEditOption[];
  labelArguments: string[];
  groupId?: string;
  rowIndex?: number;
}

export interface NormalEditRepeatGroup {
  id: string;
  addLabelKey: string;
  itemLabelKey: string;
  minimumItems: number;
  maximumItems: number;
}

export interface NormalEditForm {
  section: string;
  titleKey: string;
  sourceKind: string;
  sourceMessageKey: string;
  fields: NormalEditField[];
  repeatGroups: NormalEditRepeatGroup[];
}

export interface NormalEditValidationIssue {
  fieldId: string;
  labelKey: string;
  labelArguments: string[];
  reason: string;
  reasonArguments: string[];
}

export interface NormalEditSaveResult {
  success: boolean;
  issue?: NormalEditValidationIssue;
}

@Component
export struct NormalEditFieldRowComp {
  @Prop field: NormalEditField;
  @Link selectedChoiceFieldId: string;
  labelText: (field: NormalEditField) => string = (_field: NormalEditField) => '';
  selectedOptionKey: (field: NormalEditField) => string = (_field: NormalEditField) => '';
  valueChanged: (fieldId: string, value: string) => void = (_fieldId: string, _value: string) => {};

  build() {
    if (this.field.type === 'Choice') {
      Row({ space: 8 }) {
        Text(this.labelText(this.field))
          .fontSize(AppTypography.EDITOR_ROW)
          .fontColor(AppColors.MUTED)
          .textAlign(TextAlign.Start)
          .layoutWeight(1)
          .maxLines(1)
        Text(healthResource(this.selectedOptionKey(this.field)))
          .fontSize(AppTypography.EDITOR_ROW)
          .fontColor(AppColors.ACTION)
          .maxLines(1)
        Image(AppImages.choiceChevron())
          .renderMode(ImageRenderMode.Template)
          .fillColor(AppColors.ACTION)
          .width(14)
          .height(14)
          .objectFit(ImageFit.Contain)
          .rotate({ angle: 90 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(AppColors.HEALTH_CARD)
      .borderRadius(10)
      .onClick(() => { this.selectedChoiceFieldId = this.field.id; })
    } else {
      Column({ space: 6 }) {
        Text(this.labelText(this.field))
          .fontSize(AppTypography.LABEL)
          .fontColor(AppColors.MUTED)
          .width('100%')
          .textAlign(TextAlign.Start)
        TextInput({ placeholder: '', text: this.field.value })
          .fontColor(AppColors.WHITE)
          .placeholderColor(AppColors.MUTED)
          .backgroundColor(AppColors.TRANSPARENT)
          .border({ width: 1, color: AppColors.MUTED })
          .borderRadius(8)
          .height(42)
          .onChange((value: string) => { this.valueChanged(this.field.id, value); })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(AppColors.HEALTH_CARD)
      .borderRadius(10)
    }
  }
}

@Component
export struct NormalEditRepeatGroupComp {
  @Prop group: NormalEditRepeatGroup;
  @Prop groupRows: number[] = [];
  @Link selectedChoiceFieldId: string;
  localizedText: (key: string, args: string[]) => string = (_key: string, _args: string[]) => '';
  labelText: (field: NormalEditField) => string = (_field: NormalEditField) => '';
  selectedOptionKey: (field: NormalEditField) => string = (_field: NormalEditField) => '';
  fieldValueChanged: (fieldId: string, value: string) => void = (_fieldId: string, _value: string) => {};
  rowMutated: (groupId: string, operation: string, rowIndex: number) => void = (_g: string, _o: string, _r: number) => {};
  groupFields: (groupId: string, rowIndex: number) => NormalEditField[] = (_g: string, _r: number) => [];
  fieldForKey: (field: NormalEditField) => string = (_field: NormalEditField) => '';

  build() {
    Column({ space: 10 }) {
      ForEach(this.groupRows, (rowIndex: number) => {
        Column({ space: 10 }) {
          Row() {
            Text(this.localizedText(this.group.itemLabelKey, [(rowIndex + 1).toString()]))
              .fontSize(AppTypography.LABEL)
              .fontColor(AppColors.WHITE)
              .layoutWeight(1)
            if (this.groupRows.length > this.group.minimumItems) {
              Text($r('app.string.health_edit_remove_item'))
                .fontSize(AppTypography.CAPTION)
                .fontColor(AppColors.ACTION)
                .padding(8)
                .onClick(() => { this.rowMutated(this.group.id, 'Remove', rowIndex); })
            }
          }
          .width('100%')
          ForEach(this.groupFields(this.group.id, rowIndex), (field: NormalEditField) => {
            NormalEditFieldRowComp({
              field: field,
              selectedChoiceFieldId: $selectedChoiceFieldId,
              labelText: this.labelText,
              selectedOptionKey: this.selectedOptionKey,
              valueChanged: this.fieldValueChanged
            })
          }, (field: NormalEditField) => this.fieldForKey(field))
        }
        .width('100%')
        .padding(12)
        .backgroundColor(AppColors.HEALTH_CARD)
        .borderRadius(12)
      }, (rowIndex: number) => `${this.group.id}-${rowIndex}`)
      Text(`+ ${this.localizedText(this.group.addLabelKey, [])}`)
        .fontSize(AppTypography.LABEL)
        .fontColor(this.groupRows.length < this.group.maximumItems ? AppColors.ADD_ACTION : AppColors.MUTED)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding(13)
        .backgroundColor(AppColors.HEALTH_CARD)
        .borderRadius(10)
        .onClick(() => {
          if (this.groupRows.length < this.group.maximumItems) {
            this.rowMutated(this.group.id, 'Add', -1);
          }
        })
    }
    .width('100%')
  }
}

@Component
export struct NormalEditChoiceOverlayComp {
  @Prop field: NormalEditField;
  @Link selectedChoiceFieldId: string;
  labelText: (field: NormalEditField) => string = (_field: NormalEditField) => '';
  valueChanged: (fieldId: string, value: string) => void = (_fieldId: string, _value: string) => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.OVERLAY_60)
        .onClick(() => { this.selectedChoiceFieldId = ''; })
      Column() {
        Text(this.labelText(this.field))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.WHITE)
          .width('100%')
          .padding({ left: 20, right: 20, top: 18, bottom: 18 })
        Scroll() {
          Column() {
            ForEach(this.field.options, (option: NormalEditOption) => {
              Row() {
                Text(healthResource(option.labelKey))
                  .fontSize(16)
                  .fontColor(AppColors.WHITE)
                  .layoutWeight(1)
                if (option.value === this.field.value) {
                  Image(AppImages.choiceCheck())
                    .renderMode(ImageRenderMode.Template)
                    .fillColor(AppColors.ACTION)
                    .width(18)
                    .height(18)
                    .objectFit(ImageFit.Contain)
                }
              }
              .width('100%')
              .height(52)
              .padding({ left: 20, right: 20 })
              .onClick(() => {
                this.valueChanged(this.field.id, option.value);
                this.selectedChoiceFieldId = '';
              })
            }, (option: NormalEditOption) => option.value)
          }
          .width('100%')
        }
        .width('100%')
        .constraintSize({ maxHeight: 420 })
        Text($r('app.string.common_cancel'))
          .fontSize(AppTypography.EDITOR_ROW)
          .fontColor(AppColors.ACTION)
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(52)
          .padding({ top: 16 })
          .onClick(() => { this.selectedChoiceFieldId = ''; })
      }
      .width('86%')
      .constraintSize({ maxHeight: 560 })
      .backgroundColor(AppColors.HEALTH_CARD)
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
  }
}
