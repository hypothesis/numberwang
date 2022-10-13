# Incremental updates

## What about triggers?

We didn't consider triggers, because: 

 * They are a bit scary
 * They directly interact with the main app's data
 * They might make dumping and loading more complex
 * We can probably get away with...

## `SELECT ... INSERT INTO ...` basically

For incremental updates we are basically talking about creating an empty table
and then updating it with more curated data from the main data.

This has the advantage over materialized views that you can partially update
the data instead of starting from scratch.

## Slow to start, good to update

 * Seems to be slower than the equivalent materialized view
 * More verbose
 * A full fat dump of the annotation data takes about 50 minutes
 * Updates can be in the seconds

## Tending towards bad performance?

### Big data types

The annotation table has no small id, it uses full UUIDs, which are quite large
compared to ints. We also store lists of them for parent references. This makes
a compact table difficult, as we need the UUID to perform updates on.

A bigger culprit is likely the tags, which have no length or number limit and
are stored in an array.

Both the list of parent UUIDs and tags are listed as "EXTENDED" data types and
I suspect the cause of some of the performance issues.

### Fragmented data

Over time the data will get updated. This is likely to lead to fragmentation
in the stored data which could impact performance in a way that's impossible
for materialized views.

However we can always regenerate from scratch to fix this.

### Can we have fully denormalized tables?

One tempting idea is to scan over the annotation table to create an `id` to
UUID mapping, and then store much more normalized tables based on this 
instead of the full parent ids.

Similarly, we could create a normalized tags table and annotation tags lookup
table.

Each of these would require scanning over the annotation table multiple times
which could be very slow the first time. On the other hand our current scan
takes an absolute age, so maybe it would be similar? I suspect once we are 
reading `TOAST`-ed values, our performance is going to tank.

One possible solution to syncing for updates is to read the rows we want to 
update into a materialized view and then updating all the dependent tables
from that one. This would solve the update issue to some extent.

## I think we are going to have to try this

I think we may want to:

 * Try the full sized table (with most columns we think we might need)
 * ... but try it a few million rows at a time
 * If it's too slow / impactful try a slim version of the table
 * If that's still not good enough... we'll need another plan

I've seen pretty inconsistent speed in testing, and I don't know if it'll 
translate at all to live. Honestly I think we will need to run a real version
of the full update we expect to run, but limited to 1 million rows and watch
our stats. If that's ok, we can do it again with more.

We need to be careful in how we limit this, because a naive approach could
easily trigger a full table scan, so our performance for 1 million rows might 
be virtually the same as 40 million if we do it wrong.



