// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProgramController)
const programControllerProvider = ProgramControllerProvider._();

final class ProgramControllerProvider
    extends $AsyncNotifierProvider<ProgramController, List<ProgramModel>> {
  const ProgramControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programControllerHash();

  @$internal
  @override
  ProgramController create() => ProgramController();
}

String _$programControllerHash() => r'f1487d974a9f83539a66cdd2f9bf9563c9753a7c';

abstract class _$ProgramController extends $AsyncNotifier<List<ProgramModel>> {
  FutureOr<List<ProgramModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<ProgramModel>>, List<ProgramModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ProgramModel>>, List<ProgramModel>>,
              AsyncValue<List<ProgramModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Fetches archived programs from program_history.

@ProviderFor(programHistory)
const programHistoryProvider = ProgramHistoryProvider._();

/// Fetches archived programs from program_history.

final class ProgramHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProgramModel>>,
          List<ProgramModel>,
          FutureOr<List<ProgramModel>>
        >
    with
        $FutureModifier<List<ProgramModel>>,
        $FutureProvider<List<ProgramModel>> {
  /// Fetches archived programs from program_history.
  const ProgramHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<ProgramModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProgramModel>> create(Ref ref) {
    return programHistory(ref);
  }
}

String _$programHistoryHash() => r'a010bd1cddcffce99450d6d950988098ada40aa1';

/// Fetches a single program by ID. Used by the router when navigating
/// directly to a deep-link URL (i.e. state.extra is null on browser reload).

@ProviderFor(programById)
const programByIdProvider = ProgramByIdFamily._();

/// Fetches a single program by ID. Used by the router when navigating
/// directly to a deep-link URL (i.e. state.extra is null on browser reload).

final class ProgramByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgramModel?>,
          ProgramModel?,
          FutureOr<ProgramModel?>
        >
    with $FutureModifier<ProgramModel?>, $FutureProvider<ProgramModel?> {
  /// Fetches a single program by ID. Used by the router when navigating
  /// directly to a deep-link URL (i.e. state.extra is null on browser reload).
  const ProgramByIdProvider._({
    required ProgramByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'programByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$programByIdHash();

  @override
  String toString() {
    return r'programByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProgramModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgramModel?> create(Ref ref) {
    final argument = this.argument as String;
    return programById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$programByIdHash() => r'300a0b9a143e9ce4171f8e81e398768fd5010721';

/// Fetches a single program by ID. Used by the router when navigating
/// directly to a deep-link URL (i.e. state.extra is null on browser reload).

final class ProgramByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProgramModel?>, String> {
  const ProgramByIdFamily._()
    : super(
        retry: null,
        name: r'programByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a single program by ID. Used by the router when navigating
  /// directly to a deep-link URL (i.e. state.extra is null on browser reload).

  ProgramByIdProvider call(String programId) =>
      ProgramByIdProvider._(argument: programId, from: this);

  @override
  String toString() => r'programByIdProvider';
}
