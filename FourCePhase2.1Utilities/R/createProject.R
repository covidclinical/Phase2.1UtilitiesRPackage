#' Creates repository infrastructure for a 4CE Phase 2.1 Project.  Creates local repositories,
#' prompts for a GitHub username, and tries to create the corresponding GitHub repositories
#' and push inital contents.
#'
#' @param projectName The name of the project.  Will be used to create correlated repository names.
#' @param workingDirectory The directory in which the project repositories will be created.
#' 
#' @keywords 4CE
#' @export

createProject <- function (projectName, workingDirectory="/RDevelopment") {

    phaseName = "Phase2.1"

    ## names for the directories to be created
    rPackageRespositoryName = paste(
        sep = "", 
        phaseName,
        projectName,
        "RPackage"
    )

    privateSummariesRepositoryName = paste(
        sep = "", 
        phaseName,
        projectName,
        "RSummariesPrivate"
    )

    publicSummariesRepositoryName = paste(
        sep = "", 
        phaseName,
        projectName,
        "RSummariesPublic"
    )

    ## R package repository
    rPackageParentRepositoryPath = 
        file.path(
            workingDirectory, 
            rPackageRespositoryName
        )

    ## site data repository
    privateSummariesRepositoryPath = 
        file.path(
            workingDirectory, 
            privateSummariesRepositoryName
        )

    ## country data repository
    publicSummariesRepositoryPath = 
        file.path(
            workingDirectory, 
            publicSummariesRepositoryName
        )

    if (dir.exists(rPackageParentRepositoryPath)) {
        stop(rPackageParentRepositoryPath, " already exists!")
    }   
    
    if (dir.exists(privateSummariesRepositoryPath)) {
        stop(privateSummariesRepositoryPath, " already exists!")
    }
    
    if (dir.exists(publicSummariesRepositoryPath)) {
        stop(publicSummariesRepositoryPath, " already exists!")
    }

    ## create the directories for the repositories
    dir.create(rPackageParentRepositoryPath)
    dir.create(privateSummariesRepositoryPath)
    dir.create(publicSummariesRepositoryPath)

    ## add READMEs
    writeReadmeMd(
        projectName = rPackageRespositoryName, 
        workingDirectory = rPackageParentRepositoryPath, 
        message = paste(
            sep="", 
            "R code to run, validate, and submit the analysis for the ", projectName, " project.\n\n",
            "To install this package in R:\n\n",
            "```\n",
            "devtools::install_github(\"https://github.com/covidclinical/", 
                rPackageRespositoryName, 
                "\", subdir=\"", 
                "FourCe",
                phaseName,
                projectName,
                "\", upgrade=FALSE)\n",
            "```\n")
    )

    writeReadmeMd(
        projectName = privateSummariesRepositoryName, 
        workingDirectory = privateSummariesRepositoryPath, 
        message = paste(sep="", "Private summary data repository for the ", projectName, " project.")
    )

    writeReadmeMd(
        projectName = publicSummariesRepositoryName, 
        workingDirectory = publicSummariesRepositoryPath, 
        message = paste(sep="", "Public summary data repository for the ", projectName, " project.")
    )

    ## directory in which the R package will be built under the Git repository
    rPackagePath = file.path(
        rPackageParentRepositoryPath,
        paste(
            sep = "",
            "FourCe", 
            phaseName,
            projectName
        )
    )

    ## create the R package inside of that directory
    usethis::create_package(
        path = rPackagePath
    )

    ## create the three required stubs for the R package
    createPhase2.1Stubs(projectName, rPackagePath, privateSummariesRepositoryName, publicSummariesRepositoryName)

    ## initialize git repositories
    doInitializeAddCommit(rPackageParentRepositoryPath)
    doInitializeAddCommit(privateSummariesRepositoryPath)
    doInitializeAddCommit(publicSummariesRepositoryPath)

    ## create GitHub repositories and push
    createGitHubRepositoryAndPush(rPackageRespositoryName, rPackageParentRepositoryPath, private=FALSE)
    createGitHubRepositoryAndPush(privateSummariesRepositoryName, privateSummariesRepositoryPath, private=TRUE)
    createGitHubRepositoryAndPush(publicSummariesRepositoryName, publicSummariesRepositoryPath, private=TRUE)
}

