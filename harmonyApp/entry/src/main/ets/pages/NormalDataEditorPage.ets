import promptAction from '@ohos.promptAction';
import { getService } from '../core/bridge/HarmonyServiceProvider';
import { AuthRoutes } from '../auth/navigation/AuthRoutes';
import { navigate, navigateWithParams, NavOperation } from '../auth/navigation/AuthNavigator';
import { AppColors, AppSpacing, AppTypography } from '../core/resources/AppResources';
import { healthResource } from '../core/resources/HealthLocalization';

interface NormalEditFormTitle {
  titleKey: string;
  sourceMessageKey: string;
}

@Preview
@Entry
@Component
struct NormalDataEditorPage {
  @State sections: string[] = [];
  @State titleKeys: string[] = [];
  @State sourceMessageKey: string = '';

  aboutToAppear(): void {
    try {
      this.sections = JSON.parse(getService().healthEditableSectionsJson()) as string[];
      this.titleKeys = this.sections.map((section: string) => {
        const json: string = getService().normalHealthEditFormJson(section);
        const form: NormalEditFormTitle = JSON.parse(json) as NormalEditFormTitle;
        if (this.sourceMessageKey.length === 0 && form.sourceMessageKey.length > 0) {
          this.sourceMessageKey = form.sourceMessageKey;
        }
        return form.titleKey;
      });
    } catch (error) {
      this.sections = [];
      this.titleKeys = [];
    }
  }

  onBackPress(): boolean {
    navigate(NavOperation.Pop, '');
    return true;
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        // 左右两侧操作按钮
        Row() {
          Text('‹')
            .fontSize(36)
            .fontColor(AppColors.WHITE)
            .width(52)
            .height('100%')
            .textAlign(TextAlign.Center)
            .onClick(() => {
              navigate(NavOperation.Pop, '')
            })

          Blank()

          Text($r('app.string.health_edit_use_defaults'))
            .fontSize(AppTypography.LABEL)
            .fontColor(AppColors.ACTION)
            .padding(8)
            .onClick(() => {
              this.useDefaults()
            })
        }
        .width('100%')
        .height('100%')
        .alignItems(VerticalAlign.Center)

        // 始终相对于整个导航栏居中
        Text($r('app.string.health_edit_normal_data'))
          .fontSize(18)
          .fontColor(AppColors.WHITE)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
          .constraintSize({
            maxWidth: '50%'
          })
      }
      .width('100%')
      .height(62)
      .padding({
        left: 16,
        right: 16
      })

      Text($r('app.string.health_edit_select_hint'))
        .fontSize(AppTypography.LABEL)
        .fontColor(AppColors.MUTED)
        .width('100%')
      .padding({ left: AppSpacing.SCREEN, right: AppSpacing.SCREEN, top: 12, bottom: 12 })

      if (this.sourceMessageKey.length > 0) {
        Text(healthResource(this.sourceMessageKey))
          .fontSize(AppTypography.LABEL)
          .fontColor(AppColors.HEALTH_WARNING)
          .width('100%')
          .padding(12)
          .backgroundColor(AppColors.HEALTH_CARD)
          .borderRadius(10)
          .margin({ left: AppSpacing.SCREEN, right: AppSpacing.SCREEN, bottom: 10 })
      }

      List({ space: 10 }) {
        ForEach(this.sections, (section: string, index: number) => {
          ListItem() {
            Row() {
              Text(healthResource(this.titleKeys[index] || section))
                .fontSize(16)
                .fontColor(AppColors.WHITE)
                .layoutWeight(1)
              Text('›').fontSize(24).fontColor(AppColors.MUTED)
            }
            .width('100%')
            .padding(18)
            .backgroundColor(AppColors.HEALTH_CARD)
            .borderRadius(12)
            .onClick(() => {
              navigateWithParams(NavOperation.Push, AuthRoutes.toNormalDataSection(section));
            })
          }
        }, (section: string) => section)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: AppSpacing.SCREEN, right: AppSpacing.SCREEN, bottom: 24 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BLACK)
  }

  private useDefaults(): void {
    try {
      if (getService().restoreAllNormalHealthDefaults() === 'true') {
        promptAction.showToast({
          message: $r('app.string.health_edit_defaults_refresh'),
          duration: 1500
        });
      }
    } catch (error) {
      promptAction.showToast({ message: $r('app.string.health_edit_invalid'), duration: 1500 });
    }
  }
}
