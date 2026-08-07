import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';
import router from '@ohos.router';
import { uploadAvatarToServer, uploadAvatarBytesToServer, avatarBytesToBase64 } from '../home/account/AvatarImage';
import {
  LoginEffect,
  LoginEffectType,
  LoginState
} from '../auth/logic/LoginState';
import { getLoginViewModel } from '../auth/viewmodel/LoginViewModelProvider';
import { navigate, NavOperation, showToast } from '../auth/navigation/AuthNavigator';
import {
  COROS_BUTTON_RED,
  COROS_BLACK,
  COROS_WHITE
} from '../auth/components/AuthColors';
import { AuthHeader } from '../auth/components/AuthBranding';
import { ErrorText, CorosButton } from '../auth/components/AuthInputs';
import { AuthRoutes, ProfilePageParams } from '../auth/navigation/AuthRoutes';
import { handleAuthEffect } from '../auth/navigation/AuthEffectHandler';
import { AppColors } from '../core/resources/AppResources';
import {
  BirthDatePickerSheetV2,
  HeightPickerSheetV2,
  WeightPickerSheetV2,
  UnitPickerSheetV2,
  CountryPickerSheetV2,
  GenderPickerSheetV2
} from './ProfileCompletionPickers';
import {
  ProfilePickerRowComponent,
  ProfileTextRowComponent,
  ProfileGenderRowComponent,
  UnavailableFeatureDialogComponent
} from './ProfileCompletionForm';
import {
  ProfileAvatarComponent,
  AvatarActionSheetComponent
} from './ProfileCompletionAvatar';

@Preview
@Entry
@Component
struct ProfileCompletionPage {
  private viewModel = getLoginViewModel();
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State localError: string = '';
  @State profileAvatarUri: string = '';
  @State profileUsername: string = '';
  @State profileBirthDate: string = '';
  @State profileHeightCm: string = '';
  @State profileWeightKg: string = '';
  @State profileGender: string = '';
  @State profileMeasurementSystem: string = 'Metric';
  @State profileCountry: string = '';
  @State profilePhone: string = '';
  @State profileEmail: string = '';
  @State unavailableDialogVisible: boolean = false;
  @State avatarSheetVisible: boolean = false;
  @State activePicker: string = '';
  @State editMode: boolean = false;
  @State avatarChanged: boolean = false;
  @State avatarCacheVersion: number = 0;
  /** MSRV-015：信息修改页"选图后未保存"的本地预览与字节（仅内存态，保存时才写缓存/上传）。 */
  @State pendingAvatarBase64: string = '';
  @State pendingAvatarBytes: Uint8Array = new Uint8Array(0);
  @State originalAvatarUri: string = '';
  @State originalUsername: string = '';
  @State originalBirthDate: string = '';
  @State originalHeightCm: string = '';
  @State originalWeightKg: string = '';
  @State originalGender: string = '';
  @State originalCountry: string = '';

  aboutToAppear(): void {
    let params = router.getParams() as ProfilePageParams;
    this.editMode = params !== null && params !== undefined && params.editMode === true;
    this.syncState();
    this.captureOriginalProfile();
  }

  onBackPress(): boolean {
    this.handleProfileBack();
    return true;
  }