#' Returns the text of the empty R function call stub for the project 
#'
#' @param projectName The name of the project.
#' @param functionName The name of the function to be emitted.
#' @param commentPreamble The preamble of the comments to be emitted.
#' @param functionBody Any text to be included in the function body.

emit4CeFunctionStub <- function (projectName, functionName, commentPreamble, functionBody="") {
    return(
        paste(
            sep="",
            "
#' ", commentPreamble, " for the ", projectName, " project
#'
#' @keywords 4CE
#' @export

", functionName ," <- function() {
", functionBody, "
}
"
        )
    )
}

#' Writes the result of calling emit4CeFunctionStub to a file named functionName.R
#'
#' @param projectName The name of the project.
#' @param functionName The name of the function to be emitted.
#' @param commentPreamble The preamble of the comments to be emitted.
#' @param workingDirectory The working directory into which the file will be written
#' @param functionBody Any text to be included in the function body.

emit4CeFunctionStubToFile <- function (projectName, functionName, commentPreamble, workingDirectory, functionBody="") {

    writeLines(
        emit4CeFunctionStub(
            projectName=projectName, 
            functionName=functionName, 
            commentPreamble=commentPreamble,
            functionBody=functionBody
        ), 
        con=file.path(workingDirectory, "R", paste(sep="", functionName, ".R"))
    )
}

#' Creates R function stubs for a 4CE Project 
#'
#' @param projectName The name of the project.
#' @param workingDirectory The directory in which the code stubs will be written.
#' @param privateSummariesRepositoryName The name of the repository for the private summary data for this project.
#' @param publicSummariesRepositoryName The name of the repository for the public summary data for this project.

createPhase2.1Stubs <- function (projectName, workingDirectory, privateSummariesRepositoryName, publicSummariesRepositoryName) {

    runAnalysisFunctionBody = '
    ## make sure this instance has the latest version of the quality control and data wrangling code available
    devtools::install_github("https://github.com/covidclinical/Phase2.1DataRPackage", subdir="FourCePhase2.1Data", upgrade=FALSE)

    ## get the site identifier assocaited with the files stored in the /4ceData/Input directory that 
    ## is mounted to the container
    currSiteId = FourCePhase2.1Data::getSiteId()

    ## run the quality control
    FourCePhase2.1Data::runQC(currSiteId)

    ## DO NOT CHANGE ANYTHING ABOVE THIS LINE
    ## To Do: implement analytic workflow, saving results to a site-specific 
    ## file to be sent to the coordinating site later via submitAnalysis()
    '

    ## runAnalysis()
    emit4CeFunctionStubToFile(
        projectName=projectName, 
        functionName="runAnalysis", 
        workingDirectory=workingDirectory,
        commentPreamble="Runs the analytic workflow",
        functionBody=runAnalysisFunctionBody
    )

    ## validateAnalysis()
    emit4CeFunctionStubToFile(
        projectName=projectName, 
        functionName="validateAnalysis", 
        workingDirectory=workingDirectory,
        commentPreamble="Validates the results of the analytic workflow",
        functionBody="\t#TODO: implement validation"
    )

    ## TODO: add code to push result files to github; may require too much bookkeeping w.r.t. generated files
    ## submitAnalysis()
    emit4CeFunctionStubToFile(
        projectName=projectName, 
        functionName="submitAnalysis",
        workingDirectory=workingDirectory, 
        commentPreamble="Submits the results of the analytic workflow",
        functionBody="\t#TODO: implement data submission"
    )

    ## submitAnalysis()
    emit4CeFunctionStubToFile(
        projectName=projectName, 
        functionName="submitAnalysis",
        workingDirectory=workingDirectory, 
        commentPreamble="Submits the results of the analytic workflow",
        functionBody="\t#TODO: implement data submission"
    )

    ## getPrivateSummaryRepositoryUrl()
    emit4CeFunctionStubToFile(
        projectName=projectName, 
        functionName="getPrivateSummaryRepositoryUrl",
        workingDirectory=workingDirectory, 
        commentPreamble="Returns the GitHub URL of the Private Summary Repository for this project",
        functionBody=paste(sep="", "\treturn(\"https://github.com/covidclinical/", privateSummariesRepositoryName, ".git\")")
    )

    ## getPublicSummaryRepositoryUrl()
    emit4CeFunctionStubToFile(
        projectName=projectName, 
        functionName="getPublicSummaryRepositoryUrl",
        workingDirectory=workingDirectory, 
        commentPreamble="Returns the GitHub URL of the Public Summary Repository for this project",
        functionBody=paste(sep="", "\treturn(\"https://github.com/covidclinical/", publicSummariesRepositoryName, ".git\")")
    )
}

