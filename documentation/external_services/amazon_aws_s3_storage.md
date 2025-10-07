
Storage configuration
=======================

Storage consists of a set of "temporary" buckets that are used for ingest, and a set of "permanent" buckets that are used for long-term storage.


Temporary buckets
==================

These buckets are used for managing uploads. Once a user presses the "submit" button, files are moved into a permanent bucket.

Temporary buckets are named in the APP_CONFIG[:s3][:bucket]


Permanent buckets
==================

Each server's "primary" permanent bucket is named in the
APP_CONFIG[:s3][:merritt_bucket]. This is the bucket that the submission
process moves files into. Replication to additional buckets is managed by AWS
configurations.

Deletion and lifecycle rules
-----------------------------

versioned-object-deletion
- Checkboxes
  - Apply to all objects
  - Move noncurrent versions of objects between storage classes
  - Permanently delete noncurrent versions of objects
  - Delete expired object delete markers or incomplete multipart uploads
- (skip for non-production) Transition noncurrent versions of objects between storage classes
  - Glacier deep archive
  - 1 day after noncurrent
- Permanently delete noncurrent versions of objects
  - 370 days (7 for non-production)
- Delete expired object delete markers or incomplete multipart uploads
  - Delete expired object delete markers
  - Delete incomplete multipart uploads
  - 2 days
