ScrollsPost.PAGES["stats/online"] = ScrollsPost.PAGES["stats/total_cards"] = ScrollsPost.PAGES["stats/total_sold"] = ScrollsPost.PAGES["stats/total_gold"] = function() {
  function configure_graph(graph, period, data) {
    var graph_data = {};
    graph_data.chart = {
      type: "line",
      zoomType: "x",
      marginTop: 20,
      marginBottom: 40,
      marginRight: 15,
    };

    graph_data.legend = {
      enabled: false
    }

    graph_data.tooltip = {
      shared: true,
      pointFormat: '<span style="color:{series.color}">' + I18n.t("js.total") + '</span>: <b>{point.y}</b><br/>'
    };

    graph_data.xAxis = {
      type: "datetime", tickInterval: period * 1000, datalabels: {enabled: true},
      plotBands: plot_bands,
    };

    graph_data.xAxis.labels = {
      rotation: -30,
      y: 20
    };

    graph_data.yAxis = [
      {title: {text: false, allowDecimals: false, min: 0}}
    ];

    graph_data.yAxis[0].title.x = -5;
    graph_data.yAxis[0].title.style = {
      color: "#2f7ed8"
    };

    graph_data.yAxis[0].labels = {
      style: {color: "#2f7ed8"},
      x: -20
    };

    graph_data.series = [
      {data: data},
    ]

    graph.highcharts(graph_data);
  }

  configure_graph($("#graph-day"), 3600, stats_day);
  configure_graph($("#graph-week"), 86400 / 2, stats_week);
}