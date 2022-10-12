ANALYZE VERBOSE "user";
ANALYZE VERBOSE "group";
ANALYZE VERBOSE annotation;

-- INFO:  analyzing "public.user"
-- INFO:  "user": scanned 30000 of 44150 pages, containing 1064583 live rows and 43980 dead rows; 30000 rows in sample, 1566711 estimated total rows
-- ANALYZE
-- Time: 4566.130 ms (00:04.566)
-- INFO:  analyzing "public.group"
-- INFO:  "group": scanned 5068 of 5068 pages, containing 249756 live rows and 20112 dead rows; 30000 rows in sample, 249756 estimated total rows
-- ANALYZE
-- Time: 310.158 ms
-- INFO:  analyzing "public.annotation"
-- INFO:  "annotation": scanned 30000 of 5817768 pages, containing 216432 live rows and 1006 dead rows; 30000 rows in sample, 41971705 estimated total rows
-- ANALYZE
-- Time: 16810.320 ms (00:16.810)
