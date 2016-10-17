#' Checkpoint at current or given sequence number
#' @param sequenceNumber optional
#' @export
checkpoint <- function(sequenceNumber) {

    params <- list(action = 'checkpoint')
    if (!missing(sequenceNumber)) {
        params <- c(params, list(checkpoint = sequenceNumber))
    }

    ## send checkpointing request
    write_line_to_stdout(toJSON(params, auto_unbox = TRUE))

    ## wait until checkpointing is finished
    read_line_from_stdin()

}
