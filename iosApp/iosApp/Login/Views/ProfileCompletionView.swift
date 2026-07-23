import SwiftUI
import PhotosUI
import UIKit

private enum ProfilePicker: Identifiable {
    case birthDate
    case height
    case weight
    case unit
    case country

    var id: String {
        switch self {
        case .birthDate: return "birthDate"
        case .height: return "height"
        case .weight: return "weight"
        case .unit: return "unit"
        case .country: return "country"
        }
    }
}
 
 #Preview {
     ProfileCompletionView(
         viewModel: LoginViewModel(),
         router: AuthRouter(
             push: { _ in },
             pop: {},
             replaceTop: { _ in },
             resetTo: { _ in },
             resetKeepingEntranceAndPush: { _ in }
         )
     )
     .preferredColorScheme(.dark)
 }

struct ProfileCompletionView: View {
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    @State private var draft: ProfileDraft
    @State private var activePicker: ProfilePicker?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarData: Data?
    @State private var localError: String?

    init(viewModel: LoginViewModel, router: AuthRouter) {
        self.viewModel = viewModel
        self.router = router
        let session = viewModel.state.currentSession
        let defaultName = session?.resolvedDisplayName ?? session?.account ?? ""
        self._draft = State(
            initialValue: ProfileDraft(
                avatarUri: nil,
                username: defaultName,
                birthDate: "",
                heightCm: nil,
                weightKg: nil,
                measurementSystem: .metric,
                phone: "",
                countryRegion: session?.region ?? "CN",
                gender: nil
            )
        )
    }

    var body: some View {
        ZStack {
            AppColors.Core.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: backToEntrance) {
                        Text(appLocalized("common_back"))
                            .foregroundStyle(.white)
                            .font(.system(size: 44, weight: .light))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .frame(height: 52)
                .padding(.horizontal, 18)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: 14)
                        Text(appLocalized("profile_completion_title"))
                            .foregroundStyle(.white)
                            .font(.system(size: 28, weight: .light))
                        Spacer().frame(height: 8)
                        Text(appLocalized("profile_completion_description"))
                            .foregroundStyle(AppColors.Profile.description)
                            .font(.system(size: 14))
                            .lineSpacing(3)
                        Spacer().frame(height: 20)
                        ProfileAvatarButton(
                            avatarData: avatarData,
                            selectedPhoto: $selectedPhoto
                        )
                        .frame(maxWidth: .infinity)
                        Spacer().frame(height: 20)
                        ProfileTextRow(
                            label: appLocalized("profile_username"),
                            required: true,
                            value: Binding(
                                get: { draft.username },
                                set: { draft.username = String($0.prefix(20)); localError = nil }
                            ),
                            placeholder: appLocalized("profile_username_placeholder")
                        )
                        ProfileActionRow(
                            label: appLocalized("profile_birth_date"),
                            required: true,
                            value: draft.birthDate,
                            placeholder: appLocalized("profile_fill_in"),
                            onTap: { activePicker = .birthDate }
                        )
                        ProfileActionRow(
                            label: appLocalized("profile_height"),
                            required: true,
                            value: draft.heightCm.map { "\($0) cm" } ?? "",
                            placeholder: appLocalized("profile_fill_in"),
                            onTap: { activePicker = .height }
                        )
                        ProfileActionRow(
                            label: appLocalized("profile_weight"),
                            required: true,
                            value: draft.weightKg.map { String(format: "%.1f kg", $0) } ?? "",
                            placeholder: appLocalized("profile_fill_in"),
                            onTap: { activePicker = .weight }
                        )
                        ProfileActionRow(
                            label: appLocalized("profile_measurement"),
                            required: false,
                            value: draft.measurementSystem.title,
                            placeholder: "",
                            onTap: { activePicker = .unit }
                        )
                        ProfileTextRow(
                            label: appLocalized("profile_phone"),
                            required: false,
                            value: Binding(
                                get: { draft.phone },
                                set: { draft.phone = String($0.filter { $0.isNumber || $0 == "+" || $0 == "-" }.prefix(20)) }
                            ),
                            placeholder: appLocalized("profile_phone_placeholder"),
                            keyboardType: .phonePad
                        )
                        ProfileActionRow(
                            label: appLocalized("profile_country_region"),
                            required: false,
                            value: countryDisplayName(draft.countryRegion),
                            placeholder: appLocalized("common_china"),
                            onTap: { activePicker = .country }
                        )
                        ProfileGenderRow(selected: draft.gender) {
                            draft.gender = $0
                            localError = nil
                        }
                        Spacer().frame(height: 18)
                    }
                    .padding(.horizontal, 18)
                }
                .scrollIndicators(.hidden)

                VStack(spacing: 8) {
                    ErrorText(localError ?? viewModel.state.errorMessage)
                    CorosFilledButton(
                        text: appLocalized("common_complete"),
                        color: corosButtonRed,
                        enabled: viewModel.canSubmitProfile(draft),
                        isLoading: viewModel.state.isLoading,
                        buttonHeight: 48,
                        action: submitProfile
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(AppColors.Core.black)
            }
        }
        .sheet(item: $activePicker) { picker in
            ProfilePickerSheet(picker: picker, draft: $draft)
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.hidden)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            Task {
                let data = try? await newValue.loadTransferable(type: Data.self)
                await MainActor.run {
                    avatarData = data
                    if let data {
                        draft.avatarUri = ProfileImageStore.save(data)
                    }
                }
            }
        }
    }

    private func submitProfile() {
        guard viewModel.canSubmitProfile(draft) else { return }
        viewModel.submitProfile(draft)
    }

    private func backToEntrance() {
        viewModel.clearSessionSilently()
        router.resetTo(.entrance)
    }
}

