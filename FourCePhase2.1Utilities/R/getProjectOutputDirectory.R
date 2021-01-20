#' Returns the name of the project's output directory. runAnalysis() should 
#' save its output here, and submitAnalysis() will expect to read from this location.
#' This function checks to make sure the location exists, and if not, creates it.
#'
#' @keywords 4CE

getProjectOutputDirectory <- function(){

    ## get the URL for the repository, we will strip out the project name
    dataRepositoryUrl = getPublicSummaryRepositoryUrl()
	repositoryName = gsub(
		x = gsub(
			x = dataRepositoryUrl, 
			pattern="https://github.com/covidclinical/", 
			fixed=TRUE, 
			replacement=""), 
		pattern=".git", 
		fixed=TRUE, 
		replacement="")
	
	projectName = gsub(x = repositoryName, pattern = "SummariesPublic", replacement = "", fixed = TRUE)
	
    ## concatenate project name to global 4CE output directory
    dirName = file.path(
        FourCePhase2.1Data::getContainerScratchDirectory(),
        projectName
    )

	if (!dir.exists(dirName)) {
		dir.create(dirName)
	}

	return(dirName)
}
