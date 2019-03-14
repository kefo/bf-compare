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

let $sq := $config:STATS-QUERIES/sq:stats-queries/sq:stats-query[xs:string(@name) eq $view]

let $html := 
    <html>
        <head>
            <title>Query: {$view}</title>
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
                    <div class="col-12">
                        <h1>Query: {$view}</h1>
                        <hr />
                        <p>{$sq/sq:description/text()}</p>
                        <hr />
                        {
                        for $q in $sq/sq:query
                        return
                            <div>
                                <h2>Dataset: {xs:string($q/@dataset)}</h2>
                                <pre><code>{xdmp:quote($q/text())}</code></pre>
                            </div>
                    }
                    </div>
                </div>
            </div>
        </body>
    </html>

return
    if ($accept-type eq "text/html") then
        (
            xdmp:set-response-code(200, "OK"),
            xdmp:add-response-header("Content-type", "text/html"),
            $html
        )
    else
        $sq
    