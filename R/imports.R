#' An R Kinesis Consumer
#'
#' This is a placeholder for storing import directives, please find more details in the \code{README.md} file.
#' @docType package
#' @importFrom futile.logger flog.trace flog.debug flog.info flog.appender appender.file flog.layout
#' @importFrom jsonlite fromJSON toJSON base64_dec base64_enc unbox
#' @importFrom rJava .jnew J .jbyte
#' @name kineRic-package
NULL

.onLoad <- function(libname, pkgname) {
    rJava::.jpackage(pkgname, lib.loc = libname,
                     morePaths = list.files(system.file('inst/java', package = pkgname), full.names = TRUE))
}
