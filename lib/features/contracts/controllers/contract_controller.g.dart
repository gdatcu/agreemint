// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$enrollmentContractControllerHash() =>
    r'66b7c23428be50271f4183678c8f73ef8b255109';

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

abstract class _$EnrollmentContractController
    extends BuildlessAutoDisposeAsyncNotifier<ContractModel?> {
  late final String enrollmentId;

  FutureOr<ContractModel?> build(String enrollmentId);
}

/// See also [EnrollmentContractController].
@ProviderFor(EnrollmentContractController)
const enrollmentContractControllerProvider =
    EnrollmentContractControllerFamily();

/// See also [EnrollmentContractController].
class EnrollmentContractControllerFamily
    extends Family<AsyncValue<ContractModel?>> {
  /// See also [EnrollmentContractController].
  const EnrollmentContractControllerFamily();

  /// See also [EnrollmentContractController].
  EnrollmentContractControllerProvider call(String enrollmentId) {
    return EnrollmentContractControllerProvider(enrollmentId);
  }

  @override
  EnrollmentContractControllerProvider getProviderOverride(
    covariant EnrollmentContractControllerProvider provider,
  ) {
    return call(provider.enrollmentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'enrollmentContractControllerProvider';
}

/// See also [EnrollmentContractController].
class EnrollmentContractControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          EnrollmentContractController,
          ContractModel?
        > {
  /// See also [EnrollmentContractController].
  EnrollmentContractControllerProvider(String enrollmentId)
    : this._internal(
        () => EnrollmentContractController()..enrollmentId = enrollmentId,
        from: enrollmentContractControllerProvider,
        name: r'enrollmentContractControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$enrollmentContractControllerHash,
        dependencies: EnrollmentContractControllerFamily._dependencies,
        allTransitiveDependencies:
            EnrollmentContractControllerFamily._allTransitiveDependencies,
        enrollmentId: enrollmentId,
      );

  EnrollmentContractControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.enrollmentId,
  }) : super.internal();

  final String enrollmentId;

  @override
  FutureOr<ContractModel?> runNotifierBuild(
    covariant EnrollmentContractController notifier,
  ) {
    return notifier.build(enrollmentId);
  }

  @override
  Override overrideWith(EnrollmentContractController Function() create) {
    return ProviderOverride(
      origin: this,
      override: EnrollmentContractControllerProvider._internal(
        () => create()..enrollmentId = enrollmentId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        enrollmentId: enrollmentId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    EnrollmentContractController,
    ContractModel?
  >
  createElement() {
    return _EnrollmentContractControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EnrollmentContractControllerProvider &&
        other.enrollmentId == enrollmentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, enrollmentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EnrollmentContractControllerRef
    on AutoDisposeAsyncNotifierProviderRef<ContractModel?> {
  /// The parameter `enrollmentId` of this provider.
  String get enrollmentId;
}

class _EnrollmentContractControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          EnrollmentContractController,
          ContractModel?
        >
    with EnrollmentContractControllerRef {
  _EnrollmentContractControllerProviderElement(super.provider);

  @override
  String get enrollmentId =>
      (origin as EnrollmentContractControllerProvider).enrollmentId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
