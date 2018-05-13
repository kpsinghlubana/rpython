library(testthat)
#source("../OlapR_Setup.R")
TestArgs <- getOption("TestArgs")
test_that("End to End test for explore", {
  cnnstr <- TestArgs$connectionString
  cubeName <- TestArgs$cubeNameUnbracketed
  
  ocs <- OlapConnection(cnnstr)
  
  expect_equal(capture.output(explore(ocs)), c("Analysis Services Tutorial", "Internet Sales", "Reseller Sales", "Sales Summary"))
  expect_equal(capture.output(explore(ocs, cubeName)), c("Customer","Date","Due Date","Employee" ,"Internet Sales Order Details", "Measures","Product","Promotion","Reseller","Reseller Geography","Sales Reason","Sales Territory","Ship Date"))
  expect_equal(capture.output(explore(ocs, cubeName, "Measures")),"Measures")
  expect_equal(capture.output(explore(ocs, cubeName, "Measures", "Measures")),"MeasuresLevel")
  expect_equal(length(capture.output(explore(ocs, cubeName, "Measures", "Measures", "MeasuresLevel"))), 34)
  
  expect_equal(length(capture.output(explore(ocs, cubeName, "Product"))), 22)
  expect_equal(capture.output(explore(ocs, cubeName, "Product", "Size")), c("(All)", "Size"))
  expect_equal(length(capture.output(explore(ocs, cubeName, "Product", "Size", "Size"))),20)
})


test_that("End to End test for execute", {
  cnnstr <- TestArgs$connectionString
  cubeName <- TestArgs$cubeNameBracketed
  
  ocs <- OlapConnection(cnnstr)
    
  qry <- Query(validate = TRUE)
  cube(qry) <- cubeName
  
  columns(qry) <- c("[Measures].[Internet Sales Count]")
  rows(qry) <- c("[Product].[Product Line].[Product Line].MEMBERS") 
  pages(qry) <- "[Date].[Calendar Quarter].MEMBERS"
  
  flatcube <- execute2D(ocs, qry)
  
  names(flatcube) <- c("X1", "X2", "X3")
  cached2DResult = read.csv(paste0(TestArgs$testDirectory,"/cachedObjects/sampleQueryResult2d.csv"), row.names = 1, col.names = c("", "1", "2", "3"))
  

  expect_true(all(flatcube == cached2DResult, na.rm = TRUE))  #Test against cached result
  
  cube <- executeMD(ocs, qry)
  cachedMDResult <- scan(paste0(TestArgs$testDirectory,"/cachedObjects/sampleQueryResultmd.txt"))  
  
  expect_true(all(c(cube) == cachedMDResult, na.rm = TRUE))  #Test against cached result
})


test_that("End to End test for Validate", {
  cnnstr <- TestArgs$connectionString
  cubeName <- TestArgs$cubeNameBracketed
  
  ocs <- OlapConnection(cnnstr)
  
  qry <- Query(validate = TRUE)
  cube(qry) <- "invalid"
  
  columns(qry) <- c("[Measures].[Internet Sales Count]", "[Measures].[Internet Sales-Sales Amount]")
  rows(qry) <- c("[Prod].[Product Line].[Product Line].MEMBERS")   #Invalid Cube
  expect_error(capture.output(execute2D(ocs, qry)), "Query validation error")
  
  cube(qry) <- cubeName
  rows(qry) <- c("[Prod].[Product Line].[Product Line].MEMBERS")   #Invalid Dimension
  expect_error(capture.output(execute2D(ocs, qry)), "Query validation error")
  
  rows(qry) <- c("[Product].[Product].[Product Line].MEMBERS")   #Invalid Hierarchy
  expect_error(capture.output(execute2D(ocs, qry)), "Query validation error")
  
  rows(qry) <- c("[Product].[Product Line].[Prod Line].MEMBERS")   #Invalid Level
  expect_error(capture.output(execute2D(ocs, qry)), "Query validation error")
  
  rows(qry) <- c("[Product].[Product Line].[Product Line].[Radfe]")   #Invalid Member
  expect_error(capture.output(execute2D(ocs, qry)), "Query validation error")
  
  columns(qry) <- c("[Measures].[Internet Sales Count]", "[Measures].[Internet Sales Sales Amount]")  #Invalid Measure
  rows(qry) <- c("[Product].[Product Line].[Product Line].MEMBERS")
  expect_error(capture.output(execute2D(ocs, qry)), "Query validation error")
  
  columns(qry) <- c("[Measures].[Internet Sales Count]", "[Measures].[Internet Sales-Sales Amount]")  #Valid Query
  rows(qry) <- c("[Product].[Product Line].[Product Line].[Road]")
  flat <- execute2D(ocs, qry)
  expect_equal(NROW(flat), 1)
  expect_equal(NCOL(flat), 3)
  expect_equal(flat[[1]], "Road")
  expect_equal(flat[[2]], 15552)
})


