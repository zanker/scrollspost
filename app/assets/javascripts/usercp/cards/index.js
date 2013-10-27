ScrollsPost.PAGES["usercp/cards/index"] = function() {
  var scope = $("#usercp_cards_index");
  // Tabs
  scope.find(".nav-tabs li a").click(function(event) {
    $(this).tab("show");
  });

  // Dropdowns
  scope.find(".dropdown-menu a").click(function(event) {
    event.preventDefault();

    var dropdown = $(this).closest(".dropdown");

    var label = dropdown.find(".dropdown-toggle span");
    label.html(label.data("prefix") + " <span>" + $(this).text() + "</span>");

    dropdown.find("li.active").removeClass("active");
    $(this).closest("li").addClass("active");
  });

  // Change logger
  var changes = {}, unsaved = null, pending = null;
  function log_change(card_id, field, value) {
    if( !changes[card_id] ) changes[card_id] = {};
    changes[card_id][field] = value;

    unsaved = true;
  }

  // Change pusher
  var saving = $("#saving");
  var update_timer;
  function push_updates() {
    if( !unsaved || pending ) {
      update_timer = setTimeout(push_updates, 2000);
      return;
    }

    saving.show();

    $.ajax(saving.data("path"), {
      type: "PUT",
      data: {updates: changes},
      error: function() {
        $("#sync-failed").modal("show");
      },
      success: function() {
        $("#sync-failed").modal("hide");
      },
      complete: function() {
        pending = null;
        setTimeout(push_updates, 2000);
        saving.hide();
      }
    });

    changes = {}, unsaved = null;
    pending = true;
  }

  update_timer = setTimeout(push_updates, 2000);

  // We're leaving with unsaved or pending
  window.onbeforeunload = function() {
    if( unsaved || pending ) {
      // Push an update immediately
      if( !pending ) {
        if( update_timer ) clearTimeout(update_timer);
        push_updates();
      }

      return I18n.t("js.pending_changes");
    }
  }

  // Check for changes to flag as update required
  $(".to-buy, .buy-price, .to-sell, .sell-price").keyup(function(event) {
    if( update_timer ) clearTimeout(update_timer);
    update_timer = setTimeout(push_updates, 5000);

    var card_id = $(this).closest("tr").data("card");
    log_change(card_id, $(this).data("key"), $(this).val());
  });


  // Auto quantity
  $("#tab-auto-quantity form").submit(function(event) {
    event.preventDefault();

    $(this).find("input[type='submit']").button("loading");

    var buy_mode = $("#buy-quantity li.active a").data("key");
    var sell_mode = $("#sell-quantity li.active a").data("key");

    var list = scope.find("table tbody tr");
    list.each(function() {
      var card_id = $(this).data("card");
      var buy = $(this).find(".to-buy");
      var sell = $(this).find(".to-sell");

      var quantity = $(this).data("quantity"), in_deck = $(this).data("deck"), tradable = $(this).data("trade");
      var missing = $(this).hasClass("missing");

      // Update buy
      var to_set;
      if( buy_mode != "" ) {
        switch( buy_mode ) {
          case "zero": to_set = 0; break;
          case "3-all": to_set = Math.max(3 - quantity, 0); break;
          case "2-all": to_set = Math.max(2 - quantity, 0); break;
          case "1-all": to_set = Math.max(1 - quantity, 0); break;
          case "3-have": to_set = quantity > 0 ? Math.max(3 - quantity, 0) : 0; break;
          case "2-have": to_set = quantity > 0 ? Math.max(2 - quantity, 0) : 0; break;
          case "3-deck": to_set = in_deck > 0 ? Math.max(3 - in_deck, 0) : 0; break;
          case "2-deck": to_set = in_deck > 0 ? Math.max(2 - in_deck, 0) : 0; break;
          case "3-miss": to_set = missing ? Math.max(3 - quantity, 0) : 0; break;
          case "2-miss": to_set = missing ? Math.max(2 - quantity, 0) : 0; break;
          case "1-miss": to_set = missing ? Math.max(1 - quantity, 0) : 0; break;
        }

        if( to_set != buy.val() ) {
          log_change(card_id, "buy-quantity", to_set);
        }

        buy.val(to_set);
      }

      // Update sell
      if( sell_mode != "" ) {
        to_set = 0;
        switch( sell_mode ) {
          case "zero": to_set = 0; break;
          case "non-deck": to_set = Math.max(tradable - in_deck, 0); break;
          case "3-keep": to_set = Math.max(tradable - 3, 0); break;
          case "2-keep": to_set = Math.max(tradable - 2, 0); break;
          case "1-keep": to_set = Math.max(tradable - 1, 0); break;
        }


        if( to_set != sell.val() ) {
          log_change(card_id, "sell-quantity", to_set);
        }

        sell.val(to_set);
      }
    });

    $(this).find("input[type='submit']").button("reset");
  });

  // Auto price
  $("#tab-auto-price form").submit(function(event) {
    event.preventDefault();

    $(this).find("input[type='submit']").button("loading");

    $.ajax($(this).attr("action"), {
      type: "POST",
      data: {period: $("#period li.active a").data("key")},
      success: function(res) {
        var modifier = parseInt($("#percent input").val());
        if( !$.isNumeric(modifier) ) modifier = 0;
        if( modifier != 0 ) modifier = modifier / 100;
        modifier += 1;

        var table = scope.find("table tbody");
        for( var card_id in res ) {
          var price = Math.round((res[card_id] * modifier) / 5) * 5;
          table.find("tr[data-card='" + card_id + "']").find(".buy input.buy-price, .sell input.sell-price").val(price);

          log_change(card_id, "buy", price);
          log_change(card_id, "sell", price);
        }

        scope.find("input[type='submit']").button("reset");
      }
    });
  });
}