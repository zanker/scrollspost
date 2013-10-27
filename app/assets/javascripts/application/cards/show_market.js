ScrollsPost.PAGES["cards/show_market"] = function() {
  var scope = $("#cards_show_market");

  var graph_base = {};
  graph_base.chart = {
    type: "line",
    zoomType: "x",
    marginTop: 10,
    marginBottom: 80,
  };

  graph_base.tooltip = {
    shared: true
  };

  graph_base.xAxis = {
    type: "datetime", tickInterval: 86400 * 1000, datalabels: {enabled: true}
  };

  graph_base.xAxis.labels = {
    rotation: -30,
    y: 20
  };

  function configure_graph(graph, type, data) {
    var graph_data = $.merge(graph_base, {});
    graph_data.chart = {
      type: "line",
      zoomType: "x",
      marginTop: 20,
      marginBottom: 80,
      marginRight: 15,
    };

    graph_data.tooltip = {
      shared: true
    };

    graph_data.xAxis = {
      type: "datetime", tickInterval: 86400 * 1000, datalabels: {enabled: true},
      plotBands: plot_bands,
    };

    graph_data.xAxis.labels = {
      rotation: -30,
      y: 20
    };

    graph_data.yAxis = [
      {title: {text: I18n.t("js." + type + "_price"), allowDecimals: false, min: 0}}
      //{title: {text: I18n.t("js.units")}, opposite: true, allowDecimals: false, reversed: true, min: 0},
    ];

    graph_data.yAxis[0].title.x = -5;
    graph_data.yAxis[0].title.style = {
      color: "#2f7ed8"
    };

    graph_data.yAxis[0].labels = {
      style: {color: "#2f7ed8"},
      x: -20
    };

    /*
    graph_data.yAxis[1].title.x = 5;
    graph_data.yAxis[1].title.style = {
      color: "#8bbc21"
    };

    graph_data.yAxis[1].labels = {
      style: {color: "#8bbc21"},
      x: 20
    };
    */

    graph_data.legend = {
      enabled: true
    };

    graph_data.series = [
      {data: data["price"], name: I18n.t("js." + type + "_price")},
      {data: data["suggested"], name: I18n.t("js.suggested_price")}
      //{data: data["units"], yAxis: 1, name: I18n.t("js.units")}
    ]

    graph.highcharts(graph_data);
  }

  configure_graph($("#buy-graph"), "buy", buy_stats);
  configure_graph($("#sell-graph"), "sell", sell_stats);

  // Setup the units sold graph which is separate
  var graph_data = $.merge(graph_base, {});
  delete(graph_data.chart.marginRight);

  graph_data.colors = ["#2f7ed8", "#8bbc21"];
  graph_data.yAxis = [
    {title: {text: I18n.t("js.buy_units"), allowDecimals: false}, min: 0},
    {title: {text: I18n.t("js.sell_units"), allowDecimals: false}, min: 0, reverse: true, opposite: true}
  ];

  graph_data.yAxis[0].title.x = -5;
  graph_data.yAxis[0].title.style = {
    color: "#2f7ed8"
  };

  graph_data.yAxis[0].labels = {
    style: {color: "#2f7ed8"},
    x: -20
  };

  graph_data.yAxis[1].title.x = 5;
  graph_data.yAxis[1].title.style = {
    color: "#8bbc21"
  };

  graph_data.yAxis[1].labels = {
    style: {color: "#8bbc21"},
    x: 20
  };

  graph_data.legend = {
    enabled: true
  };

  graph_data.series = [
    {data: unit_stats["buy"], name: I18n.t("js.buy_units")},
    {data: unit_stats["sell"], yAxis: 1, name: I18n.t("js.sell_units")},
  ]

  $("#unit-graph").highcharts(graph_data);
}