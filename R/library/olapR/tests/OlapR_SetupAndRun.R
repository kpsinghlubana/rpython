library(olapR)

########
### Setup and Run the Distributed Computing Unit test suite
###
### Running the tests:
### 1. Set the parameters specified below at the command line or in a script
### 2. edit the test configuration file that you specify in the parameters as needed
### 3. source this file  

# set the platform type
library(RUnit)
library(rpart)
library(lattice)
library(methods)

library(testthat)


AnalysisServer<-''
if (AnalysisServer=='') AnalysisServer <- Sys.getenv("RTEST_SQL_SERVER")
if (AnalysisServer=='') AnalysisServer <- '.\\MRS'
if (AnalysisServer=='') AnalysisServer <- '.'
cat("AnalysisServer='", AnalysisServer, "'\n", sep="")

print(AnalysisServer)
endToEndTests <- TRUE

workDir <- getwd()
repoRoot <- file.path(workDir,"dependencies")
testDirectory <- file.path(repoRoot, "OlapTests")

cnnstr <- paste0("Data Source=", AnalysisServer, "; Provider=MSOLAP;")
#cnnstr <- "Data Source=.\\MRS; Provider=MSOLAP;"
cubeNameBracketed <- "[Analysis Services Tutorial]"
cubeNameUnbracketed <- "Analysis Services Tutorial"


rxTestArgs <- list(
  # Compute context specifications
  gitRoot = repoRoot,
  testDirectory = testDirectory,
  connectionString = cnnstr,
  cubeNameBracketed = cubeNameBracketed,
  cubeNameUnbracketed = cubeNameUnbracketed,
  consoleOutput = FALSE,
  wait = TRUE,
  autoCleanup = TRUE,
  ### Additional args for tests
  rxTestOdbc = FALSE,
  rxHaveWritePermission = TRUE  # Set to FALSE to run only tests that read data
)  

options(rxTestArgs = rxTestArgs)
rm(rxTestArgs)
# Run the tests 
testDir <- TestArgs$testDirectory
testFileRegexp <- "runTests.R$"
testFuncRegexp <- "^test.+" 
suiteName <- "OlapR Tests"
filename <- NULL

# load needed libraries
require("RUnit", quietly = TRUE) || stop("RUnit package must be loaded to execute tests.")

# change the options for RUnit so that the names of the tests are printed as it is run
RUnit_opts <- getOption("RUnit", list())
RUnit_opts$verbose <- 1L
RUnit_opts$silent <- TRUE
RUnit_opts$verbose_fail_msg <- TRUE
options(RUnit = RUnit_opts)


# Set up test suite
if (is.null(testDir)) stop("The directory to the tests, testDir, must be specified." )
testDirs <- file.path(testDir)	
testSuite <- RUnit::defineTestSuite(name = "OlapTests", testFileRegexp = testFileRegexp , 
                                    testFuncRegexp = testFuncRegexp, 
                                    dirs = testDirs, rngKind = "default", rngNormalKind = "default")
if (!RUnit::isValidTestSuite(testSuite)) 
{
  print(testSuite)
  stop("FAILED! Test Suite is not valid")
}

testResult <- RUnit::runTestSuite(testSuite)
saveRDS(testResult, "testResult.rds")

RUnit::printTextProtocol(testResult, showDetails=FALSE)
RUnit::printTextProtocol(testResult,file.path(paste(filename,"txt",sep=".")))



