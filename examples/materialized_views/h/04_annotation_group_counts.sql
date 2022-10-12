DROP MATERIALIZED VIEW reporting.annotation_group_counts;

CREATE MATERIALIZED VIEW reporting.annotation_group_counts AS (
    SELECT
        data.*,
        EXTRACT('year' FROM created_week - INTERVAL '6 month')::smallint AS academic_year,
        CONCAT(
            EXTRACT('year' FROM created_week - INTERVAL '6 month'),
            '-',
            CASE WHEN EXTRACT('quarter' FROM created_week - INTERVAL '6 month') < 3 THEN 1 ELSE 2 END
        ) AS academic_half_year,
        COUNT(1)::integer AS count
    FROM (
        SELECT
            -- Cast to a date as it's 4 bytes instead of 8
            DATE_TRUNC('week', created)::date AS created_week,
            authority_id,
            group_id
        FROM reporting.annotations
    ) as data
    GROUP BY GROUPING SETS (
        (created_week, authority_id),
        (created_week, authority_id, group_id)
    )
    ORDER BY created_week, authority_id, group_id
) WITH NO DATA;

-- 43Mb! 1m!
-- 34Mb
-- Time: 99547.840 ms (01:39.548)

CREATE UNIQUE INDEX annotation_group_counts_created_week_authority_id_group_id_idx ON reporting.annotation_group_counts (group_id, authority_id, created_week);
CREATE INDEX annotation_group_counts_authority_idx ON reporting.annotation_group_counts USING HASH (authority_id);
CREATE INDEX annotation_group_counts_group_id_idx ON reporting.annotation_group_counts USING HASH (group_id) WHERE group_id IS NOT NULL;
CREATE INDEX annotation_group_counts_created_week_idx ON reporting.annotation_group_counts USING BRIN (created_week);
CREATE INDEX annotation_group_counts_academic_year_idx ON reporting.annotation_group_counts (academic_year);
CREATE INDEX annotation_group_counts_academic_half_year_idx ON reporting.annotation_group_counts (academic_half_year);

REFRESH MATERIALIZED VIEW reporting.annotation_group_counts;
-- Time: 101790.364 ms (01:41.790)
REFRESH MATERIALIZED VIEW CONCURRENTLY reporting.annotation_group_counts;
-- Time: 55920.649 ms (00:55.921) ?!

ANALYZE VERBOSE reporting.annotation_group_counts;

-- Stats on the above

SELECT attname, correlation FROM pg_stats WHERE tablename='annotation_group_counts';
SELECT pg_size_pretty(pg_table_size('reporting.annotation_group_counts'));
SELECT pg_size_pretty(pg_relation_size('reporting.annotation_group_counts_authority_idx'));
SELECT pg_size_pretty(pg_relation_size('reporting.annotation_group_counts_group_id_idx'));
SELECT pg_size_pretty(pg_relation_size('reporting.annotation_group_counts_created_week_idx'));
SELECT pg_size_pretty(pg_relation_size('reporting.annotation_group_counts_academic_year_idx'));
SELECT pg_size_pretty(pg_relation_size('reporting.annotation_group_counts_academic_half_year_idx'));
SELECT pg_size_pretty(pg_relation_size('reporting.annotation_group_counts_created_week_authority_id_group_id_idx'));
-- 18Mb, not too bad?