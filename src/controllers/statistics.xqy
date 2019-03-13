xquery version "1.0-ml";

(: MODULES :)
import module namespace headers      = "info:lc/casalini/headers#" at "../../helpers/headers.xqy";
import module namespace config = "info:lc/casalini/config#" at "../../config.xqy";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

(: NAMESPACES :)
declare namespace xdmp  = "http://marklogic.com/xdmp";
declare namespace map   = "http://marklogic.com/xdmp/map";
declare namespace cts   = "http://marklogic.com/cts";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace idx   = "info:lc/xq-modules/lcindex";
declare namespace ldsstaging   = "info:lc/xq-modules/ldsstaging";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace sq    = "info:lc/ns/casalini/stats-queries";

declare variable $dataset as xs:string := xdmp:get-request-field("dataset", "");
declare variable $view as xs:string := xdmp:get-request-field("view", "");
declare variable $serialization as xs:string := xdmp:get-request-field("serialization", "");

let $headers := headers:get()
let $accept-type := headers:get-acceptType()
let $accept-type := 
    if ($serialization ne "") then
        if ($serialization eq "xml") then
            "application/xml"
        else if ($serialization eq "json") then
            "application/json"
        else
            "text/html"
    else
        $accept-type
let $directory := fn:concat("/", $dataset, "/")

let $sq := $config:STATS-QUERIES/sq:stats-queries/sq:stats-query[xs:string(@name) eq $view]/sq:query
let $query := ($sq[xs:string(@dataset) eq $dataset], $sq[xs:string(@dataset) eq "all"])[1]
let $querystr:= 
    fn:concat(
        $config:STATS-QUERIES/sq:stats-queries/sq:prefixes/text(),
        codepoints-to-string(10),
        $query/text()
    )
let $sqname := xs:string($query/../@name)
let $ddsmap := map:get($config:DATASETS, $dataset)
let $params := 
    map:new((
        map:entry("g", sem:iri(map:get($ddsmap, "graph")))
    ))

let $results := sem:sparql($querystr, $params)
let $response := 
    map:new((
        map:entry("query-name", $sqname),
        map:entry("query", $querystr),
        map:entry("results", $results)
    ))

let $document := 
    if ($accept-type eq "text/html" or $accept-type eq "application/json") then
        map:new((
            map:entry("query-name", $sqname),
            map:entry("query", $querystr),
            map:entry("results", $results)
        ))
    else
        element results {
            element query-name {$sqname},
            element query {$querystr},
            sem:query-results-serialize($results)
        }

return
    if ( fn:empty($results) eq fn:false() ) then
        (
            xdmp:set-response-content-type($accept-type),
            $document
        )
    else
        (
            xdmp:set-response-content-type("text/plain"),
            "No results found."
        )
        