
makePackage <- function(packageName, assignList = list(), aggregateList = list(), symbols = list(), clientPrefix = 'ds.', serverSuffix = 'DS',
                        authors = 'person("Iulian", "Dragan", email = "iulian.dragan@sib.swiss", role = c("aut", "cre"))',
                        license = NULL, destPath = '.'){
  # restart every time:
  clientPackageName <- paste0(packageName, 'Client')
  unlink(paste0(tempdir(), '/', packageName), recursive = TRUE)
  unlink(paste0(tempdir(), '/', clientPackageName), recursive = TRUE)
  serverDir <- paste0(tempdir(), '/', packageName)
  clientDir <- paste0(tempdir(), '/', clientPackageName)
  dir.create(serverDir)
  dir.create(clientDir)
  assignFuncList <- lapply(names(assignList), function(packName){
     sapply(assignList[[packName]], function(funName){
      syms <- c(symbols[[funName]], unlist(symbols[names(symbols)=='']))
      ret <- makeOneFunction(packName, funName, 'assign', 'DS', syms)
      clientFun <- paste0(clientPrefix, funName)
      serverFun <- paste0(funName, serverSuffix)
      clientFile <- paste0(clientDir,'/',clientFun, '.R')
      serverFile <- paste0(serverDir,'/',serverFun, '.R')
      cat(paste0(clientFun,' <- ', ret$client), file = clientFile)
      cat(paste0( serverFun, ' <- ', ret$server), file = serverFile)
      return(serverFun)
     })
   })
  aggregateFuncList <- lapply(names(aggregateList), function(packName){
    sapply(aggregateList[[packName]], function(funName){
      syms <- c(symbols[[funName]], unlist(symbols[names(symbols)=='']))
      ret <-makeOneFunction(packName, funName, 'aggregate', 'DS', syms)
      clientFun <- paste0(clientPrefix, funName)
      serverFun <- paste0(funName, serverSuffix)
      clientFile <- paste0(clientDir,'/',clientFun, '.R')
      serverFile <- paste0(serverDir,'/',serverFun, '.R')
      cat(paste0(clientFun,' <- ', ret$client), file = clientFile)
      cat(paste0( serverFun, ' <- ', ret$server), file = serverFile)
      return(serverFun)
    })
  })

  Map(function(fname,dest){
      fsource <- capture.output(print(get(fname, envir = as.environment('package:dsWrapR'))))
      fsource[1] <- paste0(fname, ' <- ',fsource[1])
      # without the lines starting with "<" (meta package rubbish)
      cat(fsource[grep('^<', fsource, invert = TRUE)], file = paste0(dest,'/little_helpers.R'), sep ="\n")
      #paste(fsource[grep('^<', fsource, invert = TRUE)], collapse = "\n")
    }, c('.encode.arg', '.decode.arg'), c(clientDir, serverDir))

  # DESCRIPTION
  servDesc <- readLines(system.file('server', 'DESCRIPTION', package='dsWrapR'))
  servDesc[1] <- paste0(servDesc[1],' ', packageName)
  servDesc[5] <- paste0(servDesc[5],' ', Sys.Date())
  servDesc[6] <- paste0('Authors@R: ', authors)
  #AggregateMethods
  servDesc[10] <-paste0(servDesc[10], paste(unlist(aggregateFuncList), collapse = ', '))
  #AssignMethods
  servDesc[11] <-paste0(servDesc[11], paste(unlist(assignFuncList), collapse = ', '))
  if(!is.null(license)){
    servDesc[8] <- paste0(servDesc[8],' ', license)
  }
  clDesc <- readLines(system.file('client', 'DESCRIPTION', package='dsWrapR'))
  clDesc[1] <- paste0(clDesc[1],' ', clientPackageName)
  clDesc[5] <- paste0(clDesc[5],' ', Sys.Date())
  clDesc[6] <- paste0('Authors@R: ', authors)
  if(!is.null(license)){
    clDesc[8] <- paste0(clDesc[8],' ', license)
  }
  cat(clDesc, file = paste0(clientDir,'/DESCRIPTION'), sep ="\n")
  cat(servDesc, file = paste0(serverDir,'/DESCRIPTION'), sep ="\n")
}
