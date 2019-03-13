xquery version "1.0-ml";

(: MODULES :)
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace headers      = "info:lc/casalini/headers#" at "../../helpers/headers.xqy";

(: NAMESPACES :)
declare namespace xdmp  = "http://marklogic.com/xdmp";
declare namespace map   = "http://marklogic.com/xdmp/map";
declare namespace cts   = "http://marklogic.com/cts";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace trix  =   "http://www.w3.org/2004/03/trix/trix-1/";

declare variable $dataset as xs:string := xdmp:get-request-field("dataset", "");
declare variable $identifier as xs:string := xdmp:get-request-field("identifier", "");
declare variable $view as xs:string := fn:replace(xdmp:get-request-field("view", ""), '\.', '');
declare variable $serialization as xs:string := xdmp:get-request-field("serialization", "");

declare variable $prefer as xs:string := xdmp:get-request-field("prefer", "");

declare function local:cbd($uri, $inbound-refs, $level) {
    let $newlevel := $level + 1
    let $result := local:describe($uri, $inbound-refs)
    return
        (
            $result,
            
            for $r in $result
            let $o := sem:triple-object($r)
            where $level < 3 and ( xdmp:type($o) eq xs:QName("sem:iri") or xdmp:type($o) eq xs:QName("sem:blank") )
            return local:cbd(xs:string($o), fn:false(), $newlevel)
        )
};

declare function local:describe($uri, $inbound-refs) {
    let $query := fn:concat("DESCRIBE <", $uri , ">")
    let $results := sem:sparql($query)
    let $graph := 
        if ($inbound-refs) then
            let $q := fn:concat("CONSTRUCT { ?s ?p <", $uri , "> } WHERE { ?s ?p <", $uri , "> }")
            return ($results, sem:sparql($q))
        else
            $results
    return $graph
};

let $headers := headers:get()
let $accept-type := headers:get-acceptType()
let $inbound-refs := 
    if ( $prefer eq "PreferInboundReferences" ) then
        fn:true()
    else
        fn:false()

let $host := fn:concat(xdmp:get-request-protocol(), "://", map:get($headers, "host"))
let $uri := fn:concat($host, "/resources/", $dataset, "/", $identifier)

let $triples := 
    if ($view eq "cbd") then
        let $cbd := local:cbd($uri, $inbound-refs, 0)
        return fn:distinct-values($cbd)
    else
        let $mlcbd := local:describe($uri, $inbound-refs)
        return
            for $i in $mlcbd
            where xs:string(sem:triple-subject($i)) eq $uri or xs:string(sem:triple-object($i)) eq $uri
            return $i

return 
    if ( fn:count($triples) eq 0 ) then
        (
            xdmp:set-response-code(404, "404 Not Found"),
            "404 Not Found"
        )
    else
        if ( $serialization eq "rdf" ) then
            (
                xdmp:set-response-code(200, "OK"),
                xdmp:add-response-header("Content-type", "application/rdf+xml"),
                sem:rdf-serialize($triples, "rdfxml")
            )
        else if ( $serialization eq "n3" ) then
            (
                xdmp:set-response-code(200, "OK"),
                xdmp:add-response-header("Content-type", "text/n3"),
                sem:rdf-serialize($triples, "n3")
            )
        else if ( $serialization eq "nt" ) then
            (
                xdmp:set-response-code(200, "OK"),
                xdmp:add-response-header("Content-type", "text/plain"), (: should technically be application/n-triples :)
                sem:rdf-serialize($triples, "ntriple")
            )
        else if ( $serialization eq "ttl" ) then
            (
                xdmp:set-response-code(200, "OK"),
                xdmp:add-response-header("Content-type", "text/plain"), (: should technically be text/turtle :)
                sem:rdf-serialize($triples, "turtle")
            )
        else
            sem:rdf-serialize($triples, "rdfxml")

