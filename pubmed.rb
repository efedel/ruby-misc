#!/usr/bin/env ruby
# pull data from pubmed
# http://eutils.ncbi.nlm.nih.gov/entrez/query/static/esearch_help.html
# http://eutils.ncbi.nlm.nih.gov/entrez/query/static/efetch_help.html

require 'uri'
require 'open-uri'

#BASE_URL='http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?'
#ARGS:
# Database: Entrez database values available from EInfo. pubmed is the default.
# http://eutils.ncbi.nlm.nih.gov/entrez/eutils/einfo.fcgi?
#   db=database name       # pubmed protein
# History: Requests utility to maintain results in user's environment. 
# Used in conjunction with WebEnv.
#   usehistory=y 
#
# Web Environment: Value previously returned in XML results from ESearch or
# EPost. This value may change with each utility call. If WebEnv is used,
# History search numbers can be included in an ESummary URL, e.g., 
# term=cancer+AND+%23X (where %23 replaces # and X is the History search 
# number).
#   WebEnv=WgHmIcDG]B etc.
#
# Query_key:  The value used for a history search number or previously returned
# in XML results from ESearch or EPost.
#   query_key=6
#
# Tool: A string with no internal spaces that identifies the resource which is
# using Entrez links (e.g., tool=flybase). This argument is used to help NCBI
# provide better service to third parties generating Entrez queries from 
# programs. As with any query system, it is sometimes possible to ask the same
# question different ways, with different effects on performance. NCBI requests
# that developers sending batch requests include a constant 'tool' argument for
# all requests using the utilities.
#   tool=
#
# Search terms: This command uses search terms or phrases with or without Boolean operators.  See the PubMed or Entrez help for information about search field descriptions and tags. Search fields and tags are database specific.
#   term=search strategy # example: term=asthma[mh]+OR+hay+fever[mh]
#
# Search Field: Use this command to specify a specific search field.
# PubMed fields: affl, auth, ecno, jour, iss, mesh, majr, mhda, page, pdat, 
# ptyp, si, subs, subh, tiab, word, titl, lang, uid, fltr, vol
#    field= name 
#
# Relative Dates: Limit items a number of days immediately preceding today's 
# date.
#    reldate=   # reldate=90 reldate=365
#
# Date Ranges:  Limit results bounded by two specific dates. Both mindate and 
# maxdate are required if date range limits are applied using these variables.
#    mindate=   # mindate=2001
#    maxdate=   # maxdate=2002/01/01
#
# Date Type:  Limit dates to a specific date field based on database.
#    datetype=  # datetype=edat 
# Display Numbers:
#    retstart=x  (x= sequential number of the first record retrieved - 
#                 default=0 which will retrieve the first record)
#    retmax=y  (y= number of items retrieved)
# Retrieval Mode:
#    retmode=xml
# Retrieval Type:
#    rettype=   # PubMed values: count uilist (default)
# Sort:
#    sort=      # PubMed values: author last+author journal pub+date
#               # Gene values: Weight Name Chromosome

def build_uri(args)
  q = args.map {|k,v| "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}"}.join('&')
  URI::HTTP.build( { :host => 'eutils.ncbi.nlm.nih.gov',
                     :path => '/entrez/eutils/esearch.fcgi',
                     :query => q })
end

=begin
# Search and fetch XML from PubMed
searchPubmed <- function(query.term) {
  # change spaces to + in query
  query.gsub <- gsub(" ", "+", query.term)
  # change single-quotes to URL-friendly %22
  query.gsub <- gsub("'","%22", query.gsub)
  # Perform search and save history, this will save PMIDS in history
  pub.esearch <- getURL(paste("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=",
                              query.gsub, "&usehistory=y", sep = ""))
  # Parse esearch XML
  pub.esearch <- xmlTreeParse(pub.esearch, asText = TRUE)
  # Count number of hits (super assign)
  pub.count <<- as.numeric(xmlValue(pub.esearch[["doc"]][["eSearchResult"]][["Count"]]))
  # Save WebEnv-string, it contains "links" to all articles in my search
  pub.esearch <- xmlValue(pub.esearch[["doc"]][["eSearchResult"]][["WebEnv"]])
  # Show how many articles that's being downloaded
  cat("Searching (downloading", pub.count, "articles)\n")

  ## We need to batch download, since efetch will cap at 10k articles ##
  # Start at 0
  RetStart <- 0
  # End at 10k
  RetMax <- 10000
  # Calculate how many itterations will be needed
  Runs <- (pub.count %/% 10000) + 1
  # Create empty object
  pub.efetch <- NULL
  # Loop to batch download
  for (i in 1:Runs) {
        # Download XML based on hits saved in pub.esearch (WebEnv)
        x <- getURL(paste("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&WebEnv=",
                          pub.esearch,"&query_key=1&retmode=xml&retstart=", RetStart, "&retmax=", RetMax, sep = ""))
        # Remove XML declarations, else it wont parse correctly later, since different gets are being pasted together.
        # This is probably quick-and-dirty, perhaps it could be done more elegantly with the XML-package
        x <- gsub("<.xml version=\"1\\.0\".>\n<!DOCTYPE PubmedArticleSet PUBLIC \"-//NLM//DTD PubMedArticle, 1st January 2012//EN\" \"http://www\\.ncbi\\.nlm\\.nih\\.gov/corehtml/query/DTD/pubmed_120101\\.dtd\">\n", "", x)
        x <- gsub("<PubmedArticleSet>\n", "", x)
        x <- gsub("\n</PubmedArticleSet>\n", "", x)
        # Add data to previous downloads
        pub.efetch <- paste(pub.efetch, x, sep="")
        # Increase range for next batch
        RetStart <- RetStart + 10000
        RetMax <- RetMax + 10000
      }
  # Add tags to create valid XML
  pub.efetch <- paste("<PubmedArticleSet>\n",pub.efetch,"</PubmedArticleSet>\n")
  # Print that download is completed
  cat("Completed download from PubMed.\n")
  # Return XML
  return(pub.efetch)
}

# Function to extract journal name from individual article
extractJournal <- function(query.term = query) {
  # Parse XML into XML Tree
  xml.data <- xmlTreeParse(pub.efetch, useInternalNodes = TRUE)
  # Use xpathSApply to extract Journal name
  journal <- xpathSApply(xml.data, "//PubmedArticle/MedlineCitation/MedlineJournalInfo/MedlineTA", xmlValue)
  # Show how many journals that were extracted
  cat("Extracted ", length(journal), " hits (",length(journal)/pub.count," %) from a total of ",
     pub.count," hits. For query named: ", query.term,"\n", sep="")
  # Create data frame with journal counts
  journal <- data.frame(count(journal))
  # Calculcate percent
  journal$percent <- journal$freq / pub.count
  # return data
  return(journal)
}
=end