#' Writes a placeholder README.md for a git repository
#'
#' @param projectName The name of the git repository
#' @param workingDirectory The directory in which the README.md will be written.

writeReadmeMd <- function(projectName, workingDirectory, message="") {

    writeLines(
        con=file.path(workingDirectory, "README.md"),
        paste(sep="",
"# ", projectName, "
", message, "
"
        )
    )
}


#' Given a path to a directory, this function initialzies a new Git repository there,
#' then adds all of the current contents and does an initial commit.
#'
#' @param repositoryPath The path to the directory that will become the git repository

doInitializeAddCommit <- function(repositoryPath) {
    
    ## init the repository
    system(
        paste(
            sep = "",
            "git init ", repositoryPath
        )
    )

    ## save current directory and change to the specified working directory
    originalDirectory = getwd()
    setwd(repositoryPath)

    ## add the current directory contents and run an initial commit
    system(
        paste(sep="", "git add . ", repositoryPath, "; git -c user.email=\"4CE@i2b2transmart.org\" -c user.name=\"4CE Consortium\" commit -m \"auto generated initial commit\"")
    )

    ## return to the directory we were in when we started
    setwd(originalDirectory)
}

#' Given a path to a directory that contians a local Git repository,
#' this function uses the GitHub web API to create a new repository under
#' the covidclinical organization, adds it as a remote to the local repository,
#' and pushes to the new GitHub remote.
#'
#' @param repositoryName The name of the repository
#' @param repositoryPath The path to the directory that contains the local git repository

createGitHubRepositoryAndPush <- function(repositoryName, repositoryPath, private=FALSE) {

    ## use the git credential helper to retrieve (and store, if necessary) username and password
    credentials = getGitCredentials(protocol = "https", host = "github.com")

    ## if that failed, report an error
    if (is.na(credentials[1])) {
        stop("Unable to retrieve / store git credentials.")
    }

    username = credentials["username"]
    password = credentials["password"]

    ## use GitHub API to create the remote
    if (private) {
        system(
            paste(
                sep="",
                "curl -u '", username, ":", password, "' https://api.github.com/orgs/covidclinical/repos -d '{\"name\":\"", repositoryName, "\", \"private\":true}'"
            )
        )
    } else {
        system(
            paste(
                sep="",
                "curl -u '", username, ":", password, "' https://api.github.com/orgs/covidclinical/repos -d '{\"name\":\"", repositoryName, "\"}'"
            )
        )
    }

    ## add the remote
    originalDirectory = getwd()
    setwd(repositoryPath)
    system(
        paste(
            sep="",
            "git remote add origin https://github.com/covidclinical/", repositoryName, ".git"
        )
    )

    ## push (git should use cached credentials here)
    system("git push -u origin master")
    
    ## return to the directory we were in when we started
    setwd(originalDirectory)
}