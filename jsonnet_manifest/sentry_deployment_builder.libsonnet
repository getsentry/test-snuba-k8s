local k8s = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';

local app_functions = import 'cogs/app_functions.libsonnet';
local systems = import 'cogs/systems.libsonnet';

local deployment = k8s.apps.v1.deployment;
local container = k8s.core.v1.container;
local volmount = k8s.core.v1.volumeMount;
local affinity = k8s.core.v1.affinity;


local validation_message(field, field_value, sentry_deployment) =
  std.format('Invalid %s: %s in %s - %s', [
    field,
    field_value,
    sentry_deployment.service,
    sentry_deployment.component,
  ]);

local validate_deployment(sentry_deployment) =
  assert std.member(
    std.objectValues(app_functions),
    sentry_deployment.app_function
  ) : validation_message(
    'app_function', sentry_deployment.app_function, sentry_deployment
  );

  assert std.member(
    std.objectValues(systems),
    sentry_deployment.system
  ) : validation_message(
    'system', sentry_deployment.system, sentry_deployment
  );

  assert
    (
      sentry_deployment.shared_resource_id != null
      && sentry_deployment.app_feature == 'shared'
    ) || (
      sentry_deployment.shared_resource_id == null
      && sentry_deployment.app_feature != 'shared'
    ) : std.format(
      'Shared app_feature is only allowed with a shared resource id in %s - %s' % [
        sentry_deployment.service,
        sentry_deployment.component,
      ]
    );

  {};

{
  local full_name(sentry_deployment) =
    std.join('-', [
      sentry_deployment.service,
      sentry_deployment.component,
    ]),

  local base_labels(sentry_deployment) = {
    service: sentry_deployment.service,
    component: sentry_deployment.component,
  },

  local labels(sentry_deployment) =
    base_labels(sentry_deployment) +
    {
      app_feature: sentry_deployment.app_feature,
      app_function: sentry_deployment.app_function,
      system: sentry_deployment.system,
      subsystem: sentry_deployment.subsystem,
    },

  build(
    sentry_deployment,
  ): validate_deployment(sentry_deployment)
     + deployment.new(
       name=full_name(sentry_deployment),
       containers=[]
     )
     + deployment.metadata.withLabels(labels(sentry_deployment))
     + deployment.metadata.withNamespace(sentry_deployment.namespace)
     + deployment.spec.withMinReadySeconds(60)
     + deployment.spec.selector.withMatchLabels(
       base_labels(sentry_deployment)
     ) +
     deployment.spec.strategy.rollingUpdate.withMaxSurge(100) +
     deployment.spec.strategy.rollingUpdate.withMaxUnavailable(0) +
     deployment.spec.template.metadata.withAnnotations({
       'cluster-autoscaler.kubernetes.io/safe-to-evict': true,
     }) +
     deployment.spec.template.metadata.withLabels(
       labels(sentry_deployment)
     ) +
     deployment.spec.template.spec.withServiceAccountName(
       sentry_deployment.service_account_name,
     ),
}
