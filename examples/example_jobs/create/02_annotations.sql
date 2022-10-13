DROP TABLE IF EXISTS reporting.annotations CASCADE;

CREATE TABLE reporting.annotations (
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
    child_uuids UUID[],
    tags TEXT[],
    id SERIAL PRIMARY KEY
);

CREATE UNIQUE INDEX annotations_uuid_idx ON reporting.annotations (uuid);
CREATE INDEX annotations_created_idx ON reporting.annotations (created);
CREATE INDEX annotations_updated_idx ON reporting.annotations (updated);