#' Run Kinesis Consumer application
#' @param initialize optional function to be run on startup
#' @param processRecords function to process records taking a \code{data.frame} object with \code{partitionKey}, \code{sequenceNumber} and \code{data} columns as the \code{records} argument. Probably you only need the \code{data} column from this object
#' @param shutdown optional function to be run when finished processing all records in a shard
#' @param checkpointing if set to \code{TRUE} (default), \code{kineric} will checkpoint after each \code{processRecords} call. To disable checkpointing altogether, set this to \code{FALSE}. If you want to checkpoint periodically, set this to the frequency in minutes as integer.
#' @param logfile file path of the log file. To disable logging, set \code{flog.threshold} to something high
#' @export
kineric <- function(initialize, processRecords, shutdown, checkpointing = TRUE, logfile = tempfile()) {

    ## store when we last checkpointed
    checkpoint_timestamp <- Sys.time()

    ## log to file instead of stdout (which is used for communication with the Kinesis daemon)
    devnull <- flog.appender(appender.file(logfile))
    flog.info('Starting R Kinesis Consumer application')

    ## add shard ID in each log line
    flog.layout(function(level, msg, ...) {
        timestamp <- format(Sys.time(), tz = 'UTC')
        parsed <- lapply(list(...), function(x) ifelse(is.null(x), 'NULL', x))
        msg <- do.call(sprintf, c(msg, parsed))
        sprintf("%s [%s UTC] %s %s\n", names(level), timestamp, line$shardId, msg)
    })

    ## run an infinite loop reading from stdin and writing to stout
    while (TRUE) {

        ## read and parse next message from stdin
        line <- read_line_from_stdin()

        ## init Kinesis consumer app
        if (line$action == 'initialize') {

            flog.info('Start of initialize ')
            if (!missing(initialize)) {
                initialize()
            }
            flog.info('End of initialize')

        }

        ## we are about to kill this process
        if (line$action == 'shutdown') {
            flog.info('Shutting down')
            if (!missing(shutdown)) {
                shutdown()
            }
            if (line$reason == 'TERMINATE') {
                checkpoint()
            }
        }

        ## process records
        if (line$action == 'processRecords') {

            n <- nrow(line$records)
            flog.debug(paste('Processing', n, 'records'))

            ## nothing to do right now
            if (n == 0) next()

            ## parse response into data.table
            records <- data.frame(
                partitionKey   = line$records$partitionKey,
                sequenceNumber = line$records$sequenceNumber,
                data           = sapply(line$records$data,
                                        function(x) rawToChar(base64_dec(x)), USE.NAMES = FALSE))

            ## do business logic
            processRecords(records)

            ## always checkpoint
            if (isTRUE(checkpointing)) {
                checkpoint()
            }

            ## checkpoint once every few minutes
            if (is.integer(checkpointing) && length(checkpointing) == 1 &&
                difftime(Sys.time(), checkpoint_timestamp, units = 'mins') > checkpointing) {

                flog.debug('Time to checkpoint')
                checkpoint(line$records[nrow(line$records), 'sequenceNumber'])

                ## reset timer
                checkpoint_timestamp <- Sys.time()

            }

        }

        ## return response for action
        if (line$action != 'checkpoint') {
            write_line_to_stdout(toJSON(list(action = unbox('status'), responseFor = unbox(line$action))))
        }

        ## indeed shut down if this process is not needed any more
        if (line$action == 'shutdown') {
            quit(save = 'no', status = 0, runLast = FALSE)
        }

    }

}
