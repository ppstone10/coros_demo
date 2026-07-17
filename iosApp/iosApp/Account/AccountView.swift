import PhotosUI
import SwiftUI
import Shared

struct AccountView: View {
    @ObservedObject var viewModel: LoginViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    let router: AuthRouter
    @Binding var isFullscreen: Bool
    @State private var editingProfile = false
    @State private var showDeleteDialog = false
    @State private var localError: String?

    var body: some View {
        let _ = languageStore.current

        if editingProfile {
            PersonalProfileEditView(viewModel: viewModel) {
                editingProfile = false
                isFullscreen = false
            }
        } else {
            accountContent
        }
    }

    private var accountContent: some View {
        let draft = viewModel.currentProfileDraft()
        let session = viewModel.state.currentSession
        let username = draft.username.isEmpty ? appLocalized("account_default_user") : draft.username

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(appLocalized("account_title"))
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    LanguageSelectionButton()
                }
                .padding(.top, 8).padding(.bottom, 8)

                Button {
                    editingProfile = true
                    isFullscreen = true
                } label: {
                    HStack(spacing: 14) {
                        AccountAvatar(path: draft.avatarUri, username: username)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(username).font(.system(size: 19)).foregroundStyle(.white)
                            Text(session?.account ?? "").font(.system(size: 12)).foregroundStyle(AppColors.Account.muted).lineLimit(1)
                        }
                        Spacer()
                        Text(appLocalized(session?.isProfileComplete == true ? "account_profile_complete" : "account_profile_incomplete"))
                            .font(.system(size: 11))
                            .foregroundStyle(session?.isProfileComplete == true ? AppColors.Account.complete : AppColors.Account.incomplete)
                    }
                    .padding(18)
                    .background(AppColors.Account.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                AccountSectionTitle(appLocalized("account_personal_info"))
                VStack(spacing: 0) {
                    AccountValueRow(appLocalized("profile_username"), username)
                    AccountValueRow(appLocalized("profile_birth_date"), draft.birthDate)
                    AccountValueRow(appLocalized("profile_height"), draft.heightCm.map { "\($0) cm" } ?? "")
                    AccountValueRow(appLocalized("profile_weight"), draft.weightKg.map { String(format: "%.1f kg", $0) } ?? "")
                    AccountValueRow(appLocalized("profile_country_region"), countryDisplayName(draft.countryRegion))
                }
                .background(AppColors.Account.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                AccountSectionTitle(appLocalized("account_section"))
                VStack(spacing: 0) {
                    AccountValueRow(appLocalized("account_login_account"), session?.account ?? "")
                    AccountActionRow(appLocalized("account_logout"), color: .white) { viewModel.logout() }
                    AccountActionRow(appLocalized("account_delete"), color: AppColors.Account.destructive) { showDeleteDialog = true }
                }
                .background(AppColors.Account.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if let localError {
                    Text(localError).font(.system(size: 13)).foregroundStyle(AppColors.Health.warning).padding(.top, 18)
                }
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 18)
        }
        .scrollIndicators(.hidden)
        .background(AppColors.Core.black)
        .confirmationDialog(appLocalized("account_delete_confirmation"), isPresented: $showDeleteDialog, titleVisibility: .visible) {
            Button(appLocalized("common_confirm"), role: .destructive) {
                localError = viewModel.deleteCurrentAccountMessage()
            }
            Button(appLocalized("common_cancel"), role: .cancel) {}
        }
    }
}

private struct AccountAvatar: View {
    let path: String?
    let username: String

    var body: some View {
        Group {
            if let image = ProfileImageStore.image(at: path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Text(String(username.prefix(1)).uppercased())
                    .font(.system(size: 23, weight: .medium)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.Account.avatarFallback)
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(Circle())
    }
}

private struct AccountSectionTitle: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title).font(.system(size: 13)).foregroundStyle(AppColors.Account.muted)
            .padding(.top, 24).padding(.bottom, 10).padding(.leading, 4)
    }
}

private struct AccountValueRow: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }

    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundStyle(.white)
            Spacer()
            Text(value.isEmpty ? appLocalized("common_not_set") : value).font(.system(size: 13)).foregroundStyle(AppColors.Account.muted)
        }
        .padding(.horizontal, 16).frame(height: 52)
        .overlay(alignment: .bottomLeading) {
            Rectangle().fill(AppColors.Account.divider).frame(height: 1).padding(.leading, 16)
        }
    }
}

