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

let $html := 
    <html>
        <head>
            <title>Compare: {$comparison}</title>
            <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous" />
            <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.18/css/dataTables.bootstrap4.min.css" crossorigin="anonymous" />
            <script src="https://code.jquery.com/jquery-3.3.1.slim.min.js" integrity="sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo" crossorigin="anonymous"><![CDATA[ ]]></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js" integrity="sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1" crossorigin="anonymous"><![CDATA[ ]]></script>
            <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js" integrity="sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM" crossorigin="anonymous"><![CDATA[ ]]></script>
            <script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/1.10.18/js/jquery.dataTables.min.js" crossorigin="anonymous"><![CDATA[ ]]></script>
            <script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/1.10.18/js/dataTables.bootstrap4.min.js" crossorigin="anonymous"><![CDATA[ ]]></script>
        </head>
        <body>
            <div class="container">
                <div class="row">
                    <div>
                        <h1>Compare: {$comparison}</h1>
                    </div>
                    {$div}
                </div>
            </div>
            <script>
            <![CDATA[
                $(document).ready( function () {
                    $('#t1').DataTable( 
                        {
                            paging: false
                        } 
                    )
                });
            ]]>
            </script>
        </body>
    </html>

return
    if ( fn:local-name($div) eq "div" ) then
        (
            xdmp:set-response-code(200, "OK"),
            xdmp:add-response-header("Content-type", "text/html"),
            $html
        )
    else
        $div
        