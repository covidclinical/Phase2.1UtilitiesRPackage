# Phase2.1UtilitiesRPackage
This repository contians R utility functions for Phase 2.1 of the 4CE Consortium.

# Installation

To install this package in R:

``` R
devtools::install_github("https://github.com/covidclinical/Phase2.1UtilitiesRPackage", subdir="FourCePhase2.1Utilities", upgrade=FALSE)
```

# 4CE Phase 2.1 Project Overview

Every 4CE consortium Phase 2.1 project will be associated with 3 separate GitHub repositories.  One will contain the R code to implement the analysis,
and two will be used to store and organize the results from the analyses.  The repositories will be named according to this convention:

`Phase2.1[PROJECT_NAME]RPackage`: the repository that will contain the R code to run the project's analytics

`Phase2.1[PROJECT_NAME]RSummariesPrivate`: the repository where private summary data will be submitted 

`Phase2.1[PROJECT_NAME]RSummariesPublic`: the repository where public summary data will be stored


## Automated Project Creation

The R library (`FourCePhase2.1Utilities`) in this repository contains functions that can automatically create these repositories (both local copies and on GitHub) and pre-populate them with several useful files.  This library has been tested in the 4CE Docker container.  It may run in other R environments, 
exercise left to reader.

To get started, run the Docker container, making the parent directory of where you want to create the R 
package on the host available at `/RDevelopment` in the container.

Here I am just using `/tmp`, you will likely want to use something else:

```shell
docker run --rm --name 4ce -d -v /tmp:/RDevelopment \
                            -p 8787:8787 \
                            -p 2200:22 \
                            -e CONTAINER_USER_USERNAME=testuser \
                            -e CONTAINER_USER_PASSWORD=testpassword \
                            dbmi/4ce-analysis:latest
```

Either connect to the container via ssh and run R, e.g.:

```shell
ssh testuser@localhost -p 2200
R
```

Or connect to RStudio in a web browser (see container documentation).

The latest versions of the 4CE Docker container come pre-configured with this R library installed. To ensure that you have the latest version of this software, however, you should run the following in your R session in the container before proceeding:

``` R
devtools::install_github("https://github.com/covidclinical/Phase2.1UtilitiesRPackage", subdir="FourCePhase2.1Utilities", upgrade=FALSE)
```

