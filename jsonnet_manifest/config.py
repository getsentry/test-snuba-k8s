import os

DEBUG = False
SENTRY_DSN = None

# Query Specifics
CLUSTERS = [
    {
    'host': 'clickhouse-001',
    'port': 9000,
    'http_port': 8123,
    'storage_sets': {
        "cdc",
        "discover",
        "events",
        "events_ro",
        "metrics",
        "migrations",
        "outcomes",
        "querylog",
        "sessions",
        "transactions",
        "profiles",
        "functions",
        "replays",
        "generic_metrics_sets",
        "generic_metrics_distributions",
        "search_issues",
        "generic_metrics_counters",
        "spans",
        "group_attributes",
        "generic_metrics_gauges",
        "metrics_summaries",
        "profile_chunks",
    },
    'single_node': True,
    },
]

# Clickhouse migrations to be skipped.
SKIPPED_MIGRATION_GROUPS = {
    'querylog',
    'test_migration',
}

# Capacity Management
ENFORCE_BYTES_SCANNED_WINDOW_POLICY = False

CLICKHOUSE_READONLY_USER = os.environ.get('CLICKHOUSE_READONLY_USER', 'default')
CLICKHOUSE_READONLY_PASSWORD = os.environ.get('CLICKHOUSE_READONLY_PASSWORD', '')

CLICKHOUSE_TRACE_USER = os.environ.get('CLICKHOUSE_TRACE_USER', 'default')
CLICKHOUSE_TRACE_PASSWORD = os.environ.get('CLICKHOUSE_TRACE_PASSWORD', '')


DEFAULT_MAX_BATCH_SIZE = 50000
DEFAULT_MAX_BATCH_TIME_MS = 1000
DEFAULT_QUEUED_MAX_MESSAGE_KBYTES = 50000
DEFAULT_QUEUED_MIN_MESSAGES = 20000

# Put query stats back into Clickhouse.
RECORD_QUERIES = True

# Record COGS in generic metrics consumer.
RECORD_COGS = False

# Always add these keys to PREWHERE filters to stop reading extra data.
PREWHERE_KEYS = ['event_id', 'issue', 'tags[sentry:release]', 'message', 'environment', 'project_id']

BROKER_CONFIG = {
    'bootstrap.servers': 'kafka-001:9092'
}

REDIS_HOST = '10.225.239.107'
REDIS_PORT = 6379
USE_REDIS_CLUSTER = False

RATE_LIMIT_CLUSTER = None

REDIS_CLUSTERS = {
    "cache": None,
    "rate_limiter": RATE_LIMIT_CLUSTER,
    "subscription_store": None,
    "replacements_store": None,
    "config": None,
    "dlq": None,
    "optimize": None,
    "admin_auth": None,
}

# replacer settings
REPLACER_MAX_MEMORY_USAGE = 50 * (1024**3) # 50GB
REPLACER_KEY_TTL = 1
REPLACER_IMMEDIATE_OPTIMIZE = True

CONFIG_STATE = {'use_readthrough_query_cache': 1, 'cache_expiry_sec': 500, 'query_settings/max_threads': 12, 'query_settings/max_memory_usage': 20000000000, 'query_settings/prefer_localhost_replica': 0}

TOPIC_PARTITION_COUNTS = {
    'events': 1,
    'transactions': 1,
    'ingest-metrics': 1,
    'ingest-performance-metrics': 1,
}

ADMIN_REGIONS = ["s4s", "de", "disney", "geico", "goldmansachs", "ly", "zendesk-eu"]
