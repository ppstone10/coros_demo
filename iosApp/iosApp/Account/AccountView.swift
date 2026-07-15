import PhotosUI
import SwiftUI
import Shared

struct AccountView: View {
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter
    @Binding var isFullscreen: Bool
    @State private var editingProfile = false
    @State private var showDeleteDialog = false
    @State private var localError: String?

    var body: some View {
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
        let username = draft.username.isEmpty ? AppText.Account.defaultUser : draft.username

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(AppText.Account.my)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 18).padding(.bottom, 18)

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
                        Text(session?.isProfileComplete == true ? AppText.Account.complete : AppText.Account.incomplete)
                            .font(.system(size: 11))
                            .foregroundStyle(session?.isProfileComplete == true ? AppColors.Account.complete : AppColors.Account.incomplete)
                    }
                    .padding(18)
                    .background(AppColors.Account.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                AccountSectionTitle(AppText.Account.personalInfo)
                VStack(spacing: 0) {
                    AccountValueRow(AppText.Profile.username, username)
                    AccountValueRow(AppText.Profile.birthDate, draft.birthDate)
                    AccountValueRow(AppText.Profile.height, draft.heightCm.map { "\($0) cm" } ?? "")
                    AccountValueRow(AppText.Profile.weight, draft.weightKg.map { String(format: "%.1f kg", $0) } ?? "")
                    AccountValueRow(AppText.Profile.country, draft.countryRegion)
                }
                .background(AppColors.Account.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                AccountSectionTitle(AppText.Account.accountSection)
                VStack(spacing: 0) {
                    AccountValueRow(AppText.Account.loginAccount, session?.account ?? "")
                    AccountActionRow(AppText.Account.logout, color: .white) { viewModel.logout() }
                    AccountActionRow(AppText.Account.delete, color: AppColors.Account.destructive) { showDeleteDialog = true }
                }
                .background(AppColors.Account.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if let localError {
                    Text(localError).font(.system(size: 13)).foregroundStyle(Color.red).padding(.top, 18)
                }
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 18)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
        .confirmationDialog(AppText.Account.deleteConfirmation, isPresented: $showDeleteDialog, titleVisibility: .visible) {
            Button(AppText.Common.confirm, role: .destructive) {
                localError = viewModel.deleteCurrentAccountMessage()
            }
            Button(AppText.Common.cancel, role: .cancel) {}
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
                    .background(Color(red: 48 / 255, green: 48 / 255, blue: 52 / 255))
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
            Text(value.isEmpty ? AppText.Common.notSet : value).font(.system(size: 13)).foregroundStyle(AppColors.Account.muted)
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
                Button(action: onClose) { Text(AppText.Common.back).font(.system(size: 38, weight: .light)) }
                    .frame(width: 64, alignment: .leading)
                Spacer()
                Text(AppText.Profile.personalInfo).font(.system(size: 18, weight: .medium))
                Spacer()
                Button(AppText.Common.save, action: save)
                    .font(.system(size: 14)).frame(width: 64).padding(.vertical, 8)
                    .background(canSave ? AppColors.Health.action : Color(red: 95 / 255, green: 0, blue: 28 / 255))
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
                        Text(AppText.Profile.username).foregroundStyle(.white)
                        TextField("", text: $draft.username).multilineTextAlignment(.trailing)
                            .foregroundStyle(Color(red: 216 / 255, green: 216 / 255, blue: 220 / 255)).tint(corosRed)
                        Image(AppImages.Profile.edit).resizable().scaledToFit().frame(width: 16, height: 16)
                    }
                    .frame(height: 56).overlay(alignment: .bottom) { divider }

                    editRow(AppText.Profile.gender, value: draft.gender?.title ?? "") { activePicker = .gender }
                    editRow(AppText.Profile.birthDate, value: draft.birthDate) { activePicker = .birthDate }
                    editRow(AppText.Profile.height, value: draft.heightCm.map { "\($0) cm" } ?? "") { activePicker = .height }
                    editRow(AppText.Profile.weight, value: draft.weightKg.map { String(format: "%.1f kg", $0) } ?? "") { activePicker = .weight }
                    editRow(AppText.Profile.country, value: draft.countryRegion) { activePicker = .country }
                }
                .padding(.horizontal, 26)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.black)
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
                Text(value.isEmpty ? AppText.Common.notSet : value).font(.system(size: 15))
                    .foregroundStyle(value.isEmpty ? corosMuted : Color(red: 216 / 255, green: 216 / 255, blue: 220 / 255))
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
    @State private var country = "中国"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(AppText.Common.cancel) { dismiss() }
                Spacer()
                Text(title).font(.system(size: 19, weight: .semibold))
                Spacer()
                Button(AppText.Common.confirm, action: confirm)
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
                    Picker("", selection: $country) { ForEach(["中国", "美国", "英国", "日本"], id: \.self) { Text($0).tag($0) } }.pickerStyle(.wheel)
                }
            }
            .colorScheme(.dark)
        }
        .presentationDetents([.height(360)]).presentationDragIndicator(.hidden)
        .background(Color(red: 26 / 255, green: 26 / 255, blue: 27 / 255).ignoresSafeArea())
        .onAppear {
            height = draft.heightCm ?? 175
            weightTenths = Int(((draft.weightKg ?? 60) * 10).rounded())
            gender = draft.gender ?? .male
            country = draft.countryRegion
        }
    }

    private var title: String {
        switch picker {
        case .birthDate: return AppText.Profile.birthDate
        case .gender: return AppText.Profile.gender
        case .height: return "身高 (cm)"
        case .weight: return "体重 (kg)"
        case .country: return AppText.Profile.country
        }
    }

    private func confirm() {
        switch picker {
        case .birthDate:
            let value = Calendar.current.dateComponents([.year, .month, .day], from: date)
            draft.birthDate = "\(value.year ?? 2002)年\(value.month ?? 1)月\(value.day ?? 1)日"
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
                phone: "", countryRegion: state.currentSession?.region == "US" ? "美国" : "中国", gender: nil
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
