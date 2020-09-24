## call the git credential system to store https 'github.com' credentials
setGitHubCredentials <- function (gitHubUsername, gitHubPassword) {
    creds = c(
        "protocol=https",
        "host=github.com",
        paste0("username=", gitHubUsername),
        paste0("password=", gitHubPassword),
        ""
    )

    return(system("git credential approve", input=creds, intern=TRUE))
}

## ask user to enter username and password, let them review, then call setGitHubCredentials()
interactiveSetGitHubCredentials <- function () {
    
    loop = 1
    gitHubUsername = ""
    gitHubPassword = ""

    while (loop) {
        gitHubUsername = readline("Enter your GitHub username: ")
        gitHubPassword = getPass::getPass("Enter your GitHub password: ")

        ans = readline("Would you like to review your GitHub username and password before caching them? [y/N/cancel]")

        if (tolower(ans) == 'cancel') {
            cat("Operation canceled\n")
            return()
        }

        if (ans == 'y' || ans == 'Y') {
            print(gitHubUsername)
            print(gitHubPassword)

            ans = readline("Are these correct? [y/N/cancel]")

            if (tolower(ans) == 'cancel') {
                cat("Operation canceled\n")
                return()
            }

            if (ans == 'y' || ans == 'Y') {
                loop = 0
            }
        } else {
            loop = 0
        }
    }

    return(setGitHubCredentials(gitHubUsername, gitHubPassword))
}

## call the git credential system to request https 'github.com' credentials
getGitHubCredentials <- function () {
    creds = c(
            "protocol=https",
            "host=github.com",
            ""
        )

    cachedCreds = system("git credential fill", input=creds, intern=TRUE)

    xSplit = strsplit(cachedCreds, split="=", fixed=TRUE)
    xNames = unlist(lapply(xSplit, FUN=function(v){return(v[1])}))
    xValues = unlist(lapply(xSplit, FUN=function(v){return(v[2])}))
    names(xValues) = xNames

    return(xValues)
}

## call the git credential system to request https 'github.com' credentials
## if not available, then ask the user to enter them manually
tryGetGitHubCredentials <- function () {

    ## TODO: implement me
    #creds = getGitHubCredentials()

    
}