ScrollsPost.PAGES["replays/index"] = function() {
  var scope = $("#replays_index");

  $("#search form").submit(function(event) {
    event.preventDefault();

    $(this).data("loading");
    var path = $(this).attr("action");

    // Resources
    var resources = [];
    $("#resources .btn").each(function() {
      var row = $(this);
      if( row.hasClass("active") ) resources.push(row.data("key"));
    });

    if( resources.length == $("#resources .btn").length ) resources = ["all"];

    // Game type
    var type = $("#type li.active a").data("key");

    // Game version
    var version = $("#version li.active a").data("key");

    // Construct base path
    path += "/" + resources.join("-");
    if( type != "all" ) path += "/type-" + type;
    if( version != "all" ) path += "/version-" + version;

    // Rating
    var min = parseInt($("#rating input:first").val()) || 0;
    var max = parseInt($("#rating input:last").val()) || 9999;

    if( min != 0 || max != 9999 ) {
      path += "/rating-" + min + "-" + max;
    }

    window.location = path.replace("//", "/");
  });
}