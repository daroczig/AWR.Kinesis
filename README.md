# AWS.Kinesis: An Amazon Kinesis Client Library for R

This R package is a wrapper around and an interface to the Amazon Kinesis Client Library (KCL) [MultiLangDaemon](https://github.com/awslabs/amazon-kinesis-client/tree/5d045521ce2da803cb4791d19faaeb63ea267c83/src/main/java/com/amazonaws/services/kinesis/multilang), which is part of the [Amazon KCL for Java](https://github.com/awslabs/amazon-kinesis-client). This Java-based daemon takes care of communicating with the Kinesis API (to retrieve status of streams, shards and eg to retrieve records from those) and also handles a bunch of other useful things, like checkpointing using Amazon DynamoDB -- so that the R developer can actually concentrate on the stream processing algorithm.

## Writing a record processor application

A minimal stream processing script written in R looks something like:

```r
AWS.Kinesis::kinesis_consumer(processRecords = function(records) {
	flog.info(jsonlite::toJSON(records)))
}
```

This R script, executed by the MultiLangDaemon, reads records from the Kinesis stream and logs those as JSON in the application log, which by default is a temporary file. Note: it's important not to write anything to `stdout`, as `stdin` and `stdout` is used by the package internals to communicate with the MultiLangDaemon. But as the package is already depends on and integrates the `futile.logger` R package, it's very convenient to use the `flog` functions for app logging with various log levels.

Let's see a more complex stream processing app:

```r
AWS.Kinesis::kinesis_consumer(
        initialize     = function()
            flog.info('Loading some data'),
        processRecords = function(records)
            flog.info('Received some records from Kinesis'),
        shutdown       = function()
            flog.info('Bye'),
        updater        = list(list(1, function()
            flog.info('Updating some data every minute')),
            list(1/60, function()
                flog.info('This is a high frequency updater call'))))
```

This application takes multiple (anonymous) functions. Besides the `processRecords` argument, which we used in the above application to define a function to process the records, we also have an init, a shutdown and two updater functions. The `initialize` and `shutdown` calls are trivial: these functions are run when the applications starts and when it stops, eg when there are no further records to be read from a shard due to a shard merge operation.

The `updater` part starts a timer in the background and executes the defined functions at the given frequency (1 minute and 1 second in the above example) before the `processRecords` calls.

So this application will log
* `Loading some data` on app start,
* `Received some records from Kinesis` every time it reads from Kinesis,
* `This is a high frequency updater call` (almost) every second after a process records call,
* `Updating some data every minute` around once a minute,
* `Bye` when the app stops.

Use the `initialize` function to load/cache some data for the `processRecords` calls, then use the `updater` functions to refresh your cached data on a regular basis. To store credentials to databases, APIs etc, use the [kmR](https://github.com/cardcorp/kmR) R package to interact with the AWS Key Management Service.

## Executing the record processor application

The R script has to be an executable, so add the executable bit (`chmod +x`) and also set a hashbang (for eg `Rscript` or littler). Then define a configuration file for the MultiLangDaemon, for example:

```
executableName = ./demo_app.R
streamName = demo_stream
applicationName = demo_app
```

This config file will look for a `demo_stream` Kinesis stream in the default (US East) region, start reading the oldest available record (via `TRIM_HORIZON`), and run the `demo_app.R` script to process the records, using to the `demo_app` DynamodDB table for checkpointing. There are quite many other useful settings as well, see the [example file of the Python client](https://github.com/awslabs/amazon-kinesis-client-python/blob/master/samples/sample.properties) for more details.

Running the MultiLangDaemon with the above defined configuration file is easy, as the required `jar` files are bundled with the `AWR` package:

```
/usr/bin/java -cp `Rscript --vanilla -e "cat(system.file('java', package = 'AWR'))"`/*:`pwd` com.amazonaws.services.kinesis.multilang.MultiLangDaemon ./demo.properties
```

## Further reading

Again, this is just a wrapper around the MultiLangDaemon, so the related documentation will be extremely useful if you get stuck:
* [AWS introduction into Kinesis](http://docs.aws.amazon.com/streams/latest/dev/introduction.html)
* [AWS docs on using the KCL](http://docs.aws.amazon.com/streams/latest/dev/developing-consumers-with-kcl.html)
* [Java Kinesis Client](https://github.com/awslabs/amazon-kinesis-client)
* [Python Kinesis Client](https://github.com/awslabs/amazon-kinesis-client-python)
