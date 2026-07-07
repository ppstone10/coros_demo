import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import {
  LoginEffect,
  LoginEffectType,
  LoginState
} from '../login/LoginState';
import { getLoginViewModel } from '../login/LoginViewModelProvider';
import {
  COROS_BUTTON_RED,
  COROS_BLACK,
  COROS_WHITE,
  COROS_RED,
  COROS_MUTED,
  COROS_LINE
} from '../login/components/AuthColors';
import {
  AuthTitle,
  ErrorText,
  CorosButton,
  AuthHeader
} from '../login/components/AuthComponents';
import { AuthRoutes } from '../login/AuthRoutes';

@Entry
@Component
struct ProfileCompletionPage {
  private viewModel = getLoginViewModel();
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State localError: string = '';
  @State profileUsername: string = '';
  @State profileBirthDate: string = '';
  @State profileHeightCm: string = '';
  @State profileWeightKg: string = '';
  @State profileGender: string = '';
  @State profileMeasurementSystem: string = 'Metric';
  @State profileCountry: string = '中国';
  @State profilePhone: string = '';
  @State profileActionEnabled: boolean = false;
  @State unavailableDialogVisible: boolean = false;

  aboutToAppear(): void {
    this.syncState();
  }

  onBackPress(): boolean {
    this.handleProfileBack();
    return true;
  }

