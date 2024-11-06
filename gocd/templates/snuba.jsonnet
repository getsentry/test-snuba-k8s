local snuba = import './pipelines/snuba.libsonnet';
local pipedream = import 'github.com/getsentry/gocd-jsonnet/libs/pipedream.libsonnet';

local pipedream_config = {
  name: 'snuba',
  materials: {
    test_snuba_k8s_repo: {
      git: 'git@github.com:getsentry/test-snuba-k8s.git',
      shallow_clone: true,
      branch: 'main',
      destination: 'snuba',
    },
  },
  rollback: {
    material_name: 'test_snuba_k8s_repo',
    stage: 'deploy-primary',
    elastic_profile_id: 'snuba',
  },

  // Set to true to auto-deploy changes (defaults to true)
  auto_deploy: true,
};

pipedream.render(pipedream_config, snuba)
