(function() {
  var width = 260;
  var height = Math.round(width * 1.7352);
  var scale = width / 260;
  var active_card_id = null;

  ScrollsPost.Helpers.render_tooltip = function(card, card_data) {
    active_card_id = card_data.name;

    card.css({width: width, height: height + 20});

    var assets = [];

    // Base card
    var row = $("<img class='base' src='" + card_data.images.base + "' height='" + height + "'>"); assets.push(row)
    row.css({height: height, width: width, top: "20px"});

    // Background for cost
    row = $("<img class='cost' src='" + card_data.images.costbg + "'>"); assets.push(row);
    var img_width = 90;
    row.css({top: -height - 0, left: (width / 2) - (img_width / 2)});

    // Resource icon for cost
    row = $("<img class='resource' src='" + card_data.images.resource + "'>"); assets.push(row);
    row.css({top: -height - 0, left: 12, height: 28 * scale, width: 28 * scale});

    // Cost #
    row = $("<img class='resource-cost' src='" + card_data.images.cost + "'>"); assets.push(row);
    row.css({top: -height - 0, left: 15, height: 28 * scale, width: 22 * scale});

    // Name
    row = $("<div class='name'>" + card_data.name + "</div>"); assets.push(row);
    row.css({top: -height - 0});

    // Types
    var text = "<span class='type-cat'>" + I18n.t("js.types." + card_data.category) + "</span>";
    if( card_data.types.length > 0 ) text += ": " + card_data.types.join(", ")

    row = $("<div class='types'>" + text + "</div>"); assets.push(row);
    row.css({top: -height + 2});

    // Card image
    row = $("<img class='icon' src='" + card_data.images.card + "'>"); assets.push(row);
    row.css({top: -height + 13, left: 37, width: width - 61});

    // HP / CD / ATTACK
    var stat_bg;
    if( card_data.images.statsbg ) {
      spell_offset = 14;

      stat_bg = $("<img class='stats' src='" + card_data.images.statsbg + "'>"); assets.push(stat_bg);
      stat_bg.css({top: -height - 2, left: 34, width: width - 66});

      row = $("<img class='stat stat-atk' src='" + card_data.images.stat_atk + "'>"); assets.push(row);
      row.css({top: -height - 2, left: -122, width: 20, height: 20});

      row = $("<img class='stat stat-cd' src='" + card_data.images.stat_cd + "'>"); assets.push(row);
      if( card_data.images.stat_cd.match(/dash/) ) {
        row.css({top: -height - 2, left: -84});
      } else {
        row.css({top: -height - 2, left: -84, width: 20, height: 20});
      }

      row = $("<img class='stat stat-hp' src='" + card_data.images.stat_hp + "'>"); assets.push(row);
      row.css({top: -height - 2, left: -45, width: 20, height: 20});
    }

    // Add all the text into one div so we can position it sanely
    var html = "<div class='text'>";

    var passive_rules, desc, flavor;
    if( card_data.passive_rules && card_data.passive_rules.length > 0 ) {
      var rules = "";
      for( var i=0,total=card_data.passive_rules.length; i < total; i++ ) {
        rules += "<li><span class='astrisk'>*</span> " + card_data.passive_rules[i] + "</li>";
      }

      html += "<div class='passive-rules'><ul>" + rules + "</ul></div>"
    }

    if( card_data.desc ) {
      html += "<div class='desc'>" + card_data.desc + "</div>";
    }

    if( card_data.flavor ) {
      html += "<div class='flavor'>" + card_data.flavor.replace(/\\n/g, "<br>") + "</div>";
    }

    assets.push($(html));

    // Push it all onto the card
    var pending_contents = card.find(".pending-contents");
    pending_contents.empty();

    var contents = card.find(".contents");
    for( var i=0, total=assets.length; i < total; i++ ) {
      assets[i].appendTo(pending_contents);
    }

    // Now reposition the text
    var text = card.find(".text");

    var stat_offset = stat_bg ? 2 : 51;
    text.css({
      top: -height + stat_offset,
      left: 45,
      width: width - 85,
      height: Math.round(height * 0.32)
    });

    var flavor = text.find(".flavor");
    if( flavor ) {
      flavor.css({width: width - 110});
    }

    // We don't want to show the tooltip until all the assets are loaded
    var total_images = 0, loaded_images = 0;
    function check_images() {
      if( active_card_id != card_data.name ) return;

      loaded_images += 1;

      if( total_images == loaded_images ) {
        ScrollsPost.tt_location.offset = 140;

        card.css("top", parseInt(card.css("top")) - 120);
        card.find(".loading").hide();
        contents.removeClass("contents").addClass("pending-contents");
        pending_contents.show().removeClass("pending-contents").addClass("contents");
      }
    }

    for( var i=0, total=assets.length; i < total; i++ ) {
      if( assets[i].is("img") ) {
        total_images += 1;
        assets[i].load(check_images);
      }
    }
  }
})();

