DROP MATERIALIZED VIEW reporting.annotations_fast;

CREATE MATERIALIZED VIEW IF NOT EXISTS reporting.annotations_fast AS (
    SELECT
        id,
        user_id,
        group_id,
        authority_id,
        created
    FROM reporting.annotations
    ORDER BY created
) WITH NO DATA;

CREATE UNIQUE INDEX ON reporting.annotations_fast (id);
CREATE INDEX ON reporting.annotations_fast USING BRIN (created);

REFRESH MATERIALIZED VIEW reporting.annotations_fast;
ANALYZE VERBOSE reporting.annotations_fast;

-- Time: 262075.012 ms (04:22.075) 2085 MB


SELECT pg_size_pretty(pg_table_size('reporting.annotations_fast'));
--SELECT pg_size_pretty(pg_relation_size('reporting.annotations_created_idx'));



----

DROP MATERIALIZED VIEW reporting.annotations_fast2;

CREATE MATERIALIZED VIEW IF NOT EXISTS reporting.annotations_fast2 AS (
    SELECT
        id,
        user_id,
        group_id,
        authority_id,
        created
    FROM reporting.annotations_fast
    ORDER BY created
) WITH NO DATA;

CREATE UNIQUE INDEX ON reporting.annotations_fast2 (id);
CREATE INDEX ON reporting.annotations_fast2 USING BRIN (created);

REFRESH MATERIALIZED VIEW reporting.annotations_fast2;
ANALYZE VERBOSE reporting.annotations_fast2;

-- Time: 225227.918 ms (03:45.228)