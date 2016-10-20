#' Encrypt plain text via KMS
#' @param key KMS key ID, fully specified Amazon Resource Name or an alias with the \code{alias/} prefix
#' @param text max 4096 bytes long string
#' @return base64-encoded text
#' @export
#' @examples \dontrun{
#' kms_encrypt('alias/mykey', 'foobar')
#' }
kms_encrypt <- function(key, text) {

    ## prepare the request
    req <- .jnew("com.amazonaws.services.kms.model.EncryptRequest")
    req$setKeyId(key)
    req$setPlaintext(J('java.nio.ByteBuffer')$wrap(.jbyte(charToRaw(as.character(text)))))

    ## send to AWS
    client <- .jnew("com.amazonaws.services.kms.AWSKMSClient")
    cipher <- client$encrypt(req)$getCiphertextBlob()$array()

    ## encode and return
    base64_enc(cipher)

}


#' Decrypt cipher into plain text via KMS
#' @param cipher base64-encoded ciphertext
#' @return string
#' @export
kms_decrypt <- function(cipher) {

    ## prepare the request
    req <- .jnew("com.amazonaws.services.kms.model.DecryptRequest")
    req$setCiphertextBlob(J('java.nio.ByteBuffer')$wrap(.jbyte(base64_dec(cipher))))

    ## send to AWS
    client <- .jnew("com.amazonaws.services.kms.AWSKMSClient")
    rawToChar(client$decrypt(req)$getPlaintext()$array())

}
