ScrollsPost.PAGES["replays/show"] = function() {
  var scope = $("#replays_show");

  scope.find(".show-spoilers").click(function(event) {
    event.preventDefault();
    scope.find(".nospoiler").remove();
    scope.find(".spoiler").show();
  });

  $("#downloads a:first").click(function() {
    $("#replay-info").modal("show");
  });

  $("#downloads a:last").click(function() {
    $("#replay-url").modal("show");
  });

  // Setup the deck URLs
  for( var side in card_summary ) {
    var deck = ScrollsPost.Helpers.cards.encode(card_summary[side]);
    if( deck == "1;" ) continue;

    var link = $("#deck-" + side);
    link.attr("href", link.attr("href") + deck);
  }

  // Damage graphs
  if( ScrollsPost.graphs ) {
    var resource_color = {
      growth: "#97DE1D",
      decay: "#D01CE8",
      energy: "#edbd36",
      order: "#184DED"
    }

    function update_cards_played(side, round) {
      var cards = ScrollsPost.graphs[side].cards[round];

      var played = $("#damage-chart").find(".side-" + side + " .cards-played");
      var label = played.find("span:first");
      label.text(label.data("text").replace("{number}", round));
      if( cards ) {
        played.find("ul").html(cards);
      } else {
        played.find("ul").html("<li><div class='no-cards'>" + I18n.t("js.none") + "</div></li>");
      }

    }

    // Figure out stats for graph limits
    var most_damage = 0, most_resources = 0;
    for( var side in ScrollsPost.graphs ) {
      for( var i=0, total=ScrollsPost.graphs[side].damage.length; i < total; i++ ) {
        var dmg = ScrollsPost.graphs[side].damage[i][1];
        if( dmg > most_damage ) most_damage = dmg;
      }

      for( var type in ScrollsPost.graphs[side].resource ) {
        for( var i=0, total=ScrollsPost.graphs[side].resource[type].length; i < total; i++ ) {
          var res = ScrollsPost.graphs[side].resource[type][i][1];
          if( res > most_resources ) most_resources = res;
        }
      }
    }

    function configure_graph(side, data) {
      var graph = $("#graph-" + side);
      var graph_data = {};
      graph_data.colors = [];

      graph_data.chart = {
        type: "line",
        zoomType: "x",
        marginTop: 10,
        marginBottom: 80
      };

      graph_data.tooltip = {
        shared: true,
        headerFormat: "<span style='font-size: 10px'>" + I18n.t("js.round") + " {point.key}</span><br/>",
        borderColor: "#000000",
        formatter: function() {
          update_cards_played("white", this.x);
          update_cards_played("black", this.x);

          var items = this.points || Highcharts.splat(this);
          var series = items[0].series;
          var list = [series.tooltipHeaderFormatter(items[0])];
          Highcharts.each(items, function (item) {
            series = item.series;
            list.push((series.tooltipFormatter && series.tooltipFormatter(item)) || item.point.tooltipFormatter(series.tooltipOptions.pointFormat));
          });

          return list.join('');
        }
      };

      graph_data.xAxis = {
        type: "linear",
        datalabels: {enabled: true},
        allowDecimals: false
      };

      graph_data.xAxis.labels = {
        y: 20
      };

      graph_data.yAxis = [
        {title: {text: I18n.t("js.damage_done")}, allowDecimals: false, min: 0, max: most_damage},
        {title: {text: I18n.t("js.resources")}, opposite: true, allowDecimals: false, reverse: true, min: 0, max: most_resources}
      ];

      graph_data.yAxis[0].title.x = -5;
      graph_data.yAxis[0].title.style = {
        color: "#D42F45"
      };

      graph_data.yAxis[0].labels = {
        style: {color: "#D42F45"},
        x: -20
      };

      graph_data.yAxis[1].title.x = 5;
      graph_data.yAxis[1].title.style = {
        color: "#2f7ed8"
      };

      graph_data.yAxis[1].labels = {
        style: {color: "#2f7ed8"},
        x: 20
      };

      graph_data.legend = {
        enabled: true
      };

      graph_data.series = [];
      graph_data.series.push({type: "area", data: data.damage, name: I18n.t("js.damage_done")});
      graph_data.colors.push("#D42F45");

      for( var type in data.resource ) {
        graph_data.series.push({data: data.resource[type], name: "# " + I18n.t("js.resource." + type), yAxis: 1});
        graph_data.colors.push(resource_color[type]);
      }

      graph.highcharts(graph_data);
    }

    for( var side in ScrollsPost.graphs ) {
      configure_graph(side, ScrollsPost.graphs[side]);
      update_cards_played(side, ScrollsPost.graphs[side].first_card_round);
    }
  }
}