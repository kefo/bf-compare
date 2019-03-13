xquery version "1.0-ml";

(: MODULES :)
import module namespace headers      = "info:lc/casalini/headers#" at "../../helpers/headers.xqy";

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
declare variable $identifier as xs:string := xdmp:get-request-field("identifier", "");

let $headers := headers:get()
let $accept-type := headers:get-acceptType()

return 
    if ($dataset ne "" and $identifier ne "") then
        let $uri := fn:concat("/resources/", $dataset, "/", $identifier)
        let $uri := 
            if ($accept-type eq "application/xml") then
                fn:concat($uri, ".xml")
            else if ($accept-type eq "application/rdf+xml") then
                fn:concat($uri, ".rdf")
            else if ($accept-type eq "text/html") then
                fn:concat($uri, ".html")
            else
                fn:concat($uri, ".xml")
        return
            (
                xdmp:set-response-code(303, "303 See Other"),
                xdmp:redirect-response($uri)
            )
    else
        (
            xdmp:set-response-code(404, "404 Not Found"),
            "404 Not Found"
        )