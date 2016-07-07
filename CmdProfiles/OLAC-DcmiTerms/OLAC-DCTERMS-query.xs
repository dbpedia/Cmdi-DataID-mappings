declare default element namespace "http://www.clarin.eu/cmd/";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace dc="http://purl.org/dc/terms/";
declare namespace olac="http://www.language-archives.org/OLAC/1.0/";
declare namespace dataid="http://dataid.dbpedia.org/ns/core#";
declare namespace hdl="http://hdl.handle.net/";
declare namespace sparql="http://xsparql.deri.org/demo/xquery/sparql-functions.xquery";
declare namespace xsd =  "http://www.w3.org/2001/XMLSchema#";
declare namespace dcat="http://www.w3.org/ns/dcat#";
declare namespace void =  "http://rdfs.org/ns/void#";
declare namespace owl =  "http://www.w3.org/2002/07/owl#";
declare namespace datacite =  "http://purl.org/spar/datacite/";

declare function dataid:capitalize-first( $arg as xs:string? )  as xs:string? {

   fn:concat(fn:upper-case(fn:substring($arg,1,1)), fn:lower-case(fn:substring($arg,2)))
 } ;

(: get namespace uri of prefixed uri string :)

declare function dataid:resolve-prefixed-uri ( $n as xs:string )  {
    let $zw1 := fn:substring($n, 0, string-length(substring-before($n, ":"))+2)
    return if(fn:index-of(("foaf:", "rdf:", "dc:", "olac:", "dataid:", "hdl:", "sparql:", "xsd:", "dcat:", "void:", "owl:"), $zw1) > 0) then 
		fn:concat(fn:namespace-uri(element {fn:concat($zw1, "x")} {""}), fn:substring($n, string-length(substring-before($n, ":"))+2))
	else
		$n
};

declare function dataid:get-datacite-scheme( $uri as xs:string? )  as xs:string? {

  	let $oo := dataid:resolve-prefixed-uri($uri)
  	let $scheme := if(fn:contains($oo, "handle.net")) then "handle"
  			else if(fn:contains($oo, "isbn")) then "isbn"
  			else "unknowntodo"
  	return fn:concat("datacite:", $scheme)
 } ;

(: create lexvo language uri :)
declare function dataid:get-lexvo-uri ( $iso as xs:string ) as xs:string {
	
	let $zw := if(fn:string-length($iso) != 3) then
			error(QName("no iso 639-3 language tag", $iso))
		else
			sparql:createURI(fn:concat("http://lexvo.org/id/iso639-3/", $iso))
	return $zw
};

(: create new agent and authorization :)
declare function dataid:insert-agent ( $uri as xs:string, $name as xs:string, $role as xs:string ) as xs:string {
	
	let $urii := if(fn:contains($uri, "/dataid.ttl")) then 
		fn:concat(fn:substring-before(fn:string($uri), "/dataid.ttl") , "/", fn:encode-for-uri(fn:string(fn:substring-after($role, ":"))))
	else
		fn:concat($uri , "/", fn:encode-for-uri(fn:string(fn:substring-after($role, ":"))))
	let $agent :=  sparql:createURI($urii)
	let $auth :=  sparql:createURI(fn:concat($urii, "-authorization"))

	construct{
		$uri  			dataid:associatedAgent 		$agent .
		$uri  			dataid:underAuthorization 	$auth .

		$uri  {fn:substring-before($role, ":") }:{fn:substring-after($role, ":")} $agent .

        $agent 			a 							dataid:Agent ;
        				dataid:hasAuthorization  	$auth ;
        				foaf:name 					$name .

		$auth 			a 							dataid:Authorization ;
				        dataid:authorityAgentRole   dataid:{dataid:capitalize-first(fn:substring-after($role, ":"))} ;
				        dataid:authorizedAgent      $agent ;
				        dataid:authorizedFor        $uri ;
				        dataid:isInheritable        "true"^^xsd:boolean ;
				        dataid:validForAccessLevel  dataid:PrivateAccess , dataid:SemiPrivateAccess , dataid:PublicAccess .
	}
};