  build() {
    Stack() {
      Column() {
        Scroll() {
          Column() {
            AuthHeader({ showBack: true, showFeedback: false,
              onBack: () => { this.handleProfileBack(); } });

            Blank().height(22)

            Text('完善个人信息')
              .fontSize(36)
              .fontColor(COROS_WHITE)
              .lineHeight(44)
              .fontWeight(FontWeight.Lighter)

            Blank().height(12)

            Text('以下信息可以帮助我们对体育科学做出更准确的预测，请仔细填写。')
              .fontSize(18)
              .fontColor('#E8E8EC')
              .lineHeight(28)

            Blank().height(28)

            this.ProfileTextRow('用户名', true, this.profileUsername, '输入用户名', (value: string) => {
              this.profileUsername = value.substring(0, 20);
            });
            this.ProfileTextRow('出生日期', true, this.profileBirthDate, '例如：2002年11月17日', (value: string) => {
              this.profileBirthDate = value;
            });
            this.ProfileTextRow('身高（cm）', true, this.profileHeightCm, '例如：175', (value: string) => {
              this.profileHeightCm = value.replace(/[^0-9]/g, '').substring(0, 3);
            });
            this.ProfileTextRow('体重（kg）', true, this.profileWeightKg, '例如：60.0', (value: string) => {
              this.profileWeightKg = value.replace(/[^0-9.]/g, '').substring(0, 5);
            });
            this.ProfilePickerRow('公英制', false, this.measurementLabel(), '', () => { this.toggleMeasurementSystem(); });
            this.ProfileTextRow('手机', false, this.profilePhone, '输入手机号', (value: string) => {
              this.profilePhone = value.replace(/[^0-9+\-]/g, '').substring(0, 20);
            });
            this.ProfilePickerRow('国家与地区', false, this.profileCountry, '中国', () => { this.showUnavailableFeature(); });
            this.GenderRow();

            Blank().height(16)
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
        }
        .layoutWeight(1)

        Column() {
          ErrorText({ message: this.localError });
          Blank().height(8)
          CorosButton({ textValue: '完成', color: COROS_BUTTON_RED,
            enabledValue: this.profileActionEnabled, loading: this.isLoading,
            onTap: () => { this.submitProfile(); } });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 18 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(COROS_BLACK)

      if (this.unavailableDialogVisible) {
        this.UnavailableFeatureDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  @Builder
  ProfileTextRow(label: string, required: boolean, value: string, placeholder: string, onChange: (v: string) => void) {
    Row() {
      this.RequiredLabel(label, required);
      TextInput({ text: value, placeholder: placeholder })
        .fontSize(18).fontColor(COROS_WHITE).placeholderColor(COROS_MUTED)
        .caretColor(COROS_RED).backgroundColor(COROS_BLACK).textAlign(TextAlign.End)
        .layoutWeight(1).padding(0).height(66)
        .onChange((v: string) => { onChange(v); this.refreshProfileActionState(); })
    }
    .width('100%').height(66).alignItems(VerticalAlign.Center)
    Divider().color(COROS_LINE)
  }

  @Builder
  ProfilePickerRow(label: string, required: boolean, value: string, placeholder: string, onClick: () => void) {
    Row() {
      this.RequiredLabel(label, required);
      Blank().layoutWeight(1)
      Text(value.length > 0 ? value : placeholder)
        .fontSize(18).fontColor(value.length > 0 ? '#DADAE0' : COROS_MUTED).textAlign(TextAlign.End)
      Text(' >').fontSize(18).fontColor(COROS_MUTED).margin({ left: 12 })
    }
    .width('100%').height(66).alignItems(VerticalAlign.Center)
    .onClick(() => { onClick(); })
    Divider().color(COROS_LINE)
  }

  @Builder
  GenderRow() {
    Row() {
      this.RequiredLabel('性别', true);
      Blank().layoutWeight(1)
      Row() {
        Row() {
          Text('♀').fontSize(22).fontColor(this.profileGender === 'Female' ? COROS_RED : '#D8D8DD')
          Text(' 女').fontSize(20).fontColor(this.profileGender === 'Female' ? COROS_RED : '#D8D8DD')
            .fontWeight(FontWeight.Medium)
        }
        .width(82).height(48).justifyContent(FlexAlign.Center)
        .border({
          width: this.profileGender === 'Female' ? 1 : 0,
          color: this.profileGender === 'Female' ? COROS_RED : '#00000000',
          radius: 9
        })
        .backgroundColor('#19191B')
        .onClick(() => {
          this.profileGender = this.profileGender === 'Female' ? '' : 'Female';
          this.refreshProfileActionState();
        })

        Blank().width(10)

        Row() {
          Text('♂').fontSize(22).fontColor(this.profileGender === 'Male' ? COROS_RED : '#D8D8DD')
          Text(' 男').fontSize(20).fontColor(this.profileGender === 'Male' ? COROS_RED : '#D8D8DD')
            .fontWeight(FontWeight.Medium)
        }
        .width(82).height(48).justifyContent(FlexAlign.Center)
        .border({
          width: this.profileGender === 'Male' ? 1 : 0,
          color: this.profileGender === 'Male' ? COROS_RED : '#00000000',
          radius: 9
        })
        .backgroundColor('#19191B')
        .onClick(() => {
          this.profileGender = this.profileGender === 'Male' ? '' : 'Male';
          this.refreshProfileActionState();
        })
      }
    }
    .width('100%').height(78).alignItems(VerticalAlign.Center)
  }

  @Builder
  RequiredLabel(textLabel: string, required: boolean) {
    Row() {
      Text(textLabel).fontSize(20).fontColor(COROS_WHITE)
      if (required) {
        Text('*').fontSize(16).fontColor(COROS_RED)
      }
    }
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  UnavailableFeatureDialog() {
    Column() {
      Blank().layoutWeight(1)
      Column({ space: 20 }) {
        Text('抱歉，该功能还在实现中').fontSize(16).fontColor(COROS_WHITE).textAlign(TextAlign.Center)
        Text('知道了').fontSize(16).fontColor(COROS_RED)
          .onClick(() => { this.unavailableDialogVisible = false; })
      }
      .padding({ left: 28, right: 28, top: 24, bottom: 24 })
      .backgroundColor('#222224').borderRadius(12).margin({ left: 42, right: 42 })
      Blank().layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#0000009E')
    .onClick(() => { this.unavailableDialogVisible = false; })
  }

  private handleProfileBack(): void {
    this.localError = '';
    this.viewModel.clearSessionSilently();
    this.syncState();
    router.clear();
    router.replaceUrl({ url: AuthRoutes.ENTRANCE });
  }

  private submitProfile(): void {
    let heightCm: number = this.profileHeightCm.length > 0 ? parseInt(this.profileHeightCm) : 0;
    let weightKg: number = this.profileWeightKg.length > 0 ? parseFloat(this.profileWeightKg) : 0;
    this.viewModel.submitProfile(
      '', this.profileUsername, this.profileBirthDate,
      heightCm, weightKg, this.profileMeasurementSystem,
      this.profilePhone, this.profileCountry, this.profileGender
    );
    this.syncState();
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect !== null && effect.type === LoginEffectType.AuthSucceeded) {
      router.clear();
      router.replaceUrl({ url: AuthRoutes.SIGNED_IN });
      this.showMessage('资料已保存');
    } else {
      let state: LoginState = this.viewModel.state;
      if (state.errorMessage.length > 0) {
        this.localError = state.errorMessage;
      }
    }
  }

  private refreshProfileActionState(): void {
    let heightCm: number = this.profileHeightCm.length > 0 ? parseInt(this.profileHeightCm) : 0;
    let weightKg: number = this.profileWeightKg.length > 0 ? parseFloat(this.profileWeightKg) : 0;
    this.profileActionEnabled = this.viewModel.canSubmitProfile(
      this.profileUsername, this.profileBirthDate, heightCm, weightKg, this.profileGender
    );
  }

  private measurementLabel(): string {
    return this.profileMeasurementSystem === 'Imperial' ? '英制（mi/ft/inch/lb）' : '公制（km/m/cm/kg）';
  }

  private toggleMeasurementSystem(): void {
    this.profileMeasurementSystem = this.profileMeasurementSystem === 'Imperial' ? 'Metric' : 'Imperial';
  }

  private showUnavailableFeature(): void {
    this.unavailableDialogVisible = true;
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.isLoading = state.isLoading;
    this.errorMessage = state.errorMessage;
    if (state.currentSession !== null) {
      this.profileUsername = state.currentSession.displayName;
    }
  }

  private showMessage(message: string): void {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      console.error('showToast failed');
    }
  }
}