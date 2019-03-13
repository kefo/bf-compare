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

declare namespace compare = 'info:lc/casalini/compare#';

declare variable $comparison as xs:string := xdmp:get-request-field("comparison", "");
declare variable $datasets := xdmp:get-request-field("dataset");

let $headers := headers:get()
let $host := fn:concat(xdmp:get-request-protocol(), "://", map:get($headers, "host"))
let $format := "html"
let $datasets := 
    for $i in $datasets
    where $i ne ""
    return $i

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

let $cmap := map:get($config:COMPARISONS, $comparison)
let $vars := 
    map:new((
        map:entry(xdmp:key-from-QName(xs:QName("compare:host")), $host),
        map:entry(xdmp:key-from-QName(xs:QName("compare:datasets")), $datasets),
        map:entry(xdmp:key-from-QName(xs:QName("compare:cmap")), $cmap)
    ))
let $div := xdmp:invoke( map:get($cmap, "xqyfile"), $vars)

return
    if ( fn:local-name($div) eq "div" ) then
        (
            xdmp:set-response-code(200, "OK"),
            xdmp:add-response-header("Content-type", "text/html"),
            $div
        )
    else
        $div
        