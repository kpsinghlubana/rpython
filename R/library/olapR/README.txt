OlapR is an R Package that allows for data to be imported from OLAP cubes stored in SQL Server Analysis Services into R. 
OlapR specifically generates MDX queries for the user with a simple, R style API, allowing for easy query authoring and validation even without 
complete knowledge of the MDX language. Although OlapR does not provide this API for all MDX scenarios, all of the most common and useful 
slice, dice, drilldown, rollup, and pivot scenarios in N dimensions are available through OlapR. For anything that is too complex for OlapR to handle,
the user can input a direct MDX query and OlapR will handle passing and executing that query on the Analysis Services server.

Main Features:
- Explore the cube metadata
- Create query objects
	- Set cube, columns, rows, pages, slicers, etc.
- Execute and (optionally) validate queries
	- Results can be a multidimensional R array or...
	- Results can be flattened into 2D and returned in a data.frame
	

Pre-requisites

- R

- SQL Server Analysis Services (we have tested with SSAS 2016 RTM on Windows 10). 

- If you want to run the demos mentioned below, you will need the Analysis Services Tutorial cube. This is included as a backup file "OlapTest.abf".
	You can simply restore the included "OlapTest.abf" file into your Analysis Services Server in Sql Server Management Studio (SSMS). 
		- To restore the file, open an Administrator instance of SSMS. Connect to your Analysis Services database, right click on "databases" and click "Restore".
			Then, in the backup file space, put the path to OlapTest.abf on your machine. Click OK. Refresh your database (right-click -> refresh) and make sure Analysis Services Tutorial is in the Databases folder.

Installation steps
  1.	Build the OlapR package in R:
		- Navigate to the OlapR folder in an Administrator command prompt
		- Use the command "R CMD INSTALL olapR_0.0.0.9001.zip" - this should install the OlapR package into your R library.
  
  2.	Run simple tests to validate your installation and connection. Sample code below (Replace Data Source, Cube, etc as appropriate). 
	If you do not want to write your own tests, you can just try the FullDemo.R included in the package (in the tests folder).
  
			library(olapR)

			cnnstr <- "Data Source=localhost; Provider=MSOLAP;"
			ocs <- OlapConnection(cnnstr)
		  
			#Query objects can be constructed and passed to execute
			
			qry <- Query(validate = TRUE)
			cube(qry) <- "[Analysis Services Tutorial]"

			columns(qry) <- c("[Measures].[Internet Sales Count]", "[Measures].[Internet Sales-Sales Amount]")
			rows(qry) <- c("[Product].[Product Line].[Product Line].MEMBERS") 
			pages(qry) <- c("[Sales Territory].[Sales Territory Region].[Sales Territory Region].MEMBERS")
			chapters(qry) <- "[Date].[Calendar Quarter].MEMBERS"

			cube <- executeMD(ocs, qry)
			
			###########################################
			
			#Or pure MDX queries can be passed to execute
			
			mdx <- "SELECT {[Measures].[Internet Sales Count]} ON COLUMNS, [Product].[Model Name].MEMBERS ON ROWS
					FROM [Analysis Services Tutorial] WHERE [Date].[Calendar Year].[Calendar Year].[CY 2007];"
			flatcube <- execute2D(ocs, mdx)
			
			###########################################
			
			explore(ocs, "Analysis Services Tutorial", "Product", "Size", "Size")
  
  3.	For more information regarding olapR functions, please see olapR R documentation (??olapR)

