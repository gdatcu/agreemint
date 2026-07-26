// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$programEnrollmentsControllerHash() =>
    r'9fde0d24317e2b5c3755b74e458fece51f192211';

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

abstract class _$ProgramEnrollmentsController
    extends BuildlessAutoDisposeAsyncNotifier<List<EnrollmentModel>> {
  late final String programId;

  FutureOr<List<EnrollmentModel>> build(String programId);
}

/// See also [ProgramEnrollmentsController].
@ProviderFor(ProgramEnrollmentsController)
const programEnrollmentsControllerProvider =
    ProgramEnrollmentsControllerFamily();

/// See also [ProgramEnrollmentsController].
class ProgramEnrollmentsControllerFamily
    extends Family<AsyncValue<List<EnrollmentModel>>> {
  /// See also [ProgramEnrollmentsController].
  const ProgramEnrollmentsControllerFamily();

  /// See also [ProgramEnrollmentsController].
  ProgramEnrollmentsControllerProvider call(String programId) {
    return ProgramEnrollmentsControllerProvider(programId);
  }

  @override
  ProgramEnrollmentsControllerProvider getProviderOverride(
    covariant ProgramEnrollmentsControllerProvider provider,
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
  String? get name => r'programEnrollmentsControllerProvider';
}

/// See also [ProgramEnrollmentsController].
class ProgramEnrollmentsControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ProgramEnrollmentsController,
          List<EnrollmentModel>
        > {
  /// See also [ProgramEnrollmentsController].
  ProgramEnrollmentsControllerProvider(String programId)
    : this._internal(
        () => ProgramEnrollmentsController()..programId = programId,
        from: programEnrollmentsControllerProvider,
        name: r'programEnrollmentsControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$programEnrollmentsControllerHash,
        dependencies: ProgramEnrollmentsControllerFamily._dependencies,
        allTransitiveDependencies:
            ProgramEnrollmentsControllerFamily._allTransitiveDependencies,
        programId: programId,
      );

  ProgramEnrollmentsControllerProvider._internal(
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
  FutureOr<List<EnrollmentModel>> runNotifierBuild(
    covariant ProgramEnrollmentsController notifier,
  ) {
    return notifier.build(programId);
  }

  @override
  Override overrideWith(ProgramEnrollmentsController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProgramEnrollmentsControllerProvider._internal(
        () => create()..programId = programId,
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
  AutoDisposeAsyncNotifierProviderElement<
    ProgramEnrollmentsController,
    List<EnrollmentModel>
  >
  createElement() {
    return _ProgramEnrollmentsControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramEnrollmentsControllerProvider &&
        other.programId == programId;
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
mixin ProgramEnrollmentsControllerRef
    on AutoDisposeAsyncNotifierProviderRef<List<EnrollmentModel>> {
  /// The parameter `programId` of this provider.
  String get programId;
}

class _ProgramEnrollmentsControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ProgramEnrollmentsController,
          List<EnrollmentModel>
        >
    with ProgramEnrollmentsControllerRef {
  _ProgramEnrollmentsControllerProviderElement(super.provider);

  @override
  String get programId =>
      (origin as ProgramEnrollmentsControllerProvider).programId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
