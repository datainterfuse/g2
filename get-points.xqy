xquery version "1.0-ml";
declare namespace k = "http://www.opengis.net/kml/2.2";
<locations>
{
	let $results := cts:search(fn:doc(), cts:element-query(xs:QName("coordinates"), cts:and-query(())))
	for $result in $results
	  return <location>
	            <name>{$result//k:name/text()}</name>
	            <lat>{fn:string($result//coordinates/@lat)}</lat>
	            <long>{fn:string($result//coordinates/@long)}</long>
	            <url>{fn:base-uri($result)}</url>
          </location>
}</locations>