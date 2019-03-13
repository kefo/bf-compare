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

declare variable $dataset as xs:string := xdmp:get-request-field("dataset", "");
declare variable $format as xs:string := xdmp:get-request-field("format", "");

declare variable $page as xs:string := xdmp:get-request-field("page", "1");
declare variable $count as xs:string := xdmp:get-request-field("count", "30");
declare variable $q as xs:string := xdmp:get-request-field("q", "");

let $headers := headers:get()
let $accept-type := headers:get-acceptType()
let $accept-type := 
    if ($format ne "") then
        if ($format eq "xml") then
            "application/xml"
        else
            "text/html"
    else
        $accept-type
let $directory := fn:concat("/", $dataset, "/")

let $options := 
    <options xmlns="http://marklogic.com/appservices/search">
        <additional-query>
            {
                if ( $dataset ne "" ) then
                    cts:directory-query( $directory )
                else
                    ()
            }
        </additional-query>
        <!-- <searchable-expression xmlns:idx="info:lc/xq-modules/lcindex" xmlns:ldsstaging="info:lc/xq-modules/ldsstaging">//idx:result/ldsstaging:label</searchable-expression> -->
        <debug>true</debug>
    </options>

let $ctsquery := cts:query(search:parse($q, $options))
let $params := 
    map:new((
        map:entry("ctsquery", $ctsquery)
    ))
    
let $query := '
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>  
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX bf: <http://id.loc.gov/ontologies/bibframe/>
    PREFIX bfsvde: <http://share-vde.org/rdfBibframe/>
    PREFIX madsrdf: <http://www.loc.gov/mads/rdf/v1#>
    
    PREFIX cts: <http://marklogic.com/cts#>
    
    SELECT ?s ?l ?type
    WHERE {
        {
            ?s rdfs:label|rdf:value ?l .
            FILTER( cts:contains(?l, $ctsquery) ) .
            ?s a ?type .
            VALUES ?type { bf:Work bf:Instance bfsvde:SuperWork } .
            FILTER( isIRI(?s) ) .
        } UNION {
            ?s rdfs:label|rdf:value ?l .
            FILTER( cts:contains(?l, $ctsquery) ) .
            ?w bf:subject ?s .
            ?s a ?type .
        } UNION {
            ?i rdfs:label|rdf:value ?l .
            FILTER( cts:contains(?l, $ctsquery) ) .
            ?s bf:identifiedBy ?i .
            ?s a ?type .
        } UNION {
            ?i rdfs:label|rdf:value ?l .
            FILTER( cts:contains(?l, $ctsquery) ) .
            ?ins bf:identifiedBy ?i .
            {
                ?s bf:hasInstance ?ins .
            } UNION {
                ?ins bf:instanceOf ?s .
            }
            ?s a ?type .
        }
    }
    group by ?s
    LIMIT 1000
    '
(: let $store := sem:store((), $ctsquery) :)
let $results := sem:sparql($query, $params)

let $total := xs:string(fn:count($results))
let $hits := 
    if ( $accept-type eq "text/html" ) then
        for $r in $results
        let $uri := xs:string(map:get($r, "s"))
        let $type := xs:string(map:get($r, "type"))
        let $shorttype := 
            if ( fn:contains($type, "#") ) then
                fn:tokenize($type, "#")[fn:last()]
            else
                fn:tokenize($type, "/")[fn:last()]
        let $dataset := 
            for $k in map:keys($config:DATASETS)
            where fn:contains($uri, $k)
            return $k
        let $label := xs:string(map:get($r, "l"))
        return
            (
                element p {
                    <span>
                        <!-- <a href="{fn:concat($uri, '.html')}">{fn:concat($uri, '.html')}</a><br /> -->
                        <a href="{fn:concat($uri, '.rdf')}">{fn:concat($uri, '.rdf')}</a><br />
                        <a href="{fn:concat($uri, '.cbd.rdf')}">{fn:concat($uri, '.cbd.rdf')}</a><br />
                    </span>,
                    <span>
                        <b>Dataset</b>: {$dataset} <br />
                        <b>{$shorttype}</b>: {$label}
                        <br />
                    </span>
                },
                <br />
            )
    else
        $results
let $document := 
    if ($accept-type eq "text/html") then
        <html>
            <head />
            <body>
                <p>
                    Page {$page} of { xs:string( fn:ceiling( xs:integer($total) div xs:integer($count) ) ) } ({$count} per page) - {xs:string($total)} total hits
                </p>
                <br />
                {$hits}
            </body>
        </html>
    else
        $hits

return
    if ( fn:empty($hits) eq fn:false() ) then
        (
            xdmp:set-response-content-type($accept-type),
            $document
        )
    else
        (
            xdmp:set-response-content-type("text/plain"),
            "No results found."
        )