private struct AccountActionRow: View {
    let text: String
    let color: Color
    let action: () -> Void
    init(_ text: String, color: Color, action: @escaping () -> Void) { self.text = text; self.color = color; self.action = action }

    var body: some View {
        Button(action: action) {
            Text(text).font(.system(size: 14)).foregroundStyle(color).frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16).frame(height: 52)
        }
        .buttonStyle(.plain)
    }
}

private enum EditProfilePicker: String, Identifiable {
    case birthDate, gender, height, weight, country
    var id: String { rawValue }
}

private struct PersonalProfileEditView: View {
    @ObservedObject var viewModel: LoginViewModel
    let onClose: () -> Void
    @State private var original: ProfileDraft
    @State private var draft: ProfileDraft
    @State private var activePicker: EditProfilePicker?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarData: Data?

    init(viewModel: LoginViewModel, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
        let value = viewModel.currentProfileDraft()
        _original = State(initialValue: value)
        _draft = State(initialValue: value)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) { Text(appLocalized("common_back")).font(.system(size: 38, weight: .light)) }
                    .frame(width: 64, alignment: .leading)
                Spacer()
                Text(appLocalized("profile_personal_info")).font(.system(size: 18, weight: .medium))
                Spacer()
                Button(appLocalized("common_save"), action: save)
                    .font(.system(size: 14)).frame(width: 64).padding(.vertical, 8)
                    .background(canSave ? AppColors.Health.action : AppColors.Account.saveDisabled)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .disabled(!canSave)
            }
            .foregroundStyle(.white).padding(.horizontal, 18).frame(height: 62)

            ScrollView {
                VStack(spacing: 0) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Group {
                            if let avatarData, let image = UIImage(data: avatarData) {
                                Image(uiImage: image).resizable().scaledToFill()
                            } else if let image = ProfileImageStore.image(at: draft.avatarUri) {
                                Image(uiImage: image).resizable().scaledToFill()
                            } else {
                                Image(AppImages.Profile.camera).resizable().scaledToFit()
                            }
                        }
                        .frame(width: 76, height: 76).clipShape(Circle())
                    }
                    .buttonStyle(.plain).padding(.top, 20).padding(.bottom, 28)

                    HStack {
                        Text(appLocalized("profile_username")).foregroundStyle(.white)
                        TextField("", text: $draft.username).multilineTextAlignment(.trailing)
                            .foregroundStyle(AppColors.Account.value).tint(corosRed)
                        Image(AppImages.Profile.edit).resizable().scaledToFit().frame(width: 16, height: 16)
                    }
                    .frame(height: 56).overlay(alignment: .bottom) { divider }

                    editRow(appLocalized("profile_gender"), value: draft.gender?.title ?? "") { activePicker = .gender }
                    editRow(appLocalized("profile_birth_date"), value: draft.birthDate) { activePicker = .birthDate }
                    editRow(appLocalized("profile_height"), value: draft.heightCm.map { "\($0) cm" } ?? "") { activePicker = .height }
                    editRow(appLocalized("profile_weight"), value: draft.weightKg.map { String(format: "%.1f kg", $0) } ?? "") { activePicker = .weight }
                    editRow(appLocalized("profile_country_region"), value: countryDisplayName(draft.countryRegion)) { activePicker = .country }
                }
                .padding(.horizontal, 26)
            }
            .scrollIndicators(.hidden)
        }
        .background(AppColors.Core.black)
        .sheet(item: $activePicker) { EditProfilePickerSheet(picker: $0, draft: $draft) }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self) else { return }
                await MainActor.run {
                    avatarData = data
                    draft.avatarUri = ProfileImageStore.save(data)
                }
            }
        }
    }

    private var divider: some View { Rectangle().fill(corosLine).frame(height: 1) }
    private var canSave: Bool {
        viewModel.canSubmitProfile(draft) && (draft != original || avatarData != nil)
    }

    private func editRow(_ label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label).font(.system(size: 16)).foregroundStyle(.white)
                Spacer()
                Text(value.isEmpty ? appLocalized("common_not_set") : value).font(.system(size: 15))
                    .foregroundStyle(value.isEmpty ? corosMuted : AppColors.Account.value)
                Image(AppImages.Profile.next).resizable().scaledToFit().frame(width: 19, height: 19)
            }
            .frame(height: 56).overlay(alignment: .bottom) { divider }
        }
        .buttonStyle(.plain)
    }

    private func save() {
        guard canSave else { return }
        if viewModel.submitInlineProfile(draft) == nil {
            onClose()
        }
    }
}

