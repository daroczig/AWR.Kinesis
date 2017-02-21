#' An R Kinesis Consumer
#'
#' Please find more details in the \code{README.md} file.
#' @docType package
#' @importFrom futile.logger flog.trace flog.debug flog.info flog.appender appender.file flog.layout
#' @importFrom jsonlite fromJSON toJSON base64_dec base64_enc unbox
#' @importFrom rJava .jnew J .jbyte
#' @importFrom utils assignInMyNamespace
#' @import AWR
#' @name AWR.Kinesis-package
NULL

## init for future update in below .onLoad hook
stdincon <- NULL

.onLoad <- function(libname, pkgname) {

    ## load stdin only once per R session to avoid the memory leak with
    ## always re-opening the connection
    assignInMyNamespace('stdincon',
                        suppressWarnings(file('stdin', open = 'r', blocking = TRUE)))

}

.onUnload <- function(libpath) {

    ## close opened connection
    close(stdincon)

}
