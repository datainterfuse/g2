function initialize() {
	var latlng = new google.maps.LatLng(38.796908,-80.498657);
	var myOptions = {
	zoom: 1,
	center: latlng,
	mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	var map = new google.maps.Map(document.getElementById("map"),
	myOptions);

	loadPoints(map);

}

function buildMarkerClickEventHandler(marker, href) {
	google.maps.event.addListener(marker, 'click', function() {
		window.location = "/kml-info.xqy?kml=" + href;
	});
};


function loadPoints(map) {
	$.ajax({
		url: "/get-points.xqy",
		contentType: "xml",
		success: function(data) {
			var bounds = new google.maps.LatLngBounds();
			$(data).find("location").each(function(index) {
				var lat = $(this).find("lat").text();
				var long = $(this).find("long").text();
				var marker = new google.maps.Marker({
					position: new google.maps.LatLng(lat, long),
					map: map,
					title: $(this).find("name").text()
				});
				buildMarkerClickEventHandler(marker, $(this).find("url").text());
				bounds.extend(new google.maps.LatLng(lat, long));
			});
			map.fitBounds(bounds);
		}
	});
};

$(document).ready(function() {
	initialize();
});