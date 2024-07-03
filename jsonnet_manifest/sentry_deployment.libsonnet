{
  /*
   Generates a Sentry Kubernetes Deployment.
   All Sentry k8s deployments should follow some basic traits that
   are defined here like:
   - Common labels
   - some init containers including the datadog proxy
   - port forwarding
   - rollout strategy.
   More specific deployments (like the snuba deployment) should
   extend this object adding their specific structure.
  */

  local config = self,

  // Logical break down of our systems into independent services.
  service: error 'No service name provided',
  // The component identifies the deployment for a specific service.
  component: error 'No component name provided',

  // [cogs] Product feature for cloud cost accounting.
  app_feature: error 'No app_feature provided',
  // [cogs] The function this resource belongs to.
  // Must come from cogs/app_functions.libsonnet
  app_function: error 'No app_function provided',
  // [cogs] The type of system this resource represents.
  // Must come from cogs/systems.libsonnet
  system: error 'No system provided',
  // [cogs] Further break down of the system.
  subsystem: null,
  // [cogs] Identifies resources that are shared between app_features
  shared_resource_id: null,
  // [cogs] Groups shared resources into platform to have an aggregate
  // cost.
  platform_id: null,

  // K8s namespace if it has to be specified.
  namespace: 'default',
  // Service account running the deployment
  service_account_name: null,
}
