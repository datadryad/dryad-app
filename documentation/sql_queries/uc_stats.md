# UC Stats

I was asked for stats which take a while to figure out queries for
because so much information is spread across versions in our database.
I'm adding them here so we don't have to keep re-inventing them and there
isn't a UC systemwide tenant now that has all the RORs for using UI reporting.

IDK if all these queries are perfect but it was an "oh by the way" request from
someone who wanted information right away.  They may also be useful for more
one-off requests in the future.

The following gives published items with an author at one of the UC RORs
that are listed in our tenants.
```mysql
SELECT DISTINCT ids.id FROM dcs_affiliations affil
JOIN dcs_affiliations_authors affil_auth
ON affil.`id` = affil_auth.`affiliation_id`
JOIN stash_engine_authors author
ON affil_auth.`author_id` = author.id
JOIN stash_engine_resources res
ON author.`resource_id` = res.id
JOIN stash_engine_identifiers ids
ON res.`identifier_id` = ids.id
WHERE ror_id IN 
('https://ror.org/01an7q238', 'https://ror.org/03djjyk45', 'https://ror.org/01ewh7m12', 'https://ror.org/03rafms67', 'https://ror.org/05kbg7k66', 'https://ror.org/02mmp8p21', 'https://ror.org/05rrcem69', 'https://ror.org/05q8kyc69', 'https://ror.org/05ehe8t08', 'https://ror.org/00fyrp007', 'https://ror.org/05t6gpm70', 'https://ror.org/04gyf1771', 'https://ror.org/03fgher32', 'https://ror.org/00cm8nm15', 'https://ror.org/03bfp2076', 'https://ror.org/046rm7j60', 'https://ror.org/05h4zj272', 'https://ror.org/04p5baq95', 'https://ror.org/03b66rp04', 'https://ror.org/04k3jt835', 'https://ror.org/01d88se56', 'https://ror.org/04vq5kb54', 'https://ror.org/00mjfew53', 'https://ror.org/00d9ah105', 'https://ror.org/00pjdza24', 'https://ror.org/03nawhv43', 'https://ror.org/02t274463', 'https://ror.org/03s65by71', 'https://ror.org/0168r3w48', 'https://ror.org/01kbfgm16', 'https://ror.org/04mg3nk07', 'https://ror.org/05ffhwq07', 'https://ror.org/04v7hvq31', 'https://ror.org/01vf2g217', 'https://ror.org/043mz5j54', 'https://ror.org/03hwe2705', 'https://ror.org/01t8svj65', 'https://ror.org/04g7y4303')
AND pub_state = 'published'
```

UC Authors of datasets grouped by publication year.  I'm assuming the first resource
where the files show up is the one with the publication year that is correct.
```mysql
SELECT pub_year, count(pub_year) as number FROM
(SELECT pub_ids.id, first_pub.min_resource_id, year(res2.publication_date) as pub_year FROM
(SELECT DISTINCT ids.id FROM dcs_affiliations affil
JOIN dcs_affiliations_authors affil_auth
ON affil.`id` = affil_auth.`affiliation_id`
JOIN stash_engine_authors author
ON affil_auth.`author_id` = author.id
JOIN stash_engine_resources res
ON author.`resource_id` = res.id
JOIN stash_engine_identifiers ids
ON res.`identifier_id` = ids.id
WHERE ror_id IN 
('https://ror.org/01an7q238', 'https://ror.org/03djjyk45', 'https://ror.org/01ewh7m12', 'https://ror.org/03rafms67', 'https://ror.org/05kbg7k66', 'https://ror.org/02mmp8p21', 'https://ror.org/05rrcem69', 'https://ror.org/05q8kyc69', 'https://ror.org/05ehe8t08', 'https://ror.org/00fyrp007', 'https://ror.org/05t6gpm70', 'https://ror.org/04gyf1771', 'https://ror.org/03fgher32', 'https://ror.org/00cm8nm15', 'https://ror.org/03bfp2076', 'https://ror.org/046rm7j60', 'https://ror.org/05h4zj272', 'https://ror.org/04p5baq95', 'https://ror.org/03b66rp04', 'https://ror.org/04k3jt835', 'https://ror.org/01d88se56', 'https://ror.org/04vq5kb54', 'https://ror.org/00mjfew53', 'https://ror.org/00d9ah105', 'https://ror.org/00pjdza24', 'https://ror.org/03nawhv43', 'https://ror.org/02t274463', 'https://ror.org/03s65by71', 'https://ror.org/0168r3w48', 'https://ror.org/01kbfgm16', 'https://ror.org/04mg3nk07', 'https://ror.org/05ffhwq07', 'https://ror.org/04v7hvq31', 'https://ror.org/01vf2g217', 'https://ror.org/043mz5j54', 'https://ror.org/03hwe2705', 'https://ror.org/01t8svj65', 'https://ror.org/04g7y4303')
AND pub_state = 'published') as pub_ids
JOIN ( SELECT MIN(id) as min_resource_id, identifier_id FROM stash_engine_resources WHERE file_view = 1 GROUP BY identifier_id) as first_pub
ON pub_ids.id = first_pub.identifier_id
JOIN stash_engine_resources res2
ON res2.id = first_pub.min_resource_id) all_q
GROUP BY pub_year
ORDER BY pub_year;
```

Published datasets by the submitter and their current affiliation as a UC tenant. It could
probably be optimized by using the tenant_id in the resource instead.  There may be some difference
in number since users may move affiliations as they change jobs and the original tenant was the
one that was present on initial submission.
```mysql
SELECT pub_year, count(pub_year) as number FROM
(SELECT pub_ids.id, first_pub.min_resource_id, year(res2.publication_date) as pub_year FROM
(SELECT DISTINCT seid.id FROM stash_engine_resources res
JOIN stash_engine_users users
ON res.`user_id` = users.id
JOIN stash_engine_identifiers seid
ON res.identifier_id = seid.id
WHERE users.`tenant_id` IN ('ucb', 'ucd', 'uci', 'ucla', 'ucm', 'ucop', 'ucpress', 'ucr', 'ucsb', 'ucsc', 'ucsd', 'ucsf')
AND pub_state = 'published') as pub_ids
JOIN ( SELECT MIN(id) as min_resource_id, identifier_id FROM stash_engine_resources WHERE file_view = 1 GROUP BY identifier_id) as first_pub
ON pub_ids.id = first_pub.identifier_id
JOIN stash_engine_resources res2
ON res2.id = first_pub.min_resource_id) all_q
GROUP BY pub_year
ORDER BY pub_year;
```