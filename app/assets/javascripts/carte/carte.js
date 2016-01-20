var LON = '2.428462';
var LAT = '46.538192';

function initCarto() {
    OSM = L.tileLayer("http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png", {
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    });

    position = get_position() || default_position();

    map = L.map("map", {
        center: new L.LatLng(position.lat, position.lon),
        zoom: position.zoom,
        layers: [OSM]
    });

    if (qp_active())
        display_qp(JSON.parse($("#quartier_prioritaires").val()));

    if (cadastre_active())
        display_cadastre(JSON.parse($("#cadastres").val()));

    freeDraw = new L.FreeDraw();
    freeDraw.options.setSmoothFactor(4);
    freeDraw.options.simplifyPolygon = false;

    map.addLayer(freeDraw);

    if ($("#json_latlngs").val() != '' && $("#json_latlngs").val() != '[]') {
        map.setZoom(18);

        $.each($.parseJSON($("#json_latlngs").val()), function (i, val) {
            freeDraw.createPolygon(val);
        });

        map.fitBounds(freeDraw.polygons[0].getBounds());
    }
    else if (position.lat == LAT && position.lon == LON)
        map.setView(new L.LatLng(position.lat, position.lon), 5);

    add_event_freeDraw();
}

function default_position (){
    return {lon: LON, lat: LAT, zoom: 13}
}

function get_external_data (latLngs){

    if (qp_active())
        display_qp(get_qp(latLngs));

    if (cadastre_active())
        display_cadastre(get_cadastre(latLngs));
}

function add_event_freeDraw() {
    freeDraw.on('markers', function (e) {
        $("#json_latlngs").val(JSON.stringify(e.latLngs));

        get_external_data(e.latLngs);
    });

    $("#new").on('click', function (e) {
        freeDraw.setMode(L.FreeDraw.MODES.CREATE);
    });

    $("#edit").on('click', function (e) {
        freeDraw.setMode(L.FreeDraw.MODES.EDIT);
    });

    $("#delete").on('click', function (e) {
        freeDraw.setMode(L.FreeDraw.MODES.DELETE);
    });
}

function get_position() {
    var position;

    $.ajax({
        url: '/users/dossiers/' + dossier_id + '/carte/position',
        dataType: 'json',
        async: false
    }).done(function (data) {
        position = data
        position.zoom = default_position().zoom
    });

    return position;
}

function jsObject_to_array(qp_list) {
    return Object.keys(qp_list).map(function (v) {
        return qp_list[v];
    });
}