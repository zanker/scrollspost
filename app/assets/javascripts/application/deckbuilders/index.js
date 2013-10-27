ScrollsPost.PAGES["deckbuilders/index"] = function() {
  $("#loading").modal("show");

  if( typeof(window.card_data) == "object" ) {
    ScrollsPost.PAGES["deckbuilders/index/ready"](window.card_data);
  } else {
    $(document).ready(function() {
      ScrollsPost.PAGES["deckbuilders/index/ready"](window.card_data);
    });
  }
}


ScrollsPost.PAGES["deckbuilders/index/ready"] = function(card_data) {
  if( typeof(window.card_data) != "object" ) return;
  delete(window.card_data);

  var scope = $("#deckbuilders_index");
  $("html").addClass("noselect");

  var total_cards = card_data.length;
  var config = {}, deck_cards = {}, deck_offsets = {}, id_map = {};

  var has_inventory = card_inventory !== null;

  // Manage config
  var manage = $("#manage");

  config.auto_align = config.click_controls = $("#click-controls").is(":checked");
  $("#click-controls").click(function() {
    config.auto_align = config.click_controls = $(this).is(":checked")
  });

  config.force_inventory = $("#force-inventory").is(":checked");
  $("#force-inventory").click(function() {
    if( !has_inventory ) {
      $("#mod-required").modal("show");
      $(this).attr("disabled", true);
      return;
    }

    config.force_inventory = $(this).is(":checked");
    update_cards();
  });

  // Render all the cards and deal with card previews
  var game_card = scope.find(".game-card");
  ScrollsPost.Helpers.render_tooltip(game_card, card_data[0]);

  var card_rows = {}, attach_states = {}, card_count = {};
  for( var i=0; i < total_cards; i++ ) {
    var card = card_data[i];
    card.internal_id = i;

    id_map[card.card_id] = i;

    var html = "";

    html += "<li data-internal-id=" + i + " data-card-id=" + card.card_id + ">";
    html += "<div class='img'><img src='" + card.images.card_small + "'></div>";
    html += "<div class='info'>";
    html += "<div class='primary'>";
    if( has_inventory && card_inventory[card.id] && card_inventory[card.id] > 0 ) {
      html += "<div class='quantity'><span>" + card_inventory[card.id] + "</span><span>x</span></div>";
    }

    html += "<div class='name rarity-" + card.rarity +"'>" + card.name + "</div>";
    html += "</div>";

    //html += "<div class='type'>" + I18n.t("js.types." + card.category) + "</div>";
    html += "<div class='data'>";
    html += "<div class='cost'><div class='imgflow'><img src='" + card.images.resource + "'></div><span>" + card.total_cost + "</span></div>";
    html += "<div class='stats'>";
    if( card.stats.atk ) html += "<div class='atk'>" + I18n.t("js.atk") + " <span>" + card.stats.atk + "</span></div>";
    if( card.stats.cd ) html += "<div class='cd'>" + I18n.t("js.cd") + " <span>" + card.stats.cd + "</span></div>";
    if( card.stats.hp ) html += "<div class='hp'>" + I18n.t("js.hp") + " <span>" + card.stats.hp + "</span</div>";
    html += "</div>";
    html += "</div>";
    html += "</div>";
    html += "</li>";

    card_rows[i] = $(html);
    attach_states[i] = true;
  }

  var list = $("#cards .well ul");
  for( var i=0; i < total_cards; i++ ) {
    card_rows[i].appendTo(list);
  }

  $("#cards .well").on("mouseenter", "ul li", function() {
    ScrollsPost.Helpers.render_tooltip(game_card, card_data[$(this).data("internal-id")]);
  });

  $("#deck .well").on("mouseenter", ".deck-card", function(event) {
    if( $("#search:visible").length == 1 ) {
      ScrollsPost.Helpers.render_tooltip(game_card, card_data[$(this).data("internal-id")]);
    } else {
      ScrollsPost.quick_tooltip($(this), card_data[$(this).data("internal-id")], event);
    }
  }).on("mouseleave", ".deck-card", function() {
    ScrollsPost.hide_tooltip()
  });

  $("#summary .well, #manage .well").mouseenter(function() {
    $("html").removeClass("noselect");
  });

  $("#summary .well, #manage .well").mouseleave(function() {
    $("html").addClass("noselect");
  });

  // Card visibility if we hit 3
  function card_draggable(internal_id, enable) {
    if( enable ) {
      card_rows[internal_id].removeClass("limit-hit");
    } else {
      card_rows[internal_id].addClass("limit-hit");
    }
  }

  // Filtering of cards
  var search = $("#search");

  function update_cards() {
    // Grab the filters
    var resources = {};
    $("#resources .btn").each(function() {
      var row = $(this);
      if( row.hasClass("active") ) resources[row.data("key")] = true;
    });

    var rarities = {};
    $("#rarities .btn").each(function() {
      var row = $(this);
      if( row.hasClass("active") ) rarities[row.data("key")] = true;
    });

    var category = $("#categories li.active a").data("key");
    if( category == "all" ) category = null;
    var rules = $("#rules li.active a").data("key");
    if( rules == "all" ) rules = null;

    var name = $.trim($("#name input").val());
    if( name != "" ) {
      name = new RegExp(name, "i");
    }

    // Start filtering
    var active_cards = {};
    var has_active = null;
    for( var i=0; i < total_cards; i++ ) {
      var card = card_data[i];
      if( config.force_inventory && has_inventory ) {
        if( !card_inventory[card.id] || card_inventory[card.id] <= 0 || ( card_count[card.card_id] && card_count[card.card_id] >= card_inventory[card.id] ) ) {
          continue;
        }
      }

      if( category != null && card.category != category ) {
        continue;
      }

      if( rules != null && $.inArray(rules, card.passive_rule_slugs) == -1 ) {
        continue;
      }

      if( !rarities[card.rarity] ) continue;

      var invalid = true;
      for( var key in resources ) {
        if( $.inArray(key, card.resources) != -1 ) {
          invalid = false;
          break;
        }
      }

      if( invalid ) continue;

      if( name && !card.name.match(name) ) continue;

      active_cards[i] = true;
      has_active = true;
    }

    $("#no-cards")[has_active ? "hide" : "show"]();

    var first_id = null;
    for( var i=0; i < total_cards; i++ ) {
      if( active_cards[i] && !attach_states[i] ) {
        card_rows[i].show();
        attach_states[i] = true;

      } else if( !active_cards[i] && attach_states[i] ) {
        card_rows[i].hide();
        attach_states[i] = false;
      }

      if( !first_id && attach_states[i] ) {
        first_id = i;
      }
    }

    if( first_id ) {
      ScrollsPost.Helpers.render_tooltip(game_card, card_data[first_id]);
    }
  }

  search.find(".btn-group .btn").click(update_cards);
  search.find(".dropdown-menu a").click(update_cards);
  search.find("input[type='text']").keyup(update_cards);
  search.find("form").submit(function(e) {e.preventDefault(); update_cards()});

  // Card management
  function construct_deck_card(internal_id, card) {
    if( typeof(card) != "object" ) {
      console.log("WARNING: Unknown internal id " + internal_id + " given, cannot load card.");
      return;
    }

    var html = "<div class='deck-card' style='background-image: url(\"" + card.images.card + "\")' data-internal-id=" + internal_id + ">";
    html += "<div class='name rarity-" + card.rarity +"'>" + card.name + "</div>";
    html += "<div class='data'>";
    html += "<div class='cost'><img src='" + card.images.resource + "'><span>" + card.total_cost + "</span></div>";
    html += "<div class='stats'>";
    if( card.stats.atk ) html += "<div class='atk'>" + I18n.t("js.atk") + " <span>" + card.stats.atk + "</span></div>";
    if( card.stats.cd ) html += "<div class='cd'>" + I18n.t("js.cd") + " <span>" + card.stats.cd + "</span></div>";
    if( card.stats.hp ) html += "<div class='hp'>" + I18n.t("js.hp") + " <span>" + card.stats.hp + "</span</div>";
    html += "</div>";
    html += "</div>";

    deck_card = $(html).hide();
    deck_card.appendTo(scope);
    deck_card.fadeIn(100);

    return deck_card;
  }

  var dragging, deck_card, active_card, drag_type, startX, startY;
  var deck_container = $("#deck .well");

  // Update card status based on inventory
  function update_card_inventory(internal_id) {
    if( !has_inventory ) return;

    var inventory = card_inventory[card_data[internal_id].id];
    if( !inventory || inventory == 0 ) return;

    var leftover = Math.max(inventory - card_count[card_data[internal_id].card_id], 0);
    card_rows[internal_id].find(".quantity span:first").text(leftover);

    if( !config.force_inventory ) return;

    // Ran out of cards, hide it
    if( leftover <= 0 ) {
      if( attach_states[internal_id] ) {
        card_rows[internal_id].hide();
        attach_states[internal_id] = false;
      }
    // Have enough again, can show it
    } else if( !attach_states[internal_id] ) {
      attach_states[internal_id] = true;
      card_rows[internal_id].show();
    }
  }

  // Remove a card
  function remove_card(card) {
    var internal_id = card.data("internal-id");
    var card_id = card_data[internal_id].card_id;
    if( card_count[card_id] == 3 ) {
      card_draggable(internal_id, true);
    }

    card_count[card_id] -= 1;

    if( deck_container.find(".deck-card").length == 1 ) {
      $("#deck-empty").fadeIn(100);
    }

    card.remove();

    var uniq_id = card.data("uniq-id");
    for( var i=0, total=deck_cards[internal_id].length; i< total; i++ ) {
      if( deck_cards[internal_id][i].data("uniq-id") == uniq_id ) {
        deck_cards[internal_id].splice(i, 1);
        break;
      }
    }

    if( card_count[card_id] <= 0 ) {
      delete(deck_cards[internal_id]);
      delete(deck_offsets[internal_id]);

      if( config.auto_align ) {
        organize_cards(internal_id);
      }
    }

    store_deck();

    ScrollsPost.hide_tooltip();

    // Update the card list quantity
    update_card_inventory(internal_id);
  }

  // Block the right click menu when running under click controls
  $("#cards, #deck").contextmenu(function(event) {
    if( config.click_controls ) {
      event.preventDefault();
    }
  });

  // Drag movements
  $("#deck .well").on("mousedown", ".deck-card", function(event) {
    event.preventDefault();

    var internal_id = $(this).data("internal-id");
    if( config.click_controls && event.which == 3 ) {
      remove_card($(this));
      return;
    } else if( event.which != 1 ) {
      return;
    }

    startX = event.pageX;
    startY = event.pageY;

    active_card = card_data[internal_id];
    deck_card = $(this);
    deck_card[0].style.zIndex = 10;

    dragging = true;
    drag_type = "deck";

    dragOffsetY = event.pageY - this.offsetTop;
    dragOffsetX = event.pageX - this.offsetLeft;
  });

  // Start drag logging
  $("#cards .well ul li").mousedown(function(event) {
    event.preventDefault();

    var internal_id = $(this).data("internal-id");
    if( config.click_controls && event.which == 3 && deck_cards[internal_id] ) {
      remove_card(deck_cards[internal_id][deck_cards[internal_id].length - 1]);
      return;
    }

    var card_id = card_data[internal_id].card_id
    if( card_count[card_id] && card_count[card_id] >= 3 ) return;

    if( config.click_controls ) {
      if( event.which != 1 ) return;

      active_card = card_data[$(this).data("internal-id")];
      deck_card = construct_deck_card(active_card.internal_id, active_card);

      drag_type = "cards";
      dragging = true;
      return;
    }

    startX = event.pageX;
    startY = event.pageY;

    active_card = card_data[$(this).data("internal-id")];

    dragging = true;
    drag_type = "cards";
  });

  var dragOffsetX, dragOffsetY;
  $(document).mousemove(function(event) {
    if( !dragging || config.click_controls ) return;

    var xOffset = event.pageX, yOffset = event.pageY;

    // Need to do a fancy drag
    if( drag_type == "cards" ) {
      var xDiff = Math.abs(event.pageX - startX);
      var yDiff = Math.abs(event.pageY - startY);
      if( xDiff <= 4 && yDiff <= 4 ) return;

      if( !deck_card ) {
        $("#deck-empty").fadeOut(100);
        deck_card = construct_deck_card(active_card.internal_id, active_card);
      }

      yOffset -= 75;
      xOffset -= 100;

    // Otherwise try and keep it based on where the cursor was
    } else {
      yOffset -= dragOffsetY;
      xOffset -= dragOffsetX;
    }

    deck_card[0].style.top = yOffset + "px";
    deck_card[0].style.left = xOffset + "px";
  });

  var uniq_id = 0;
  $(document).mouseup(function(event) {
    if( !dragging ) return;

    dragging = false;
    active_card = null;

    var type = config.click_controls ? "deck" : check_collision(deck_card, event.pageX, event.pageY);

    // Add it to the deck
    if( type == "deck" ) {
      var internal_id = deck_card.data("internal-id");
      if( drag_type == "cards" ) {
        if( config.click_controls ) {
          var pos = deck_container.position();
          deck_card[0].style.top = pos.top + "px";
          deck_card[0].style.left = pos.left + "px";
        }

        if( !deck_offsets[internal_id] ) deck_offsets[internal_id] = {};

        var card_id = card_data[internal_id].card_id;
        if( !card_count[card_id] ) card_count[card_id] = 0;
        card_count[card_id] += 1;

        if( card_count[card_id] >= 3 ) {
          card_draggable(internal_id, false);
        }

        $("#deck-empty").hide();
      }

      deck_card[0].style.zIndex = "auto";
      deck_card.detach();
      deck_card.appendTo(deck_container);

      if( !deck_cards[internal_id] ) deck_cards[internal_id] = [];
      deck_cards[internal_id].push(deck_card);
      deck_card.data("uniq-id", uniq_id += 1);

      if( config.auto_align ) {
        organize_cards(internal_id);
      } else {
        snap_to_box(deck_card);
      }

      deck_card = null;
      store_deck();

      update_card_inventory(internal_id);

    // Just hide it
    } else if( deck_card ) {
      if( drag_type == "deck" ) {
        remove_card(deck_card);
      }

      deck_card.fadeOut(150, function() { $(this).remove(); });
      deck_card = null;
    }
  });

  var cards_box, deck_box;
  function calculate_boxes() {
    if( cards_box || deck_box ) return;

    var pos = $("#cards").position();
    cards_box = {};
    cards_box.top = pos.top;
    cards_box.left = pos.left;
    cards_box.bottom = pos.top + $("#cards").height();
    cards_box.right = pos.left + $("#cards").width();

    pos = $("#deck").position();

    deck_box = {};
    deck_box.top = pos.top;
    deck_box.left = pos.left;
    deck_box.bottom = pos.top + $("#deck").height();
    deck_box.right = pos.left + $("#deck").width();
  }

  function snap_to_box(object) {
    calculate_boxes();

    var pos = object.position();
    if( pos.top <= (deck_box.top + 10) ) {
      object[0].style.top = (deck_box.top + 10) + "px";
    }

    var bottom = pos.top + object.height();
    if( bottom >= deck_box.bottom ) {
      object[0].style.top = (deck_box.bottom - object.height() - 36) + "px";
    }

    if( pos.left <= (deck_box.left + 40) ) {
      object[0].style.left = (deck_box.left + 36) + "px";
    }

    var right = pos.left + object.width();
    if( right >= (deck_box.right + 40) ) {
      object[0].style.left = (deck_box.right - object.width() + 20) + "px";
    }
  }

  function check_collision(object, x, y) {
    calculate_boxes();

    if( cards_box.top <= y && cards_box.bottom >= y ) {
      if( cards_box.left <= x && cards_box.right >= x ) {
        return "cards";
      }
    }

    if( deck_box.top <= y && deck_box.bottom >= y ) {
      if( (deck_box.left - object.width()) <= x && (deck_box.right + object.width()) >= x ) {
        return "deck";
      }
    }

    return null;
  }

  // Handle resizing to recache our bounding boxes
  // as well as fixing all the out of bound cards
  var snap_cards;
  function full_collision_check() {
    if( config.auto_align ) {
      organize_cards();
    } else {
      deck_container.find(".deck-card").each(function() {
        snap_to_box($(this));
      });
    }
  }

  $(window).resize(function() {
    cards_box = null, deck_box = null;

    if( snap_cards ) clearTimeout(snap_cards);
    snap_cards = setTimeout(full_collision_check, 500);
  });

  // Showing/hiding the preview/search UI
  $("#toggle-search").click(function(event) {
    event.preventDefault();

    var offset = $("#preview-search").height();

    if( !$("#preview-search").is(":visible") ) {
      $("#preview-search").show();
      $(this).text(I18n.t("js.hide_search"));
    } else {
      $("#preview-search").hide();
      $(this).text(I18n.t("js.show_search"));
      offset *= -1;
    }

    cards_box = null, deck_box = null;
    deck_container.find(".deck-card").each(function() {
      this.style.top = (parseInt(this.style.top) + offset) + "px";

      deck_offsets[$(this).data("internal-id")].y += offset;
    });
  });

  // Figure out stats about the deck
  var stat_fields = {}, cat_fields = {};
  scope.find("#summary dd").each(function() {
    var klass = $(this).attr("class");
    if( klass == "category" ) {
      cat_fields[$(this).data("category")] = $(this);
    } else {
      stat_fields[klass] = $(this);
    }
  });

  var no_precision = {precision: 0};
  function calculate_stats() {
    var cost = 0;
    var total = 0;
    var avg = 0;

    var categories = {};
    for( var card_id in card_count ) {
      var quantity = card_count[card_id];
      if( quantity <= 0 ) continue;

      var card = card_data[id_map[card_id]];

      total += quantity;
      cost += (card.price.suggested * quantity);

      if( !categories[card.category] ) categories[card.category] = 0;
      categories[card.category] += quantity;
    }

    avg = total > 0 ? (cost / total) : 0;

    stat_fields["total-cost"].html(I18n.toNumber(cost, no_precision) + "<span class='gold'>" + I18n.t("js.gold_suffix") + "</span>");
    stat_fields["avg-cost"].html(I18n.toNumber(avg, no_precision) + "<span class='gold'>" + I18n.t("js.gold_suffix") + "</span>");
    stat_fields["total-cards"].text(total);

    for( var id in cat_fields ) {
      cat_fields[id].text(categories[id] || 0);
    }
  }

  // Handle positioning cards on the board automatically
  function organize_cards(changed_id, skip_animation) {
    calculate_boxes();

    var xOffsetStart = deck_box.left + 36;
    var xOffset = xOffsetStart, yOffset = deck_box.top + 10;

    // We don't need to reposition everything if the card is already organized
    if( changed_id != null && card_count[card_data[changed_id].card_id] > 1 && deck_offsets[changed_id] ) {
      var cards = deck_cards[changed_id];
      yOffset = deck_offsets[changed_id].y;
      xOffset = deck_offsets[changed_id].x;

      var yPad = 20;
      for( var i=1, total=cards.length; i < total; i++ ) {
        cards[i][0].style.zIndex = i;
        cards[i][0].style.top = (yOffset + yPad) + "px";
        cards[i][0].style.left = xOffset + "px";

        yPad += 20;
      }

      return;
    }

    var list = deck_container.find(".deck-card");
    var maxX = deck_box.right - 20;
    var width = list.first().width() + 5;
    var height = list.first().height() + 30;

    // We're modifying the position of everything at >= this card
    // Figure out the position of something we can anchor to reduce the work
    if( changed_id != null && !deck_cards[changed_id] ) {
      var last_card;
      for( var internal_id=0; internal_id < changed_id; internal_id++ ) {
        if( deck_cards[internal_id] ) {
          last_card = internal_id;
        }
      }

      if( last_card ) {
        yOffset = deck_offsets[last_card].y;
        xOffset = deck_offsets[last_card].x + width;
        if( xOffset >= maxX ) {
          yOffset += height;
          xOffset = xOffsetStart;
        }

      } else {
        changed_id = null;
      }
    } else {
      changed_id = null;
    }

    // Reposition
    var anim_opts = {duration: 300, queue: false, easing: "linear"};
    for( var internal_id=(changed_id || 0); internal_id < total_cards; internal_id++ ) {
      var cards = deck_cards[internal_id];
      if( !cards ) continue;

      var card_id = card_data[internal_id].card_id;

      var yPad = 0;
      for( var i=0, total=card_count[card_id]; i < total; i++ ) {
        cards[i][0].style.zIndex = i;

        if( !skip_animation ) {
          cards[i].stop();
          cards[i].animate({top: (yOffset + yPad) + "px", left: xOffset + "px"}, anim_opts);
        } else {
          cards[i][0].style.top = (yOffset + yPad) + "px";
          cards[i][0].style.left = xOffset + "px";
        }


        yPad += 20;
      }

      deck_offsets[internal_id].x = xOffset;
      deck_offsets[internal_id].y = yOffset;

      xOffset += width;
      if( xOffset >= maxX ) {
        yOffset += height;
        xOffset = xOffsetStart;
      }
    }

    deck_container.css("height", yOffset - deck_box.top + (height * 2));
  }

  // Bulk adding of cards
  var run_id = 0;
  function bulk_add_cards(card_ids) {
    $("#deck-empty").hide();

    if( !deck_cards ) deck_cards = {};
    if( !deck_offsets ) deck_offsets = {};
    run_id += 1;

    for( var card_id in card_ids ) {
      var quantity = card_ids[card_id];
      var internal_id = id_map[card_id];
      var card = card_data[internal_id];

      if( !deck_offsets[internal_id] ) deck_offsets[internal_id] = {};

      card_count[card_id] = quantity;
      if( quantity >= 3 ) card_draggable(internal_id, false);
      update_card_inventory(internal_id);

      if( !deck_cards[internal_id] ) deck_cards[internal_id] = [];

      for( var i=0; i < quantity; i++ ) {
        var deck_card = deck_cards[internal_id][i];
        if( !deck_card ) {
          deck_card = construct_deck_card(internal_id, card);
          deck_card.data("uniq-id", uniq_id += 1);
          deck_card.appendTo(deck_container);
          deck_cards[internal_id].push(deck_card);
        }

        deck_card.data("marked", run_id);
      }
    }

    if( run_id > 1 ) {
      for( var internal_id in deck_cards ) {
        var list = [];
        for( var i=0, total=deck_cards[internal_id].length; i < total; i++ ) {
          if( deck_cards[internal_id][i].data("marked") == run_id ) {
            list.push(deck_cards[internal_id][i]);
          } else {
            deck_cards[internal_id][i].remove();
          }
        }

        if( list.length == 0 ) {
          delete(deck_cards[internal_id]);
          delete(deck_offsets[internal_id]);
          card_count[card_data[internal_id].card_id] = 0;

          card_draggable(internal_id, true);
          update_card_inventory(internal_id);

        } else {
          deck_cards[internal_id] = list;
        }

      }
    }

    organize_cards(null, true);
    calculate_stats();
  }


  if( window.location.hash != "" && window.location.hash.match(/;/) ) {
    bulk_add_cards(ScrollsPost.Helpers.cards.decode(window.location.hash.substring(1)));

    setTimeout(function() {
      $("#loading").modal("hide");
    }, 200);
  } else {
    $("#loading").modal("hide");
  }

  // Add historical data for changing cards on hash changes automatically
  var new_hash = null;
  $(window).on("hashchange", function() {
    if( new_hash == window.location.hash ) return;
    bulk_add_cards(ScrollsPost.Helpers.cards.decode(window.location.hash.substring(1)));
  });


  // And create the URL to store data in
  function store_deck() {
    var str = ScrollsPost.Helpers.cards.encode(card_count);
    new_hash = str ? ("#" + str) : null;
    window.location.hash = str || "";

    calculate_stats();
  }
}