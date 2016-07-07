DMDI profiles to DataID
======

This repository provides the necessary mappings to convert CMDI resources into DataIDs.

We use XSPARQL to convert XML to TURTLE RDF and offer possible XSPARQL queries for every profile (.xs files). 
The [AkswXsparql](https://github.com/AKSW/xsparql) project provides the XSPARQL engine used.

These are the command line calls to execute a query:

important parameters:
fromSource:	the path to the source xml file or directory

file:		the path to the result rdf file

rdfformat:	the output serialization (see [here](https://jena.apache.org/documentation/io/) for all options)

the last entry is always the query file (.xs) without a parameter name


======================================================
Example 1: Converting a single CMDI file into a DataID

(there are no dependent files, therefor just one file to process)

java -cs="your classpath here" org.sourceforge.xsparql.Main --fromSource="/your/path/here/source.xml" --file="/path/to/result.ttl" --rdfformat="Turtle" /your/query/file.xs

======================================================
Example 2: Converting a multiple dependent CMDI file into a DataID

(there are multiple files containing the information needed for a single DataID --> put all of them into a single directory (and only those!))

java -cs="your classpath here" org.sourceforge.xsparql.Main --fromSource="/your/path/to/source/dir" --file="/path/to/result.ttl" --rdfformat="Turtle" /your/query/file.xs
