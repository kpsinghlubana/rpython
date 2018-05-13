######################################################################
############################# ETL ####################################
######################################################################


##############################################################
# data source to data source
##############################################################
etl1 <- function() {
  # The query to get the data
  qq <- "select top 10000 ArrDelay,CRSDepTime,DayOfWeek from AirlineDemoSmall"
  # The connection string
  conStr <- paste("Driver={SQL Server};Server=.;Database=RevoTestDB;",
                  "Trusted_Connection=TRUE;", sep = "")
  # The data source - retrieves the data from the database
  dsSqls <- RxSqlServerData(sqlQuery=qq, connectionString=conStr)
  # The destination data source
  dsSqls2 <- RxSqlServerData(table ="cleanData",  connectionString = conStr)
  # A transformation function
  transformFunc <- function(data) {
    data$CRSDepHour <- as.integer(trunc(data$CRSDepTime))
    return(data)
  }
  # The transformation variables
  transformVars <- c("CRSDepTime")
  # set the compute context
  sqlCompute <- RxInSqlServer(numTasks=4, connectionString=conStr)
  rxSetComputeContext(sqlCompute)

  # drop table if necessary
  if (rxSqlServerTableExists("cleanData")) {
    rxSqlServerDropTable("cleanData")
  }

  rxDataStep(inData = dsSqls,
             outFile = dsSqls2,
             transformFunc=transformFunc,
             transformVars=transformVars,
             overwrite = TRUE)
  return(NULL)
}

# check it works using the package
conStr <- "Driver={SQL Server};Server=.;Database=RevoTestDB;Trusted_Connection=TRUE;"
etlSP1 <- StoredProcedure(etl1, "spETL_ds_to_ds", filePath = "C:\\Users\\joz\\Documents\\Repos\\bigAnalytics\\sqlrutils\\extras\\sql_scripts", dbName ="RevoTestDB")
registerStoredProcedure(etlSP1, conStr)
executeStoredProcedure(etlSP1, connectionString = conStr)


##############################################################
# data source to data frame
##############################################################

etl2 <- function() {
  # The query to get the data
  qq <- "select top 10000 ArrDelay,CRSDepTime,DayOfWeek from AirlineDemoSmall"
  # The connection string
  conStr <- paste("Driver={SQL Server};Server=.;Database=RevoTestDB;",
                  "Trusted_Connection=TRUE;", sep = "")
  # The data source - retrieves the data from the database
  dsSqls <- RxSqlServerData(sqlQuery=qq, connectionString=conStr)
  # A transformation function
  transformFunc <- function(data) {
    data$CRSDepHour <- as.integer(trunc(data$CRSDepTime))
    return(data)
  }
  # The transformation variables
  transformVars <- c("CRSDepTime")
  # set the compute context
  sqlCompute <- RxInSqlServer(numTasks=4, connectionString=conStr)
  rxSetComputeContext(sqlCompute)

  dsSqls2 <- rxDataStep(inData = dsSqls,
                        transformFunc=transformFunc,
                        transformVars=transformVars,
                        overwrite = TRUE)
}
# check it works using the package
conStr <- "Driver={SQL Server};Server=.;Database=RevoTestDB;Trusted_Connection=TRUE;"
etlSP2 <- StoredProcedure(etl2, "spETL_ds_to_df", filePath = "C:\\Users\\joz\\Documents\\Repos\\bigAnalytics\\sqlrutils\\extras\\sql_scripts",
                       connectionString = conStr)
registerStoredProcedure(etlSP2)
ds2v2 <- executeStoredProcedure(etlSP2)
sp_file <- "C:\\Users\\joz\\Documents\\Repos\\bigAnalytics\\sqlrutils\\sqlrutils\\inst\\extdata/etl.RData"
save(etlSP2, etlSP1, file = sp_file )

######################################################################
########################### TRAINING #################################
######################################################################

