// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mentor_auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MentorAuthController)
const mentorAuthControllerProvider = MentorAuthControllerProvider._();

final class MentorAuthControllerProvider
    extends $AsyncNotifierProvider<MentorAuthController, bool> {
  const MentorAuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mentorAuthControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mentorAuthControllerHash();

  @$internal
  @override
  MentorAuthController create() => MentorAuthController();
}

String _$mentorAuthControllerHash() =>
    r'15347f79759ffa69fd519244f201f97495a36f65';

abstract class _$MentorAuthController extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
