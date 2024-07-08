local app_functions = import 'cogs/app_functions.libsonnet';
local systems = import 'cogs/systems.libsonnet';
local editor = import 'editor.libsonnet';
local k8s = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';
local sentry = import 'sentry_deployment.libsonnet';
local sentry_builder = import 'sentry_deployment_builder.libsonnet';

local deployment = k8s.apps.v1.deployment;
local container = k8s.core.v1.container;
local volmount = k8s.core.v1.volumeMount;
local volume = k8s.core.v1.volume;
local service = k8s.core.v1.service;
local sa = k8s.core.v1.serviceAccount;

local make_name(name) = 'snuba-' + name;

{
  local mod = self,


  build_deployment(
    name,
    namespace,
    port,
    command,
    replicas,
    cpu,
    memory
  ): sentry_builder.build(sentry {
       // TODO: Add validation here.
       service: 'snuba',
       component: name,
       app_feature: 'something',
       app_function: app_functions.STORAGE,
       system: systems.KAFKA_CONSUMER,
       service_account_name: make_name(name),
     })
     + deployment.spec.withReplicas(replicas)
     + deployment.spec.template.metadata.withAnnotations({
       configVersion: '1b6513a9eaebcd3a0cd7523829ea7cdb',
     })
     + deployment.spec.template.spec.withContainers([
       container.new(
         name='snuba-' + name,
         image='us.gcr.io/sentryio/snuba:92816dfc25a17de2dccd3df68a86d8de2871bfc8'
       )
       + container.withPorts(port)
       + container.withEnvMap({
         SNUBA_SETTINGS: '/etc/snuba.conf.py',
         SENTRY_ENVIRONMENT: 'st-mystuff',
         UWSGI_MAX_REQUESTS: '10000',
         UWSGI_DISABLE_LOGGING: 'true',
         UWSGI_ENABLE_THREADS: 'true',
         UWSGI_DIE_ON_TERM: 'true',
         UWSGI_NEED_APP: 'true',
         UWSGI_HTTP_SOCKET: '0.0.0.0:' + port,
         UWSGI_IGNORE_SIGPIPE: 'true',
         UWSGI_IGNORE_WRITE_ERRORS: 'true',
         UWSGI_DISABLE_WRITE_EXCEPTION: 'true',
         ENVOY_ADMIN_PORT: '15000',
         SNUBA_PROFILES_SAMPLE_RATE: '1.0',
         CLICKHOUSE_MIGRATIONS_USER: 'snuba',
       })
       + container.withArgs(command)
       + container.withResourcesRequests(cpu, memory)
       + container.withVolumeMounts(
         [
           volmount.new('dhsn', '/dev/shm'),
           volmount.new('snuba-config', '/etc/snuba.conf.py', readOnly=true)
           + volmount.withSubPath('snuba.conf.py'),
         ]
       ),
     ])
     + deployment.spec.template.spec.withTerminationGracePeriodSeconds(40)
     + deployment.spec.template.spec.withVolumes([
       volume.fromConfigMap(
         name='snuba-config',
         configMapName='snuba',
         configMapItems=[
           {
             key: 'snuba.conf.py',
             path: 'snuba.conf.py',
           },
         ],
       ),
       volume.fromEmptyDir('dshm', emptyDir={ medium: 'Memory' }),
       volume.fromEmptyDir('envoy-bootstrap-data'),
     ]),

  build_api_service(
    name,
    namespace,
    port,
    command,
    replicas,
    cpu,
    memory
  ):
    {
      [name + '-deployment']: mod.build_deployment(
        name,
        namespace,
        port,
        command,
        replicas,
        cpu,
        memory
      ) + editor.patch_container(
        [make_name(name)],
        container.lifecycle.preStop.exec.withCommand([
          '/bin/sh',
          '-ec',
          'touch /tmp/snuba.down && sleep 40',
        ])
        + container.livenessProbe.httpGet.withPath('/health')
        + container.livenessProbe.httpGet.withPort(port)
        + container.livenessProbe.withInitialDelaySeconds(10)
        + container.livenessProbe.withPeriodSeconds(10)
        + container.readinessProbe.httpGet.withPath('/health')
        + container.readinessProbe.httpGet.withPort(port)
        + container.readinessProbe.withInitialDelaySeconds(10)
        + container.readinessProbe.withPeriodSeconds(5)
        + container.startupProbe.httpGet.withPath('/health')
        + container.startupProbe.httpGet.withPort(port)
        + container.startupProbe.withInitialDelaySeconds(10)
        + container.startupProbe.withPeriodSeconds(10)
      ),
      [name + '-service']: service.new(
                             name=make_name(name),
                             ports=[{
                               port: port,
                               targetPort: port,
                             }],
                             selector={
                               service: make_name(name),
                             }
                           )
                           + service.metadata.withName(make_name(name))
                           + service.metadata.withNamespace(namespace)
                           + service.metadata.withLabels({
                             service: make_name(name),
                           }),
      [name + '-serviceAccount']: sa.new(make_name(name))
                                  + sa.metadata.withNamespace(namespace),
    },

  build_consumer(
    name,
    namespace,
    command,
    replicas,
    cpu,
    memory
  ): {
    [name + '-deployment']: mod.build_deployment(
      name,
      namespace,
      0,  // TODO: Remove this, it does nothing here
      command,
      replicas,
      cpu,
      memory
    ),
  },
}
