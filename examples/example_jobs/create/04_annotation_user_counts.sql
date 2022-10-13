DROP MATERIALIZED VIEW IF EXISTS reporting.annotation_user_counts CASCADE;

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
        FROM reporting.annotations
    ) as data
    GROUP BY (created_month, authority_id, user_id)
    ORDER BY created_month, authority_id, user_id
) WITH NO DATA;

CREATE INDEX annotation_group_counts_authority_idx ON reporting.annotation_user_counts USING HASH (authority_id);
CREATE INDEX annotation_user_counts_authority_idx ON reporting.annotation_user_counts USING HASH (user_id);
CREATE INDEX annotation_user_counts_created_week_idx ON reporting.annotation_user_counts (created_month);