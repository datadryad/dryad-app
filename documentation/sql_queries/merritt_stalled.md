# Query for recent stalled items in Merritt

Unless manual changes were applied or a long submission times out, items in the queue state table have 2 success messages.  The first
happens when we get an acceptance from Merritt Sword.  The second happens when we retrive the item from the OAI-PMH feed to verify
information and completion status in Merritt.

This query finds the most recent submissions (between 2-72 hours old) that have not received a 2nd success message.  Most of these
would be errors in Merritt, but there might be exceptions for large submissions that take longer than 2 hours or for items that timed
out before receiving an initial success confirmation from Merritt on submission.

Not 100% accurrate, but a useful place to start when asking Merritt to investigate stalling out of submissions on their end.

When we've seen this problem, the item is also not available in the OAI-PMH feed (or our logs) and that version doesn't appear if
checking the Merritt UI directly.

```
SELECT res.id, download_uri, ver.`merritt_version`, rs.resource_state, sl.`created_at`, sl.`archive_submission_request`, sl.`archive_response`
FROM stash_engine_resources res
JOIN 
  (SELECT resource_id, count(id) as entry_count
  FROM stash_engine_repo_queue_states
  WHERE state = 'completed' 
  AND created_at BETWEEN DATE_SUB(NOW(), INTERVAL '72' HOUR) AND DATE_SUB(NOW(), INTERVAL '2' HOUR)
  GROUP BY resource_id
  HAVING entry_count < 2) q
    ON res.id = q.resource_id
  JOIN stash_engine_versions ver
    ON res.id = ver.resource_id
  JOIN `stash_engine_resource_states` rs
    ON res.id = rs.`resource_id`
  LEFT JOIN `stash_engine_submission_logs` sl
   ON res.id = sl.`resource_id`
WHERE sl.created_at > DATE_SUB(NOW(), INTERVAL '72' HOUR);
```
