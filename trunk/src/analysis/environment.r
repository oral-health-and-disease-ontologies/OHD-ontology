## Author: Alan Ruttenberg
## Project: OHD
## Date: May, 2013
##
## Modified by Bill Duncan December, 2015
##
## Support functions for demos. See load.r
## Cache query results during session so debugging is easier.

# load necessary libraries for sparql
library(rrdf) # defunct
library(MASS)
library(SPARQL)
source("SPARQL.r")
library(ggplot2)
library(ggthemes) ## needs to be downloaded from CRAN and installed: R CMD install ggthemes.tgz
library(gridExtra)

# if we use SPARQL library don't translate xsd:Date, so we can be compatible with RRDF
set_rdf_type_converter("http://www.w3.org/2001/XMLSchema#date",identity)

## triple store on local machine
local_r21_nightly <- "http://localhost:8080/openrdf-sesame/repositories/OHDRL20150412"

## note form of sparql update query is not as documented. Should be
## openrdf-sesame/repositories/OHDRL20150412/statements but that
## doesn't work.

local_r21_nightly_update <- "http://localhost:8080/openrdf-workbench/repositories/OHDRL20150412/update"

# triple store nightly build on the imac in the dungeon
dungeon_r21_nightly <- "http://dungeon.ctde.net:8080/openrdf-sesame/repositories/ohd-r21-nightly"

duncan_r21 <- "http://192.168.1.137:8080/openrdf-sesame/repositories/ohd-partial"

if(!exists("current_endpoint"))
 { print("You have to set current_endpoint first"); } # <<- duncan_r21 }

if(!exists("current_sparqlr"))
{ current_sparqlr <<- "rrdf"; }

# strings for prefixes
default_ohd_prefixes <- function  ()
{ all_prefixes_as_string(); }

lastSparqlQuery <- NULL;

querystring <- function(...,prefixes=default_ohd_prefixes)
  { string <- paste(...,sep="\n");
    lastSparqlQuery <<- paste(prefixes_for_sparql(string),"\n",string,"\n");
    lastSparqlQuery
  }

clearSPARQLSessionCache <- function ()
 { sessionQueryCache <<- new.env(hash=TRUE); }

sessionQueryCache <- new.env(hash=TRUE);

## See if we have a cached result for query executed at endpoint
cachedQuery <- function (query,endpoint)
{ if (exists(endpoint,sessionQueryCache))
  { endpointCache <- get(endpoint,sessionQueryCache);
    if (exists(query,endpointCache)) return(get(query,endpointCache)) }
  NULL
}

## Cache result for query executed at endpoint
cacheQuery <- function (query,endpoint,result)
{ if (exists(endpoint,sessionQueryCache))
  { endpointCache <- get(endpoint,sessionQueryCache)}
  else
  { endpointCache <<- new.env(hash=TRUE)
    assign(endpoint,endpointCache,sessionQueryCache) }
  assign(query,result,endpointCache)
  result
 }

## return the session cache
queryCache <- function() { sessionQueryCache }

trace_sparql_queries <- FALSE;

## execute a sparql query. endpoint defaults to current_endpoint, sparql library defaults to "rrdf"
queryc <- function(...,endpoint=current_endpoint,prefixes=default_ohd_prefixes,cache=TRUE,trace=trace_sparql_queries)
{ string <- paste(..., sep="\n");
  if (identical(prefixes,FALSE))  { prefixes <- (function () {}) }
  querystring <- querystring(string,prefixes=prefixes);
  if (trace) { cat(querystring) }
  cached <- cachedQuery(querystring(string,prefixes=prefixes),endpoint);
  if ((!is.null(cached)) && cache)
    cached
  else
    { queryres <- if (current_sparqlr=="rrdf")
                {sparql.remote(endpoint,querystring(string,prefixes=prefixes)) }
                else if (current_sparqlr=="SPARQL")
                {res<-SPARQL(endpoint,querystring(string,prefixes=prefixes))
                 res$results}
      if (length(queryres)==2 && Reduce("==",dim(queryres)==cbind(0,0))) # the function returned a 0x0 empty matrix, i.e. error
        { cat("There was an error in the SPARQL query") }
      else 
        { cacheQuery(querystring(string,prefixes=prefixes),endpoint,queryres) }
      queryres
    }
}

