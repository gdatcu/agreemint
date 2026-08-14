// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prospect_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProspectsController)
const prospectsControllerProvider = ProspectsControllerProvider._();

final class ProspectsControllerProvider
    extends $AsyncNotifierProvider<ProspectsController, List<ProspectModel>> {
  const ProspectsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prospectsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prospectsControllerHash();

  @$internal
  @override
  ProspectsController create() => ProspectsController();
}

String _$prospectsControllerHash() =>
    r'7edf3312df64b1c95431fd3b0a2cfa3bace73d9c';

abstract class _$ProspectsController
    extends $AsyncNotifier<List<ProspectModel>> {
  FutureOr<List<ProspectModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<ProspectModel>>, List<ProspectModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ProspectModel>>, List<ProspectModel>>,
              AsyncValue<List<ProspectModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