ScrollsPost.tt_location = {};
ScrollsPost.quick_tooltip = function(parent, card_data, last_event) {
  if( !ScrollsPost.tooltip_container ) ScrollsPost.tooltip_container = $("<div id='card-tooltip' class='game-card'><div class='loading'><div class='indicator'></div><span>" + I18n.t("js.loading") + "</span></div><div class='contents'></div><div class='pending-contents'></div></div>").appendTo($("body"));
  var tooltip = ScrollsPost.tooltip_container;
  var tooltip_contents = tooltip.find(".contents"), tooltip_loading = tooltip.find(".loading");


  ScrollsPost.tt_location.offset = 20;

  if( !tooltip_loading.is(":visible") ) {
    tooltip.find(".contents *").remove();
    tooltip.css({top: last_event.pageY - ScrollsPost.tt_location.offset, left: last_event.pageX + 40});
    tooltip_loading.show();
    tooltip_contents.hide();
    tooltip.show();
  }

  ScrollsPost.Helpers.render_tooltip(tooltip, card_data);

  $(document)[0].onmousemove = function(event) {
    tooltip[0].style.top = (event.pageY - ScrollsPost.tt_location.offset) + "px";
    tooltip[0].style.left = (event.pageX + 40) + "px";
  }
}

ScrollsPost.hide_tooltip = function() {
  if( ScrollsPost.tooltip_container ) {
    ScrollsPost.tooltip_container.data("active-id", "");
    ScrollsPost.tooltip_container.hide();
    $(document)[0].onmousemove = null;
  }
}

ScrollsPost.tooltip = function(selector) {
  if( !ScrollsPost.tooltip_container ) ScrollsPost.tooltip_container = $("<div id='card-tooltip' class='game-card'><div class='loading'><div class='indicator'></div><span>" + I18n.t("js.loading") + "</span></div><div class='contents'></div><div class='pending-contents'></div></div>").appendTo($("body"));
  var tooltip = ScrollsPost.tooltip_container;
  var tooltip_contents = tooltip.find(".contents"), tooltip_loading = tooltip.find(".loading");

  var tooltip_xhr, show_timer, tooltip_active, last_event;

  function show_tooltip() {
    var card_id = tooltip.data("active-id");
    ScrollsPost.tt_location.offset = 20;

    if( !tooltip_loading.is(":visible") ) {
      tooltip.find(".contents *").remove();
      tooltip.css({top: last_event.pageY - ScrollsPost.tt_location.offset, left: last_event.pageX + 40});
      tooltip_loading.show();
      tooltip_contents.hide();
      tooltip.show();
    }

    tooltip_active = true;

    tooltip_xhr = $.ajax("/scroll/tooltip/" + card_id, {
      error: function() {
        if( tooltip.data("active-id") != card_id ) return;

      },
      success: function(card_data) {
        if( tooltip.data("active-id") != card_id ) return;

        ScrollsPost.Helpers.render_tooltip(tooltip, card_data);
      },
    });
  }

  selector.each(function() {
    var card = $(this);
    var card_id = card.data("card-id");
    card.mouseenter(function(event) {
      if( tooltip_xhr ) tooltip_xhr.abort();
      tooltip.data("active-id", card_id);

      last_event = event;

      if( show_timer ) clearTimeout(show_timer);
      show_timer = setTimeout(show_tooltip, 100);
    });

    card.mouseleave(function() {
      tooltip_active = null;
      if( show_timer ) clearTimeout(show_timer);

      tooltip.data("active-id", "");
      tooltip.hide();
    });
  });

  $(document)[0].onmousemove = function(event) {
    if( tooltip_active ) {
      tooltip[0].style.top = (event.pageY - ScrollsPost.tt_location.offset) + "px";
      tooltip[0].style.left = (event.pageX + 40) + "px";
    } else {
      last_event = event;
    }
  }
}