## retrieve the last sparql query result
lastSparql <- function() { cat(lastSparqlQuery) }

## describe a term.
rdfd <- function(uri,limit=100)
{  cat("What things have it as subject\n")
   print(queryc(paste("select distinct ?pl ?p ?vl ?v  where { <",uri,"> ?p ?v. optional {?p rdfs:label ?pl}. optional { ?v rdfs:label ?vl}} limit ",limit,sep="")),sep="\n" )
   cat("What things have it as object\n")
   print(queryc(paste("select distinct ?sl ?s ?pl ?p  where { ?s ?p <",uri,"> . optional{?p rdfs:label ?pl}. optional { ?s rdfs:label ?sl}} limit ",limit,sep="")))

 }

## describe an entity given its label
rdfdl <- function(label,limit=100)
{  cat("What things have it as subject\n");
   print(queryc(paste(" select distinct ?uri ?p ?pl  ?v ?vl  where ",
              "{  ?uri rdfs:label \"",label,"\".",
              "   ?uri ?p ?v. ",
              "   optional {?p rdfs:label ?pl}. ",
              "   optional {?v rdfs:label ?vl}.",
              " } limit ",limit,
                sep=""
              )));
   cat("What things have it as object\n")
   print(queryc(paste(" select distinct  ?s ?sl  ?p ?pl ?uri  where ",
              "{  ?uri rdfs:label \"",label,"\".",
              "   ?s ?p ?uri. ",
              "   optional {?p rdfs:label ?pl}. ",
              "   optional {?s rdfs:label ?sl}.",
              " } limit",limit,
                sep=""
              )));
 }


# plot using SVG in the browser
bplot <- function (...)
  { svg(filename="/tmp/rsvg.svg")
    plot(...)
    dev.off()
    browseURL("file:///tmp/rsvg.svg")
  }

sparqlUpdate <- function (...)
  { update <- querystring(paste(...,sep="\n"));
    postForm(current_update_endpoint,update=update,style='POST')
  }

## need to fix so that it can figure out the repo label itself
setOWLIMQueryTimeout <- function(timeout_seconds)
{ update=paste(
    "DELETE { graph ?ctx ",
    "{?place owlim:query-timeout ?current.} } ",
    "INSERT { graph ?ctx ",
    "   {?place owlim:query-timeout ",timeout_seconds,". }}",
    "WHERE ",
    " { ?ctx a rep:RepositoryContext.",
    "   graph ?ctx",
    "   {  _:a rdfs:label \"OHD R21 2015-04-08 RL\".",
    "      _:a  a rep:Repository.",
    "     ?place owlim:query-timeout ?current.",
    "     }",sep="\n");
  sparqlUpdate
  }

read.sparql.file <- function (file, limit=0, print.query=FALSE){
  ## read contents from file 
  con <- file(file, "r", blocking = FALSE)
  sparql <- readLines(con)
  close(con)
  
  ## collapsed lines 
  sparql <- paste(sparql, sep = "", collapse="  \n ")
  
  ## check for limit
  if (limit > 0)
    sparql <- paste(sparql," limit ", limit, " \n", sep="")
  
  ## check for print to screen
  if (print.query) { cat(sparql) }
  
  ## return sparql query
  sparql
}

query.from.file <- function (file, limit=0, print.query=FALSE, as.data.frame=TRUE, remove.prefixes=TRUE) {
  ## get query string from file
  query.string <- read.sparql.file(file, limit, print.query)
  
  ## check if prefixes need to be removed from query string
  if (remove.prefixes == TRUE) {
    query.string <- gsub("PREFIX[ ]*[^\n]*\n","",query.string)
  }
  
  ## get results
  res <- queryc(query.string)
  
  if (as.data.frame == TRUE) {
    ## convert to dataframe; note: stringsAsFactors must be false
    return.val <- as.data.frame(res, stringsAsFactors = F)
  }
  else {
    return.val <- res
  }
  
  ## return results
  return.val
}