// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$enrollmentPaymentsControllerHash() =>
    r'78d25f94760dede5fac02ea33441c10975f7ca32';

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

abstract class _$EnrollmentPaymentsController
    extends BuildlessAutoDisposeAsyncNotifier<List<PaymentModel>> {
  late final String enrollmentId;

  FutureOr<List<PaymentModel>> build(String enrollmentId);
}

/// See also [EnrollmentPaymentsController].
@ProviderFor(EnrollmentPaymentsController)
const enrollmentPaymentsControllerProvider =
    EnrollmentPaymentsControllerFamily();

/// See also [EnrollmentPaymentsController].
class EnrollmentPaymentsControllerFamily
    extends Family<AsyncValue<List<PaymentModel>>> {
  /// See also [EnrollmentPaymentsController].
  const EnrollmentPaymentsControllerFamily();

  /// See also [EnrollmentPaymentsController].
  EnrollmentPaymentsControllerProvider call(String enrollmentId) {
    return EnrollmentPaymentsControllerProvider(enrollmentId);
  }

  @override
  EnrollmentPaymentsControllerProvider getProviderOverride(
    covariant EnrollmentPaymentsControllerProvider provider,
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
  String? get name => r'enrollmentPaymentsControllerProvider';
}

/// See also [EnrollmentPaymentsController].
class EnrollmentPaymentsControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          EnrollmentPaymentsController,
          List<PaymentModel>
        > {
  /// See also [EnrollmentPaymentsController].
  EnrollmentPaymentsControllerProvider(String enrollmentId)
    : this._internal(
        () => EnrollmentPaymentsController()..enrollmentId = enrollmentId,
        from: enrollmentPaymentsControllerProvider,
        name: r'enrollmentPaymentsControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$enrollmentPaymentsControllerHash,
        dependencies: EnrollmentPaymentsControllerFamily._dependencies,
        allTransitiveDependencies:
            EnrollmentPaymentsControllerFamily._allTransitiveDependencies,
        enrollmentId: enrollmentId,
      );

  EnrollmentPaymentsControllerProvider._internal(
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
  FutureOr<List<PaymentModel>> runNotifierBuild(
    covariant EnrollmentPaymentsController notifier,
  ) {
    return notifier.build(enrollmentId);
  }

  @override
  Override overrideWith(EnrollmentPaymentsController Function() create) {
    return ProviderOverride(
      origin: this,
      override: EnrollmentPaymentsControllerProvider._internal(
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
    EnrollmentPaymentsController,
    List<PaymentModel>
  >
  createElement() {
    return _EnrollmentPaymentsControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EnrollmentPaymentsControllerProvider &&
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
mixin EnrollmentPaymentsControllerRef
    on AutoDisposeAsyncNotifierProviderRef<List<PaymentModel>> {
  /// The parameter `enrollmentId` of this provider.
  String get enrollmentId;
}

class _EnrollmentPaymentsControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          EnrollmentPaymentsController,
          List<PaymentModel>
        >
    with EnrollmentPaymentsControllerRef {
  _EnrollmentPaymentsControllerProviderElement(super.provider);

  @override
  String get enrollmentId =>
      (origin as EnrollmentPaymentsControllerProvider).enrollmentId;
}

String _$globalPendingPaymentsControllerHash() =>
    r'b1e6a64d6d5c13f361ee2b1c07a21f157159868d';

/// See also [GlobalPendingPaymentsController].
@ProviderFor(GlobalPendingPaymentsController)
final globalPendingPaymentsControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      GlobalPendingPaymentsController,
      List<PaymentModel>
    >.internal(
      GlobalPendingPaymentsController.new,
      name: r'globalPendingPaymentsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$globalPendingPaymentsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$GlobalPendingPaymentsController =
    AutoDisposeAsyncNotifier<List<PaymentModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
