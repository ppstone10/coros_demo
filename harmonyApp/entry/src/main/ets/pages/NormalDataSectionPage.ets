import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { getService } from '../core/bridge/HarmonyServiceProvider';
import { NormalDataSectionParams } from '../auth/navigation/AuthRoutes';
import { navigate, NavOperation } from '../auth/navigation/AuthNavigator';
import { AppColors, AppSpacing, AppTypography } from '../core/resources/AppResources';
import { healthResource } from '../core/resources/HealthLocalization';
import { localizedHealthText } from '../health/HealthDashboardTypes';
import {
  NormalEditField,
  NormalEditOption,
  NormalEditRepeatGroup,
  NormalEditForm,
  NormalEditValidationIssue,
  NormalEditSaveResult,
  NormalEditFieldRowComp,
  NormalEditRepeatGroupComp,
  NormalEditChoiceOverlayComp
} from '../health/editor/NormalDataSectionComponents';

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
              NormalEditFieldRowComp({
                field: field,
                selectedChoiceFieldId: $selectedChoiceFieldId,
                labelText: (item: NormalEditField) => this.fieldLabel(item),
                selectedOptionKey: (item: NormalEditField) => this.selectedOptionKey(item),
                valueChanged: (fieldId: string, value: string) => this.updateFieldById(fieldId, value)
              })
            }
          }, (field: NormalEditField) => this.fieldForEachKey(field))
          ForEach(this.repeatGroups, (group: NormalEditRepeatGroup) => {
            ListItem() {
              NormalEditRepeatGroupComp({
                group: group,
                groupRows: this.groupRows(group.id),
                selectedChoiceFieldId: $selectedChoiceFieldId,
                localizedText: (key: string, args: string[]) => this.localized(key, args),
                labelText: (item: NormalEditField) => this.fieldLabel(item),
                selectedOptionKey: (item: NormalEditField) => this.selectedOptionKey(item),
                fieldValueChanged: (fieldId: string, value: string) => this.updateFieldById(fieldId, value),
                rowMutated: (groupId: string, operation: string, rowIndex: number) => this.mutate(groupId, operation, rowIndex),
                groupFields: (groupId: string, rowIndex: number) => this.groupFields(groupId, rowIndex),
                fieldForKey: (item: NormalEditField) => this.fieldForEachKey(item)
              })
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
        NormalEditChoiceOverlayComp({
          field: this.selectedChoiceField(),
          selectedChoiceFieldId: $selectedChoiceFieldId,
          labelText: (item: NormalEditField) => this.fieldLabel(item),
          valueChanged: (fieldId: string, value: string) => this.updateFieldById(fieldId, value)
        })
      }
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

  private fieldForEachKey(field: NormalEditField): string {
    // Choice 行 key 含选中值：选择变化时强制重建以刷新显示（Choice 非输入框，无焦点问题）。
    // 其余（TextInput）保持稳定 id，避免输入时重建导致焦点丢失。
    if (field.type === 'Choice') {
      return `${field.id}:${field.value}`;
    }
    return field.id;
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
