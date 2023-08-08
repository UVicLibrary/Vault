var script = document.createElement('script');
script.src = src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBi8Yld0eJJqEC95p0EYSHbFCvs5NKmXMg&callback=initMap";
script.aync = true;

window.initMap = function(){
    var map = new google.maps.Map(
        document.getElementById('map'), {
            zoom: 4,
            center: {lat: 48.463150, lng: -123.312189}
        }
    );
    var bounds = new google.maps.LatLngBounds();

    //create markers
    for (i = 0; i < items.length; i++) {
        latlng = items[i]["coordinates_tesim"][0].split(";"); //split into array of individual points
        for(k = 0; k < latlng.length; k++) {
            lat = parseFloat(latlng[k].split(", ")[0]);
            lng = parseFloat(latlng[k].split(", ")[1]);

            title = items[i].title_tesim[0];
            position = new google.maps.LatLng(lat, lng);

            content =
                '<h4>' + title + '</h4>' +
                '<div style="display: table;">' +
                '<a style="text-decoration: none; color:#333;" href=' + '/concern/generic_works/' + items[i]["id"] + '>' +
                '<div style="display: table-row">' +
                '<div style="display: table-cell;"><img src="' + items[i].thumbnail_path_ss + '" alt ="content_thumbnail" height="60" width = "auto"/></div>' +
                '<div style="display: table-cell; vertical-align: top; padding-left: 10px;">' + (items[i]["description_tesim"] == null ? "" : truncate(items[i]["description_tesim"][0], 250)) + '</div>' +
                '</div></a>' +
                '<div style="display: table-row">' +
                '<div style="display: table-cell; padding-top:5px;"><a href=' + '/concern/generic_works/' + items[i]["id"] + '>View</a></div>' +
                '<div style="display: table-cell; text-align: right">' + (items[i]["geographic_coverage_label_tesim"] == null ? "" : items[i]["geographic_coverage_label_tesim"]) + '</div>' +
                '</div>' +
                '</div>';

            marker = new google.maps.Marker({
                map: null,
                position: {lat: lat, lng: lng},
                title: title,
                groupSize: 1,
                text: content
            });

            var overlap = false;
            for (j = 0; j < markers.length; j += 1) {
                //add marker info to currently existing marker
                if (position.equals(markers[j].getPosition())) {
                    overlap = true;
                    markers[j].text = markers[j].text + '<hr style="border-top: 1px solid #cccccc;" />' + content;
                    markers[j].groupSize = markers[j].groupSize + 1;
                    if (markers[j].groupSize > 1) {
                        markers[j].setLabel(String(markers[j].groupSize));
                    }
                    break;
                }
            }

            if (!overlap) {
                marker.setMap(map);
                bounds.extend(position); //map will zoom and move so that all markers are on the screen
                map.fitBounds(bounds);
                var infowindow = new google.maps.InfoWindow();
                google.maps.event.addListener(marker, 'mouseover', (function (marker, content, infowindow) {
                    return function () {
                        // If an info window is already open, close it before opening a new one
                        if (openInfoWindow)
                            openInfoWindow.close();
                        infowindow.setContent(marker.text); // include additions from overlapping markers
                        openInfoWindow = infowindow;
                        infowindow.open(map, marker);
                        map.addListener('click', (function (marker) {
                            return function () {
                                infowindow.close();
                            };
                        })(marker));
                    };
                })(marker, content, infowindow));
                markers.push(marker);
            }
        }
    }

    var options = {
        imagePath: 'https://developers.google.com/maps/documentation/javascript/examples/markerclusterer/m',
        maxZoom: 20,
        gridSize: 20
    };

    function truncate(str, maxlength) {
        return (str.length > maxlength) ?
            str.slice(0, maxlength - 1) + '…' : str;
    }

    var markerCluster = new MarkerClusterer(map, markers, options);
}

document.head.appendChild(script);