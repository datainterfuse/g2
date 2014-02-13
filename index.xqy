xquery version "1.0-ml";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

(: declare namespaces, variables and functions here :)
declare namespace x = "http://www.w3.org/1999/xhtml";
declare namespace b = "http://az.border.posts";
declare namespace p = "http://az.human.terrain";
declare namespace k = "http://www.opengis.net/kml/2.2";

declare variable $options :=
  <options xmlns="http://marklogic.com/appservices/search">
    <constraint name="Company">
      <range type="xs:string" collation="http://marklogic.com/collation/en/S1/T0020/AS">
        <element ns="http://az.human.terrain" name="Company"/>
        <facet-option>limit=30</facet-option>
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
      </range>
    </constraint>
    <constraint name="years">
      <range type="xs:date">
        <bucket lt="2014-01-01" gt="2013-01-01" name="2013">2013</bucket>
        <bucket lt="2013-01-01" gt="2012-01-01" name="2012">2012</bucket>
        <bucket lt="2012-01-01" gt="2011-01-01" name="2011">2011</bucket>
        <bucket lt="2011-01-01" gt="2010-01-01" name="2010">2010</bucket>
        <bucket le="2010-01-01" name="early">Before 2010</bucket>
        <element ns="http://az.border.posts" name="DOI"/>
        <facet-option>limit=10</facet-option>
      </range>
    </constraint>
  </options>;
  
declare variable $results :=
	let $q := fn:string(xdmp:get-request-field("q"))
	let $start := xs:unsignedLong(xdmp:get-request-field("start"))
	return search:search($q, $options, $start);

declare function local:getPath($result)
{
	let $uri := fn:string($result/@uri)
	return local:getPathByUri($uri)
};

declare function local:getPathByUri($uri)
{
	let $len := fn:string-length($uri)
	let $path := fn:substring($uri, 1, $len - 4)
	return $path
};

declare function local:getDocName($result)
{
    let $uri := fn:string($result/@uri)
    return local:getDocNameByUri($uri)
};

declare function local:getDocNameByUri($uri)
{
	let $path := fn:tokenize($uri, "/")
	let $name := $path[4]
	let $tok := fn:tokenize($name, "[.]")
	let $doc := $tok[1]
    	return fn:replace($doc,"_", " ")
};

declare function local:description($result)
{
  for $text in $result/search:snippet/search:match/node()
  return
    if (fn:node-name($text) eq xs:QName("search:highlight"))
    then <span class="highlight">{$text/text()}</span>
    else $text
};

declare function local:displayResults()
{
	let $items :=
		for $result in $results/search:result
			let $doc := fn:doc($result/@uri)
			let $node := $doc/node()
			return typeswitch($node)
				case text() return $node
				case element(x:html) return local:displayHtml($result)
				case element(p:person) return local:displayPerson($result)
				case element(b:post) return local:displayBorder($result)
				case element(k:Placemark) return local:displayKml($result)
				default return <div>Sorry, No Results Found!<br/><br/></div>
	return
		if($items)
		then (local:pagination($results), $items)
		else <div>No results for your search!<br/><br/><br/></div>
};

declare function local:displayHtml($result)
{
	let $name := local:getDocName($result)
	return
	  <div>
	    <div class="name"><a href="/index.xqy?html={fn:encode-for-uri($result/@uri)}">{$name}</a></div>
	    <div class="description">{local:description($result)}</div>
	  </div>
};

declare function local:displayBorder($result)
{
	let $doc := fn:doc($result/@uri)
	let $name := $doc//b:Name/text()
		return
			  <div>
			    <div class="name"><a href="/index.xqy?border={fn:encode-for-uri($result/@uri)}">{$name}</a></div>
			    <div class="description">{local:description($result)}</div>
	  		</div>
};

