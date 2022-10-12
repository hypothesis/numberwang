# Findings

## Impact on customers is uncertain

Generating these views is an intensive process. It's not clear how much impact
on general performance this will have even though it doesn't block access.

## Materialized views work well for aggregations

Most of our aggregations over a nice version of the annotation table work in
1-3 minutes. We can also do this concurrently, which means there is no down
time to customers looking at the data as it's rebuilt.

This is pretty nice.

It does require you having at least one `UNIQUE` index over the data

## A materialized view over the annotation table is _probably_ too slow

A materialized view over the annotation table takes about 12 minutes at a 
minimum. To make it something we can do using `CONCURRENTLY` we have to add
an index, and store more data, which takes it to about 15 minutes.

Doing it concurrently takes about 30 minutes.

When I initially tried copying more columns for a generally usable table I 
couldn't get it to work reliably. This suggests to me, we might be worryingly
close to a cliff edge that might cause problems.

The timings here are also quite rosey, as there is no other activity. Real 
world performance, or rows being inserted as we work might throw up problems.

I think we should consider alternatives.

## Tips and tricks with materialized views

### Mind your data types for smaller, faster tables

### You need a unique index to do concurrent update

Pretty much what it says on the tin. You need a unique index. This is a pain
for the annotation table as the only easy candidate for this is `id` which is
a huge GUID.

For aggregated tables you can use an index across multiple rows for the same
result.

### We can control row order to ensure good correlation

Adding an `ORDER BY` clause to created date or something similar doesn't cost
much in terms of execution time, and can increase the effectiveness of indexes.

### Good correlation allows us to use BRIN indexes

BRIN indexes are interesting because they are absolutely tiny. For example a 
B-tree index on the annotation table might be ~900Mb, but the BRIN index is
88kb.

In order for them to not have abysmal performance it seems you need:

 * Excellent correlation
 * Low numbers of deleted or updated rows
 * Want to select many rows at once (100k+)

This does match some of our use cases.

### You can `GROUP BY GROUPING SETS` to specific exact grouping combinations

Using `CUBE` and `ROLLUP` allows you to get many combinations of counts in the 
same table by having some fields blank. However, these might generate 
combinations you don't care about.
 
You can also use `GROUP BY GROUPING SETS` to specify exactly the ones you want.

### Partial indexes are potentially useful on roll-up type tables

Tables like the above generate lots of columns with sparse entries. Partial
indexes are smaller and more efficient in these scenarios.

### I think we should `ANALYZE` our materialized views once they are done

I don't think Postgres analyses views when they are created automatically, so
we should probably trigger this ourselves, to ensure query planning against 
them is efficient immediately. This is especially true for BRIN indexes, as if
Postgres doesn't know we have good correlation, it won't use it.