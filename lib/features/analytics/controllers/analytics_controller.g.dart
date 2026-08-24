// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnalyticsSummaryController)
const analyticsSummaryControllerProvider =
    AnalyticsSummaryControllerProvider._();

final class AnalyticsSummaryControllerProvider
    extends
        $AsyncNotifierProvider<AnalyticsSummaryController, AnalyticsSummary> {
  const AnalyticsSummaryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsSummaryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsSummaryControllerHash();

  @$internal
  @override
  AnalyticsSummaryController create() => AnalyticsSummaryController();
}

String _$analyticsSummaryControllerHash() =>
    r'64bfc081fa06cac79c0d7dd6e743265900ba20ba';

abstract class _$AnalyticsSummaryController
    extends $AsyncNotifier<AnalyticsSummary> {
  FutureOr<AnalyticsSummary> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<AnalyticsSummary>, AnalyticsSummary>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AnalyticsSummary>, AnalyticsSummary>,
              AsyncValue<AnalyticsSummary>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
