import { AppColors, AppImages } from '../resources/AppResources';

@Component
export struct BottomNavBarComp {
  @Prop selectedTab: number = 0;
  onTabClick?: (index: number) => void;

  build() {
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
      if (this.onTabClick) this.onTabClick(index);
    })
  }
}
