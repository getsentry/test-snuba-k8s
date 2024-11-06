local getsentry = import 'github.com/getsentry/gocd-jsonnet/libs/getsentry.libsonnet';
local gocdtasks = import 'github.com/getsentry/gocd-jsonnet/libs/gocd-tasks.libsonnet';

// The return value of this function is the body of a GoCD pipeline.
// More information on gocd-flavor YAML this is producing can be found here:
// - https://github.com/tomzo/gocd-yaml-config-plugin#pipeline
// - https://www.notion.so/sentry/GoCD-New-Service-Quickstart-6d8db7a6964049b3b0e78b8a4b52e25d

// Snuba deploy to SaaS is blocked till S4S deploy is healthy
local s4s_health_check(region) =
  if region == 's4s' then
    [
      {
        health_check: {
          jobs: {
            health_check: {
              environment_variables: {
                SENTRY_AUTH_TOKEN: '{{SECRET:[devinfra-sentryio][token]}}',
                DATADOG_API_KEY: '{{SECRET:[devinfra][st_datadog_api_key]}}',
                DATADOG_APP_KEY: '{{SECRET:[devinfra][st_datadog_app_key]}}',
                LABEL_SELECTOR: 'service=snuba',
              },
              elastic_profile_id: 'snuba',
              tasks: [
                gocdtasks.script(importstr '../bash/s4s-sentry-health-check.sh'),
                gocdtasks.script(importstr '../bash/s4s-ddog-health-check.sh'),
              ],
            },
          },
        },
      },
    ]
  else
    [];

// Snuba deploy to ST is blocked till SaaS deploy is healthy
local saas_health_check(region) =
  if region == 'us' then
    [
      {
        health_check: {
          jobs: {
            health_check: {
              environment_variables: {
                SENTRY_AUTH_TOKEN: '{{SECRET:[devinfra-sentryio][token]}}',
                DATADOG_API_KEY: '{{SECRET:[devinfra][sentry_datadog_api_key]}}',
                DATADOG_APP_KEY: '{{SECRET:[devinfra][sentry_datadog_app_key]}}',
                LABEL_SELECTOR: 'service=snuba',
              },
              elastic_profile_id: 'snuba',
              tasks: [
                gocdtasks.script(importstr '../bash/saas-sentry-health-check.sh'),
                gocdtasks.script(importstr '../bash/saas-sentry-error-check.sh'),
                gocdtasks.script(importstr '../bash/saas-ddog-health-check.sh'),
              ],
            },
          },
        },
      },
    ]
  else
    [];

local deploy_canary_stage(region) =
  if region == 'us' then
    [
      {
        'deploy-canary': {
          fetch_materials: true,
          jobs: {
            'deploy-canary': {
              timeout: 1200,
              elastic_profile_id: 'snuba',
              environment_variables: {
                SENTRY_AUTH_TOKEN: '{{SECRET:[devinfra-sentryio][token]}}',
                DATADOG_API_KEY: '{{SECRET:[devinfra][sentry_datadog_api_key]}}',
                DATADOG_APP_KEY: '{{SECRET:[devinfra][sentry_datadog_app_key]}}',
                LABEL_SELECTOR: 'service=snuba,is_canary=true',
              },
              tasks: [
                gocdtasks.script(importstr '../bash/deploy.sh'),
                gocdtasks.script(importstr '../bash/canary-ddog-health-check.sh'),
              ],
            },
          },
        },
      },
    ]
  else
    [];

function(region) {
  environment_variables: {
    SENTRY_REGION: region,
    // Required for checkruns.
    GITHUB_TOKEN: '{{SECRET:[devinfra-github][token]}}',
    GOCD_ACCESS_TOKEN: '{{SECRET:[devinfra][gocd_access_token]}}',
  },
  lock_behavior: 'unlockWhenFinished',
  materials: {
    test_snuba_k8s_repo: {
      git: 'git@github.com:getsentry/test-snuba-k8s.git',
      shallow_clone: false,
      branch: 'main',
      destination: 'snuba',
    },
  },
  stages: [
            {
              checks: {
                jobs: {
                  checks: {
                    elastic_profile_id: 'snuba',
                    tasks: [
                      gocdtasks.script(importstr '../bash/check-github.sh'),
                    ],
                  },
                },
              },
            },

          ] +
          deploy_canary_stage(region) + [

    {
      'deploy-primary': {
        fetch_materials: true,
        jobs: {
          'deploy-primary': {
            timeout: 1200,
            elastic_profile_id: 'snuba',
            environment_variables: {
              LABEL_SELECTOR: 'service=snuba',
            },
            tasks: [
              if getsentry.is_st(region) then
                gocdtasks.script(importstr '../bash/deploy-st.sh')
              else
                gocdtasks.script(importstr '../bash/deploy.sh'),
            ],
          },
        },
      },
    },

  ] + s4s_health_check(region) + saas_health_check(region),
}
