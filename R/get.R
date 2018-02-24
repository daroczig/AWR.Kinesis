#' Get record from a Kinesis Stream
#' @param stream stream name (string)
#' @param region AWS region (string)
#' @param limit number of records to fetch
#' @note Use this no more than getting sample data from a stream - it's not intended for prod usage.
#' @references \url{https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/kinesis/model/GetRecordsRequest.html}
#' @return character vector that you might want to post-process eg with \code{jsonlite::stream_in}
#' @export
kinesis_get_records <- function(stream, region = 'us-west-1', limit = 25) {

    ## prepare Kinesis client
    client <- .jnew('com.amazonaws.services.kinesis.AmazonKinesisClient')
    client$setEndpoint(sprintf('kinesis.%s.amazonaws.com', region))

    ## prepare iterator
    req <- .jnew('com.amazonaws.services.kinesis.model.GetShardIteratorRequest')
    req$setStreamName(stream)
    req$setShardId(.jnew('java/lang/String', '0'))
    req$setShardIteratorType('TRIM_HORIZON')
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
