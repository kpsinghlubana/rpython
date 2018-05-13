library(olapR)

test_that("OlapConnection class works properly", {
  ocs <- OlapConnection()
  expect_true(is.OlapConnection(ocs))
  expect_false(is.OlapConnection(1))
  expect_equal(ocs$cnn, "Data Source=localhost; Provider=MSOLAP;")
  
  expect_error(OlapConnection(connectionString = NULL), "cnn must be passed as a string")
  expect_warning(OlapConnection("Data Source=localhost;"), "cnn must contain 'Provider=MSOLAP;'")
  #expect_warning(OlapConnection("Provider=MSOLAP;"), "cnn must contain 'Data Source=[a data source];'")
  
  ocs <- OlapConnection("Provider =MSOLAP; Data Source= localhost; asdfase= adfeasdf; ae =a sadf")
  expect_equal(ocs$cnn, "Provider =MSOLAP; Data Source= localhost; asdfase= adfeasdf; ae =a sadf")
})


test_that("Query class works properly", {
  qry <- Query()
  expect_equal(qry$vldt, FALSE)
  qry <- Query(validate=TRUE)
  expect_equal(qry$vldt, TRUE)
  
  expect_true(is.Query(qry))
  expect_false(is.Query(1))
  
  cube <- "[Analysis Services Tutorial]"
  cube(qry) <- cube
  
  cols <- c("[Measures].[Reseller Sales Count]", "[Measures].[Reseller Sales-Sales Amount]")
  columns(qry) <- cols
  
  rows <- c("[Product].[Product Line].CHILDREN")
  rows(qry) <- rows
  
  pages <- c("[Sales Reason].[Sales Reasons].[Marketing].CHILDREN")
  pages(qry) <- pages
  
  chapters <- c("[Sales Territory].[Sales Territory Region].CHILDREN")
  chapters(qry) <- chapters
  
  sections <- c("[Date].[Calendar Year].[CY 2006]", "[Date].[Calendar Year].[CY 2007]", "[Date].[Calendar Year].[CY 2008]")
  axis(qry, 5) <- sections
  
  slicers <- c("[Sales Territory].[Sales Territories].[Sales Territory Region].[Northwest]")
  slicers(qry) <- slicers
  
  expect_equal(cube(qry), cube)
  expect_equal(columns(qry), cols)
  expect_equal(rows(qry), rows)
  expect_equal(pages(qry), pages)
  expect_equal(axis(qry, 5), sections)
  expect_equal(slicers(qry), slicers)
  
  lst <- list(1, 2, "asdf")
  expect_error(cube(lst), "attempt to access 'cube' on object that is not a Query")
  expect_error(columns(lst), "attempt to access 'columns' on object that is not a Query")
  expect_error(rows(lst), "attempt to access 'rows' on object that is not a Query")
  expect_error(pages(lst), "attempt to access 'pages' on object that is not a Query")
  expect_error(axis(lst), "attempt to access 'axis' on object that is not a Query")
  expect_error(slicers(lst), "attempt to access 'slicers' on object that is not a Query")
  
  x <- c("asdf")
  expect_error(cube(lst) <- x, "attempt to access 'cube' on object that is not a Query")
  expect_error(columns(lst) <- x, "attempt to access 'columns' on object that is not a Query")
  expect_error(rows(lst) <- x, "attempt to access 'rows' on object that is not a Query")
  expect_error(pages(lst) <- x, "attempt to access 'pages' on object that is not a Query")
  expect_error(axis(lst) <- x, "attempt to access 'axis' on object that is not a Query")
  expect_error(slicers(lst) <- x, "attempt to access 'slicers' on object that is not a Query")
  
  expect_equal(compose(qry), "SELECT {[Measures].[Reseller Sales Count], [Measures].[Reseller Sales-Sales Amount]} ON AXIS(0), {[Product].[Product Line].CHILDREN} ON AXIS(1), {[Sales Reason].[Sales Reasons].[Marketing].CHILDREN} ON AXIS(2), {[Sales Territory].[Sales Territory Region].CHILDREN} ON AXIS(3), {[Date].[Calendar Year].[CY 2006], [Date].[Calendar Year].[CY 2007], [Date].[Calendar Year].[CY 2008]} ON AXIS(4) FROM [Analysis Services Tutorial] WHERE {[Sales Territory].[Sales Territories].[Sales Territory Region].[Northwest]}")
  
  expect_error(compose(lst), "attempt to access 'compose' on object that is not a Query")
  columns(qry) <- c("")
  expect_error(compose(qry), "Columns must be set, and cannot contain blank entries")
  columns(qry) <- cols
  pages(qry) <- c("asdf", "")
  expect_error(compose(qry), "Axes cannot contain blank entries")
  pages(qry) <- pages
  cube(qry) <- c("")
  expect_error(compose(qry), "A single Cube must be set")
  cube(qry) <- c("[Analysis Services Tutorial]", "[AdventureWorks]")
  expect_error(compose(qry), "A single Cube must be set")

})


