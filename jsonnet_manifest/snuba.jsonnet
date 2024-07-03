local service = import 'snuba_service.libsonnet';

{
  'snuba-admin': service.build_api_service(
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
  ),
  'snuba-api': service.build_api_service(
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
  ),
}