In order to perform the following steps you **must** have been granted permission to create repositories under the [covidclinical GitHub organization](https://github.com/covidclinical).  Only members of the 4CE consortium will be granted this permission, and they should request it through the [phase-2 4CE slack channel](https://covidclinical.slack.com/archives/C012UTRHJCR).

In the rest of this example, we will create a new project called "MyAnalysis". This example is for illustrative purposes only.
You should replace "MyAnalysis" with the name of the project that you are creating before running the code.

After having installed the `FourCePhase2.1Utilities` R library (see above), you can begin the process of creating the repositories for the "MyAnalysis" project in your R session with the following command.
You will be prompted for your GitHub username and personal access token (PAT) as the repositories are created and pre-populated, and given the chance to review your credentials before proceeding.  For assistance creating a PAT, see [github documentation](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token).  This portion of the code is calling the GitHub API, which now requires the use of PATs in place of passwords.

```
FourCePhase2.1Utilities::createProject("MyAnalysis")
```

If you are using RStudio, you may receive a message that states "The R session is currently busy. Are you sure you want to quit?".  Respond to this by clicking "No".

This `createProject(...)` function call will generate all of the repositories required to support a 4CE Phase 2.1 project.  By default, 
the local copies of these repositories are created under `/RDevelopment/` in the container. You can provide an alternative location by specifying the `workingDirectory` argument to `createProject(...)`.

If for some reason the interaction with GitHub fails (e.g., you entered an incorrect password, or you do not have permission to create repositories under the covidclinical GitHub organization), you will receive error messages in R, and will need to delete the local directories that were created by `createProject()` before re-attempting to create the project.

You would now modify `runAnalysis()` and `validateAnalysis()` inside of the 
`Phase2.1MyAnalysisRPackage` repository.  There is no technical requirement for you to implement `validateAnalysis()`, it is there as a convenient location to do any error checking before the results are uploaded by `submitAnalysis()`.

Note that the R package lives in a subdirectory 
of the repository named `FourCePhase2.1[PROJECT_NAME]` (`FourCePhase2.1MyAnalysis` in our example). The `README.md` for your package comes pre-populated with example code to install your package in R from this subdirectory.  You can add as much additional supporting code as you would like 
to your package in additional files, or in the files for these three functions.  For more information on developing R packages in general, see http://r-pkgs.had.co.nz

The code for `submitAnalysis()` has been pre-populated for you.  You do not need to implement this function.  All of the analysis results get uploaded to the `Phase2.1[PROJECT_NAME]RSummariesPublic` GitHub repository by `submitAnalysis()`.  It works by cloning that repository from GitHub, creating a new branch for the site that is running the code, committing the analysis result files generated by `runAnalysis()` to the branch, then pushing the branch to GitHub.  GitHub credentials required to perform the `clone` and `push` are cached in the container using git's credential helper mechanism.  We have configured the container to use [git-credential-cache](https://git-scm.com/docs/git-credential-cache) to store credentials in-memory so that they are not written to the container's file system. The user is prompted in their R session to enter their username and password / PAT (either one will work for this purpose) using the getPass package. 

Once all of the sites have submitted their results, the project owner can merge these branches to run the meta-analysis.

`runAnalysis()` should implement your analytic workflow, then save the result files in the directory returned by calling `getProjectOutputDirectory()`.  The result files that get written to this directory need to adhere to the following naming convention in order for `submitAnalysis()` to function correctly:

`[SiteId]_[i].[extension]`

where `[SiteId]` is the site identifier stored in the `currSiteId` variable (extracted from the names of the site's input data files) at the beginning of `runAnalyasis()`; `[i]` is an index enumerating the various result files generated by your analytic workflow (this can be numeric or alpha,  multiple characters); `[extension]` is a file extension.  Even if the analysis only produces a single file, the name of the file must adhere to this convention, including the underscore and index string.

For example, if the analysis is being run at a site called "Harvard", and it produces two files, one with a table of summary results, and another with a set of model coefficients, then the files might be named as: `Harvard_SummaryTable.csv` and `Harvard_Coefficients.txt`.  When the package is run at the "Bordeaux" site, the files would be named `Bordeaux_SummaryTable.csv` and `Bordeaux_Coefficients.txt`.  `submitAnalysis()` will pick up both of these files and put them in branches of the `Phase2.1[PROJECT_NAME]RSummariesPublic` called `topic-Harvard` and `topic-Bordeaux`, respectively.

In the `Phase2.1MyAnalysisRPackage` example, for simplicity and illustration, we have commented out code that reads site level data in `runAnalysis()` (which would normally perform QC and extract the site identifier) and hard-coded a single site ID.  We then installed the package and ran all three `runAnalysis()`, `validateAnalysis()`, and `submitAnalysis()` functions, which pushed dummy result files to a branch in `Phase2.1MyAnalysisRSummariesPublic`.

For sites that need to run their analyses in isloated (no internet connectivity) environments, the container should be saved (see [README](https://github.com/covidclinical/Phase2.1DockerAnalysis) for the container) after the user runs `runAnalsyis()` and `validateAnalysis()`, but before running `submitAnalysis()`.  The default recommended location (see above) for the results of `runAnalsyis()` to be saved is local to the container's file system, so the result files will persist while the image is moved to a host with internet connectivity (but no access to sensitive patient-level site data) where the summary data can safely be pushed to the GitHub repository.

To help other consortium members understand and run your code, please include well-thought-out comments and documentation.  Please see http://r-pkgs.had.co.nz/man.html for information on documenting packages and functions using Roxygen.  

Once you are done developing your code, generate documentation using the devtools (Roxygen) package,
with the R working directory set to the package's directory. You don't need to run this in the same R
session as above, in fact, the remainder of this code works fine in RStudio.

Note that we are running this **inside the R package directory within the git repository**:

```
setwd("/RDevelopment/Phase2.1MyAnalysisRPackage/FourCePhase2.1MyAnalysis")
devtools::document()
```

The R package for your project is now ready to push to GitHub to become available to run at the 4CE sites, and you can do so using your 
tool of choice for working with git.  Since the local copies are stored on the docker host's 
storage (if you ran the container with a `-v` option specifying a host file system location, and used that location when calling `createProject(...)`), this can either be done inside the container, or in the host environemt.  If working
in the host environment, you would need to adjust file locations appropriately.

You should consider a more nuanced approach to source control, but to complete the example without 
additional complexity, we will assume that you are staging, committing, and pushing all of your 
code at once.
E.g., from the Linux command line in the container, we would:

Add your changes to staging:

```shell
cd /RDevelopment/Phase2.1MyAnalysisRPackage
git add -A
```

Now commit from within that same directory, substituting the *user.email*, *user.name*, and *message* values appropriately.  The user.email and user.name values can be configured at the environment level rather than specifying them explicitly in the commit invocation.  See git 
documentation for details.

```shell
git -c user.email="my.email@address.com" -c user.name="my name" commit -m "implemented runAnalysis, validateAnalysis, submitAnalysis and generated documentation"
```

You are now ready to push the updates to GitHub.  The repository has already been set up with an appropriate remote.

``` shell
git push -u origin master
```

If all of this has worked correctly, you should be able to visit:

<pre>https://github.com/covidclinical/Phase2.1[PROJECT_NAME]]RPackage</pre>

(https://github.com/covidclinical/Phase2.1MyAnalysisRPackage in our example)

and see the modifications that you pushed.  You can install your package using the code displayed on the README (main) page for the repository, e.g.:

```
devtools::install_github("https://github.com/covidclinical/Phase2.1MyAnalysisRPackage", subdir="FourCePhase2.1MyAnalysis", upgrade=FALSE)
```

Then, from an R session, the user can then invoke functions in your package such as:

```
FourCePhase2.1MyAnalysis::runAnalysis()
```