declare function local:displayKml($result)
{
	let $doc := fn:doc($result/@uri)
	let $name := $doc//k:name/text()
		return
			  <div>
			    <div class="name"><a href="/index.xqy?kml={fn:encode-for-uri($result/@uri)}">{$name}</a></div>
			    <div class="description">{$doc//k:description}</div>
	  		</div>
	  		
};

declare function local:displayPerson($result)
{
	let $doc := fn:doc($result/@uri)
	let $name := $doc//p:Person/text()
		return
		  <div>
		    <div class="name"><a href="/index.xqy?person={fn:encode-for-uri($result/@uri)}">{$name}</a></div>
		    <div class="description"><p>{local:description($result)}</p></div>
	  	</div>
};

declare function local:htmlDisplay($uri)
{
	let $doc := fn:doc($uri)
	return 
		<div>
			<div class="name"><h3>{local:getDocNameByUri($uri)}</h3></div>
			<div class="contact">{$doc//x:body}</div>
		</div>
};

declare function local:loadDoc($uri)
{
	fn:doc($uri)
};

declare function local:personInfo($uri)
{
	let $doc := fn:doc($uri)
	let $person := $doc//p:Person/text()
	let $pos := $doc//p:Position/text()
	let $co := $doc//p:Company/text()
	let $desc := $doc//p:Remarks/text()
	let $tel := $doc//p:Telephone/text()
	let $email := $doc//p:Email/text()
	let $address := $doc//p:Address/text()
	return <div>
	       <h3>{$person}</h3>
	       <div>{$pos} at {$co}</div>
	       <div class="description">{$desc}</div>
	       <div class="contact">
		       <table>
			 <tr>
			   <th>Telephone:</th>
			   <td>{$tel}</td>
			  </tr>
			  <tr>
			   <th>Email:</th>
			   <td>{$email}</td>
			  </tr>
			  <tr>
			   <th>Address:</th>
			   <td>{$address}</td>
			  </tr>
		       </table>
		</div>
       </div>
};

declare function  local:borderInfo($uri)
{
	let $doc := fn:doc($uri)
	return <div>
	          <h3>{$doc//b:Name}</h3>
	          <div>DOI: {$doc//b:DOI}</div>
	          <div>Coordinates: {$doc//b:Geo-References}</div>
	          <div class="description">{$doc//b:Remarks}</div>
      		</div>
};

declare function  local:kmlInfo($uri)
{
	let $doc := fn:doc($uri)
	let $coords := $doc//k:Point/coordinates
	let $token := fn:tokenize($coords, ",")
	let $lat := $token[2]
	let $long := $token[1]
	let $url := fn:concat("http://maps.google.com/maps/api/staticmap?markers=color:red%7C", $lat)
	let $url := fn:concat($url, ",")
	let $url := fn:concat($url, $long)
	let $url := fn:concat($url, "&amp;zoom=14&amp;size=500x300&amp;sensor=false")
	return <div>
	          <h3>{$doc//k:name/text()}</h3>
	          <div>Coordinates: {$coords}</div>
	          <div class="description">{$doc//k:description}</div>
	          <div id="map">
		  	<img alt="Google Map" src="{$url}"/>
		  </div>
		  <div>
		  	<h3>Results Within 1 Mile</h3>
		  	{local:kmlSearch(1,xs:double($lat),xs:double($long))}
		  </div>
      		</div>
      		
};

declare function local:kmlSearch($radius, $lat, $long)
{
	let $circle := cts:circle($radius, cts:point($lat,$long))
	let $results := cts:search(fn:doc(), cts:element-attribute-pair-geospatial-query(xs:QName("coordinates"), xs:QName("lat"), xs:QName("long"), $circle))
	for $result in $results
		return
			<div>
				<div class="name">{$result//k:name}</div>
				<div>Coordinates: {$result//coordinates}</div>
	  		</div>
};

declare function local:pagination($resultspag)
{
    let $start := xs:unsignedLong($resultspag/@start)
    let $length := xs:unsignedLong($resultspag/@page-length)
    let $total := xs:unsignedLong($resultspag/@total)
    let $last := xs:unsignedLong($start + $length -1)
    let $end := if ($total > $last) then $last else $total
    let $qtext := $resultspag/search:qtext[1]/text()
    let $next := if ($total > $last) then $last + 1 else ()
    let $previous := if (($start > 1) and ($start - $length > 0)) then fn:max((($start - $length),1)) else ()
    let $next-href := 
         if ($next) 
         then fn:concat("/index.xqy?q=",if ($qtext) then fn:encode-for-uri($qtext) else (),"&amp;start=",$next,"&amp;submitbtn=page")
         else ()
    let $previous-href := 
         if ($previous)
         then fn:concat("/index.xqy?q=",if ($qtext) then fn:encode-for-uri($qtext) else (),"&amp;start=",$previous,"&amp;submitbtn=page")
         else ()
    let $total-pages := fn:ceiling($total div $length)
    let $currpage := fn:ceiling($start div $length)
    let $pagemin := 
        fn:min(for $i in (1 to 4)
        where ($currpage - $i) > 0
        return $currpage - $i)
    let $rangestart := fn:max(($pagemin, 1))
    let $rangeend := fn:min(($total-pages,$rangestart + 4))
    
    return (
        <div id="countdiv"><b>{$start}</b> to <b>{$end}</b> of {$total}</div>,
        (:local:sort-options(),:)
        if($rangestart eq $rangeend)
        then ()
        else
            <div id="pagenumdiv"> 
               { if ($previous) then <a href="{$previous-href}" title="View previous {$length} results">Last</a> else () }
               {
                 for $i in ($rangestart to $rangeend)
                 let $page-start := (($length * $i) + 1) - $length
                 let $page-href := concat("/index.xqy?q=",if ($qtext) then encode-for-uri($qtext) else (),"&amp;start=",$page-start,"&amp;submitbtn=page")
                 return 
                    if ($i eq $currpage) 
                    then <b>&#160;<u>{$i}</u>&#160;</b>
                    else <span class="hspace">&#160;<a href="{$page-href}">{$i}</a>&#160;</span>
                }
               { if ($next) then <a href="{$next-href}" title="View next {$length} results">Next</a> else ()}
            </div>
    )
};

declare function local:facets()
{
    for $facet in $results/search:facet
    let $facet-count := fn:count($facet/search:facet-value)
    let $facet-name := fn:data($facet/@name)
    return
        if($facet-count > 0)
        then <div class="facet">
                <div class="greensubheading"><img src="images/checkblank.gif"/>{$facet-name}</div>
                {
                        for $val in $facet/search:facet-value
                        let $print := if($val/text()) then $val/text() else "Unknown"
                        let $qtext := ($results/search:qtext)
                        let $this :=
                            if (fn:matches($val/@name/string(),"\W"))
                            then fn:concat('"',$val/@name/string(),'"')
                            else if ($val/@name eq "") then '""'
                            else $val/@name/string()
                        let $this := fn:concat($facet/@name,':',$this)
                        let $selected := fn:matches($qtext,$this,"i")
                        let $icon := 
                            if($selected)
                            then <img src="images/checkmark.gif"/>
                            else <img src="images/checkblank.gif"/>
                        let $link := 
                            if($selected)
                            then search:remove-constraint($qtext,$this,$options)
                            else if(fn:string-length($qtext) gt 0)
                            then fn:concat("(",$qtext,")"," AND ",$this)
                            else $this
                        let $link := fn:encode-for-uri($link)
                        return
                            <div class="facet-value">{$icon}<a href="index.xqy?q={$link}">
                            {fn:lower-case($print)}</a> [{fn:data($val/@count)}]</div>
                }          
            </div>
         else <div>&#160;</div>
};

xdmp:set-response-content-type("text/html; charset=utf-8"),
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>G2</title>
		<link href="css/common.css" rel="stylesheet" type="text/css"/>
	</head>
	<body>
		
		<div id="opacity-layout">
			<header>
				<a class="logo" href="/"></a>
				<section class="search">
					<form name="formsearch" method="get" action="index.xqy" id="formsearch">
						<div id="searchdiv">
							<input type="text" name="q" id="q" size="55" value="{xdmp:get-request-field("q")}"/>
							<button type="button" id="reset_button" onclick="document.getElementById('q').value = ''; document.location.href='index.xqy'">x</button>&#160;
							<input style="border:0; width:0; height:0; background-color: #A7C030" type="text" size="0" maxlength="0"/>
							<input type="submit" id="submitbtn" name="submitbtn" value="search"/>&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;<a href="advanced.xqy">advanced search</a>
						</div>
					</form>
				</section>
			</header>
			<div id="wrapper">
				<div id="leftcol">
					<aside>
						<nav>
							<a class="dashboard" href="/">Dashboard</a>
							<a class="active map" href="/map.xqy">Map</a>
						</nav>
					</aside>
					<div>
						{local:facets()}
					</div>
				</div>
				<div id="rightcol">
					
					<div id="detaildiv">
						{
							if(xdmp:get-request-field("q"))
							then local:displayResults()
							else if(xdmp:get-request-field("person"))
								then local:personInfo(xdmp:get-request-field("person"))
								else if(xdmp:get-request-field("border"))
									then local:borderInfo(xdmp:get-request-field("border"))
									else if(xdmp:get-request-field("html"))
										then local:htmlDisplay(xdmp:get-request-field("html"))
										else if(xdmp:get-request-field("kml"))
											then local:kmlInfo(xdmp:get-request-field("kml"))
											else if(xdmp:get-request-field("doc"))
												then local:loadDoc(xdmp:get-request-field("doc"))
												else ( )


						}
					</div>
				</div>
			</div>
		</div>
		<footer>
		    <div class="footerContent" id="footerContent">
			<nav>
			    <a class="dashboard" href="/">Dashboard</a>
			    <a class="map" href="/map.xqy">Map</a>
                	</nav>
			<address>
			    <span class="address">
				4298 Lawnvale Dr Gainesville , VA 20155
			    </span>
			    <span class="phone">
				1.888.909.0571 
			    </span>
			    <span class="email">
				<a href="mailto:info@datainterfuse.com">info@datainterfuse.com</a>
			    </span>
			</address>
		    </div>
		    <div class="copyright">
			Data Interfuse &copy; 2013
			&nbsp;|&nbsp;
			<a href="#">Legal Notice</a>
		    </div>
        </footer>
	</body>	
</html>