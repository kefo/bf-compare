xquery version "1.0";

module namespace config = 'info:lc/casalini/config#'; 

(: NAMESPACES :)
declare namespace xdmp  = "http://marklogic.com/xdmp";
declare namespace map   = "http://marklogic.com/xdmp/map";

declare variable $config:DATASETS := 
    map:new((
        map:entry(
            "casalini", 
            map:new((
                map:entry("directory", "/casalini/"),
                map:entry("uri-search", ("http://dev-vde.atcult.it/sharevde/rdfBibframe", "http://id.loc.gov", "http://marklogic.com/semantics/blank")),
                map:entry("uri-replace", ("%HOST%/resources/casalini", "%HOST%/resources/id", "%HOST%/resources/casalini/blank")),
                map:entry("graph", "info:lc/graphs/casalini/shakespeare")
            ))
        ),
        map:entry(
            "lc", 
            map:new((
                map:entry("directory", "/lc/"),
                map:entry("uri-search", ("http://bibframe.example.org", "#", "http://id.loc.gov", "http://marklogic.com/semantics/blank")),
                map:entry("uri-replace", ("%HOST%/resources/lc", "/", "%HOST%/resources/id", "%HOST%/resources/lc/blank")),
                map:entry("graph", "info:lc/graphs/lc/shakespeare")
            ))
        )
    ));
    

declare variable $config:STATS-QUERIES := 
    if ( xdmp:modules-database() eq 0 ) then
        xdmp:document-get(fn:concat(xdmp:modules-root(), "/stats-queries.xml"))
    else
        xdmp:eval(
        '
        xquery version "1.0";
        fn:doc("/stats-queries.xml")
        ', 
        (),
        <options xmlns='xdmp:eval'>
            <database>{xdmp:modules-database()}</database>
        </options>
    );
    
declare variable $config:COMPARISONS := 
    map:new((
        map:entry(
            "general", 
            map:new((
                map:entry("queries", ("triples-count", "bfworks-count", "rdaworks-count", "rdaexpressions-count", "bfinstances-count", "nates-works-instances-by-lccn")),
                map:entry("xqyfile", "/views/compare-general.xqy")
            ))
        ),
        map:entry(
            "types", 
            map:new((
                map:entry("queries", ("types")),
                map:entry("xqyfile", "/views/compare-types.xqy")
            ))
        )
    ));

