local k8s = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';

local container = k8s.core.v1.container;
local deployment = k8s.apps.v1.deployment;

{
  patch_container(container_names, extension):
    deployment.mapContainersWithName(
      container_names,
      function(c) c + extension,
    ),
}
