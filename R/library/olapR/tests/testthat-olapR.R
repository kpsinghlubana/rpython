# Script source before TestThat tests are run in shipR.

AnalysisServer<-''
if (AnalysisServer=='') AnalysisServer <- Sys.getenv("RTEST_SQL_SERVER")
if (AnalysisServer=='') AnalysisServer <- '.\\MRS'
if (AnalysisServer=='') AnalysisServer <- '.'
#cat("AnalysisServer='", AnalysisServer, "'\n", sep="")

workDir <- getwd()
repoRoot <- file.path(workDir,"")
testDirectory <- file.path(repoRoot, "..")

cnnstr <- paste0("Data Source=", AnalysisServer, "; Provider=MSOLAP;")
cubeNameBracketed <- "[Analysis Services Tutorial]"
cubeNameUnbracketed <- "Analysis Services Tutorial"

TestArgs <- list(
  # Compute context specifications
  gitRoot = repoRoot,
  testDirectory = testDirectory,
  connectionString = cnnstr,
  cubeNameBracketed = cubeNameBracketed,
  cubeNameUnbracketed = cubeNameUnbracketed
)  

options(TestArgs = TestArgs)
rm(TestArgs)

