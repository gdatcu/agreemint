// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EnrollmentContractController)
const enrollmentContractControllerProvider =
    EnrollmentContractControllerFamily._();

final class EnrollmentContractControllerProvider
    extends
        $AsyncNotifierProvider<EnrollmentContractController, ContractModel?> {
  const EnrollmentContractControllerProvider._({
    required EnrollmentContractControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'enrollmentContractControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$enrollmentContractControllerHash();

  @override
  String toString() {
    return r'enrollmentContractControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EnrollmentContractController create() => EnrollmentContractController();

  @override
  bool operator ==(Object other) {
    return other is EnrollmentContractControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$enrollmentContractControllerHash() =>
    r'd6fcd5b863a1ae4d1a862179fd604e518941895c';

final class EnrollmentContractControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          EnrollmentContractController,
          AsyncValue<ContractModel?>,
          ContractModel?,
          FutureOr<ContractModel?>,
          String
        > {
  const EnrollmentContractControllerFamily._()
    : super(
        retry: null,
        name: r'enrollmentContractControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EnrollmentContractControllerProvider call(String enrollmentId) =>
      EnrollmentContractControllerProvider._(
        argument: enrollmentId,
        from: this,
      );

  @override
  String toString() => r'enrollmentContractControllerProvider';
}

abstract class _$EnrollmentContractController
    extends $AsyncNotifier<ContractModel?> {
  late final _$args = ref.$arg as String;
  String get enrollmentId => _$args;

  FutureOr<ContractModel?> build(String enrollmentId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<ContractModel?>, ContractModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ContractModel?>, ContractModel?>,
              AsyncValue<ContractModel?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(GlobalContractsController)
const globalContractsControllerProvider = GlobalContractsControllerProvider._();

final class GlobalContractsControllerProvider
    extends
        $AsyncNotifierProvider<GlobalContractsController, List<ContractModel>> {
  const GlobalContractsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalContractsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalContractsControllerHash();

  @$internal
  @override
  GlobalContractsController create() => GlobalContractsController();
}

String _$globalContractsControllerHash() =>
    r'f88c10fa0e4520ee50b5780afd69b0d652867c68';

abstract class _$GlobalContractsController
    extends $AsyncNotifier<List<ContractModel>> {
  FutureOr<List<ContractModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<ContractModel>>, List<ContractModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ContractModel>>, List<ContractModel>>,
              AsyncValue<List<ContractModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
