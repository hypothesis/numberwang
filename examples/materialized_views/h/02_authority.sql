-- This is a bit of a weird trade off. By using a table we can use 'smallint'
-- columns for the authority_id everywhere, which cuts down on table size.
-- We lose a little speed from having a join (when required), but gain a little
-- speed by everything being smaller.

DROP MATERIALIZED VIEW reporting.authorities;
CREATE MATERIALIZED VIEW IF NOT EXISTS reporting.authorities AS (
    SELECT
        (row_number() over ())::smallint as id,
        authority
    FROM (
        SELECT DISTINCT(authority) as authority
        FROM "group"
    ) as data
) WITH NO DATA;

CREATE UNIQUE INDEX ON reporting.authorities (id);
CREATE UNIQUE INDEX ON reporting.authorities USING HASH (authority);

REFRESH MATERIALIZED VIEW reporting.authorities;
ANALYZE VERBOSE reporting.authorities;