ScrollsPost.PAGES["pricing/index"] = function() {
  var scope = $("#pricing_index");

  var name_cache = {};
  scope.find("table tbody tr").each(function() {
    var row = $(this);

    var field = row.find(".name");
    name_cache[field.data("name")] = row;
  });


  $("#live-search input").keyup(function() {
    var search = $.trim($(this).val());
    var regex = new RegExp(search, "i");

    for( var name in name_cache ) {
      var row = name_cache[name];
      if( !name.match(regex) ) {
        row.hide();
      } else {
        row.show();
      }
    }
  });

  $("#search").submit(function(e) { e.preventDefault(); });

  // Restore search
  var search = window.location.hash.replace("#", "");
  if( search != "" ) {
    $("#live-search input").val(search).trigger("keyup");
  }
}