(: create simple statement :)
declare function dataid:insert-simple-statements ( $uri as xs:string, $prop as xs:string, $stmt as xs:string, $lang as xs:string, $ref as xs:string) as xs:string {
	
	let $urii := sparql:createURI(fn:concat($uri, "?stmt=", fn:substring-after($prop, ":")))

	construct {
		$uri  			{fn:substring-before($prop, ":")}:{fn:substring-after($prop, ":")}		$urii .
		$urii  			a   						dataid:SimpleStatement ;
						dataid:statement			{sparql:createLiteral($stmt, $lang, "")} .
		{
			for $r in $ref
			where (fn:string-length($r) > 0)
			construct{
				$urii  			dc:references			{sparql:createURI($r)} .
			}
		}
	}	
};

(: create identifier, $scheme should usualy be something like datacite:doi :)
declare function dataid:insert-identifier ( $uri as xs:string, $scheme as xs:string, $stmt as xs:string, $ref as xs:string) as xs:string {
	
	let $urii := sparql:createURI(fn:concat($uri, "?identifier=", fn:substring-after($scheme, ":")))

	construct {
		$uri  			dataid:identifier			$urii .
		$urii  			a   						dataid:Identifier ;
						dataid:statement			{sparql:createLiteral($stmt, "", "")} ;
						datacite:usesIdentifierScheme   {fn:substring-before($scheme, ":")}:{fn:substring-after($scheme, ":")} .
		{
			for $r in $ref
			where (fn:string-length($r) > 0 and fn:starts-with($r, "http"))
			construct{
				$urii  			dc:references			{sparql:createURI($r)} .
			}
		}
	}	
};

(: create new media type :)
declare function dataid:insert-mediatype ( $uri as xs:string, $mime as xs:string ) as xs:string {
	
	let $urii := sparql:createURI(fn:concat("dataid:mediatype_", substring-after($mime, "/")))

		construct {
		$uri  			dcat:mediaType  			$urii .
		$urii  			a   						dataid:MediaType ;
        				dataid:typeExtension  		{".xml"} ;
						dataid:typeTemplate   		{$mime} .	
		}	
};

(: create new distribution and media type :)
declare function dataid:insert-distribution ( $uri as xs:string, $dlurl as xs:string, $mime as xs:string ) as xs:string {
	
	let $uripart := fn:tokenize($dlurl, ":|/")
	let $urii := dataid:resolve-prefixed-uri (fn:concat($uri, "?file=", $uripart[fn:count($uripart)], ".xml"))

	construct{
		$uri  			dcat:distribution  			$urii .
		$urii  			a   						dataid:SingleFile ;
						dataid:hasAccessLevel    	dataid:PublicAccess ;
						dataid:isDistributionOf		$uri ;
						dcat:accessURL         		$dlurl .
		{
			for $m in $mime
			where (fn:string-length($m) > 0)
			return dataid:insert-mediatype($urii, $m)
		}
	}
};

(: evaluate value, return right type :)
declare function dataid:evaluate-value ($uri,  $prop , $value , $map )  as xs:string {

	let $str := fn:string(data($value))
	let $ind := fn:index-of($map, $prop)

	let $singleline := if($map[$ind+1] = "uri") then
		sparql:createURI(dataid:resolve-prefixed-uri( $str ))
	else 
		if($map[$ind+1] = "lang") then
		sparql:createLiteral($str, data($value/@xml:lang), "")
	else 
		if(fn:contains($map[$ind+1], "func:")) then
			if(fn:contains($map[$ind+1], "lexvo")) then
				dataid:get-lexvo-uri($str)
			else ()
	else
		if(count($map[$ind+1]) > 0 and (sparql:createURI($map[$ind+1]) or dataid:resolve-prefixed-uri($map[$ind+1]))) then
			sparql:createLiteral($str, "", $map[$ind+1])
		else ()

	let $singleline := for $s in $singleline
		  construct { $uri {fn:substring-before($prop, ":") }:{fn:substring-after($prop, ":")} $s . }

	let $multiline := if(fn:contains($map[$ind+1], "func:")) then
			if(fn:contains($map[$ind+1], "agent")) then
				dataid:insert-agent($uri, $str, $prop)
			else ()
	else 
		if($map[$ind+1] = "stmt") then
			dataid:insert-simple-statements ( $uri, $prop, $str, fn:string(data($value/@xml:lang)), "")
	else 
		if($map[$ind+1] = "id") then
			dataid:insert-identifier ( $uri, dataid:get-datacite-scheme($str), $str, dataid:resolve-prefixed-uri($str))
	else()

	return if(fn:count(fn:tokenize($multiline, '(\r\n?|\n\r?)')) < 1 ) then
		$singleline
	else
		$multiline 
} ;