  @Builder
  ProfileEditHeader() {
    Row() {
      Text($r('app.string.common_back'))
        .fontSize(34)
        .fontColor(COROS_WHITE)
        .width(64)
        .onClick(() => { this.handleProfileBack(); })
      Text($r('app.string.profile_personal_info'))
        .fontSize(18)
        .fontColor(COROS_WHITE)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text($r('app.string.common_save'))
        .fontSize(14)
        .fontColor(COROS_WHITE)
        .width(64)
        .textAlign(TextAlign.Center)
        .padding({ top: 8, bottom: 8 })
        .backgroundColor(this.isProfileActionEnabled() ? AppColors.ACTION : AppColors.PROFILE_SAVE_DISABLED)
        .borderRadius(6)
        .enabled(this.isProfileActionEnabled())
        .onClick(() => {
          if (this.isProfileActionEnabled()) this.submitProfile();
        })
    }
    .width('100%')
    .height(62)
    .padding({ left: 18, right: 18 })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Stack() {
      Column() {
        if (this.editMode) {
          this.ProfileEditHeader();
        }

        Scroll() {
          Column() {
            if (this.editMode) {
              Blank().height(8)
            } else {
              AuthHeader({ showBack: true, showFeedback: false,
                backRequested: () => { this.handleProfileBack(); } });

              Blank().height(14)

              Text($r('app.string.profile_completion_title'))
                .fontSize(28)
                .fontColor(COROS_WHITE)
                .lineHeight(34)
                .fontWeight(FontWeight.Lighter)

              Blank().height(8)

              Text($r('app.string.profile_completion_description'))
                .fontSize(14)
                .fontColor(AppColors.PROFILE_DESCRIPTION)
                .lineHeight(20)

              Blank().height(20)
            }

            ProfileAvatarComponent({
              avatarUri: this.profileAvatarUri,
              avatarRevision: this.avatarCacheVersion,
              pendingAvatarBase64: this.pendingAvatarBase64,
              tapRequested: () => {
                this.dismissInput();
                this.avatarSheetVisible = true;
              }
            });

            Blank().height(8)

            ProfileTextRowComponent({
              label: $r('app.string.profile_username'),
              required: true,
              value: $profileUsername,
              placeholder: $r('app.string.profile_username_placeholder'),
              valueChanged: (value: string) => {
                return value.substring(0, 20);
              }
            });
            if (this.editMode) {
              ProfilePickerRowComponent({
                label: $r('app.string.profile_gender'),
                required: true,
                value: this.genderLabel(),
                placeholder: $r('app.string.profile_fill_in'),
                tapRequested: () => { this.openPicker('Gender'); }
              });
            }
            ProfilePickerRowComponent({
              label: $r('app.string.profile_birth_date'),
              required: true,
              value: this.profileBirthDate,
              placeholder: $r('app.string.profile_fill_in'),
              tapRequested: () => { this.openPicker('BirthDate'); }
            });
            ProfilePickerRowComponent({
              label: $r('app.string.profile_height'),
              required: true,
              value: this.profileHeightCm.length > 0 ? `${this.profileHeightCm} cm` : '',
              placeholder: $r('app.string.profile_fill_in'),
              tapRequested: () => { this.openPicker('Height'); }
            });
            ProfilePickerRowComponent({
              label: $r('app.string.profile_weight'),
              required: true,
              value: this.profileWeightKg.length > 0 ? `${this.formatWeightText(this.profileWeightKg)} kg` : '',
              placeholder: $r('app.string.profile_fill_in'),
              tapRequested: () => { this.openPicker('Weight'); }
            });
            if (!this.editMode) {
              ProfilePickerRowComponent({
                label: $r('app.string.profile_measurement'),
                required: false,
                value: this.measurementLabel(),
                placeholder: '',
                tapRequested: () => { this.openPicker('Unit'); }
              });
              ProfileTextRowComponent({
                label: $r('app.string.profile_phone'),
                required: false,
                value: $profilePhone,
                placeholder: $r('app.string.profile_phone_placeholder'),
                valueChanged: (value: string) => {
                  return value.replace(/[^0-9+\-]/g, '').substring(0, 20);
                }
              });
              ProfileTextRowComponent({
                label: $r('app.string.profile_email'),
                required: false,
                value: $profileEmail,
                placeholder: $r('app.string.profile_email_placeholder'),
                valueChanged: (value: string) => {
                  return value.trim().substring(0, 100);
                }
              });
            }
            ProfilePickerRowComponent({
              label: $r('app.string.profile_country_region'),
              required: false,
              value: this.countryLabel(this.profileCountry),
              placeholder: $r('app.string.common_china'),
              tapRequested: () => { this.openPicker('Country'); }
            });
            if (!this.editMode) {
              ProfileGenderRowComponent({
                gender: $profileGender,
                valueChanged: (_: string) => {}
              });
            }

            Blank().height(16)
          }
          .width('100%')
          .constraintSize({
            minHeight: '100%'
          })
          .justifyContent(FlexAlign.Start)
          .padding({
            left: this.editMode ? 26 : 18,
            right: this.editMode ? 26 : 18
          })
        }
        .layoutWeight(1)
        .onScrollStart(() => { this.dismissInput(); })

        if (!this.editMode) {
          Column() {
            ErrorText({ message: this.localError });
            Blank().height(5)
            CorosButton({ textValue: $r('app.string.common_complete'), color: COROS_BUTTON_RED,
              enabledValue: this.isProfileActionEnabled(), loading: this.isLoading,
              tapRequested: () => { this.submitProfile(); } });
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 8, bottom: 10 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(COROS_BLACK)

      if (this.activePicker === 'BirthDate') {
        BirthDatePickerSheetV2({ profileBirthDate: $profileBirthDate, activePicker: $activePicker });
      }
      if (this.activePicker === 'Height') {
        HeightPickerSheetV2({ profileHeightCm: $profileHeightCm, activePicker: $activePicker });
      }
      if (this.activePicker === 'Weight') {
        WeightPickerSheetV2({ profileWeightKg: $profileWeightKg, activePicker: $activePicker });
      }
      if (this.activePicker === 'Unit') {
        UnitPickerSheetV2({ profileMeasurementSystem: $profileMeasurementSystem, activePicker: $activePicker });
      }
      if (this.activePicker === 'Country') {
        CountryPickerSheetV2({ profileCountry: $profileCountry, activePicker: $activePicker });
      }
      if (this.activePicker === 'Gender') {
        GenderPickerSheetV2({ profileGender: $profileGender, activePicker: $activePicker });
      }
      if (this.avatarSheetVisible) {
        AvatarActionSheetComponent({
          visible: $avatarSheetVisible,
          photoRequested: () => { this.takeAvatarPhoto(); },
          albumRequested: () => { this.pickAvatarFromAlbum(); }
        });
      }
      if (this.unavailableDialogVisible) {
        UnavailableFeatureDialogComponent({ visible: $unavailableDialogVisible });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  private handleProfileBack(): void {
    this.localError = '';
    if (this.editMode) {
      navigate(NavOperation.Pop, '');
      return;
    }
    this.viewModel.clearSessionSilently();
    this.syncState();
    navigate(NavOperation.ResetTo, AuthRoutes.auth.ENTRANCE);
  }


  private isProfileActionEnabled(): boolean {
    let heightCm: number = this.profileHeightCm.length > 0 ? parseInt(this.profileHeightCm) : 0;
    let weightKg: number = this.profileWeightKg.length > 0 ? parseFloat(this.profileWeightKg) : 0;
    let valid: boolean = this.viewModel.canSubmitProfile(
      this.profileUsername, this.profileBirthDate, heightCm, weightKg, this.profileGender
    );
    return valid && (!this.editMode || this.hasProfileChanges());
  }

  private submitProfile(): void {
    let heightCm: number = this.profileHeightCm.length > 0 ? parseInt(this.profileHeightCm) : 0;
    let weightKg: number = this.profileWeightKg.length > 0 ? parseFloat(this.profileWeightKg) : 0;
    // MSRV-015：信息修改页若换了头像，保存时才上传内存中的待提交头像，再保存资料
    if (this.editMode && this.avatarChanged) {
      const userId: string = this.viewModel.currentUserId();
      const bytes: Uint8Array = this.pendingAvatarBytes;
      if (bytes.length > 0) {
        uploadAvatarBytesToServer(bytes, userId).then((path: string) => {
          if (path.length > 0) {
            this.profileAvatarUri = path;
            this.avatarChanged = false;
            this.avatarCacheVersion++;
            this.pendingAvatarBase64 = '';
            this.pendingAvatarBytes = new Uint8Array(0);
            this.doSaveProfile(heightCm, weightKg);
          } else {
            this.localError = 'profile_avatar_selection_failed';
          }
        });
        return;
      }
    }
    this.doSaveProfile(heightCm, weightKg);
  }

  private doSaveProfile(heightCm: number, weightKg: number): void {
    this.viewModel.submitProfile(
      this.profileAvatarUri, this.profileUsername, this.profileBirthDate,
      heightCm, weightKg, this.profileMeasurementSystem,
      this.profilePhone, this.profileEmail, this.profileCountry, this.profileGender
    );
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect !== null) {
      if (this.editMode && effect.type === LoginEffectType.ProfileSaved) {
        showToast('profile_saved');
        navigate(NavOperation.Pop, '');
      } else {
        handleAuthEffect(effect);
      }
    } else {
      let state: LoginState = this.viewModel.state;
      if (state.errorMessage.length > 0) {
        this.localError = state.errorMessage;
      }
    }
  }

  private formatWeightText(value: string): string {
    let weight: number = value.length > 0 ? parseFloat(value) : 0;
    if (isNaN(weight)) {
      return '';
    }
    return weight.toFixed(1);
  }

  private readFileBytesOfPhoto(uri: string): Uint8Array {
    try {
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);
      return new Uint8Array(buffer);
    } catch (e) {
      return new Uint8Array(0);
    }
  }

  private pickAvatarFromAlbum(): void {
    try {
      let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select(photoSelectOptions).then((result: photoAccessHelper.PhotoSelectResult) => {
        if (result.photoUris.length > 0) {
          const uri: string = result.photoUris[0];
          const userId: string = this.viewModel.currentUserId();
          if (this.editMode) {
            // MSRV-015：信息修改页选图仅保存到内存作为本页预览，不写共享缓存文件；
            // 未保存返回时内存态随页面销毁，"我"页仍显示旧头像（对齐 Android/iOS）。
            const bytes: Uint8Array = this.readFileBytesOfPhoto(uri);
            if (bytes.length === 0) {
              this.showMessage('profile_avatar_selection_failed');
              return;
            }
            this.pendingAvatarBase64 = avatarBytesToBase64(bytes);
            this.pendingAvatarBytes = bytes;
            this.avatarChanged = true;
          } else {
            // MSRV-015：信息完善页选图即上传并覆盖本地缓存
            uploadAvatarToServer(uri, userId).then((path: string) => {
              if (path.length > 0) {
                this.profileAvatarUri = path;
                this.avatarCacheVersion++;
              } else {
                this.showMessage('profile_avatar_selection_failed');
              }
            });
          }
        }
      }).catch((error: Error) => {
        console.error(`pickAvatarFromAlbum failed: ${JSON.stringify(error)}`);
        this.showMessage('profile_avatar_selection_failed');
      });
    } catch (error) {
      console.error(`pickAvatarFromAlbum failed: ${JSON.stringify(error)}`);
      this.showMessage('profile_avatar_selection_failed');
    }
  }

  private takeAvatarPhoto(): void {
    this.showMessage('profile_camera_pending');
  }

  private measurementLabel(): string {
    return this.profileMeasurementSystem === 'Imperial'
      ? this.localized($r('app.string.profile_unit_imperial'))
      : this.localized($r('app.string.profile_unit_metric'));
  }

  private genderLabel(): string {
    if (this.profileGender === 'Female') return this.localized($r('app.string.common_female'));
    if (this.profileGender === 'Male') return this.localized($r('app.string.common_male'));
    return '';
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.isLoading = state.isLoading;
    this.errorMessage = state.errorMessage;
    if (state.currentSession !== null) {
      this.profileUsername = state.currentSession.isProfileComplete && state.currentSession.displayName.length > 0 ?
        state.currentSession.displayName : this.viewModel.profileDefaultUsername(state.currentSession.account);
      this.profileAvatarUri = state.currentSession.avatarUri;
      this.profileBirthDate = state.currentSession.birthDate;
      this.profileHeightCm = state.currentSession.heightCm > 0 ? `${state.currentSession.heightCm}` : '';
      this.profileWeightKg = state.currentSession.weightKg > 0 ? state.currentSession.weightKg.toFixed(1) : '';
      this.profileMeasurementSystem = state.currentSession.measurementSystem;
      this.profilePhone = state.currentSession.phone.length > 0 ? state.currentSession.phone :
        this.viewModel.profileDefaultPhone(state.currentSession.account);
      this.profileEmail = state.currentSession.email.length > 0 ? state.currentSession.email :
        this.viewModel.profileDefaultEmail(state.currentSession.account);
      this.profileCountry = state.currentSession.countryRegion.length > 0 ? state.currentSession.countryRegion :
        (state.currentSession.region === 'US' ? 'US' : 'CN');
      this.profileGender = state.currentSession.gender;
    }
  }

  private dismissInput(): void {
    this.getUIContext().getFocusController().clearFocus();
  }

  private openPicker(name: string): void {
    this.dismissInput();
    this.activePicker = name;
  }

  private captureOriginalProfile(): void {
    this.originalAvatarUri = this.profileAvatarUri;
    this.originalUsername = this.profileUsername;
    this.originalBirthDate = this.profileBirthDate;
    this.originalHeightCm = this.profileHeightCm;
    this.originalWeightKg = this.profileWeightKg;
    this.originalGender = this.profileGender;
    this.originalCountry = this.profileCountry;
  }

  private hasProfileChanges(): boolean {
    return this.avatarChanged ||
      this.profileAvatarUri !== this.originalAvatarUri ||
      this.profileUsername !== this.originalUsername ||
      this.profileBirthDate !== this.originalBirthDate ||
      this.profileHeightCm !== this.originalHeightCm ||
      this.profileWeightKg !== this.originalWeightKg ||
      this.profileGender !== this.originalGender ||
      this.profileCountry !== this.originalCountry;
  }

  private showMessage(message: string): void {
    showToast(message);
  }

  private localized(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource.id);
  }

  private countryLabel(code: string): string {
    switch (code.trim().toUpperCase()) {
      case 'US': return this.localized($r('app.string.common_united_states'));
      case 'GB':
      case 'UK': return this.localized($r('app.string.common_united_kingdom'));
      case 'JP': return this.localized($r('app.string.common_japan'));
      default: return this.localized($r('app.string.common_china'));
    }
  }
}
