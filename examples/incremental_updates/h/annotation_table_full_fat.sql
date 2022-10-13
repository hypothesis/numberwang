DROP TABLE IF EXISTS reporting.annotations CASCADE;

CREATE TABLE reporting.annotations (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL,
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    document_id INT NOT NULL,
    authority_id SMALLINT NOT NULL,
    created DATE NOT NULL,
    updated DATE NOT NULL,
    deleted BOOLEAN NOT NULL,
    shared BOOLEAN NOT NULL,
    size INT,
    -- Are these ancestors or descendants?
    parent_uuids UUID[],
    tags TEXT[]
);

CREATE UNIQUE INDEX annotations_uuid_idx ON reporting.annotations (uuid);
CREATE INDEX annotations_created_idx ON reporting.annotations (created);
CREATE INDEX annotations_updated_idx ON reporting.annotations (updated);

WITH
    last_update_date AS (
        SELECT MAX(last_update) FROM (
            SELECT MAX(updated) - INTERVAL '1 day' AS last_update FROM reporting.annotations
            UNION
            SELECT NOW() - INTERVAL '100 year'
        ) AS data
    ),

    recent_annotations AS (
        SELECT
            id as uuid,
            groupid,
            document_id,
            created::date,
            updated::date,
            deleted,
            shared,
            LENGTH(text)::int AS size,
            "references" AS parent_uuids,
            tags,
            SPLIT_PART(userid, '@', 2) AS authority,
            SUBSTRING(SPLIT_PART(userid, '@', 1), 6) AS username
        FROM annotation
        WHERE
            updated >= (SELECT * FROM last_update_date)
        ORDER BY updated
    )

INSERT INTO reporting.annotations (
    uuid,
    user_id, group_id, document_id, authority_id,
    created, updated,
    deleted, shared, size,
    parent_uuids, tags
)
SELECT
    -- In order to update the view concurrently we need a row we can
    -- have a unique index on. Having the ID also expands what we can
    -- do with the table a lot, as we can join back to the main data.
    -- It's a shame it's a massive string...
    annotation.uuid,
    users.id as user_id,
    groups.id as group_id,
    document_id,
    authorities.id as authority_id,
    annotation.created::date,
    annotation.updated::date,
    deleted,
    shared,
    size,
    parent_uuids,
    tags
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
ON CONFLICT (uuid) DO UPDATE SET
    updated=EXCLUDED.updated,
    group_id=EXCLUDED.group_id,
    deleted=EXCLUDED.deleted,
    shared=EXCLUDED.shared,
    parent_uuids=EXCLUDED.parent_uuids,
    size=EXCLUDED.size;

ANALYZE VERBOSE reporting.annotations;

-- Time: 3055622.395 ms (50:55.622) 4609 Mb (with tags)


SELECT attname, correlation FROM pg_stats WHERE tablename='annotations';
SELECT pg_size_pretty(pg_table_size('reporting.annotations'));

-- 100K - 4s
-- 1M - 30s
-- 4m - 2:30s


-- Nightly 7s - 14s update!