(: create DataId stump :)
declare function dataid:create-dataid-stump ( $dataiduri, $mainset, $publisher, $header ) as xs:string {
	
	let $zw := "jjj"  (: otherwise i get a silly error :)
	construct{
		$dataiduri 	a 					dataid:DataId ;
			foaf:primaryTopic 			$mainset ;
			dataid:hasAccessLevel     	dataid:PublicAccess ;
			dataid:latestVersion       	$dataiduri ;
			dc:conformsTo              	<{"http://dataid.dbpedia.org/ns/core"}> ;
			dc:issued 					{$header/MdCreationDate/text()}^^xsd:date ;
			dc:modified 				{$header/MdCreationDate/text()}^^xsd:date ;
			dc:description				{fn:concat("DataID representation of Clarin resource ", $mainset)} .

        	{dataid:insert-agent($dataiduri, fn:string($publisher/text()), "dc:publisher")}
	}

};

(: ind % 2 = 0 -> property name (e.g. dc:description), ind % 2 = 1 -> ("uri"|"lang"|"func:funcName"|type uri) (e.g. "xsd:date")) :)
let $dcmap := (
	"dcat:keyword", "lang",
	"dc:conformsTo", "uri", 
	"dcat:landingPage", "uri", 
	"void:subset", "uri", 
	"dc:description", "lang", 
	"dc:hasVersion", "uri", 
	"dc:issued", "xsd:date", 
	"dc:language", "func:lexvo", 
	"dc:rights", "stmt", 
	"dc:publisher", "func:agent", 
	"dc:creator", "func:agent", 
	"dcat:contact", "func:agent", 
	"dc:isPartOf", "uri",
	"dc:identifier", "id",
	"dc:title", "lang")

let $header := //Header[1]
let $olac := //OLAC-DcmiTerms

let $org := $header/MdSelfLink/text()
let $uri := dataid:resolve-prefixed-uri($org)
let $olacid := $olac/identifier[fn:contains(text(), "hdl:")]/text()
let $olacuri := if(fn:empty($olacid)) then $uri else dataid:resolve-prefixed-uri($olacid)

let $dataid := if(fn:compare(fn:string($uri), fn:string($olacuri)) != 0) then 
	dataid:create-dataid-stump ( $uri, $olacuri, $olac/publisher, $header ) else ()

let $olacDcmi := for $tag in $olac/*
	for $pos in (1 to count($tag))
		let $prop := if(name($tag) = "subject") then
			"dcat:keyword"
		else
			fn:concat("dc:", name($tag))

		return dataid:evaluate-value($olacuri, $prop, $tag[$pos], $dcmap)

let $sets := for $tag in //ResourceProxyList/*
	for $pos in (1 to count($tag))
		let $prop := if($tag[$pos]/ResourceType/text() = "LandingPage") then
			sparql:createURI("dcat:landingPage")
		else 
			if($tag[$pos]/ResourceType/text() = "Metadata") then
			sparql:createURI("void:subset")
		else 
			"none"
		return dataid:evaluate-value($olacuri, $prop, $tag[$pos]/ResourceRef, $dcmap)

let $partsOf := for $tag in //IsPartOfList/*
	for $pos in (1 to count($tag))
		return dataid:evaluate-value($olacuri, "dc:isPartOf", $tag[$pos], $dcmap)

let $distri := for $tag in //ResourceProxyList/*
	for $pos in (1 to count($tag))
	where ($tag[$pos]/ResourceType/text() = "Metadata") 
	let $subset := sparql:createURI(dataid:resolve-prefixed-uri($tag[$pos]/ResourceRef/text()))
	return dataid:insert-distribution ($subset, $subset, $olac/format/text())

construct{
	$olacuri a dataid:{"Dataset"} ;
		dc:description {fn:concat("Dataset of CLARIN resouce ", $org)}@{"en"} ;
		dc:issued {$header/MdCreationDate/text()}^^xsd:date .

		{fn:distinct-values(
			(	$dataid,
				$distri,
				$sets,
				$olacDcmi, 
				$partsOf	)
			)}
}