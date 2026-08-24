// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EnrollmentPaymentsController)
const enrollmentPaymentsControllerProvider =
    EnrollmentPaymentsControllerFamily._();

final class EnrollmentPaymentsControllerProvider
    extends
        $AsyncNotifierProvider<
          EnrollmentPaymentsController,
          List<PaymentModel>
        > {
  const EnrollmentPaymentsControllerProvider._({
    required EnrollmentPaymentsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'enrollmentPaymentsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$enrollmentPaymentsControllerHash();

  @override
  String toString() {
    return r'enrollmentPaymentsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EnrollmentPaymentsController create() => EnrollmentPaymentsController();

  @override
  bool operator ==(Object other) {
    return other is EnrollmentPaymentsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$enrollmentPaymentsControllerHash() =>
    r'900476edda907542a0ec3807268c89b3907678bd';

final class EnrollmentPaymentsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          EnrollmentPaymentsController,
          AsyncValue<List<PaymentModel>>,
          List<PaymentModel>,
          FutureOr<List<PaymentModel>>,
          String
        > {
  const EnrollmentPaymentsControllerFamily._()
    : super(
        retry: null,
        name: r'enrollmentPaymentsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EnrollmentPaymentsControllerProvider call(String enrollmentId) =>
      EnrollmentPaymentsControllerProvider._(
        argument: enrollmentId,
        from: this,
      );

  @override
  String toString() => r'enrollmentPaymentsControllerProvider';
}

abstract class _$EnrollmentPaymentsController
    extends $AsyncNotifier<List<PaymentModel>> {
  late final _$args = ref.$arg as String;
  String get enrollmentId => _$args;

  FutureOr<List<PaymentModel>> build(String enrollmentId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<List<PaymentModel>>, List<PaymentModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PaymentModel>>, List<PaymentModel>>,
              AsyncValue<List<PaymentModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(GlobalPendingPaymentsController)
const globalPendingPaymentsControllerProvider =
    GlobalPendingPaymentsControllerProvider._();

final class GlobalPendingPaymentsControllerProvider
    extends
        $AsyncNotifierProvider<
          GlobalPendingPaymentsController,
          List<PaymentModel>
        > {
  const GlobalPendingPaymentsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalPendingPaymentsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalPendingPaymentsControllerHash();

  @$internal
  @override
  GlobalPendingPaymentsController create() => GlobalPendingPaymentsController();
}

String _$globalPendingPaymentsControllerHash() =>
    r'b1e6a64d6d5c13f361ee2b1c07a21f157159868d';

abstract class _$GlobalPendingPaymentsController
    extends $AsyncNotifier<List<PaymentModel>> {
  FutureOr<List<PaymentModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<PaymentModel>>, List<PaymentModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PaymentModel>>, List<PaymentModel>>,
              AsyncValue<List<PaymentModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