test_that("Execute and Validate work correctly", {
  expect_error(execute2D(NULL, Query()))
  expect_error(execute2D(OlapConnection(), NULL))
  expect_error(executeMD(NULL, Query()))
  expect_error(executeMD(OlapConnection(), NULL))
  expect_error(validateQuery(NULL, Query()))
  expect_error(validateQuery(OlapConnection(), NULL))
})


test_that("Explore works correctly", {
  expect_error(explore(NULL), "olapCnn must be of class 'OlapConnection'")
  
  ocs <- OlapConnection()
  expect_error(explore(ocs, NA), "cube must be either null or a string")
  expect_error(explore(ocs, "Analysis Services Tutorial", NA), "dimension must be either null or a string")
  expect_error(explore(ocs, "Analysis Services Tutorial", "Product", NA), "hierarchy must be either null or a string")
  expect_error(explore(ocs, "Analysis Services Tutorial", "Product", "Product Categories", NA), "level must be either null or a string")
})


test_that("dll helper function debracketize works correctly", {
  expect_equal(olapR:::debracketize("testword"), "testword")
  expect_equal(olapR:::debracketize("testword]"), "testword]")
  expect_equal(olapR:::debracketize("[testword"), "[testword")
  expect_equal(olapR:::debracketize("[testword]"), "testword")
  expect_equal(olapR:::debracketize("[]"), "")
  expect_equal(olapR:::debracketize(""), "")
})


test_that("dll helper functions R_TRUE and R_FALSE work correctly", {
  expect_true(olapR:::rTrue())
  expect_false(olapR:::rFalse())
})


test_that("dll helper functions extractComponent and trimRemainder work correctly", {
  testString <- "[Sales Territory].[Sales Territories].[Sales Territory Region].[Northwest]"
  
  expect_equal(olapR:::extractComponent(testString), "[Sales Territory]")
  testString <- olapR:::trimRemainder(testString)
  expect_equal(testString, "[Sales Territories].[Sales Territory Region].[Northwest]")
  
  expect_equal(olapR:::extractComponent(testString), "[Sales Territories]")
  testString <- olapR:::trimRemainder(testString)
  expect_equal(testString, "[Sales Territory Region].[Northwest]")
  
  expect_equal(olapR:::extractComponent(testString), "[Sales Territory Region]")
  testString <- olapR:::trimRemainder(testString)
  expect_equal(testString, "[Northwest]")
  
  expect_equal(olapR:::extractComponent(testString), "[Northwest]")
  testString <- olapR:::trimRemainder(testString)
  expect_equal(testString, "")
})


test_that("dll helper function calculateNumberOfCells works correctly", {
  expect_equal(olapR:::calculateNumberOfCells(c(1, 5, 2, 8)), 80)
  expect_equal(olapR:::calculateNumberOfCells(c(-1, 5, 2, 8)), -80)
  expect_equal(olapR:::calculateNumberOfCells(c(5, 9, 15)), 675)
  expect_equal(olapR:::calculateNumberOfCells(c(0, 2, 5, 7, 2)), 0)
  expect_equal(olapR:::calculateNumberOfCells(c(3, 17)), 51)
})




