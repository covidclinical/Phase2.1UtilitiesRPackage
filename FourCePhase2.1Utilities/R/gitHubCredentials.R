## This file contains functions to assist in working with the git credential manager.
## should probably eventually be factored out into a separate R package.

#' Call the git credential helper to store credentials.
#' 
#' @param protocol The protocol specification (e.g., "https") to be pased to the git credential helper
#' @param host The host specification (e.g., "github.com") to be pased to the git credential helper
#' @param username The username to be stored
#' @param password The password to be stored
#' 
#' @keywords 4CE
#' @export

setGitCredentials <- function (protocol, host, username, password) {
    creds = c(
        paste0("protocol=", protocol),
        paste0("host=", host),
        paste0("username=", username),
        paste0("password=", password),
        ""
    )

    return(invisible(system("git credential approve", input=creds, intern=TRUE)))
}

#' Ask user to enter username and password, let them review, then call 
#' setGitCredentials() to store it in the git credential manager.
#' 
#' @param protocol The protocol specification (e.g., "https") to be pased to the git credential helper
#' @param host The host specification (e.g., "github.com") to be pased to the git credential helper
#' 
#' @keywords 4CE
#' @export

interactiveSetGitCredentials <- function (protocol, host) {
    
    username = ""
    password = ""

    while (TRUE) {
        username = getPass::getPass(paste0("Enter your username for ", host, ": "))
        password = getPass::getPass(paste0("Enter your personal access token (see https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) for ", host, ": "))

        ans = readline("Would you like to review your username and password before caching them? [y/N/cancel] ")

        if (tolower(ans) == 'cancel') {
            cat("Operation canceled\n")
            return(invisible())
        }

        if (ans == 'y' || ans == 'Y') {
            cat("username: ", username, "\n")
            cat("password: ", password, "\n")

            ans = readline("Are these correct? [y/N/cancel] ")

            if (tolower(ans) == 'cancel') {
                cat("Operation canceled\n")
                return(invisible())
            }

            if (ans == 'y' || ans == 'Y') {
                break()
            }
        } else {
            break()
        }
    }

    return(invisible(setGitCredentials(protocol, host, username, password)))
}

#' Call the git credential system to request specified protocol / host credentials.
#' On success, it returns a named character vector with the requested credentials.
#' If the git credential helper fails to return the resutested credentials, it returns NA.
#' 
#' @param protocol The protocol specification (e.g., "https") to be pased to the git credential helper
#' @param host The host specification (e.g., "github.com") to be pased to the git credential helper
#' @keywords 4CE

queryGitCredentialHelper <- function(protocol, host) {

    ## input to the git credential manager
    creds = c(
            paste0("protocol=", protocol),
            paste0("host=", host),
            ""
    )

    ## temporary files to manage I/O from the system call
    tmpIn = tempfile()
    tmpOut = tempfile()
    tmpErr = tempfile()

    ## put the input to the credential manager in the temp file that will land on stdin
    writeLines(con = tmpIn, creds)

    # call the credential manager, need to run in a new session and set GIT_ASKPASS
    # to "" in order to supress prompt in both RStudio Server session and in R console
    gitAskpassTmp = Sys.getenv("GIT_ASKPASS")
    Sys.setenv(GIT_ASKPASS = "")

    sys::exec_wait(
        cmd="setsid", 
        args=c("git", "credential", "fill"), 
        std_in=tmpIn, 
        std_out=tmpOut,
        std_err=tmpErr)

    # reset environment variable to default value
    Sys.setenv(GIT_ASKPASS = gitAskpassTmp)

    ## retrieve whatever was left on STDOUT and STDERR
    cachedCreds = readLines(tmpOut)
    errMsg = readLines(tmpErr)
    
    ## if the credential manager threw a message into STDERR about not finding the username
    ## then return NA
    if (length(
            grep(
                x = errMsg,
                pattern = "fatal: could not read Username"
            )
        ) > 0) {
        return(NA)
    }

    ## otherwise parse the message written to STDOUT and return
    xSplit = strsplit(cachedCreds, split="=", fixed=TRUE)
    xNames = unlist(lapply(xSplit, FUN=function(v){return(v[1])}))
    xValues = unlist(lapply(xSplit, FUN=function(v){return(v[2])}))
    names(xValues) = xNames

    return(xValues)
}

#' Call the git credential system to request the specified protocl / host credentials.
#' If not available, then ask the user to enter them manually.
#' 
#' @param protocol The protocol specification (e.g., "https") to be pased to the git credential helper
#' @param host The host specification (e.g., "github.com") to be pased to the git credential helper
#' 
#' @keywords 4CE
#' @export

getGitCredentials <- function (protocol, host) {
    
    creds = queryGitCredentialHelper(protocol, host)

    if (is.na(creds[1])) {
        interactiveSetGitCredentials(protocol, host)
        creds = queryGitCredentialHelper(protocol, host)
    }
    
    return(creds)
}
