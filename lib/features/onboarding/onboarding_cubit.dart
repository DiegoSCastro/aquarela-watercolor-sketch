import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit managing the 3-step onboarding flow.
class OnboardingCubit extends Cubit<int> {
  OnboardingCubit() : super(0);

  static const int totalPages = 3;

  void next() {
    if (state < totalPages - 1) {
      emit(state + 1);
    }
  }

  void previous() {
    if (state > 0) {
      emit(state - 1);
    }
  }

  void goTo(int page) {
    if (page >= 0 && page < totalPages) {
      emit(page);
    }
  }
}
