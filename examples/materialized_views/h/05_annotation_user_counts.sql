DROP MATERIALIZED VIEW reporting.annotation_user_counts;

CREATE MATERIALIZED VIEW reporting.annotation_user_counts AS (
    SELECT
        data.*,
        COUNT(1)::integer AS count
    FROM (
        SELECT
            -- Cast to a date as it's 4 bytes instead of 8
            DATE_TRUNC('month', created)::date AS created_month,
            authority_id,
            user_id
        FROM reporting.annotations_fast
    ) as data
    GROUP BY (created_month, authority_id, user_id)
    ORDER BY created_month, authority_id, user_id
) WITH NO DATA;

-- Time: 60831.883 ms (01:00.832) 76MB

CREATE INDEX annotation_user_counts_authority_idx ON reporting.annotation_user_counts USING HASH (authority_id);
CREATE INDEX annotation_user_counts_user_id_idx ON reporting.annotation_user_counts USING HASH (user_id);
CREATE INDEX annotation_user_counts_created_week_idx ON reporting.annotation_user_counts (created_month);

REFRESH MATERIALIZED VIEW reporting.annotation_user_counts;
ANALYZE VERBOSE reporting.annotation_user_counts;

-- Time: 89393.624 ms (01:29.394) - 175
SELECT COUNT(1) FROM reporting.annotation_user_counts;
SELECT attname, correlation FROM pg_stats WHERE tablename='annotation_user_counts';
SELECT pg_size_pretty(pg_table_size('reporting.annotation_user_counts'));