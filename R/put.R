#' Write a record to a Kinesis Stream
#' @param stream stream name (string)
#' @param region AWS region (string)
#' @param data data blog (string)
#' @param parititionKey determines which shard in the stream the data record is assigned to, eg username, stock symbol etc (string)
#' @export
#' @references \url{http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/kinesis/model/PutRecordRequest.html}
#' @examples \dontrun{
#' df <- mtcars[1, ]
#' str(kinesis_put_record('test-AWR', data = jsonlite::toJSON(df), partitionKey = row.names(df)))
#' }
#' @return invisible list including the shard id and sequence number
kinesis_put_record <- function(stream, region = 'us-west-1', data, partitionKey) {

    ## prepare request
    req <- .jnew('com.amazonaws.services.kinesis.model.PutRecordRequest')
    req$setStreamName(stream)
    req$setData(J('java.nio.ByteBuffer')$wrap(.jbyte(charToRaw(data))))
    req$setPartitionKey(partitionKey)

    ## send to AWS
    client <- .jnew('com.amazonaws.services.kinesis.AmazonKinesisClient')
    client$setEndpoint(sprintf('kinesis.%s.amazonaws.com', region))
    res <- client$putRecord(req)

    ## return list invisible
    invisible(list(
        shard = res$getShardId(),
        sequenceNumber = res$getSequenceNumber()))

}
