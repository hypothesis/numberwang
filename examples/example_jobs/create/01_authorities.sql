DROP MATERIALIZED VIEW IF EXISTS reporting.authorities CASCADE;
CREATE MATERIALIZED VIEW IF NOT EXISTS reporting.authorities AS (
    SELECT
        -- Create a fake "primary" key
        (row_number() over ())::smallint as id,
        authority
    FROM (
        -- Ensure that our authority ids are stable over time, by ordering them
        -- by the first time they were seen
        SELECT
            authority,
            MIN(created) as first_created
        FROM "group"
        GROUP BY authority
        ORDER BY first_created
    ) as data
) WITH NO DATA;

CREATE UNIQUE INDEX ON reporting.authorities (id);
CREATE UNIQUE INDEX ON reporting.authorities (authority);