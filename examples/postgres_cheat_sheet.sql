SELECT pg_size_pretty(pg_table_size('reporting.annotations'));
SELECT pg_size_pretty(pg_relation_size('reporting.annotations_id_idx'));

-- Running queries
SELECT * FROM pg_stat_activity where state='active';

-- Kill a query

SELECT pg_cancel_backend(<PID>);

-- Checking correlation
SELECT attname, correlation FROM pg_stats WHERE tablename='annotations_smol';