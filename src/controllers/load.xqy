xquery version "1.0-ml";


(: MODULES :)
import module namespace headers      = "info:lc/casalini/headers#" at "../../helpers/headers.xqy";
import module namespace authenticate = "info:lc/casalini/authenticate#" at "../../helpers/authenticate.xqy";
import module namespace config = "info:lc/casalini/config#" at "../../config.xqy";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

(: NAMESPACES :)
declare namespace xdmp  = "http://marklogic.com/xdmp";
declare namespace map   = "http://marklogic.com/xdmp/map";
declare namespace cts   = "http://marklogic.com/cts";
declare namespace error = "http://marklogic.com/xdmp/error";
declare namespace marcxml = "http://www.loc.gov/MARC21/slim";
declare namespace dir   = "http://marklogic.com/xdmp/directory";

declare variable $dataset as xs:string := xdmp:get-request-field("dataset", "");

declare function local:process-triples($triples, $headers, $c) {
    let $host := fn:concat(xdmp:get-request-protocol(), "://", map:get($headers, "host"))
    let $uri-search := 
        for $i in map:get($c, "uri-search")
        return $i
            
    let $uri-replace := 
        for $i in map:get($c, "uri-replace")
        return fn:replace($i, "%HOST%", $host)

    let $triples := 
        for $t in $triples
        let $s := sem:triple-subject($t)
        let $_ := 
            if ( xdmp:type($s) eq xs:QName("sem:iri") ) then
                let $_ :=
                    for $i at $pos in $uri-search
                    return xdmp:set($s, fn:replace($s, $i, $uri-replace[$pos]))
                return xdmp:set($s, sem:iri($s))
            else
                $s
        let $p := sem:triple-predicate($t)
        let $o := sem:triple-object($t)
        let $_ := 
            if ( xdmp:type($o) eq xs:QName("sem:iri") ) then
                let $_ := 
                    for $i at $pos in $uri-search
                    return xdmp:set($o, fn:replace($o, $i, $uri-replace[$pos]))
                return xdmp:set($o, sem:iri($o))
            else
                $o
        return sem:triple($s, $p, $o)  
    return $triples
};

let $headers := headers:get()
let $auth-details := headers:auth-details()
let $is-admin := 
    if ( fn:empty(map:get($auth-details, "user")) ) then
        fn:false()
    else
        authenticate:is-admin( map:get($auth-details, "user") )
let $login := 
    if ($is-admin) then
        authenticate:login(map:get($auth-details, "user"), map:get($auth-details, "password"))
    else
        fn:false()

let $content-types := ("application/rdf+xml", "application/n-quads", "text/n3", "text/rdf+n3", "application/n-triples", "text/turtle" )
let $data := xdmp:get-request-body()

return
    if ( $is-admin eq fn:false() or $login eq fn:false()) then
        (
            xdmp:set-response-code(401, "401 Unauthorized"),
            "401 Unauthorized"
        )
    else if ( fn:empty(map:get($config:DATASETS, $dataset)) eq fn:true() ) then
        (
            xdmp:set-response-code(500, "Internal Server Error"),
            "Missing dataset in config file."
        )
    else if ( fn:index-of($content-types, map:get($headers, "content-type")) > 0 ) then
        let $c := map:get($config:DATASETS, $dataset)
        let $triples := 
            if ( map:get($headers, "content-type") eq "application/rdf+xml" ) then
                sem:rdf-parse($data, "rdfxml")
            else if ( map:get($headers, "content-type") eq "application/n-quads" ) then
                sem:rdf-parse($data, ("nquad", "repair"))
            else if ( map:get($headers, "content-type") eq "text/n3" or map:get($headers, "content-type") eq "text/rdf+n3" ) then
                sem:rdf-parse($data, ("n3", "repair"))
            else if ( map:get($headers, "content-type") eq "application/n-triples" ) then
                sem:rdf-parse($data, ("ntriple", "repair"))
            else if ( map:get($headers, "content-type") eq "text/turtle" ) then
                sem:rdf-parse($data, ("turtle", "repair"))
            else
                ()
        let $triples := local:process-triples($triples, $headers, $c)
        
        let $insert-options := ( fn:concat("directory=", map:get($c, "directory")) )
        let $insert-options :=
            if (map:get($c, "graph") ne "") then
                ($insert-options, fn:concat("override-graph=", map:get($c, "graph")) )
            else
                $insert-options
        let $permissions := 
            (
                xdmp:permission("lds-staging-role-user", "read"),
                xdmp:permission("lds-staging-role-admin", "update"),
                xdmp:permission("lds-staging-role-admin", "insert")
            )
        let $_ := sem:rdf-insert($triples, $insert-options, $permissions)
        let $response-text :=
            fn:concat( 
                fn:codepoints-to-string((10)), 
                "Inserted ", xs:string( fn:count($triples) ), " triples into directory: ", map:get($c, "directory"), 
                fn:codepoints-to-string((10)), 
                fn:codepoints-to-string((10))
            )
        return
            (
                xdmp:set-response-code(200, "OK"),
                $response-text
            )

    else
            (
                xdmp:set-response-code(400, "Bad request"),
                "Missing proper content-type perhaps?"
            )
            
