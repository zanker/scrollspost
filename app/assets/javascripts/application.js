//= require libraries/jquery.js
//= require libraries/highcharts.js
//= require i18n
//= require i18n/translations
//= require bootstrap/bootstrap-alert
//= require bootstrap/bootstrap-transition
//= require bootstrap/bootstrap-dropdown
//= require bootstrap/bootstrap-button
//= require bootstrap/bootstrap-tooltip
//= require bootstrap/bootstrap-tab
//= require bootstrap/bootstrap-modal
//= require highcharts-theme
//= require_self
//= require ./card_renderer
//= require_tree ./helpers/
//= require_tree ./application/

var ScrollsPost = {PAGES: {}, Helpers: {}};
ScrollsPost.initialize = function() {
  $(".tt").tooltip({animation: false, html: true, placement: "right", container: $("body")});
  $(".dropdown-toggle").dropdown();
  setTimeout(function() { $(".gabagt").attr("style", ""); }, 5000);


  $(".alert .close").click(function() {
      var alert = $(this).closest(".alert");
      alert.slideUp("fast", function() { alert.remove(); });
  });

  ScrollsPost.tooltip($(".card-tt"));

  // Search
  var search = $("#search");
  if( search.length > 0 ) {
    search.find(".btn-group .btn").click(function(event) {
      event.preventDefault();

      if( $(this).hasClass("active") ) {
        $(this).removeClass("active");
      } else {
        $(this).addClass("active");
      }
    });

    search.find(".dropdown-menu a").click(function(event) {
      event.preventDefault();

      var dropdown = $(this).closest(".dropdown");

      var label = dropdown.find(".dropdown-toggle span");
      label.html($(this).data("prefix") + " <span>" + $(this).text() + "</span>");

      dropdown.find("li.active").removeClass("active");
      $(this).closest("li").addClass("active");
    });

    search.find("form").submit(function(event) {
      event.preventDefault();

      // Compile the primary type searches
      var resources = [];
      $("#resources .btn").each(function() {
        var row = $(this);
        if( row.hasClass("active") ) resources.push(row.data("key"));
      });

      if( resources.length == $("#resources .btn").length ) resources = ["all"];

      var rarities = [];
      $("#rarities .btn").each(function() {
        var row = $(this);
        if( row.hasClass("active") ) rarities.push(row.data("key"));
      });

      if( rarities.length == $("#rarities .btn").length ) rarities = ["all"];

      var category = $("#categories li.active a").data("key");
      var rules = $("#rules li.active a").data("key");


      var version;
      if( $("#version").length == 1 ) {
        version = $("#version li.active a").data("key");
      }

      // Setup the link
      var path = $(this).attr("action") + "/" + resources.join("-") + "/" + rarities.join("-");
      if( rules ) path += "/" + rules;
      if( category ) path += "/" + category;

      if( $("#last").length > 0 ) {
        path += "/" + $("#last").find("li.active a").data("key");
      }

      if( version ) path += "/version-" + version;

      // Now add the stat searches
      $("#cost, #hp, #cd, #atk").each(function() {
        var row = $(this);
        var min = row.find("input:first");
        var max = row.find("input:last");

        var min_value = parseInt(min.val() || min.attr("placeholder"));
        var max_value = parseInt(max.val() || max.attr("placeholder"));
        console.log(min_value, max_value, row.attr("id"));
        if( min_value != parseInt(min.attr("placeholder")) || max_value != parseInt(max.attr("placeholder")) ) {
          path += "/" + row.attr("id") + "-" + min_value + "-" + max_value;
        }
      });

      $(this).find("input[type='submit']").button("loading");
      window.location = path;
    });
  }
};