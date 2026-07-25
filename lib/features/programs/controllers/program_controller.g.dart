// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$programByIdHash() => r'300a0b9a143e9ce4171f8e81e398768fd5010721';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Fetches a single program by ID. Used by the router when navigating
/// directly to a deep-link URL (i.e. state.extra is null on browser reload).
///
/// Copied from [programById].
@ProviderFor(programById)
const programByIdProvider = ProgramByIdFamily();

/// Fetches a single program by ID. Used by the router when navigating
/// directly to a deep-link URL (i.e. state.extra is null on browser reload).
///
/// Copied from [programById].
class ProgramByIdFamily extends Family<AsyncValue<ProgramModel?>> {
  /// Fetches a single program by ID. Used by the router when navigating
  /// directly to a deep-link URL (i.e. state.extra is null on browser reload).
  ///
  /// Copied from [programById].
  const ProgramByIdFamily();

  /// Fetches a single program by ID. Used by the router when navigating
  /// directly to a deep-link URL (i.e. state.extra is null on browser reload).
  ///
  /// Copied from [programById].
  ProgramByIdProvider call(String programId) {
    return ProgramByIdProvider(programId);
  }

  @override
  ProgramByIdProvider getProviderOverride(
    covariant ProgramByIdProvider provider,
  ) {
    return call(provider.programId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'programByIdProvider';
}

/// Fetches a single program by ID. Used by the router when navigating
/// directly to a deep-link URL (i.e. state.extra is null on browser reload).
///
/// Copied from [programById].
class ProgramByIdProvider extends AutoDisposeFutureProvider<ProgramModel?> {
  /// Fetches a single program by ID. Used by the router when navigating
  /// directly to a deep-link URL (i.e. state.extra is null on browser reload).
  ///
  /// Copied from [programById].
  ProgramByIdProvider(String programId)
    : this._internal(
        (ref) => programById(ref as ProgramByIdRef, programId),
        from: programByIdProvider,
        name: r'programByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$programByIdHash,
        dependencies: ProgramByIdFamily._dependencies,
        allTransitiveDependencies: ProgramByIdFamily._allTransitiveDependencies,
        programId: programId,
      );

  ProgramByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.programId,
  }) : super.internal();

  final String programId;

  @override
  Override overrideWith(
    FutureOr<ProgramModel?> Function(ProgramByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProgramByIdProvider._internal(
        (ref) => create(ref as ProgramByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        programId: programId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ProgramModel?> createElement() {
    return _ProgramByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramByIdProvider && other.programId == programId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, programId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProgramByIdRef on AutoDisposeFutureProviderRef<ProgramModel?> {
  /// The parameter `programId` of this provider.
  String get programId;
}

class _ProgramByIdProviderElement
    extends AutoDisposeFutureProviderElement<ProgramModel?>
    with ProgramByIdRef {
  _ProgramByIdProviderElement(super.provider);

  @override
  String get programId => (origin as ProgramByIdProvider).programId;
}

String _$programControllerHash() => r'416af1f2949637b59b85ead98b2bc01bb5053c72';

/// See also [ProgramController].
@ProviderFor(ProgramController)
final programControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      ProgramController,
      List<ProgramModel>
    >.internal(
      ProgramController.new,
      name: r'programControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$programControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProgramController = AutoDisposeAsyncNotifier<List<ProgramModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
