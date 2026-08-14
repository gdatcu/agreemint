// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(programRepository)
const programRepositoryProvider = ProgramRepositoryProvider._();

final class ProgramRepositoryProvider
    extends
        $FunctionalProvider<
          ProgramRepository,
          ProgramRepository,
          ProgramRepository
        >
    with $Provider<ProgramRepository> {
  const ProgramRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProgramRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProgramRepository create(Ref ref) {
    return programRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgramRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgramRepository>(value),
    );
  }
}

String _$programRepositoryHash() => r'2fde31fb7fc21931aed684dea8693d12fe1d4ccd';
