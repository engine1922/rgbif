#' A quick and simple autocomplete service that returns up to 20 name usages by 
#' doing prefix matching against the scientific name. Results are ordered by relevance.
#' 
#' @template all
#' @template occ
#' @import httr plyr
#' @export
#' 
#' @param q (character, required) Simple search parameter. The value for this parameter can be a 
#'    simple word or a phrase. Wildcards can be added to the simple word parameters only, 
#'    e.g. q=*puma*
#' @param datasetKey (character) Filters by the checklist dataset key (a uuid, see examples)
#' @param rank (character) The rank given as our rank enum.
#' @param fields (character) Fields to return in output data.frame (simply prunes columns off)
#' 
#' @return A data.frame with fields selected by fields arg.
#' 
#' @examples \dontrun{
#' name_suggest(q='Puma concolor')
#' name_suggest(q='Puma')
#' name_suggest(q='Puma', limit=2)
#' name_suggest(q='Puma', fields=c('key','canonicalName'))
#' name_suggest(q='Puma', rank="GENUS")
#' }

name_suggest <- function(q=NULL, datasetKey=NULL, rank=NULL, fields=NULL, start=NULL, 
                         limit=20, callopts=list())
{
  url = 'http://api.gbif.org/v1/species/suggest'
  args <- rgbif_compact(list(q=q, rank=rank, offset=start, limit=limit))
  temp <- GET(url, query=args, callopts)
  stop_for_status(temp)
  assert_that(temp$headers$`content-type`=='application/json')
  res <- content(temp, as = 'text', encoding = "UTF-8")
  tt <- RJSONIO::fromJSON(res, simplifyWithNames = FALSE)
  
  if(is.null(fields)){
    toget <- c("key","canonicalName","rank")
  } else { toget <- fields }
  matched <- sapply(toget, function(x) x %in% suggestfields())
  if(!any(matched))
    stop(sprintf("the fields %s are not valid", paste0(names(matched[matched == FALSE]),collapse=",")))
  out <- lapply(tt, function(x) x[names(x) %in% toget])
  do.call(rbind.fill, lapply(out, data.frame, stringsAsFactors = FALSE))
}

#' Fields available in gbif_suggest function
#' @export
#' @keywords internal
suggestfields <- function(){  
  c("key","datasetTitle","datasetKey","nubKey","parentKey","parent",
    "kingdom","phylum","clazz","order","family","genus","species",
    "kingdomKey","phylumKey","classKey","orderKey","familyKey","genusKey",
    "speciesKey","species","canonicalName","authorship",
    "accordingTo","nameType","taxonomicStatus","rank","numDescendants",
    "numOccurrences","sourceId","nomenclaturalStatus","threatStatuses",
    "synonym")
}