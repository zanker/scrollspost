Scrollspost::Application.routes.draw do
  get "/spping" => "internal#ping"

  controller :patches, :path => :patches, :as => :patches do
    get "/version-:version" => :show, :as => :show
    get "(/page-:page)" => :index, :defaults => {:page => "1"}
  end

  controller :mods, :path => :mods do
    get "/download/mod/:mod_id" => :download
    get "/repoinfo" => :repo
    get "/modlist" => :mods
  end

  namespace :api do
    namespace :v1 do
      controller :replays, :path => "/replays", :as => :replays do
        post "/" => :create
      end

      controller :pricing, :path => "/", :as => :pricing do
        get "/price/:period/:search" => :show, :as => :show
        get "/prices/:period" => :index
      end

      controller :users, :path => "/user" do
        post "/exists" => :exists
        post "/" => :create
        put "/" => :login
      end

      controller :cards, :path => "/cards" do
        post "/" => :update

        get "/" => :index
      end
    end
  end

  namespace :usercp do
    resource :settings, :only => [:edit, :update]

    resource :cards, :path => :scrolls, :only => :index do
      post "/pricing" => :pricing
      put "/" => :save_prices
      get "(/:sort_by-:sort_mode)" => :index, :as => :index, :defaults => {:sort_by => "", :sort_mode => ""}
    end
  end

  controller :deckbuilders, :path => :deckbuilder, :as => :deckbuilder do
    get "/" => :index
  end

  controller :store, :as => :store do
    get "/store/:account_id/:name(/:resources/:rarities/:category)(/:sort_by-:sort_mode)" => :show, :defaults => {:resources => "all", :rarities => "all", :category => "", :sort_by => "", :sort_mode => ""}
  end

  resource :sessions, :only => [:new, :create] do
    get "/logout" => :destroy
  end
  resources :users, :only => [:new, :create]

  resources :faq, :only => :index

  controller :cards, :as => :cards do
    get "/scroll/:card_id/:name/market" => :show_market, :as => :market, :constraints => {:card_id => /[0-9]+/}
    get "/scroll/:card_id/:name/store" => :show_store, :as => :store, :constraints => {:card_id => /[0-9]+/}
    get "/scroll/:card_id/:name/chat" => :show_chat, :as => :chat, :constraints => {:card_id => /[0-9]+/}
    get "/scroll/:card_id/:name/version-:version" => :show, :as => :show_old, :constraints => {:card_id => /[0-9]+/}
    get "/scroll/:card_id/:name" => :show, :constraints => {:card_id => /[0-9]+/}
    get "/scroll/tooltip/:card_id" => :tooltip
    get "/scroll/tooltips(/:cachebust/:webp)" => :tooltips, :as => :tooltips

    get "/scrolls/:resources/:rarities/:rule/:category(/cost-:min_cost-:max_cost)(/hp-:min_hp-:max_hp)(/cd-:min_cd-:max_cd)(/atk-:min_atk-:max-atk)(/:sort_by-:sort_mode)" => :index, :as => :index_search, :defaults => {:resources => "all", :rarities => "all", :rule => "all", :category => "all", :min_hp => "", :max_hp => "", :min_cd => "", :max_cd => "", :min_atk => "", :max_atk => "", :sort_by => "", :sort_mode => ""}
    get "/scrolls/" => :index, :as => :index, :defaults => {:resources => "all", :rarities => "all", :rule => "all", :category => "all", :min_hp => "", :max_hp => "", :min_cd => "", :max_cd => "", :min_atk => "", :max_atk => "", :sort_by => "", :sort_mode => ""}
  end

  controller :pricing, :path => :pricing, :as => :pricing do
    get "/stores(/:resources/:rarities/:category)(/:sort_by-:sort_mode)" => :store, :as => :store, :defaults => {:resources => "all", :rarities => "all", :category => "", :sort_by => "", :sort_mode => ""}
    get "/chat" => :chat, :as => :chat

    get "/:resources/:rarities/:period(/version-:version)(/:sort_by-:sort_mode)" => :index, :as => :index_search, :defaults => {:resources => "all", :rarities => "all", :period => "1-day", :sort_by => "", :sort_mode => ""}
    get "/" => :index, :defaults => {:resources => "all", :rarities => "all", :period => "1-day", :sort_by => "", :sort_mode => ""}
  end

  controller :replays do
    get "/replay/download/:game_id-:perspective.:format" => :download, :as => :download_replay
    get "/replay/:game_id-:perspective(/:page_type)/:name1-vs-:name2" => :show, :as => :show_replay

    get "/replays/player/:player_id/:name(/:resources)(/type-:type)(/version-:version)(/rating-:min_rating-:max_rating)(/sort-:sort_by-:sort_mode)(/page-:page)" => :index, :as => :replays_index_player, :defaults => {:resources => "all", :type => "all", :min_rating => "", :max_rating => "", :sort_by => "", :sort_mode => "", :page => "1"}

    get "/replays/:resources(/type-:type)(/version-:version)(/rating-:min_rating-:max_rating)(/sort-:sort_by-:sort_mode)(/page-:page)" => :index, :as => :replays_index_search, :defaults => {:resources => "all", :type => "all", :min_rating => "", :max_rating => "", :sort_by => "", :sort_mode => "", :page => "1"}
    get "/replays/" => :index, :defaults => {:resources => "all", :type => "all", :min_rating => "", :max_rating => "", :sort_by => "", :sort_mode => "", :page => "1"}
  end

  controller :stats, :path => "game-stats", :as => :stat do
    get "/online" => :online
    get "/cards" => :total_cards, :as => :cards
    get "/gold" => :total_gold
    get "/sold" => :total_sold
  end

  controller :news, :path => "/news", :as => :news do
    get "(/page-:page)" => :index, :as => :index, :defaults => {:page => "1"}
    get "/page-:page" => :index
    get "/:slug" => :show, :as => :show
  end

  get "/sitemap.xml" => "sitemap#index"
  get "/" => redirect("/pricing"), :as => :root

  unless Rails.env.production?
    match "/404" => "error#routing"
  end
end