private struct EditProfilePickerSheet: View {
    let picker: EditProfilePicker
    @Binding var draft: ProfileDraft
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var height = 175
    @State private var weightTenths = 600
    @State private var gender: ProfileGender = .male
    @State private var country = "CN"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(appLocalized("common_cancel")) { dismiss() }
                Spacer()
                Text(title).font(.system(size: 19, weight: .semibold))
                Spacer()
                Button(appLocalized("common_confirm"), action: confirm)
            }
            .foregroundStyle(.white).padding(.horizontal, 20).frame(height: 58)
            Group {
                switch picker {
                case .birthDate:
                    DatePicker("", selection: $date, displayedComponents: .date).datePickerStyle(.wheel).labelsHidden()
                case .gender:
                    Picker("", selection: $gender) { ForEach(ProfileGender.allCases, id: \.self) { Text($0.title).tag($0) } }.pickerStyle(.wheel)
                case .height:
                    Picker("", selection: $height) { ForEach(100...230, id: \.self) { Text("\($0)") } }.pickerStyle(.wheel)
                case .weight:
                    Picker("", selection: $weightTenths) { ForEach(300...2000, id: \.self) { Text(String(format: "%.1f", Double($0) / 10)) } }.pickerStyle(.wheel)
                case .country:
                    Picker("", selection: $country) {
                        ForEach(["CN", "US", "GB", "JP"], id: \.self) { code in
                            Text(countryDisplayName(code)).tag(code)
                        }
                    }.pickerStyle(.wheel)
                }
            }
            .colorScheme(.dark)
        }
        .presentationDetents([.height(360)]).presentationDragIndicator(.hidden)
        .background(AppColors.Account.sheet.ignoresSafeArea())
        .onAppear {
            height = draft.heightCm ?? 175
            weightTenths = Int(((draft.weightKg ?? 60) * 10).rounded())
            gender = draft.gender ?? .male
            country = draft.countryRegion
        }
    }

    private var title: String {
        switch picker {
        case .birthDate: return appLocalized("profile_birth_date")
        case .gender: return appLocalized("profile_gender")
        case .height: return appLocalized("profile_height_picker")
        case .weight: return appLocalized("profile_weight_picker")
        case .country: return appLocalized("profile_country_region")
        }
    }

    private func confirm() {
        switch picker {
        case .birthDate:
            let value = Calendar.current.dateComponents([.year, .month, .day], from: date)
            draft.birthDate = "\(value.year ?? 2002)\(appLocalized("profile_date_year_suffix"))\(value.month ?? 1)\(appLocalized("profile_date_month_suffix"))\(value.day ?? 1)\(appLocalized("profile_date_day_suffix"))"
        case .gender: draft.gender = gender
        case .height: draft.heightCm = height
        case .weight: draft.weightKg = Double(weightTenths) / 10
        case .country: draft.countryRegion = country
        }
        dismiss()
    }
}

extension LoginViewModel {
    func currentProfileDraft() -> ProfileDraft {
        guard let session = state.currentSession, let profile = session.profile else {
            return ProfileDraft(
                avatarUri: nil,
                username: state.currentSession?.resolvedDisplayName ?? state.currentSession?.account ?? "",
                birthDate: "", heightCm: nil, weightKg: nil, measurementSystem: .metric,
                phone: "", countryRegion: state.currentSession?.region ?? "CN", gender: nil
            )
        }
        let genderName = String(describing: profile.gender).lowercased()
        let gender: ProfileGender? = genderName.contains("female") ? .female : (genderName.contains("male") ? .male : nil)
        let measurementName = String(describing: profile.measurementSystem).lowercased()
        return ProfileDraft(
            avatarUri: profile.avatarUri,
            username: profile.username,
            birthDate: profile.birthDate,
            heightCm: profile.heightCm.map { Int($0.intValue) },
            weightKg: profile.weightKg.map { $0.doubleValue },
            measurementSystem: measurementName.contains("imperial") ? .imperial : .metric,
            phone: profile.phone,
            countryRegion: profile.countryRegion,
            gender: gender
        )
    }
}
