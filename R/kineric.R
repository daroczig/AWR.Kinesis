#' Run Kinesis Consumer application
#' @param initialize optional function to be run on startup
#' @param processRecords function to process records taking a \code{data.frame} object with \code{partitionKey}, \code{sequenceNumber} and \code{data} columns as the \code{records} argument. Probably you only need the \code{data} column from this object
#' @param shutdown optional function to be run when finished processing all records in a shard
#' @param checkpointing if set to \code{TRUE} (default), \code{kineric} will checkpoint after each \code{processRecords} call. To disable checkpointing altogether, set this to \code{FALSE}. If you want to checkpoint periodically, set this to the frequency in minutes as integer.
#' @param logfile file path
#' @export
kineric <- function(initialize, processRecords, shutdown, checkpointing = TRUE, logfile = tempfile()) {

    ## store when we last checkpointed
    checkpoint_timestamp <- now()

    ## log to file instead of stdout (which is used for communication with the Kinesis daemon)
    devnull <- flog.appender(appender.file(sprintf('%s.log', logfile)))
    flog.info('Starting app')

    ## run an infinite loop reading from stdin and writing to stout
    while (TRUE) {

        ## read and parse next message from stdin
        line <- read_line_from_stdin()

        ## init Kinesis consumer app
        if (line$action == 'initialize') {

            flog.debug(paste('Shard:', line$shardId))
            logfile <- sprintf('%s-%s.log', logfile, line$shardId)
            flog.debug(paste('Redirecting log to', logfile))
            flog.appender(appender.file(logfile))

            ## run custom initialize script
            flog.info('Init started')
            if (!missing(initialize)) {
                initialize()
            }
            flog.info('Init complete')

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
                difftime(now(), checkpoint_timestamp, units = 'mins') > checkpointing) {

                flog.debug('Time to checkpoint')
                checkpoint(line$records[nrow(line$records), 'sequenceNumber'])

                ## reset timer
                checkpoint_timestamp <- now()

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
