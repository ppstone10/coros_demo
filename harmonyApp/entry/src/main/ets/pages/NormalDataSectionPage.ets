import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { getService } from '../core/bridge/HarmonyServiceProvider';
import { NormalDataSectionParams } from '../auth/navigation/AuthRoutes';
import { navigate, NavOperation } from '../auth/navigation/AuthNavigator';
import { AppColors, AppImages, AppSpacing, AppTypography } from '../core/resources/AppResources';
import { healthResource } from '../core/resources/HealthLocalization';
import { localizedHealthText } from '../health/HealthDashboardTypes';

interface NormalEditOption {
  value: string;
  labelKey: string;
}

interface NormalEditField {
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

interface NormalEditRepeatGroup {
  id: string;
  addLabelKey: string;
  itemLabelKey: string;
  minimumItems: number;
  maximumItems: number;
}

interface NormalEditForm {
  section: string;
  titleKey: string;
  sourceKind: string;
  sourceMessageKey: string;
  fields: NormalEditField[];
  repeatGroups: NormalEditRepeatGroup[];
}

interface NormalEditValidationIssue {
  fieldId: string;
  labelKey: string;
  labelArguments: string[];
  reason: string;
  reasonArguments: string[];
}

interface NormalEditSaveResult {
  success: boolean;
  issue?: NormalEditValidationIssue;
}

@Preview
@Entry
@Component
struct NormalDataSectionPage {
  @State section: string = '';
  @State titleKey: string = '';
  @State fields: NormalEditField[] = [];
  @State repeatGroups: NormalEditRepeatGroup[] = [];
  @State sourceMessageKey: string = '';
  @State selectedChoiceFieldId: string = '';
  @State isSaving: boolean = false;

  aboutToAppear(): void {
    const params: NormalDataSectionParams = router.getParams() as NormalDataSectionParams;
    this.section = params.section || '';
    this.load(false);
  }

