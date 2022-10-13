DROP TABLE IF EXISTS reporting.annotations_uuid CASCADE;

CREATE TABLE reporting.annotations_uuid (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL
);

CREATE UNIQUE INDEX annotations_uuid_uuid_idx ON reporting.annotations_uuid (uuid);

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
            id as uuid
        FROM annotation
        WHERE
            updated >= (SELECT * FROM last_update_date)
        ORDER BY updated
    )

INSERT INTO reporting.annotations_uuid (uuid)
SELECT id as uuid FROM annotation
ON CONFLICT (uuid) DO NOTHING;

ANALYZE VERBOSE reporting.annotations_uuid;

----

DROP TABLE IF EXISTS reporting.annotations_core CASCADE;

CREATE TABLE reporting.annotations_core (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    document_id INT NOT NULL,
    authority_id SMALLINT NOT NULL,
    created DATE NOT NULL,
    updated DATE NOT NULL
);