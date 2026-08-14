// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProgramEnrollmentsController)
const programEnrollmentsControllerProvider =
    ProgramEnrollmentsControllerFamily._();

final class ProgramEnrollmentsControllerProvider
    extends
        $AsyncNotifierProvider<
          ProgramEnrollmentsController,
          List<EnrollmentModel>
        > {
  const ProgramEnrollmentsControllerProvider._({
    required ProgramEnrollmentsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'programEnrollmentsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$programEnrollmentsControllerHash();

  @override
  String toString() {
    return r'programEnrollmentsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProgramEnrollmentsController create() => ProgramEnrollmentsController();

  @override
  bool operator ==(Object other) {
    return other is ProgramEnrollmentsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$programEnrollmentsControllerHash() =>
    r'915bfe5c6b819c30997218905fa01a08feee0f97';

final class ProgramEnrollmentsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProgramEnrollmentsController,
          AsyncValue<List<EnrollmentModel>>,
          List<EnrollmentModel>,
          FutureOr<List<EnrollmentModel>>,
          String
        > {
  const ProgramEnrollmentsControllerFamily._()
    : super(
        retry: null,
        name: r'programEnrollmentsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProgramEnrollmentsControllerProvider call(String programId) =>
      ProgramEnrollmentsControllerProvider._(argument: programId, from: this);

  @override
  String toString() => r'programEnrollmentsControllerProvider';
}

abstract class _$ProgramEnrollmentsController
    extends $AsyncNotifier<List<EnrollmentModel>> {
  late final _$args = ref.$arg as String;
  String get programId => _$args;

  FutureOr<List<EnrollmentModel>> build(String programId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref
            as $Ref<AsyncValue<List<EnrollmentModel>>, List<EnrollmentModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<EnrollmentModel>>,
                List<EnrollmentModel>
              >,
              AsyncValue<List<EnrollmentModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