private struct ProfileAvatarButton: View {
    let avatarData: Data?
    @Binding var selectedPhoto: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            ZStack {
                if let avatarData, let image = UIImage(data: avatarData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 76, height: 76)
                        .clipShape(Circle())
                } else {
                    Image("icon_camera")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 76, height: 76)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileTextRow: View {
    let label: String
    let required: Bool
    @Binding var value: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            RequiredLabel(label: label, required: required)
            TextField("", text: $value, prompt: Text(placeholder).foregroundStyle(corosMuted))
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .font(.system(size: 15))
                .multilineTextAlignment(.trailing)
                .tint(corosRed)
        }
        .frame(height: 56)
        .overlay(alignment: .bottom) { Rectangle().fill(corosLine).frame(height: 1) }
    }
}

private struct ProfileActionRow: View {
    let label: String
    let required: Bool
    let value: String
    let placeholder: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                RequiredLabel(label: label, required: required)
                Spacer(minLength: 16)
                Text(value.isEmpty ? placeholder : value)
                    .foregroundStyle(value.isEmpty ? corosMuted : AppColors.Profile.value)
                    .font(.system(size: 15))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image("right_more")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 19, height: 19)
            }
            .frame(height: 56)
            .overlay(alignment: .bottom) { Rectangle().fill(corosLine).frame(height: 1) }
        }
        .buttonStyle(.plain)
    }
}

private struct RequiredLabel: View {
    let label: String
    let required: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text(label).foregroundStyle(.white).font(.system(size: 16))
            if required { Text("*").foregroundStyle(corosRed).font(.system(size: 13)) }
        }
        .frame(minWidth: 86, alignment: .leading)
    }
}

private struct ProfileGenderRow: View {
    let selected: ProfileGender?
    let onSelected: (ProfileGender) -> Void

    var body: some View {
        HStack(spacing: 12) {
            RequiredLabel(label: appLocalized("profile_gender"), required: true)
            Spacer()
            ForEach(ProfileGender.allCases, id: \.self) { gender in
                Button(action: { onSelected(gender) }) {
                    HStack(spacing: 8) {
                        Image(gender.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                        Text(gender.title)
                    }
                    .foregroundStyle(selected == gender ? corosRed : .white)
                    .font(.system(size: 16))
                    .frame(width: 72, height: 40)
                    .background(AppColors.Profile.control)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selected == gender ? corosRed : .clear, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 62)
    }
}

private struct ProfilePickerSheet: View {
    let picker: ProfilePicker
    @Binding var draft: ProfileDraft
    @Environment(\.dismiss) private var dismiss

    @State private var date = Calendar.current.date(from: DateComponents(year: 2002, month: 11, day: 17)) ?? Date()
    @State private var height = 175
    @State private var weightTenths = 600
    @State private var unit: ProfileMeasurementSystem = .metric
    @State private var country = "CN"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image("ic_profile_close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                Spacer()
                Text(title).foregroundStyle(.white).font(.system(size: 20, weight: .semibold))
                Spacer()
                Button(action: confirm) {
                    Image("ic_profile_check")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.white)
            .frame(height: 58)
            .padding(.horizontal, 20)

            switch picker {
            case .birthDate:
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
            case .height:
                Picker("", selection: $height) {
                    ForEach(90...230, id: \.self) { Text("\($0)") }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
            case .weight:
                Picker("", selection: $weightTenths) {
                    ForEach(300...2200, id: \.self) { value in
                        Text(String(format: "%.1f", Double(value) / 10.0))
                    }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
            case .unit:
                Picker("", selection: $unit) {
                    ForEach(ProfileMeasurementSystem.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
            case .country:
                Picker("", selection: $country) {
                    ForEach(["CN", "US", "GB", "JP"], id: \.self) { code in
                        Text(countryDisplayName(code)).tag(code)
                    }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
            }
            Spacer(minLength: 0)
        }
        .background(AppColors.Profile.control.ignoresSafeArea())
        .onAppear {
            height = draft.heightCm ?? 175
            weightTenths = Int(((draft.weightKg ?? 60.0) * 10).rounded())
            unit = draft.measurementSystem
            country = draft.countryRegion
        }
    }

    private var title: String {
        switch picker {
        case .birthDate: return appLocalized("profile_birth_date")
        case .height: return appLocalized("profile_height_picker")
        case .weight: return appLocalized("profile_weight_picker")
        case .unit: return appLocalized("profile_measurement")
        case .country: return appLocalized("profile_country_region")
        }
    }

    private func confirm() {
        switch picker {
        case .birthDate:
            let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            draft.birthDate = "\(components.year ?? 2002)\(appLocalized("profile_date_year_suffix"))\(components.month ?? 1)\(appLocalized("profile_date_month_suffix"))\(components.day ?? 1)\(appLocalized("profile_date_day_suffix"))"
        case .height:
            draft.heightCm = height
        case .weight:
            draft.weightKg = Double(weightTenths) / 10.0
        case .unit:
            draft.measurementSystem = unit
        case .country:
            draft.countryRegion = country
        }
        dismiss()
    }
}
