function toggleMap() {
    var map = document.getElementById("map");
    var button = document.getElementById("map_button");
    if(map.style.display === "block"){
        map.style.display = "none";
        button.innerHTML = "Show Map";
    } else {
        map.style.display = "block";
        button.innerHTML = "Hide Map";
    }
}