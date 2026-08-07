import { COROS_WHITE, COROS_LINE } from '../auth/components/AuthColors';
import { AppColors } from '../core/resources/AppResources';
import { AvatarImage } from '../home/account/AvatarImage';

@Component
export struct ProfileAvatarComponent {
  @Prop avatarUri: string = '';
  @Prop avatarRevision: number = 0;
  @Prop pendingAvatarBase64: string = '';
  tapRequested: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      AvatarImage({
        avatarUri: this.avatarUri,
        avatarSize: 76,
        avatarRevision: this.avatarRevision,
        pendingAvatarBase64: this.pendingAvatarBase64
      })
    }
    .width(76)
    .height(76)
    .borderRadius(38)
    .clip(true)
    .alignSelf(ItemAlign.Center)
    .onClick(() => { this.tapRequested(); })
  }
}

@Component
export struct AvatarActionSheetComponent {
  @Link visible: boolean;
  photoRequested: () => void = () => {};
  albumRequested: () => void = () => {};

  private dismiss(): void {
    this.visible = false;
  }

  @Builder
  SheetAction(textValue: ResourceStr, tapRequested: () => void) {
    Row() {
      Text(textValue)
        .fontSize(20)
        .fontColor(COROS_WHITE)
    }
    .width('100%')
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => { tapRequested(); })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.OVERLAY_42)
        .onClick(() => { this.dismiss(); })

      Column() {
        this.SheetAction($r('app.string.profile_take_photo'), () => {
          this.dismiss();
          this.photoRequested();
        });
        Divider().color(COROS_LINE)
        this.SheetAction($r('app.string.profile_album'), () => {
          this.dismiss();
          this.albumRequested();
        });
        Blank().width('100%').height(8).backgroundColor(AppColors.PROFILE_ACTION_DIVIDER)
        this.SheetAction($r('app.string.common_cancel'), () => {
          this.dismiss();
        });
      }
      .width('100%')
      .backgroundColor(AppColors.PROFILE_ACTION_SHEET)
      .borderRadius({ topLeft: 10, topRight: 10 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}
