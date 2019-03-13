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

let $types := map:map()

let $tmap := map:get($rmap, "types")
let $_ := 
    for $k in map:keys($tmap)
    let $sresults := map:get($tmap, $k)
    return 
        for $r in $sresults/results/sparql:sparql/sparql:results/sparql:result
        let $t := xs:string($r/sparql:binding[@name eq "t"]/sparql:uri)
        let $count := xs:string($r/sparql:binding[@name eq "count"]/sparql:literal)
        let $_ := 
            if ( fn:empty( map:get($types, $t) ) eq fn:true() ) then
                map:put($types, $t, map:map())
            else
                ()
        let $tm := map:get($types, $t)
        return map:put($tm, $k, $count)
        
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
        for $k in map:keys($types)
        let $qmap := map:get($types, $k)
        let $name := fn:replace($k, "http://mlvlp06.loc.gov:8294/resources/id/", "http://id.loc.gov/")
        return
            element tr {
                element th {
                    attribute scope {"row"},
                    $name
                },
                for $d in $compare:datasets
                let $sresults := map:get($qmap, $d)
                return
                    element td {
                        if ( fn:empty($sresults) eq fn:true() ) then
                            "0"
                        else
                            $sresults
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

