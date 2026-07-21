import { LoginState } from '../login/LoginState';
import { AppColors, AppTypography, AppSpacing } from '../resources/AppResources';
import { localizedAuthMessage } from '../resources/AuthLocalization';

@Component
export struct AccountOverviewComp {
  @Prop displayName: string = '';
  @Prop sessionAccount: string = '';
  @Prop profileAvatarUri: string = '';
  @Prop profileComplete: boolean = false;
  @Prop birthDate: string = '';
  @Prop heightText: string = '';
  @Prop weightText: string = '';
  @Prop countryRegion: string = '';
  @Prop localError: string = '';
  onLanguageClick?: () => void;
  onProfileClick?: () => void;
  onLogout?: () => void;
  onDelete?: () => void;

  build() {
    Scroll() {
      Column() {
        Row() {
          Text($r('app.string.account_title')).fontSize(26).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
          Blank().layoutWeight(1)
          SymbolGlyph($r('sys.symbol.worldclock'))
            .fontSize(26).fontColor([AppColors.WHITE]).width(44).height(44)
            .accessibilityText($r('app.string.language_switch'))
            .onClick(() => { if (this.onLanguageClick) this.onLanguageClick(); })
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
        .onClick(() => { if (this.onProfileClick) this.onProfileClick(); })

        this.SectionTitle($r('app.string.account_personal_info'));
        Column() {
          this.ValueRow($r('app.string.profile_username'), this.displayName);
          this.ValueRow($r('app.string.profile_birth_date'), this.birthDate);
          this.ValueRow($r('app.string.profile_height'), this.heightText);
          this.ValueRow($r('app.string.profile_weight'), this.weightText);
          this.ValueRow($r('app.string.profile_country_region'), this.countryRegion);
        }
        .width('100%').backgroundColor(AppColors.HEALTH_CARD).borderRadius(10)

        this.SectionTitle($r('app.string.account_section'));
        Column() {
          this.ValueRow($r('app.string.account_login_account'), this.sessionAccount);
          Text($r('app.string.account_logout')).fontSize(14).fontColor(AppColors.WHITE)
            .width('100%').height(52).padding({ left: 16 }).textAlign(TextAlign.Start)
            .onClick(() => { if (this.onLogout) this.onLogout(); })
          Text($r('app.string.account_delete')).fontSize(14).fontColor(AppColors.DESTRUCTIVE)
            .width('100%').height(52).padding({ left: 16 }).textAlign(TextAlign.Start)
            .onClick(() => { if (this.onDelete) this.onDelete(); })
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
}
