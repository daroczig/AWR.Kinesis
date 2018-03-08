#' Get record from a Kinesis Stream
#' @param stream stream name (string)
#' @param region AWS region (string)
#' @param limit number of records to fetch
#' @param shard_id  optional shard id - will pick a random active shard if left empty
#' @param iterator_type shard iterator type
#' @param start_sequence_number for \code{AT_SEQUENCE_NUMBER} and \code{AFTER_SEQUENCE_NUMBER} iterators
#' @param start_timestamp for \code{AT_TIMESTAMP} iterator
#' @note Use this no more than getting sample data from a stream - it's not intended for prod usage.
#' @references \url{https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/kinesis/model/GetRecordsRequest.html}
#' @return character vector that you might want to post-process eg with \code{jsonlite::stream_in}
#' @export
kinesis_get_records <- function(stream, region = 'us-west-1', limit = 25,
                                shard_id,
                                iterator_type = c('TRIM_HORIZON', 'LATEST',
                                                  'AT_SEQUENCE_NUMBER', 'AFTER_SEQUENCE_NUMBER',
                                                  'AT_TIMESTAMP'),
                                start_sequence_number, start_timestamp) {

    iterator_type <- match.arg(iterator_type)

    ## prepare Kinesis client
    client <- .jnew('com.amazonaws.services.kinesis.AmazonKinesisClient')
    client$setEndpoint(sprintf('kinesis.%s.amazonaws.com', region))

    ## pick a random shard if no specified
    if (missing(shard)) {
        shards <- client$describeStream(stream)
        shards <- sapply(
            as.list(shards$getStreamDescription()$getShards()$toArray()),
            function(x) x$getShardId())
        shards <- sub('^shardId-', '', shards)
        shard  <- sample(shards, 1)
    }

    ## list shards
    req <- .jnew('com.amazonaws.services.kinesis.model.ListShardsRequest')
    req$setStreamName(stream)
    shards <- client$ListShards(req)

    ## prepare iterator
    req <- .jnew('com.amazonaws.services.kinesis.model.GetShardIteratorRequest')
    req$setStreamName(stream)
    req$setShardId(.jnew('java/lang/String', '0'))
    req$setShardIteratorType(iterator_type)
    if (!missing(start_sequence_number)) {
        req$setStartingSequenceNumber(start_sequence_number)
    }
    if (!missing(start_timestamp)) {
        req$setTimestamp(start_timestamp)
    }
    iterator <- client$getShardIterator(req)$getShardIterator()

    ## get records
    req <- .jnew('com.amazonaws.services.kinesis.model.GetRecordsRequest')
    req$setLimit(.jnew('java/lang/Integer', as.integer(limit)))
    req$setShardIterator(iterator)
    res <- client$getRecords(req)$getRecords()

    ## transform from Java to R object
    sapply(res,
           function(x)
               rawToChar(x$getData()$array()))

}
