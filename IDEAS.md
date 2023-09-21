* performance benchmarks for different compile-time settings
* performance benchmarks for different run-time pragmas
* performance benchmarks for different optimizations to bulk inserts
* the `DoNotRetryError` pattern for AcidicJob
  - define error class in ApplicationJob
  - define `discard_on` in ApplicationJob
  - raise this error in code paths you don't yet have error handling for
  - this ensures that your `AcidicJob::Run` records will have an error object and the current recovery point
  - this makes debugging much easier, as you will get a backtrace to the error source, and the full context of the job run that failed
* the upsert pattern for AcidicJob
  - when keeping data in sync between your system and an external system, avoid many of the complex race-conditions by relying on UPSERTs
  - ensure that every external resource maps 1-to-1 to an internal db table
  - ensure that every db table mapping to an external resource has a unique index (likely on a single `uid` or `external_identifier` field, but can also be a composite index if the external service doesn't provide an ID)
  - ensure that all sync writes use `Model.upsert` or `Model.upsert_all`
  + this mitigates against race conditions if you are creating objects but also listening for webhooks
    + response from create API call comes, then webhook
    + webhook comes, then response from create API call


https://tatpbenchmark.sourceforge.net
  http://www.tpc.org
  https://www.tpc.org/tpce/default5.asp
  https://github.com/apavlo/py-tpcc/blob/master/pytpcc/drivers/sqlitedriver.py