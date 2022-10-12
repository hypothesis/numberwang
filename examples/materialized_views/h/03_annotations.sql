DROP MATERIALIZED VIEW reporting.annotations;

CREATE MATERIALIZED VIEW IF NOT EXISTS reporting.annotations
    AS (
        SELECT
            users.id as user_id,
            groups.id as group_id,
            authorities.id as authority_id,
            annotation.created
        FROM (
            SELECT
                SPLIT_PART(userid, '@', 2) AS authority,
                SUBSTRING(SPLIT_PART(userid, '@', 1), 6) AS username,
                *
            FROM annotation
        ) AS annotation
        JOIN "user" users ON
            users.authority = annotation.authority
            AND users.username = annotation.username
        JOIN "group" as groups ON
            groups.pubid = annotation.groupid
        JOIN reporting.authorities ON
            authorities.authority = users.authority
        WHERE
        deleted = false
        -- Ensure our data is in created order so we can use BRIN index
        ORDER BY annotation.created
    )
    WITH NO DATA;

-- Time: 740676.425 ms (12:20.676) 2085 MB
-- Time: 735490.840 ms (12:15.491) 2085 MB (post small in authority)
-- Weekly count time: 1m!

CREATE INDEX annotations_created_idx ON reporting.annotations USING BRIN (created);

REFRESH MATERIALIZED VIEW reporting.annotations;
ANALYZE VERBOSE reporting.annotations;

---

CREATE MATERIALIZED VIEW IF NOT EXISTS reporting.annotations
    AS (
        SELECT
            -- In order to update the view concurrently we need a row we can
            -- have a unique index on. Having the ID also expands what we can
            -- do with the table a lot, as we can join back to the main data.
            -- It's a shame it's a massive string...
            annotation.id as id,
            users.id as user_id,
            groups.id as group_id,
            authorities.id as authority_id,
            annotation.created
        FROM (
            SELECT
                SPLIT_PART(userid, '@', 2) AS authority,
                SUBSTRING(SPLIT_PART(userid, '@', 1), 6) AS username,
                *
            FROM annotation
        ) AS annotation
        JOIN "user" users ON
            users.authority = annotation.authority
            AND users.username = annotation.username
        JOIN "group" as groups ON
            groups.pubid = annotation.groupid
        JOIN reporting.authorities ON
            authorities.authority = users.authority
        WHERE
        deleted = false
        -- Ensure our data is in created order so we can use BRIN index
        ORDER BY annotation.created
    )
    WITH NO DATA;

CREATE INDEX annotations_created_idx ON reporting.annotations USING BRIN (created);
CREATE UNIQUE INDEX annotations_id_idx ON reporting.annotations (id);
REFRESH MATERIALIZED VIEW reporting.annotations;
-- Time: 855004.131 ms (14:15.004)
REFRESH MATERIALIZED VIEW CONCURRENTLY reporting.annotations;
-- Time: 1885003.081 ms (31:25.003) - Ooof so slow!

-- Stats on the above

SELECT pg_size_pretty(pg_table_size('reporting.annotations'));
SELECT pg_size_pretty(pg_relation_size('reporting.annotations_created_idx'));


