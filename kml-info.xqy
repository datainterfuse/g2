xquery version "1.0-ml";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
(: declare namespaces, variables and functions here :)
declare namespace k = "http://www.opengis.net/kml/2.2";

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
					<form name="formsearch" method="get" action="map.xqy" id="formsearch">
						<div id="searchdiv">
							<input type="text" name="q" id="q" size="55" value="{xdmp:get-request-field("q")}"/>
							<button type="button" id="reset_button" onclick="document.getElementById('q').value = ''; document.location.href='map.xqy'">x</button>&#160;
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
				</div>
				<div id="rightcol">
					<div id="detaildiv">
						{local:kmlInfo(xdmp:get-request-field("kml"))}
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