DROP MATERIALIZED VIEW reporting.annotation_replies;

CREATE MATERIALIZED VIEW IF NOT EXISTS reporting.annotation_replies AS (
    SELECT
        parent.id as parent_id,
        child.id as child_id
    FROM reporting.annotations as child
    LEFT OUTER JOIN (
        SELECT
            id as child_id,
            unnest(parent_uuids) as parent_uuid
        FROM reporting.annotations
    ) parent_uuids
        ON child.id = child_id
    LEFT OUTER JOIN reporting.annotations as parent
        ON parent.uuid = parent_uuid
    ORDER BY parent_id
) WITH NO DATA;

CREATE UNIQUE INDEX ON reporting.annotation_replies (parent_id, child_id);

REFRESH MATERIALIZED VIEW reporting.annotation_replies;
ANALYZE VERBOSE reporting.annotation_replies;