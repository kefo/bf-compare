xquery version "1.0";

declare namespace compare = 'info:lc/casalini/compare#';

declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map = "http://marklogic.com/xdmp/map";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

declare variable $compare:host external;
declare variable $compare:datasets external;
declare variable $compare:cmap external;

(:
let $rmap := map:map()
let $_ := 
    for $d in $compare:datasets
    return map:put($rmap, $d, map:map())

let $results := 
    for $d in $compare:datasets
    return
        for $q in map:get($compare:cmap, "queries") 
        let $r := xdmp:document-get( fn:concat($compare:host, "/resources/", $d, "/statistics/", $q, ".xml") )
        let $dmap := map:get($rmap, $d)
        return map:put($dmap, $q, $r)
:)

let $rmap := map:map()
let $_ := 
    for $q in map:get($compare:cmap, "queries") 
    return map:put($rmap, $q, map:map())

let $results := 
    for $k in map:keys($rmap)
    return
        for $d in $compare:datasets
        let $r := xdmp:document-get( fn:concat($compare:host, "/resources/", $d, "/statistics/", $k, ".xml") )
        let $qmap := map:get($rmap, $k)
        return map:put($qmap, $d, $r)

let $head := 
    element thead {
        element tr {
            <th scope="col">Stat</th>,
            for $d in $compare:datasets
            return
                element th {
                    attribute scope {"col"},
                    $d
                }
        }
    }
let $rows := 
    element tbody {
        for $k in map:keys($rmap)
        let $qmap := map:get($rmap, $k)
        return
            element tr {
                element th {
                    attribute scope {"row"},
                    $k
                },
                for $d in $compare:datasets
                let $sresults := map:get($qmap, $d)
                return
                    element td {
                        for $r in $sresults/results/sparql:sparql/sparql:results/sparql:result
                        return xs:string($r/sparql:binding/sparql:literal)
                    }
                
            }
    }
let $table := 
    element table {
        attribute class {"table table-striped"},
        $head,
        $rows
    }

return 
    element div {
        $table
    }
