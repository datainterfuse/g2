<?PHP

$queryString = $_SERVER['QUERY_STRING'];
parse_str($queryString, $vars);
unset($vars['proxyPath']);
$queryString = http_build_query($vars);

$options = array(
CURLOPT_URL => 'http://localhost:9072' . $_GET["proxyPath"] . '?' . $queryString, // location of the rest server. Be sure to preserve the query string unaltered

CURLOPT_HTTPAUTH => CURLAUTH_DIGEST, // it is very important to set the authentication type to digest

CURLOPT_USERPWD => 'admin:admin', // this is your username and password for the server. be sure your role has read permissions on the database

CURLOPT_HTTPHEADER => array('Content-type: application/json'), // the server won't respond properly unless the content-type is application/json
);

// Only set POST options for POSTs, not GETs
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
$options[CURLOPT_POST] =  1; // queries are sent in the post body, with options like pagination in the query string 

$options[CURLOPT_POSTFIELDS] = file_get_contents('php://input'); // we are not sending a traditional form map through the post, so avoid using the standard $_POST
}

$ch = curl_init(); // create curl
curl_setopt_array($ch, $options); // set curl options
curl_exec($ch); // execute curl

?>