############### data frame to data frame ##########################
train1 <- function(in_df) {
  in_df[,"DayOfWeek"] <- factor(in_df[,"DayOfWeek"], levels=c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"))
  # The model formula
  formula <- ArrDelay ~ CRSDepTime + DayOfWeek + CRSDepHour:DayOfWeek
  # Train the model
  rxSetComputeContext("local")
  mm <- rxLinMod(formula, data=in_df, transformFunc=NULL, transformVars=NULL)
  mm <- memCompress(serialize(mm, connection = NULL), type="gzip")
  return(data.frame(mm))
}

conStr <- "Driver={SQL Server};Server=.;Database=RevoTestDB;Trusted_Connection=TRUE;"
id = InputData("in_df", "select top 10000 ArrDelay,CRSDepTime,DayOfWeek,CRSDepHour from cleanData")
trainSP1 = StoredProcedure('train1', "spTrain_df_to_df", id,
                       dbName = "RevoTestDB",
                       connectionString = conStr, filePath = "C:\\Users\\joz\\Documents\\Repos\\bigAnalytics\\sqlrutils\\extras\\sql_scripts")
registerStoredProcedure(trainSP1)
model <- executeStoredProcedure(trainSP1)
result2v2 <- unserialize(model[1, 1] [[1]])
result2v2

############### 6. data frame to output parameter ##########################
train2 <- function(in_df) {
  in_df[,"DayOfWeek"] <- factor(in_df[,"DayOfWeek"], levels=c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"))
  # The model formula
  formula <- ArrDelay ~ CRSDepTime + DayOfWeek + CRSDepHour:DayOfWeek
  # Train the model
  rxSetComputeContext("local")
  mm <- rxLinMod(formula, data=in_df, transformFunc=NULL, transformVars=NULL)
  mm <- memCompress(serialize(mm, connection = NULL), type="gzip")
  return(list(mm = mm))
}

conStr <- "Driver={SQL Server};Server=.;Database=RevoTestDB;Trusted_Connection=TRUE;"
id <- InputData(name = "in_df", query = "select top 10000 ArrDelay,CRSDepTime,DayOfWeek,CRSDepHour from cleanData")
out <- OutputParameter("mm", "raw")
trainSP2 <- StoredProcedure(train2, "spTrain_df_to_op_2", id, out,
                       filePath = "C:\\Users\\joz\\Documents\\Repos\\bigAnalytics\\sqlrutils\\extras\\sql_scripts")
registerStoredProcedure(trainSP2, conStr)
executeStoredProcedure(trainSP2, id, connectionString = conStr)

sp_file <- "C:\\Users\\joz\\Documents\\Repos\\bigAnalytics\\sqlrutils\\sqlrutils\\inst\\extdata\\train.RData"
save(trainSP2, trainSP1, file = sp_file )

######################################################################
########################### SCORING ##################################
######################################################################

############### data - data frame, model - parameter, result to data frame
conStr <- "Driver={SQL Server};Server=.;Database=RevoTestDB;Trusted_Connection=TRUE;"
score1 <- function(indata, model_param, predVarName) {
  indata[,"DayOfWeek"] <- factor(indata[,"DayOfWeek"], levels=c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"))
  # stop(str(model_param))
  mm <- rxReadObject(as.raw(model_param))
  # Predict
  result <- rxPredict(modelObject = mm,
                      data = indata,
                      outData = NULL,
                      predVarNames = predVarName,
                      extraVarsToWrite = c("ArrDelay"),
                      writeModelVars = TRUE,
                      overwrite = TRUE)
  return(list(result = result))
}
id <- InputData(name = "indata", defaultQuery = "SELECT top 10 * from cleanData")
model<-InputParameter("model_param", "raw",
                       defaultQuery = paste("select top 1 value from rdata",
                                            "where [key] = 'linmod.v1'"))
out<-OutputData("result")
predVarName<-InputParameter("predVarName", "character")
scoreSP1<-StoredProcedure(score1, "spScore_df_param_df_3", id, model, out, predVarName,
                       filePath = "C:\\Users\\joz\\Documents\\Repos\\bigAnalytics\\sqlrutils\\extras\\sql_scripts")
registerStoredProcedure(scoreSP1, conStr)
executeStoredProcedure(scoreSP1, predVarName = "ArrDelayEstimate", connectionString = conStr)


# single row prediction
score2 <- function() {
  # The connection string
  conStr <- paste("Driver={SQL Server};Server=.;Database=RevoTestDB;",
                  "Trusted_Connection=TRUE;", sep = "")
  # The compute context
  computeContext <- RxInSqlServer(numTasks=4, connectionString=conStr)
  # Bring in the model
  ds <- RxSqlServerData(table = "rdata", connectionString = conStr)
  mm <- rxReadObject(ds, "linmod.v1", keyName = "[key]",
                     valueName = "[value]")
  # Predict
  df <- data.frame(DayOfWeek=factor(2, levels=c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")),
                   CRSDepTime=21.53, CRSDepHour=21)
  pred <- rxPredict(mm, df)
}

# check it works using the package
conStr <- "Driver={SQL Server};Server=.;Database=RevoTestDB;Trusted_Connection=TRUE;"
scoreSP2<-StoredProcedure(score2, "spScore_ds_ds_df2")
registerStoredProcedure(scoreSP2, conStr)
executeStoredProcedure(scoreSP2, connectionString = conStr)
sp_file<-"C:\\Users\\joz\\Documents\\Repos\\bigAnalytics\\sqlrutils\\sqlrutils\\inst\\extdata/score.RData"
save(scoreSP2, scoreSP1, file = sp_file )


######################################################################
#############INPUT AND OUTPUT PARAMS WITH SAME NAMES #################
######################################################################

fun <- function (in_df, x, y, z) {
  if (in_df[[1]] == 1) {
    in_df[[1]] <- 0
  }
  if (z) {
    z <- FALSE
  } else {
    z <- TRUE
  }
  return (list( in_df = in_df, x = x, y = y, z = z))
}
id <- InputData("in_df", defaultQuery = "SELECT 1")
ip1 <- InputParameter("x", "POSIXct", defaultQuery =
                        "Select top 1 my_date from Dates ")
t <- 1472562988
t <- as.POSIXct(t, "GMT", origin = "1960-01-01")
ip2 <- InputParameter("y", "POSIXct", defaultValue = t)
ip3 <- InputParameter("z", "logical", defaultValue = TRUE)
od <- OutputData("in_df")
op1 <- OutputParameter("x", "POSIXct")
op2 <- OutputParameter("y", "POSIXct")
op3 <- OutputParameter("z", "logical")
same_name_sp <- StoredProcedure("fun", "testSp2", id, ip1, ip2, ip3, od, op1, op2, op3,
                            filePath = "C:\\Users\\joz\\Documents\\Repos\\bigAnalytics\\sqlrutils\\extras\\sql_scripts")
registerStoredProcedure(same_name_sp, connectionString = conStr)
#executeStoredProcedure(same_name_sp, connectionString = conStr)
sp_file <- "C:\\Users\\joz\\Documents\\Repos\\bigAnalytics\\sqlrutils\\sqlrutils\\inst\\extdata/sameName.RData"
save(same_name_sp,  file = sp_file)
