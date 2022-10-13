DROP TABLE IF EXISTS reporting.annotation_uuids CASCADE;

CREATE TABLE reporting.annotation_uuids (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL
);

CREATE UNIQUE INDEX ON reporting.annotation_uuids (uuid);

----

DROP TABLE IF EXISTS reporting.annotation_meta CASCADE;

CREATE TABLE reporting.annotation_meta (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    document_id INT NOT NULL,
    authority_id SMALLINT NOT NULL,
    created DATE NOT NULL,
    updated DATE NOT NULL,
    deleted BOOLEAN NOT NULL,
    shared BOOLEAN NOT NULL
);

CREATE INDEX ON reporting.annotation_meta (created);
CREATE INDEX ON reporting.annotation_meta (updated);

----

DROP TABLE IF EXISTS reporting.tags CASCADE;

CREATE TABLE reporting.tags (
    id  SERIAL PRIMARY KEY,
    tag TEXT NOT NULL
);

CREATE UNIQUE INDEX ON reporting.tags (tag);

----

DROP TABLE IF EXISTS reporting.annotation_tags CASCADE;

CREATE TABLE reporting.annotation_tags (
    annotation_id INT NOT NULL,
    tag_id INT NOT NULL
);

CREATE UNIQUE INDEX ON reporting.annotation_tags (annotation_id, tag_id);

----

DROP TABLE IF EXISTS reporting.annotation_replies CASCADE;

CREATE TABLE reporting.annotation_replies (
    parent_id INT NOT NULL,
    child_id INT NOT NULL
);

CREATE UNIQUE INDEX ON reporting.annotation_replies (parent_id, child_id);

----

-- This is the view for an update
DROP MATERIALIZED VIEW IF EXISTS reporting.annotations_update;
DROP VIEW IF EXISTS reporting.annotations_update;

CREATE MATERIALIZED VIEW reporting.annotations_update AS (
    SELECT
        id,
        created,
        updated,
        userid,
        groupid,
        document_id,
        deleted,
        tags,
        shared,
        "references"
    FROM annotation
    WHERE
        updated >= (
            SELECT MAX(last_update) FROM (
            SELECT MAX(updated) - INTERVAL '1 day' AS last_update FROM reporting.annotation_meta
            UNION
            SELECT NOW() - INTERVAL '2 week'
        ) AS data
    )
) WITH NO DATA;

REFRESH MATERIALIZED VIEW reporting.annotations_update;


-- This is the view for a fresh create
DROP MATERIALIZED VIEW IF EXISTS reporting.annotations_update;
DROP VIEW IF EXISTS reporting.annotations_update;

CREATE VIEW reporting.annotations_update AS (
    SELECT
        id,
        created,
        updated,
        userid,
        groupid,
        document_id,
        deleted,
        tags,
        shared,
        "references"
    FROM annotation
);

----

INSERT INTO reporting.annotation_uuids (uuid)
SELECT
    -- In order to update the view concurrently we need a row we can
    -- have a unique index on. Having the ID also expands what we can
    -- do with the table a lot, as we can join back to the main data.
    -- It's a shame it's a massive string...
    annotation.id as uuid
FROM reporting.annotations_update AS annotation
-- Ensure our data is in created order for nice correlation
ORDER BY annotation.created
-- None of the fields in this table change over time
ON CONFLICT (uuid) DO NOTHING;



----

INSERT INTO reporting.annotation_meta (
    id,
    user_id,
    group_id,
    document_id,
    authority_id,
    created,
    updated,
    deleted,
    shared
)
SELECT
    annotation_uuids.id,
    users.id as user_id,
    groups.id as group_id,
    annotation.document_id,
    authorities.id as authority_id,
    annotation.created::date,
    annotation.updated::date,
    deleted,
    shared
FROM reporting.annotation_uuids AS annotation_uuids
JOIN reporting.annotations_update AS annotation
    ON annotation.id = annotation_uuids.uuid
JOIN "user" users ON
    users.authority = SPLIT_PART(userid, '@', 2)
    AND users.username = SUBSTRING(SPLIT_PART(userid, '@', 1), 6)
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
    deleted=EXCLUDED.deleted,
    shared=EXCLUDED.shared;

----

WITH
    tags_in_update AS (
        SELECT
            UNNEST(tags) as tag,
            MIN(created) as first_created
        FROM reporting.annotations_update
        GROUP BY tag
    ),

    new_tags AS (
        SELECT
            tags_in_update.tag
        FROM tags_in_update
        LEFT OUTER JOIN reporting.tags
            ON tags.tag = tags_in_update.tag
        WHERE
            tags.id IS NULL
        ORDER BY first_created
    )

INSERT INTO reporting.tags (tag)
SELECT tag
FROM new_tags
ON CONFLICT (tag) DO NOTHING;

----

-- Note! This doesn't cope with people removing tags from their annos.
INSERT INTO reporting.annotation_tags (annotation_id, tag_id)
SELECT
    annotation_id,
    tags.id as tag_id
FROM (
    SELECT
        annotation_uuids.id as annotation_id,
        UNNEST(annotation.tags) as tag
    FROM reporting.annotation_uuids AS annotation_uuids
    JOIN reporting.annotations_update AS annotation
        ON annotation.id = annotation_uuids.uuid
) AS annotation_tags
JOIN reporting.tags
    ON tags.tag = annotation_tags.tag
ON CONFLICT DO NOTHING;

----

INSERT INTO reporting.annotation_replies (parent_id, child_id)
SELECT
    parent.id AS parent_id,
    child_id
FROM (
    SELECT
        annotation_uuids.id as child_id,
        UNNEST("references") as parent_uuid
    FROM reporting.annotation_uuids AS annotation_uuids
    JOIN reporting.annotations_update AS annotation
        ON annotation.id = annotation_uuids.uuid
) AS annotation_parents
JOIN reporting.annotation_uuids AS parent
    ON parent.uuid = parent_uuid
ON CONFLICT DO NOTHING;
