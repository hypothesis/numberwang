DROP MATERIALIZED VIEW reporting.tags;

CREATE MATERIALIZED VIEW IF NOT EXISTS reporting.tags AS (
    SELECT
        -- Create a fake "primary" key
        (row_number() over ())::integer as id,
        tag
    FROM (
        -- Ensure that our authority ids are stable over time, by ordering them
        -- by the first time they were seen
        SELECT
            UNNEST(tags) as tag,
            MIN(created) as first_created
        FROM reporting.annotations
        GROUP BY tag
        ORDER BY first_created
    ) as data
) WITH NO DATA;

CREATE UNIQUE INDEX ON reporting.tags (id);
CREATE UNIQUE INDEX ON reporting.tags (tag);

REFRESH MATERIALIZED VIEW reporting.tags;
ANALYZE VERBOSE reporting.tags;

---

SELECT
    annotation.id,
    tag.id
FROM reporting.annotations as annotation
JOIN reporting.tags ON
    tags.tag = UNNEST(annotation.tags)
LIMIT 10;