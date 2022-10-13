DROP TABLE IF EXISTS reporting.annotations_increment;

CREATE TABLE reporting.annotations_increment (
    id UUID PRIMARY KEY NOT NULL,
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    authority_id SMALLINT NOT NULL,
    created DATE NOT NULL,
    updated DATE NOT NULL,
    deleted BOOLEAN NOT NULL
);

CREATE INDEX annotations_increment_created_idx ON reporting.annotations_increment (created);
CREATE INDEX annotations_increment_updated_idx ON reporting.annotations_increment (updated);

WITH
    last_update_date AS (
        SELECT MAX(last_update) FROM (
            SELECT MAX(updated) - INTERVAL '1 day' AS last_update FROM reporting.annotations_increment
            UNION
            SELECT NOW() - INTERVAL '100 year'
        ) AS data
    ),

    recent_annotations AS (
        SELECT
            id,
            created::date,
            updated::date,
            groupid,
            deleted,
            SPLIT_PART(userid, '@', 2) AS authority,
            SUBSTRING(SPLIT_PART(userid, '@', 1), 6) AS username
        FROM annotation
        WHERE
            updated >= (SELECT * FROM last_update_date)
        ORDER BY updated
    )

INSERT INTO reporting.annotations_increment
SELECT
    -- In order to update the view concurrently we need a row we can
    -- have a unique index on. Having the ID also expands what we can
    -- do with the table a lot, as we can join back to the main data.
    -- It's a shame it's a massive string...
    annotation.id as id,
    users.id as user_id,
    groups.id as group_id,
    authorities.id as authority_id,
    annotation.created::date,
    annotation.updated::date,
    deleted
FROM recent_annotations AS annotation
JOIN "user" users ON
    users.authority = annotation.authority
    AND users.username = annotation.username
JOIN "group" as groups ON
    groups.pubid = annotation.groupid
JOIN reporting.authorities ON
    authorities.authority = users.authority
-- Ensure our data is in created order for nice correlation
ORDER BY annotation.created
-- None of the fields in this table change over time
ON CONFLICT (id) DO UPDATE SET
    updated=EXCLUDED.updated,
    group_id=EXCLUDED.group_id,
    deleted=EXCLUDED.deleted;

ANALYZE VERBOSE reporting.annotations_increment;

-- Time: 1671424.253 ms (27:51.424) 2729 MB

SELECT attname, correlation FROM pg_stats WHERE tablename='annotations_increment';
SELECT pg_size_pretty(pg_table_size('reporting.annotations_increment'));

-- 1M: 23s (25s)
-- 4M: 2:01

-------- Incremental kind of sucks too

SELECT COUNT(1) FROM annotation where updated > NOW() - INTERVAL '1 week';
-- 7 seconds 170k rows
SELECT COUNT(1) FROM annotation where updated > NOW() - INTERVAL '1 month';
-- 54362.021 ms (00:54.362) 1.5m rows
SELECT COUNT(1) FROM annotation where updated > NOW() - INTERVAL '1 month';

-- Delete 1.5M and re-do (~3 weeks)
-- Time: 309813.911 ms (05:09.814)

-- Re-do 1 week
-- Time: 63313.090 ms (01:03.313)

-- We always have a 1 day overlap, which takes about 2-3 seconds
-- If we reach back a further day, it's like 4-5. Pretty good!