  onBackPress(): boolean {
    navigate(NavOperation.Pop, '');
    return true;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Row() {
          Text('‹')
            .fontSize(36)
            .fontColor(AppColors.WHITE)
            .width(80)
            .onClick(() => { navigate(NavOperation.Pop, ''); })
          Text(healthResource(this.titleKey || this.section))
            .fontSize(18)
            .fontColor(AppColors.WHITE)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
          Button($r('app.string.common_save'), { type: ButtonType.Normal })
            .fontSize(AppTypography.LABEL)
            .fontColor(this.isSaving ? AppColors.MUTED : AppColors.ACTION)
            .width(80)
            .height(44)
            .padding(0)
            .backgroundColor(AppColors.TRANSPARENT)
            .enabled(!this.isSaving)
            .onClick(() => { this.save(); })
        }
        .width('100%')
        .height(62)
        .padding({ left: 16, right: 16 })

        List({ space: 12 }) {
          if (this.sourceMessageKey.length > 0) {
            ListItem() {
              Text(healthResource(this.sourceMessageKey))
                .fontSize(AppTypography.LABEL)
                .fontColor(AppColors.HEALTH_WARNING)
                .width('100%')
                .padding(12)
                .backgroundColor(AppColors.HEALTH_CARD)
                .borderRadius(10)
            }
          }
          ListItem() {
            Text($r('app.string.health_edit_restore_card'))
              .fontSize(AppTypography.LABEL)
              .fontColor(AppColors.WHITE)
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding(13)
              .backgroundColor(AppColors.HEALTH_CARD)
              .borderRadius(10)
              .onClick(() => { this.load(true); })
          }
          ForEach(this.standaloneFields(), (field: NormalEditField) => {
            ListItem() {
              this.EditField(field)
            }
          }, (field: NormalEditField) => field.id)
          ForEach(this.repeatGroups, (group: NormalEditRepeatGroup) => {
            ListItem() {
              this.RepeatGroupEditor(group)
            }
          }, (group: NormalEditRepeatGroup) => group.id)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: AppSpacing.SCREEN, right: AppSpacing.SCREEN, top: 12, bottom: 24 })
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BLACK)
      if (this.selectedChoiceFieldId.length > 0) {
        this.ChoiceSelectionOverlay(this.selectedChoiceField())
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private EditField(field: NormalEditField) {
    if (field.type === 'Choice') {
      Row({ space: 8 }) {
        Text(this.fieldLabel(field))
          .fontSize(AppTypography.EDITOR_ROW)
          .fontColor(AppColors.MUTED)
          .textAlign(TextAlign.Start)
          .layoutWeight(1)
          .maxLines(1)
        Text(healthResource(this.selectedOptionKey(field)))
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
      .onClick(() => { this.selectedChoiceFieldId = field.id; })
    } else {
      Column({ space: 6 }) {
        Text(this.fieldLabel(field))
          .fontSize(AppTypography.LABEL)
          .fontColor(AppColors.MUTED)
          .width('100%')
          .textAlign(TextAlign.Start)
        TextInput({ placeholder: '', text: field.value })
          .fontColor(AppColors.WHITE)
          .placeholderColor(AppColors.MUTED)
          .backgroundColor(AppColors.TRANSPARENT)
          .border({ width: 1, color: AppColors.MUTED })
          .borderRadius(8)
          .height(42)
          .onChange((value: string) => { this.updateFieldById(field.id, value); })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(AppColors.HEALTH_CARD)
      .borderRadius(10)
    }
  }

  @Builder
  private RepeatGroupEditor(group: NormalEditRepeatGroup) {
    Column({ space: 10 }) {
      ForEach(this.groupRows(group.id), (rowIndex: number) => {
        Column({ space: 10 }) {
          Row() {
            Text(this.localized(group.itemLabelKey, [(rowIndex + 1).toString()]))
              .fontSize(AppTypography.LABEL)
              .fontColor(AppColors.WHITE)
              .layoutWeight(1)
            if (this.groupRows(group.id).length > group.minimumItems) {
              Text($r('app.string.health_edit_remove_item'))
                .fontSize(AppTypography.CAPTION)
                .fontColor(AppColors.ACTION)
                .padding(8)
                .onClick(() => { this.mutate(group.id, 'Remove', rowIndex); })
            }
          }
          .width('100%')
          ForEach(this.groupFields(group.id, rowIndex), (field: NormalEditField) => {
            this.EditField(field)
          }, (field: NormalEditField) => field.id)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(AppColors.HEALTH_CARD)
        .borderRadius(12)
      }, (rowIndex: number) => `${group.id}-${rowIndex}`)
      Text(`+ ${this.localized(group.addLabelKey, [])}`)
        .fontSize(AppTypography.LABEL)
        .fontColor(this.groupRows(group.id).length < group.maximumItems ? AppColors.ADD_ACTION : AppColors.MUTED)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding(13)
        .backgroundColor(AppColors.HEALTH_CARD)
        .borderRadius(10)
        .onClick(() => {
          if (this.groupRows(group.id).length < group.maximumItems) {
            this.mutate(group.id, 'Add', -1);
          }
        })
    }
    .width('100%')
  }

  @Builder
  private ChoiceSelectionOverlay(field: NormalEditField) {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.OVERLAY_60)
        .onClick(() => { this.selectedChoiceFieldId = ''; })
      Column() {
        Text(this.fieldLabel(field))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.WHITE)
          .width('100%')
          .padding({ left: 20, right: 20, top: 18, bottom: 18 })
        Scroll() {
          Column() {
            ForEach(field.options, (option: NormalEditOption) => {
              Row() {
                Text(healthResource(option.labelKey))
                  .fontSize(16)
                  .fontColor(AppColors.WHITE)
                  .layoutWeight(1)
                if (option.value === field.value) {
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
                this.updateFieldById(field.id, option.value);
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

  private load(defaults: boolean): void {
    try {
      const json: string = defaults
        ? getService().defaultNormalHealthEditFormJson(this.section)
        : getService().normalHealthEditFormJson(this.section);
      const form: NormalEditForm = JSON.parse(json) as NormalEditForm;
      this.titleKey = form.titleKey;
      this.sourceMessageKey = form.sourceMessageKey;
      this.fields = form.fields;
      this.repeatGroups = form.repeatGroups;
    } catch (error) {
      this.fields = [];
      this.repeatGroups = [];
    }
  }

  private updateFieldById(id: string, value: string): void {
    const index: number = this.fields.findIndex((field: NormalEditField) => field.id === id);
    if (index < 0) return;
    const next: NormalEditField[] = this.fields.slice();
    next[index] = {
      id: next[index].id,
      labelKey: next[index].labelKey,
      value: value,
      type: next[index].type,
      minimum: next[index].minimum,
      maximum: next[index].maximum,
      options: next[index].options,
      labelArguments: next[index].labelArguments,
      groupId: next[index].groupId,
      rowIndex: next[index].rowIndex
    };
    this.fields = next;
  }

  private localized(key: string, args: string[]): string {
    return localizedHealthText(this, key, args);
  }

  private fieldLabel(field: NormalEditField): string {
    return this.localized(field.labelKey, field.labelArguments || []);
  }

  private standaloneFields(): NormalEditField[] {
    return this.fields.filter((field: NormalEditField) => !field.groupId);
  }

  private groupRows(groupId: string): number[] {
    const rows: number[] = [];
    this.fields.forEach((field: NormalEditField) => {
      if (field.groupId === groupId && field.rowIndex !== undefined && rows.indexOf(field.rowIndex) < 0) {
        rows.push(field.rowIndex);
      }
    });
    return rows.sort((left: number, right: number) => left - right);
  }

  private groupFields(groupId: string, rowIndex: number): NormalEditField[] {
    return this.fields.filter((field: NormalEditField) => {
      return field.groupId === groupId && field.rowIndex === rowIndex;
    });
  }

  private valuesSpec(): string {
    return this.fields.map((field: NormalEditField) => {
      return `${encodeURIComponent(field.id)}=${encodeURIComponent(field.value)}`;
    }).join('&');
  }

  private mutate(groupId: string, operationName: string, rowIndex: number): void {
    try {
      const json: string = getService().mutateNormalHealthEditFormJson(
        this.section,
        this.valuesSpec(),
        groupId,
        operationName,
        rowIndex
      );
      const form: NormalEditForm = JSON.parse(json) as NormalEditForm;
      this.titleKey = form.titleKey;
      this.sourceMessageKey = form.sourceMessageKey;
      this.fields = form.fields;
      this.repeatGroups = form.repeatGroups;
    } catch (error) {
      promptAction.showToast({ message: $r('app.string.health_edit_invalid'), duration: 1500 });
    }
  }

  private selectedChoiceField(): NormalEditField {
    const field: NormalEditField | undefined = this.fields.find((item: NormalEditField) => {
      return item.id === this.selectedChoiceFieldId;
    });
    return field || {
      id: '',
      labelKey: '',
      value: '',
      type: 'Choice',
      options: [],
      labelArguments: []
    };
  }

  private selectedOption(field: NormalEditField): number {
    const index: number = field.options.findIndex((option: NormalEditOption) => {
      return option.value === field.value;
    });
    return index < 0 ? 0 : index;
  }

  private selectedOptionKey(field: NormalEditField): string {
    const option: NormalEditOption | undefined = field.options[this.selectedOption(field)];
    return option ? option.labelKey : '';
  }

  private save(): void {
    if (this.isSaving) return;
    this.isSaving = true;
    try {
      const json: string = getService().saveNormalHealthEditFormResultJson(this.section, this.valuesSpec());
      const result: NormalEditSaveResult = JSON.parse(json) as NormalEditSaveResult;
      if (!result.success) {
        promptAction.showToast({
          message: result.issue ? this.validationMessage(result.issue) : $r('app.string.health_edit_invalid'),
          duration: 1500
        });
        return;
      }
      promptAction.showToast({
        message: $r('app.string.health_edit_saved_refresh'),
        duration: 1500
      });
      navigate(NavOperation.Pop, '');
    } catch (error) {
      promptAction.showToast({ message: $r('app.string.health_edit_invalid'), duration: 1500 });
    } finally {
      this.isSaving = false;
    }
  }

  private validationMessage(issue: NormalEditValidationIssue): string {
    const label: string = this.localized(issue.labelKey, issue.labelArguments || []);
    let reasonKey: string = 'health_edit_error_inconsistent';
    if (issue.reason === 'Required') reasonKey = 'health_edit_error_required';
    else if (issue.reason === 'InvalidNumber') reasonKey = 'health_edit_error_number';
    else if (issue.reason === 'OutOfRange') reasonKey = 'health_edit_error_range';
    else if (issue.reason === 'InvalidChoice') reasonKey = 'health_edit_error_choice';
    else if (issue.reason === 'InvalidCount') reasonKey = 'health_edit_error_count';
    return this.localized(reasonKey, [label].concat(issue.reasonArguments || []));
  }
}
