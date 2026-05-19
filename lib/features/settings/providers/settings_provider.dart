import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final String officeName;
  final String officePhone;
  final String facebookLink;
  final String instagramLink;
  final bool isLoading;

  const SettingsState({
    this.officeName = '',
    this.officePhone = '',
    this.facebookLink = '',
    this.instagramLink = '',
    this.isLoading = true,
  });

  SettingsState copyWith({
    String? officeName,
    String? officePhone,
    String? facebookLink,
    String? instagramLink,
    bool? isLoading,
  }) {
    return SettingsState(
      officeName: officeName ?? this.officeName,
      officePhone: officePhone ?? this.officePhone,
      facebookLink: facebookLink ?? this.facebookLink,
      instagramLink: instagramLink ?? this.instagramLink,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SharedPreferences? _prefs;

  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await _getPrefs();

      state = state.copyWith(
        officeName: prefs.getString('officeName') ?? '',
        officePhone: prefs.getString('officePhone') ?? '',
        facebookLink: prefs.getString('facebookLink') ?? '',
        instagramLink: prefs.getString('instagramLink') ?? '',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateOfficeData({
    required String name,
    required String phone,
    required String fb,
    required String insta,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setString('officeName', name);
    await prefs.setString('officePhone', phone);
    await prefs.setString('facebookLink', fb);
    await prefs.setString('instagramLink', insta);

    state = state.copyWith(
      officeName: name,
      officePhone: phone,
      facebookLink: fb,
      instagramLink: insta,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
