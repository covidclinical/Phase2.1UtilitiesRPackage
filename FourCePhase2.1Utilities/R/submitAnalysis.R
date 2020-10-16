
#' Submits the results of the analytic workflow for the project
#' 
#' @keywords 4CE

submitAnalysis <- function() {
	
	workDirectory = FourCePhase2.1Data::getContainerScratchDirectory()

	## the file to submit for this project should reside at 
	projectOutputFiles = list.files(getProjectOutputDirectory(), full.names=TRUE)

	## there needs to be at least one
	if (length(projectOutputFiles) == 0) {
		stop("There are no files present in ", getProjectOutputDirectory())
	}

	## output naming convention is SiteId_i.txt
	fileNameParse = lapply(
		X=projectOutputFiles, 
		FUN=function(fname){
			return(
				strsplit(
					x=fname, 
					split=.Platform$file.sep, 
					fixed=TRUE
				)[[1]]
			)
		}
	)

	outputFileNames = unlist(lapply(X=fileNameParse, FUN=function(v){return(v[length(v)])}))
	siteIds = unlist(lapply(X=strsplit(outputFileNames, split="_"), FUN=function(v){return(v[1])}))

	if (length(unique(siteIds)) == 0) {
		stop("The output files are improperly named.")
	}
	if (length(unique(siteIds)) > 1) {
		stop("There are output files for multiple sites in ", getProjectOutputDirectory())
	}

	## remember the site identifier, we'll use this to name the git branch below
	siteId = unique(siteIds)

	## remember which directory we started working in so we can switch back later
	originalDirectory = getwd()

	## get git credentials to make sure the credential helper cache is warm
	credentials = FourCePhase2.1Utilities::getGitCredentials(protocol="https", host="github.com")

	if (is.na(credentials[1])) {
		stop("There was a problem retrieving the GitHub user credentials.")
	}

	## clone the data submission repository locally
	dataRepositoryUrl = getPublicSummaryRepositoryUrl()
	repositoryName = gsub(
		x = gsub(
			x = dataRepositoryUrl, 
			pattern="https://github.com/covidclinical/", 
			fixed=TRUE, 
			replace=""), 
		pattern=".git", 
		fixed=TRUE, 
		replace="")
	localRepositoryDirectory = file.path(workDirectory, repositoryName)
	system(
        paste0("git clone ", dataRepositoryUrl, " ", localRepositoryDirectory)
    )

	## create a new branch named after the site identifier
	setwd(localRepositoryDirectory)
	branchName = paste0("topic-", siteId)

	## check whether there is already a branch for this site on the remote
	branches = system(paste0("git branch -a"), intern=TRUE)
	branchIx = grep(branches, pattern=paste0("origin/", branchName), fixed=TRUE)

	## if there is one, check it out
	if (length(branchIx) == 1) {
		system(
			paste0("git checkout ", branchName)
		)
	}
	else {
		system(
			paste0("git branch ", branchName)
		)

		## checkout new branch
		system(
			paste0("git checkout ", branchName)
		)

		## push the new branch to the remote
		system(
				paste0("git push --set-upstream origin ", branchName)
		)
	}

	## add site's result files to branch
	## projectOutputFiles contains fully-qualified file names
	## outputFileNames contains just file names without prefix directories
	for (i in 1:length(projectOutputFiles)) {
		system(
			paste0("cp ", projectOutputFiles[i], " ./", outputFileNames[i])
		)
		system(
			paste0("git add ", outputFileNames[i])
		)
	}

	## commit
	system(
		paste0(
			"git -c user.email=\"4CE@i2b2transmart.org\" -c user.name=\"4CE Consortium\" commit -m \"added ",  siteId," result files \""
		)
    )

	## push to the remote
	system(
		paste0("git push")
	)

	## return to original directory
	setwd(originalDirectory)
}

