xquery version "1.0-ml";

(: MODULES :)
import module namespace headers      = "info:lc/casalini/headers#" at "../../helpers/headers.xqy";
import module namespace config = "info:lc/casalini/config#" at "../../config.xqy";

declare namespace xdmp  = "http://marklogic.com/xdmp";
declare namespace map   = "http://marklogic.com/xdmp/map";

let $html := 
    <html>
        <head>
            <title>Index</title>
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
                        <h1>Dataset compare</h1>
                        <hr />
                        <form class="form-inline" id="searchallform">
                            <div class="form-row align-items-center">
                                <div class="col-auto">
                                    <label for="seachall" class="col-form-label">Search All Datasets</label>
                                </div>
                                <div class="col-auto">
                                    <input type="text" class="form-control" id="searchall" />
                                </div>
                                <div class="col-auto">
                                    <button type="submit" id="searchall-button" class="btn btn-success">Go</button>
                                </div>
                            </div>
                        </form>
                        <hr />
                    </div>
                </div>
                {
                    for $k in map:keys($config:DATASETS)
                    return
                        <div class="row">
                           <div class="col-12">
                                <form class="form-inline" id="search{$k}form">
                                    <div class="form-row align-items-center">
                                        <div class="col-auto">
                                            <label for="seach{$k}" class="col-form-label">Search {$k} Dataset</label>
                                        </div>
                                        <div class="col-auto">
                                            <input type="text" class="form-control" id="search{$k}" />
                                        </div>
                                        <div class="col-auto">
                                            <button type="submit" id="search{$k}-button" class="btn btn-success">Go</button>
                                        </div>
                                    </div>
                                    <script>
                                        {
                                            let $js := "
                                                $('#search%K%form').on('submit', function (e) {
                                                    e.preventDefault();
                                                    page = '/resources/%K%/search/?q=' + $('#search%K%').val();
                                                    location.href = page;
                                                });
                                            "
                                            let $js := fn:replace($js, '%K%', $k)
                                            return $js
                                        }
                                    </script>
                                </form>
                                <hr />
                            </div>
                        </div>
                }
                <br />
                <div class="row">
                    <div class="col-12">
                        <h3>Comparisons</h3>
                        <br />
                        {
                            for $c in map:keys($config:COMPARISONS)
                            let $ds := 
                                for $k in map:keys($config:DATASETS)
                                return fn:concat("dataset=", $k)
                            let $dsstring := fn:string-join($ds, "&amp;")
                            return  <p><a href="/datasets/compare/{$c}.html?{$dsstring}">{$c}</a></p>
                        }
                    </div>
                </div>
            </div>
            <script>
            <![CDATA[
                $('#searchallform').on('submit', function (e) {
                    e.preventDefault();
                    page = "/search/?q=" + $('#searchall').val();
                    location.href = page;
                });
            ]]>
            </script>
        </body>
    </html>

return 
    (
        xdmp:set-response-code(200, "OK"),
        xdmp:add-response-header("Content-type", "text/html"),
        $html
    )