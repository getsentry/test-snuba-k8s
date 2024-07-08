local service = import 'snuba_service.libsonnet';

// This is the whole reduced Snuba (admin, api, configmap and consumer)

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
