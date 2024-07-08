local k8s = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';
local service = import 'snuba_service.libsonnet';

// This is the whole reduced Snuba (admin, api, configmap and consumer)

local configmap = k8s.core.v1.configMap;
local autoscaler = k8s.autoscaling.v1.horizontalPodAutoscaler;
local aspec = autoscaler.spec;

std.objectValues(service.build_api_service(
  name='admin',
  namespace='snuba-jsonnet',
  port=8000,
  command=[
    'admin',
    '--processes=3',
    '--threads=4',
  ],
  replicas=1,
  cpu='5000m',
  memory='5Gi'
))
+ std.objectValues(service.build_api_service(
  name='api',
  namespace='snuba-jsonnet',
  port=1218,
  command=[
    'api',
    '--processes=3',
    '--threads=4',
  ],
  replicas=1,
  cpu='5000m',
  memory='5Gi'
))
+ std.objectValues(service.build_consumer(
  name='errors',
  namespace='snuba-jsonnet',
  command=[
    'rust-consumer',
    '--storage',
    'errors',
    '--consumer-group',
    'snuba-consumers',
    '--max-batch-time-ms',
    '1100',
    '--concurrency',
    '4',
    '--auto-offset-reset',
    'earliest',
    '--no-strict-offset-reset',
  ],
  replicas=1,
  cpu='4000m',
  memory='4Gi'
))
+ [
  configmap.new(
    name='snuba',
    data={
      'snuba.conf.py': importstr 'config.py',
    }
  )
  + configmap.metadata.withNamespace('snuba-jsonnet')
  + configmap.metadata.withLabels({
    component: 'configmap',
    service: 'snuba',
  }),
  //autoscaler.new('snuba-api-production')
  //+ autoscaler.metadata.withLabels({
  //  app_feature: 'shared',
  //  app_function: 'storage',
  //  cogs_category: 'shared',
  //  component: 'api',
  //  environment: 'production',
  //  is_canary: 'false',
  //  service: 'snuba',
  //  shared_resource_id: 'snuba_api',
  //  system: 'snuba_api',
  //})
  //+ autoscaler.metadata.withNamespace('snuba-jsonnet')
  //+ aspec.withMaxReplicas(2)
  //+ aspec.withMinReplicas(1)
  //+ aspec.withTargetCPUUtilizationPercentage(40)
  //+ aspec.withScaleTargetRef({
  //  apiVersion: 'apps/v1',
  //  kind: 'Deployment',
  //  name: 'snuba-api-production',
  //}),
]
