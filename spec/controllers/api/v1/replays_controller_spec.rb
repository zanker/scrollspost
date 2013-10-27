require "spec_helper"

describe Api::V1::ReplaysController do
  include ActionDispatch::TestProcess

  before :all do
    GameVersion.delete_all
    @game_version = GameVersion.create!(:version => "0.95.1")
    @new_game_version = GameVersion.create!(:version => "0.96.0")
  end

  before :each do
    Replay.delete_all
  end

  after :each do
    File.unlink(Rails.root.join("public", "system", "replays", "4066803-black.spr")) rescue nil
    File.unlink(Rails.root.join("public", "system", "replays", "4170740-white.spr")) rescue nil
    File.unlink(Rails.root.join("public", "system", "replays", "4889608-black.spr")) rescue nil
  end

  it "uploads a new Scrolls replay" do
    File.unlink(Rails.root.join("public", "system", "replays", "4889608-black.spr")) rescue nil

    file = fixture_file_upload(Rails.root.join("spec", "assets", "replays", "4889608-black.spr"))

    post :create, :replay => file
    response.code.should == "200"

    replay = Replay.last
    replay.should_not be_nil
    replay.white_cards.should == [[50, 1], [52, 2], [99, 1], [128, 1], [15, 1], [20, 2], [71, 1], [125, 1]]
    replay.white_stats.should == {"udmg"=>5, "idmg"=>3, "uplay"=>4, "splay"=>5, "eplay"=>1, "drawn"=>17, "hdmg"=>4, "ikill"=>0, "hdmgID"=>128}
    replay.white_gold.should == {"match"=>0, "compl"=>0, "idols"=>0, "total"=>0}
    replay.white_rounds.should == [{"rnd"=>1, "t"=>3, "tc"=>0, "resources"=>{}, "hand"=>4}, {"rnd"=>1, "t"=>4, "hp"=>10, "pos"=>0, "diff"=>0}, {"rnd"=>1, "t"=>4, "hp"=>10, "pos"=>1, "diff"=>0}, {"rnd"=>1, "t"=>4, "hp"=>10, "pos"=>2, "diff"=>0}, {"rnd"=>1, "t"=>4, "hp"=>10, "pos"=>3, "diff"=>0}, {"rnd"=>1, "t"=>4, "hp"=>10, "pos"=>4, "diff"=>0}, {"rnd"=>1, "t"=>3, "tc"=>0, "resources"=>{}, "hand"=>5}, {"rnd"=>1, "t"=>1, "tc"=>0}, {"rnd"=>1, "t"=>3, "tc"=>0, "resources"=>{"order"=>1}, "hand"=>4}, {"rnd"=>3, "t"=>3, "tc"=>0, "resources"=>{"order"=>1}, "hand"=>5}, {"rnd"=>5, "t"=>3, "tc"=>0, "resources"=>{"order"=>1}, "hand"=>6}, {"rnd"=>7, "t"=>3, "tc"=>0, "resources"=>{"order"=>1}, "hand"=>7}, {"rnd"=>7, "t"=>1, "tc"=>0}, {"rnd"=>7, "t"=>3, "tc"=>0, "resources"=>{"order"=>2}, "hand"=>6}, {"rnd"=>7, "t"=>3, "tc"=>0, "resources"=>{"order"=>2}, "hand"=>5}, {"rnd"=>7, "t"=>6, "cid"=>50}, {"rnd"=>7, "t"=>5, "diff"=>1, "hp"=>2, "cid"=>41}, {"rnd"=>7, "t"=>3, "tc"=>0, "resources"=>{"order"=>2}, "hand"=>6}, {"rnd"=>9, "t"=>3, "tc"=>0, "resources"=>{"order"=>2}, "hand"=>7}, {"rnd"=>9, "t"=>3, "tc"=>0, "resources"=>{"order"=>2}, "hand"=>6}, {"rnd"=>9, "t"=>6, "cid"=>52}, {"rnd"=>9, "cid"=>52, "t"=>2}, {"rnd"=>9, "t"=>3, "tc"=>0, "resources"=>{"order"=>2}, "hand"=>5}, {"rnd"=>9, "t"=>6, "cid"=>99}, {"rnd"=>11, "t"=>3, "tc"=>0, "resources"=>{"order"=>2}, "hand"=>6}, {"rnd"=>11, "t"=>1, "tc"=>0}, {"rnd"=>11, "t"=>3, "tc"=>0, "resources"=>{"order"=>3}, "hand"=>5}, {"rnd"=>11, "t"=>3, "tc"=>0, "resources"=>{"order"=>3}, "hand"=>4}, {"rnd"=>11, "t"=>6, "cid"=>128}, {"rnd"=>11, "cid"=>128, "t"=>2}, {"rnd"=>13, "t"=>3, "tc"=>0, "resources"=>{"order"=>3}, "hand"=>5}, {"rnd"=>13, "t"=>1, "tc"=>0}, {"rnd"=>13, "t"=>3, "tc"=>0, "resources"=>{"order"=>4}, "hand"=>4}, {"rnd"=>13, "t"=>3, "tc"=>0, "resources"=>{"order"=>4}, "hand"=>3}, {"rnd"=>13, "t"=>6, "cid"=>15}, {"rnd"=>13, "t"=>3, "tc"=>0, "resources"=>{"order"=>4}, "hand"=>2}, {"rnd"=>13, "t"=>6, "cid"=>20}, {"rnd"=>15, "t"=>3, "tc"=>0, "resources"=>{"order"=>4}, "hand"=>3}, {"rnd"=>15, "t"=>1, "tc"=>0}, {"rnd"=>15, "t"=>3, "tc"=>0, "resources"=>{"order"=>5}, "hand"=>2}, {"rnd"=>15, "t"=>3, "tc"=>0, "resources"=>{"order"=>5}, "hand"=>1}, {"rnd"=>15, "t"=>6, "cid"=>71}, {"rnd"=>15, "t"=>5, "diff"=>6, "hp"=>-2, "cid"=>75, "kill"=>true}, {"rnd"=>17, "t"=>3, "tc"=>0, "resources"=>{"order"=>5}, "hand"=>2}, {"rnd"=>17, "t"=>3, "tc"=>0, "resources"=>{"order"=>5}, "hand"=>1}, {"rnd"=>17, "t"=>6, "cid"=>125}, {"rnd"=>17, "cid"=>125, "t"=>2}, {"rnd"=>19, "t"=>3, "tc"=>0, "resources"=>{"order"=>5}, "hand"=>2}, {"rnd"=>19, "t"=>0, "tc"=>0}, {"rnd"=>19, "t"=>3, "tc"=>0, "resources"=>{"order"=>5}, "hand"=>3}, {"rnd"=>19, "t"=>3, "tc"=>0, "resources"=>{"order"=>5}, "hand"=>2}, {"rnd"=>19, "t"=>6, "cid"=>20}, {"rnd"=>19, "t"=>3, "tc"=>0, "resources"=>{"order"=>5}, "hand"=>1}, {"rnd"=>19, "t"=>6, "cid"=>52}, {"rnd"=>19, "cid"=>52, "t"=>2}, {"rnd"=>19, "t"=>4, "hp"=>4, "pos"=>0, "diff"=>-3}]
    replay.white_sac_res.should == 5
    replay.white_sac_cards.should == 1
    replay.white_resources.should == ["order"]
    replay.white_res_totals.should == {"order" => 5}
    replay.white_time.should == 0
    replay.white_name.should == "Easy AI"
    replay.white_id.should == "RobotEasy"
    replay.black_cards.should == [[65, 1], [33, 2], [41, 1], [75, 2], [34, 2], [208, 2], [29, 1], [57, 2], [22, 1], [21, 1], [156, 1], [38, 1], [99, 1], [44, 1]]
    replay.black_stats.should == {"udmg"=>3, "idmg"=>34, "uplay"=>6, "splay"=>1, "eplay"=>2, "drawn"=>19, "hdmg"=>4, "ikill"=>3, "hdmgID"=>41}
    replay.black_gold.should ==  {"match"=>10, "compl"=>0, "idols"=>30, "total"=>40}
    replay.black_rounds.should == [{"rnd"=>1, "t"=>3, "tc"=>0, "resources"=>{}, "hand"=>5}, {"rnd"=>1, "t"=>4, "hp"=>10, "pos"=>0, "diff"=>0}, {"rnd"=>1, "t"=>4, "hp"=>10, "pos"=>1, "diff"=>0}, {"rnd"=>1, "t"=>4, "hp"=>10, "pos"=>2, "diff"=>0}, {"rnd"=>1, "t"=>4, "hp"=>10, "pos"=>3, "diff"=>0}, {"rnd"=>1, "t"=>4, "hp"=>10, "pos"=>4, "diff"=>0}, {"rnd"=>2, "t"=>3, "tc"=>1, "resources"=>{}, "hand"=>6}, {"rnd"=>2, "t"=>1, "tc"=>1, "cid"=>34}, {"rnd"=>2, "t"=>3, "tc"=>1, "resources"=>{"growth"=>1}, "hand"=>5}, {"rnd"=>4, "t"=>3, "tc"=>1, "resources"=>{"growth"=>1}, "hand"=>6}, {"rnd"=>4, "t"=>1, "tc"=>1, "cid"=>29}, {"rnd"=>4, "t"=>3, "tc"=>1, "resources"=>{"growth"=>2}, "hand"=>5}, {"rnd"=>4, "t"=>3, "tc"=>1, "resources"=>{"growth"=>2}, "hand"=>4}, {"rnd"=>4, "t"=>6, "cid"=>41}, {"rnd"=>4, "cid"=>41, "t"=>2}, {"rnd"=>6, "t"=>3, "tc"=>1, "resources"=>{"growth"=>2}, "hand"=>5}, {"rnd"=>6, "t"=>3, "tc"=>1, "resources"=>{"growth"=>2}, "hand"=>4}, {"rnd"=>6, "t"=>6, "cid"=>208}, {"rnd"=>6, "t"=>1, "tc"=>1, "cid"=>33}, {"rnd"=>6, "t"=>3, "tc"=>1, "resources"=>{"growth"=>3}, "hand"=>3}, {"rnd"=>6, "t"=>4, "hp"=>4, "pos"=>2, "diff"=>-3}, {"rnd"=>8, "t"=>3, "tc"=>1, "resources"=>{"growth"=>3}, "hand"=>4}, {"rnd"=>8, "t"=>1, "tc"=>1, "cid"=>57}, {"rnd"=>8, "t"=>3, "tc"=>1, "resources"=>{"growth"=>4}, "hand"=>3}, {"rnd"=>8, "t"=>3, "tc"=>1, "resources"=>{"growth"=>4}, "hand"=>2}, {"rnd"=>8, "t"=>6, "cid"=>65}, {"rnd"=>8, "cid"=>65, "t"=>2}, {"rnd"=>8, "t"=>4, "hp"=>2, "pos"=>2, "diff"=>-1}, {"rnd"=>10, "t"=>3, "tc"=>1, "resources"=>{"growth"=>4}, "hand"=>3}, {"rnd"=>10, "t"=>1, "tc"=>1, "cid"=>22}, {"rnd"=>10, "t"=>3, "tc"=>1, "resources"=>{"growth"=>5}, "hand"=>2}, {"rnd"=>10, "t"=>3, "tc"=>1, "resources"=>{"growth"=>5}, "hand"=>1}, {"rnd"=>10, "t"=>6, "cid"=>75}, {"rnd"=>10, "cid"=>75, "t"=>2}, {"rnd"=>10, "t"=>5, "diff"=>4, "hp"=>-3, "cid"=>52, "kill"=>true}, {"rnd"=>10, "t"=>4, "hp"=>-2, "pos"=>2, "diff"=>-2}, {"rnd"=>12, "t"=>3, "tc"=>1, "resources"=>{"growth"=>5}, "hand"=>2}, {"rnd"=>12, "t"=>3, "tc"=>1, "resources"=>{"growth"=>5}, "hand"=>1}, {"rnd"=>12, "t"=>6, "cid"=>75}, {"rnd"=>12, "cid"=>75, "t"=>2}, {"rnd"=>12, "t"=>4, "hp"=>2, "pos"=>0, "diff"=>-4}, {"rnd"=>12, "t"=>4, "hp"=>4, "pos"=>3, "diff"=>-3}, {"rnd"=>14, "t"=>3, "tc"=>1, "resources"=>{"growth"=>5}, "hand"=>2}, {"rnd"=>14, "t"=>1, "tc"=>1, "cid"=>34}, {"rnd"=>14, "t"=>3, "tc"=>1, "resources"=>{"growth"=>6}, "hand"=>1}, {"rnd"=>14, "t"=>3, "tc"=>1, "resources"=>{"growth"=>6}, "hand"=>0}, {"rnd"=>14, "t"=>6, "cid"=>21}, {"rnd"=>14, "t"=>4, "hp"=>2, "pos"=>0, "diff"=>0}, {"rnd"=>14, "t"=>4, "hp"=>4, "pos"=>3, "diff"=>0}, {"rnd"=>14, "t"=>4, "hp"=>-2, "pos"=>0, "diff"=>-2}, {"rnd"=>16, "t"=>3, "tc"=>1, "resources"=>{"growth"=>6}, "hand"=>1}, {"rnd"=>16, "t"=>0, "tc"=>1, "cid"=>33}, {"rnd"=>16, "t"=>3, "tc"=>1, "resources"=>{"growth"=>6}, "hand"=>2}, {"rnd"=>16, "t"=>3, "tc"=>1, "resources"=>{"growth"=>6}, "hand"=>1}, {"rnd"=>16, "t"=>6, "cid"=>38}, {"rnd"=>16, "cid"=>38, "t"=>2}, {"rnd"=>16, "t"=>3, "tc"=>1, "resources"=>{"growth"=>7}, "hand"=>0}, {"rnd"=>16, "t"=>6, "cid"=>156}, {"rnd"=>16, "cid"=>156, "t"=>2}, {"rnd"=>16, "t"=>4, "hp"=>-2, "pos"=>3, "diff"=>-3}, {"rnd"=>18, "t"=>3, "tc"=>1, "resources"=>{"growth"=>7}, "hand"=>1}, {"rnd"=>18, "t"=>0, "tc"=>1, "cid"=>57}, {"rnd"=>18, "t"=>3, "tc"=>1, "resources"=>{"growth"=>7}, "hand"=>2}, {"rnd"=>18, "t"=>3, "tc"=>1, "resources"=>{"growth"=>7}, "hand"=>1}, {"rnd"=>18, "t"=>6, "cid"=>208}, {"rnd"=>18, "t"=>4, "hp"=>2, "pos"=>1, "diff"=>-4}, {"rnd"=>18, "t"=>5, "diff"=>4, "hp"=>-2, "cid"=>125, "kill"=>true}, {"rnd"=>20, "t"=>3, "tc"=>1, "resources"=>{"growth"=>7}, "hand"=>2}, {"rnd"=>20, "t"=>4, "hp"=>2, "pos"=>3, "diff"=>2}]
    replay.black_sac_res.should == 6
    replay.black_sac_cards.should == 2
    replay.black_resources.should == ["growth"]
    replay.black_res_totals.should == {"growth" => 7}
    replay.black_time.should == 103
    replay.black_name.should == "Shadowed"
    replay.black_id.should == "77fcba9f336e4aff954049ccced9d537"
    replay.player_ids.should == ["RobotEasy", "77fcba9f336e4aff954049ccced9d537"]
    replay.game_resources.should == ["order", "growth"]
    replay.game_type.should == 4
    replay.game_timer.should == 90
    replay.game_rounds.should == 20
    replay.game_length.should == 103
    replay.game_id.should == 4889608
    replay.perspective.should == 1
    replay.winner.should == 1
    replay.played_at.should == Time.parse("Sat, 27 Jul 2013 02:05:31 UTC +00:00 ")
    replay.game_version_id.should == @new_game_version._id
  end

  it "converts a ScrollsGuide replay to ScrollsPost" do
    File.unlink(Rails.root.join("public", "system", "replays", "4066803-black.spr")) rescue nil
    File.exists?(Rails.root.join("public", "system", "replays", "4066803.sgr")).should be_false

    file = fixture_file_upload(Rails.root.join("spec", "assets", "replays", "4066803.sgr"))

    post :create, :replay => file
    response.code.should == "200"

    replay = Replay.last
    replay.should_not be_nil
    replay.white_cards.should == [[96, 3], [107, 3], [24, 3], [152, 1], [98, 2], [67, 1], [82, 2], [2, 3], [130, 2], [118, 2], [151, 1], [68, 3], [39, 2], [27, 1], [205, 2]]
    replay.white_stats.should == {"udmg" => 31, "idmg" => 29, "uplay" => 16, "splay" => 4, "eplay" => 0, "drawn" => 39, "hdmg" => 5, "ikill" => 2, "hdmgID" => 68}
    replay.white_gold.should == {"match" => 46, "compl" => 20, "idols" => 40, "total" => 106}
    replay.white_rounds.should == [{"rnd" => 1, "t" => 3, "tc" => 0, "resources" => {}, "hand" => 4}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 0, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 1, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 2, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 3, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 4, "diff" => 0}, {"rnd" => 1, "t" => 3, "tc" => 0, "resources" => {}, "hand" => 5}, {"rnd" => 1, "t" => 1, "tc" => 0}, {"rnd" => 1, "t" => 3, "tc" => 0, "resources" => {"energy" => 1}, "hand" => 4}, {"rnd" => 3, "t" => 3, "tc" => 0, "resources" => {"energy" => 1}, "hand" => 5}, {"rnd" => 3, "t" => 1, "tc" => 0}, {"rnd" => 3, "t" => 3, "tc" => 0, "resources" => {"energy" => 2}, "hand" => 4}, {"rnd" => 3, "t" => 3, "tc" => 0, "resources" => {"energy" => 2}, "hand" => 3}, {"rnd" => 3, "t" => 6, "cid" => 96}, {"rnd" => 3, "cid" => 96, "t" => 2}, {"rnd" => 5, "t" => 3, "tc" => 0, "resources" => {"energy" => 2}, "hand" => 4}, {"rnd" => 5, "t" => 1, "tc" => 0}, {"rnd" => 5, "t" => 3, "tc" => 0, "resources" => {"energy" => 3}, "hand" => 3}, {"rnd" => 5, "t" => 3, "tc" => 0, "resources" => {"energy" => 3}, "hand" => 2}, {"rnd" => 5, "t" => 6, "cid" => 107}, {"rnd" => 5, "cid" => 107, "t" => 2}, {"rnd" => 7, "t" => 3, "tc" => 0, "resources" => {"energy" => 3}, "hand" => 3}, {"rnd" => 7, "t" => 1, "tc" => 0}, {"rnd" => 7, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 2}, {"rnd" => 7, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 1}, {"rnd" => 7, "t" => 6, "cid" => 24}, {"rnd" => 7, "cid" => 24, "t" => 2}, {"rnd" => 7, "t" => 4, "hp" => 6, "pos" => 2, "diff" => -2}, {"rnd" => 9, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 2}, {"rnd" => 9, "t" => 0, "tc" => 0}, {"rnd" => 9, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 3}, {"rnd" => 9, "t" => 4, "hp" => 2, "pos" => 2, "diff" => -2}, {"rnd" => 11, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 4}, {"rnd" => 11, "t" => 0, "tc" => 0}, {"rnd" => 11, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 5}, {"rnd" => 11, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 4}, {"rnd" => 11, "t" => 6, "cid" => 152}, {"rnd" => 11, "t" => 4, "hp" => 6, "pos" => 1, "diff" => -2}, {"rnd" => 11, "t" => 4, "hp" => -2, "pos" => 2, "diff" => -2}, {"rnd" => 13, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 5}, {"rnd" => 13, "t" => 0, "tc" => 0}, {"rnd" => 13, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 6}, {"rnd" => 13, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 5}, {"rnd" => 13, "t" => 6, "cid" => 98}, {"rnd" => 13, "cid" => 98, "t" => 2}, {"rnd" => 13, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 4}, {"rnd" => 13, "t" => 6, "cid" => 67}, {"rnd" => 13, "t" => 5, "diff" => 2, "hp" => 0, "cid" => 41, "kill" => true}, {"rnd" => 15, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 5}, {"rnd" => 15, "t" => 0, "tc" => 0}, {"rnd" => 15, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 6}, {"rnd" => 15, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 5}, {"rnd" => 15, "t" => 6, "cid" => 82}, {"rnd" => 15, "cid" => 82, "t" => 2}, {"rnd" => 15, "t" => 4, "hp" => 6, "pos" => 3, "diff" => -2}, {"rnd" => 15, "t" => 4, "hp" => 2, "pos" => 3, "diff" => -2}, {"rnd" => 17, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 6}, {"rnd" => 17, "t" => 0, "tc" => 0}, {"rnd" => 17, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 7}, {"rnd" => 17, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 6}, {"rnd" => 17, "t" => 6, "cid" => 2}, {"rnd" => 17, "cid" => 2, "t" => 2}, {"rnd" => 17, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 5}, {"rnd" => 17, "t" => 6, "cid" => 96}, {"rnd" => 17, "cid" => 96, "t" => 2}, {"rnd" => 19, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 6}, {"rnd" => 19, "t" => 0, "tc" => 0}, {"rnd" => 19, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 7}, {"rnd" => 19, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 6}, {"rnd" => 19, "t" => 6, "cid" => 130}, {"rnd" => 19, "cid" => 130, "t" => 2}, {"rnd" => 19, "t" => 5, "diff" => 4, "hp" => 1, "cid" => 33}, {"rnd" => 21, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 7}, {"rnd" => 21, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 6}, {"rnd" => 21, "t" => 6, "cid" => 107}, {"rnd" => 21, "cid" => 107, "t" => 2}, {"rnd" => 21, "t" => 3, "tc" => 0, "resources" => {"energy" => 4}, "hand" => 5}, {"rnd" => 21, "t" => 6, "cid" => 2}, {"rnd" => 21, "cid" => 2, "t" => 2}, {"rnd" => 21, "t" => 1, "tc" => 0}, {"rnd" => 21, "t" => 3, "tc" => 0, "resources" => {"energy" => 5}, "hand" => 4}, {"rnd" => 21, "t" => 5, "diff" => 1, "hp" => 0, "cid" => 33, "kill" => true}, {"rnd" => 21, "t" => 5, "diff" => 1, "hp" => 5, "cid" => 41}, {"rnd" => 21, "t" => 5, "diff" => 1, "hp" => 3, "cid" => 154}, {"rnd" => 23, "t" => 3, "tc" => 0, "resources" => {"energy" => 5}, "hand" => 5}, {"rnd" => 23, "t" => 1, "tc" => 0}, {"rnd" => 23, "t" => 3, "tc" => 0, "resources" => {"energy" => 6}, "hand" => 4}, {"rnd" => 23, "t" => 3, "tc" => 0, "resources" => {"energy" => 6}, "hand" => 3}, {"rnd" => 23, "t" => 6, "cid" => 118}, {"rnd" => 23, "cid" => 118, "t" => 2}, {"rnd" => 23, "t" => 5, "diff" => 4, "hp" => -1, "cid" => 154, "kill" => true}, {"rnd" => 25, "t" => 3, "tc" => 0, "resources" => {"energy" => 6}, "hand" => 4}, {"rnd" => 25, "t" => 0, "tc" => 0}, {"rnd" => 25, "t" => 3, "tc" => 0, "resources" => {"energy" => 6}, "hand" => 5}, {"rnd" => 25, "t" => 3, "tc" => 0, "resources" => {"energy" => 6}, "hand" => 4}, {"rnd" => 25, "t" => 6, "cid" => 151}, {"rnd" => 25, "t" => 3, "tc" => 0, "resources" => {"energy" => 6}, "hand" => 3}, {"rnd" => 25, "t" => 6, "cid" => 24}, {"rnd" => 25, "cid" => 24, "t" => 2}, {"rnd" => 25, "t" => 5, "diff" => 4, "hp" => 0, "cid" => 75, "kill" => true}, {"rnd" => 25, "t" => 4, "hp" => 6, "pos" => 0, "diff" => -2}, {"rnd" => 27, "t" => 3, "tc" => 0, "resources" => {"energy" => 6}, "hand" => 4}, {"rnd" => 27, "t" => 3, "tc" => 0, "resources" => {"energy" => 6}, "hand" => 3}, {"rnd" => 27, "t" => 6, "cid" => 68}, {"rnd" => 27, "cid" => 68, "t" => 2}, {"rnd" => 27, "t" => 1, "tc" => 0}, {"rnd" => 27, "t" => 3, "tc" => 0, "resources" => {"energy" => 7}, "hand" => 2}, {"rnd" => 27, "t" => 5, "diff" => 4, "hp" => 9, "cid" => 41}, {"rnd" => 27, "t" => 5, "diff" => 1, "hp" => 3, "cid" => 154}, {"rnd" => 27, "t" => 5, "diff" => 1, "hp" => 8, "cid" => 41}, {"rnd" => 28, "t" => 5, "diff" => 1, "hp" => 4, "cid" => 154}, {"rnd" => 29, "t" => 3, "tc" => 0, "resources" => {"energy" => 7}, "hand" => 3}, {"rnd" => 29, "t" => 0, "tc" => 0}, {"rnd" => 29, "t" => 3, "tc" => 0, "resources" => {"energy" => 7}, "hand" => 4}, {"rnd" => 29, "t" => 3, "tc" => 0, "resources" => {"energy" => 7}, "hand" => 3}, {"rnd" => 29, "t" => 6, "cid" => 39}, {"rnd" => 29, "cid" => 39, "t" => 2}, {"rnd" => 29, "t" => 5, "diff" => 4, "hp" => 0, "cid" => 154, "kill" => true}, {"rnd" => 29, "t" => 5, "diff" => 2, "hp" => 7, "cid" => 41}, {"rnd" => 31, "t" => 3, "tc" => 0, "resources" => {"energy" => 7}, "hand" => 4}, {"rnd" => 31, "t" => 1, "tc" => 0}, {"rnd" => 31, "t" => 3, "tc" => 0, "resources" => {"energy" => 8}, "hand" => 3}, {"rnd" => 31, "t" => 3, "tc" => 0, "resources" => {"energy" => 8}, "hand" => 2}, {"rnd" => 31, "t" => 6, "cid" => 27}, {"rnd" => 31, "t" => 5, "diff" => 3, "hp" => 5, "cid" => 41}, {"rnd" => 31, "t" => 4, "hp" => 0, "pos" => 1, "diff" => -3}, {"rnd" => 32, "t" => 5, "diff" => 1, "hp" => 3, "cid" => 154}, {"rnd" => 33, "t" => 3, "tc" => 0, "resources" => {"energy" => 8}, "hand" => 3}, {"rnd" => 33, "t" => 0, "tc" => 0}, {"rnd" => 33, "t" => 3, "tc" => 0, "resources" => {"energy" => 8}, "hand" => 4}, {"rnd" => 33, "t" => 3, "tc" => 0, "resources" => {"energy" => 8}, "hand" => 3}, {"rnd" => 33, "t" => 6, "cid" => 68}, {"rnd" => 33, "cid" => 68, "t" => 2}, {"rnd" => 33, "t" => 3, "tc" => 0, "resources" => {"energy" => 8}, "hand" => 2}, {"rnd" => 33, "t" => 6, "cid" => 205}, {"rnd" => 33, "cid" => 205, "t" => 2}, {"rnd" => 33, "t" => 4, "hp" => -2, "pos" => 3, "diff" => -2}]
    replay.white_sac_res.should == 8
    replay.white_sac_cards.should == 9
    replay.white_resources.should == ["energy"]
    replay.white_res_totals.should == {"energy" => 8}
    replay.white_time.should == 422
    replay.white_name.should == "Cloud9"
    replay.white_id.should == "f5634a5cd46244c6ae5b48f2b28b2d2a"
    replay.black_cards.should == [[29, 2], [57, 3], [158, 1], [208, 3], [43, 3], [78, 3], [50, 3], [45, 3], [62, 3], [92, 3], [41, 3], [75, 3], [154, 3], [33, 2], [64, 1], [104, 2], [15, 2], [89, 3], [111, 3], [26, 2]]
    replay.black_stats.should == {"udmg" => 36, "idmg" => 30, "uplay" => 9, "splay" => 10, "eplay" => 11, "drawn" => 45, "hdmg" => 10, "ikill" => 3, "hdmgID" => 41}
    replay.black_gold.should == {"match" => 276, "compl" => 20, "idols" => 60, "total" => 356}
    replay.black_rounds.should == [{"rnd" => 1, "t" => 3, "tc" => 0, "resources" => {}, "hand" => 5}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 0, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 1, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 2, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 3, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 4, "diff" => 0}, {"rnd" => 2, "t" => 3, "tc" => 1, "resources" => {}, "hand" => 6}, {"rnd" => 2, "t" => 1, "tc" => 1, "cid" => 78}, {"rnd" => 2, "t" => 3, "tc" => 1, "resources" => {"growth" => 1}, "hand" => 5}, {"rnd" => 4, "t" => 3, "tc" => 1, "resources" => {"growth" => 1}, "hand" => 6}, {"rnd" => 4, "t" => 1, "tc" => 1, "cid" => 43}, {"rnd" => 4, "t" => 3, "tc" => 1, "resources" => {"order" => 1, "growth" => 1}, "hand" => 5}, {"rnd" => 6, "t" => 3, "tc" => 1, "resources" => {"order" => 1, "growth" => 1}, "hand" => 6}, {"rnd" => 6, "t" => 1, "tc" => 1, "cid" => 29}, {"rnd" => 6, "t" => 3, "tc" => 1, "resources" => {"order" => 1, "growth" => 2}, "hand" => 5}, {"rnd" => 6, "t" => 3, "tc" => 1, "resources" => {"order" => 1, "growth" => 2}, "hand" => 4}, {"rnd" => 6, "t" => 6, "cid" => 57}, {"rnd" => 6, "t" => 3, "tc" => 1, "resources" => {"order" => 1, "growth" => 2}, "hand" => 5}, {"rnd" => 8, "t" => 3, "tc" => 1, "resources" => {"order" => 1, "growth" => 2}, "hand" => 6}, {"rnd" => 8, "t" => 1, "tc" => 1, "cid" => 45}, {"rnd" => 8, "t" => 3, "tc" => 1, "resources" => {"order" => 2, "growth" => 2}, "hand" => 5}, {"rnd" => 8, "t" => 3, "tc" => 1, "resources" => {"order" => 2, "growth" => 2}, "hand" => 4}, {"rnd" => 8, "t" => 6, "cid" => 50}, {"rnd" => 8, "t" => 5, "diff" => 1, "hp" => 1, "cid" => 107}, {"rnd" => 8, "t" => 3, "tc" => 1, "resources" => {"order" => 2, "growth" => 2}, "hand" => 5}, {"rnd" => 10, "t" => 3, "tc" => 1, "resources" => {"order" => 2, "growth" => 2}, "hand" => 6}, {"rnd" => 10, "t" => 0, "tc" => 1, "cid" => 78}, {"rnd" => 10, "t" => 3, "tc" => 1, "resources" => {"order" => 2, "growth" => 2}, "hand" => 7}, {"rnd" => 10, "t" => 3, "tc" => 1, "resources" => {"order" => 2, "growth" => 2}, "hand" => 6}, {"rnd" => 10, "t" => 6, "cid" => 57}, {"rnd" => 10, "t" => 3, "tc" => 1, "resources" => {"order" => 2, "growth" => 2}, "hand" => 7}, {"rnd" => 12, "t" => 3, "tc" => 1, "resources" => {"order" => 2, "growth" => 2}, "hand" => 8}, {"rnd" => 12, "t" => 3, "tc" => 1, "resources" => {"order" => 2, "growth" => 2}, "hand" => 7}, {"rnd" => 12, "t" => 6, "cid" => 41}, {"rnd" => 12, "cid" => 41, "t" => 2}, {"rnd" => 12, "t" => 3, "tc" => 1, "resources" => {"order" => 2, "growth" => 2}, "hand" => 6}, {"rnd" => 12, "t" => 6, "cid" => 158}, {"rnd" => 12, "t" => 1, "tc" => 1, "cid" => 62}, {"rnd" => 12, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 2}, "hand" => 5}, {"rnd" => 13, "t" => 3, "tc" => 0, "resources" => {"order" => 3, "growth" => 2}, "hand" => 6}, {"rnd" => 14, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 2}, "hand" => 7}, {"rnd" => 14, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 2}, "hand" => 6}, {"rnd" => 14, "t" => 6, "cid" => 41}, {"rnd" => 14, "cid" => 41, "t" => 2}, {"rnd" => 14, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 2}, "hand" => 5}, {"rnd" => 14, "t" => 6, "cid" => 57}, {"rnd" => 14, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 2}, "hand" => 6}, {"rnd" => 14, "t" => 1, "tc" => 1, "cid" => 45}, {"rnd" => 14, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 3}, "hand" => 5}, {"rnd" => 16, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 3}, "hand" => 6}, {"rnd" => 16, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 3}, "hand" => 5}, {"rnd" => 16, "t" => 6, "cid" => 208}, {"rnd" => 16, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 3}, "hand" => 4}, {"rnd" => 16, "t" => 6, "cid" => 92}, {"rnd" => 16, "t" => 1, "tc" => 1, "cid" => 29}, {"rnd" => 16, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 4}, "hand" => 3}, {"rnd" => 16, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 4}, "hand" => 2}, {"rnd" => 16, "t" => 6, "cid" => 208}, {"rnd" => 16, "t" => 5, "diff" => 6, "hp" => -3, "cid" => 96, "kill" => true}, {"rnd" => 18, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 4}, "hand" => 3}, {"rnd" => 18, "t" => 0, "tc" => 1, "cid" => 41}, {"rnd" => 18, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 4}, "hand" => 4}, {"rnd" => 18, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 4}, "hand" => 3}, {"rnd" => 18, "t" => 6, "cid" => 33}, {"rnd" => 18, "cid" => 33, "t" => 2}, {"rnd" => 18, "t" => 5, "diff" => 6, "hp" => -4, "cid" => 2, "kill" => true}, {"rnd" => 20, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 4}, "hand" => 4}, {"rnd" => 20, "t" => 0, "tc" => 1, "cid" => 43}, {"rnd" => 20, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 4}, "hand" => 5}, {"rnd" => 20, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 4}, "hand" => 4}, {"rnd" => 20, "t" => 6, "cid" => 154}, {"rnd" => 20, "cid" => 154, "t" => 2}, {"rnd" => 20, "t" => 5, "diff" => 6, "hp" => -3, "cid" => 130, "kill" => true}, {"rnd" => 22, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 4}, "hand" => 5}, {"rnd" => 22, "t" => 1, "tc" => 1, "cid" => 64}, {"rnd" => 22, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 4}, {"rnd" => 22, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 3}, {"rnd" => 22, "t" => 6, "cid" => 75}, {"rnd" => 22, "cid" => 75, "t" => 2}, {"rnd" => 22, "t" => 4, "hp" => -2, "pos" => 4, "diff" => -6}, {"rnd" => 22, "t" => 5, "diff" => 3, "hp" => 2, "cid" => 82}, {"rnd" => 24, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 4}, {"rnd" => 24, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 3}, {"rnd" => 24, "t" => 6, "cid" => 15}, {"rnd" => 24, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 2}, {"rnd" => 24, "t" => 6, "cid" => 208}, {"rnd" => 24, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 1}, {"rnd" => 24, "t" => 6, "cid" => 104}, {"rnd" => 24, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 0}, {"rnd" => 24, "t" => 6, "cid" => 43}, {"rnd" => 24, "t" => 5, "diff" => 12, "hp" => -6, "cid" => 118, "kill" => true}, {"rnd" => 26, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 1}, {"rnd" => 26, "t" => 0, "tc" => 1, "cid" => 92}, {"rnd" => 26, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 2}, {"rnd" => 26, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 1}, {"rnd" => 26, "t" => 6, "cid" => 154}, {"rnd" => 26, "cid" => 154, "t" => 2}, {"rnd" => 26, "t" => 4, "hp" => -10, "pos" => 3, "diff" => -10}, {"rnd" => 28, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 2}, {"rnd" => 28, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 1}, {"rnd" => 28, "t" => 6, "cid" => 62}, {"rnd" => 28, "cid" => 41, "t" => 2}, {"rnd" => 28, "cid" => 154, "t" => 2}, {"rnd" => 28, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 2}, {"rnd" => 28, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 1}, {"rnd" => 28, "t" => 6, "cid" => 15}, {"rnd" => 28, "t" => 0, "tc" => 1, "cid" => 78}, {"rnd" => 28, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 2}, {"rnd" => 28, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 1}, {"rnd" => 28, "t" => 6, "cid" => 89}, {"rnd" => 28, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 2}, {"rnd" => 28, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 1}, {"rnd" => 28, "t" => 6, "cid" => 154}, {"rnd" => 28, "cid" => 154, "t" => 2}, {"rnd" => 28, "t" => 5, "diff" => 14, "hp" => -12, "cid" => 2, "kill" => true}, {"rnd" => 28, "t" => 5, "diff" => 2, "hp" => -1, "cid" => 107, "kill" => true}, {"rnd" => 30, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 5}, "hand" => 2}, {"rnd" => 30, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 1}, {"rnd" => 30, "t" => 6, "cid" => 111}, {"rnd" => 30, "cid" => 111, "t" => 2}, {"rnd" => 30, "t" => 0, "tc" => 1, "cid" => 62}, {"rnd" => 30, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 2}, {"rnd" => 30, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 1}, {"rnd" => 30, "t" => 6, "cid" => 89}, {"rnd" => 30, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 2}, {"rnd" => 30, "t" => 5, "diff" => 15, "hp" => -12, "cid" => 96, "kill" => true}, {"rnd" => 30, "t" => 4, "hp" => 6, "pos" => 4, "diff" => 4}, {"rnd" => 32, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 3}, {"rnd" => 32, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 2}, {"rnd" => 32, "t" => 6, "cid" => 75}, {"rnd" => 32, "cid" => 75, "t" => 2}, {"rnd" => 32, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 1}, {"rnd" => 32, "t" => 6, "cid" => 89}, {"rnd" => 32, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 2}, {"rnd" => 32, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 1}, {"rnd" => 32, "t" => 6, "cid" => 50}, {"rnd" => 32, "t" => 5, "diff" => 1, "hp" => 6, "cid" => 39}, {"rnd" => 32, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 2}, {"rnd" => 32, "t" => 0, "tc" => 1, "cid" => 26}, {"rnd" => 32, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 3}, {"rnd" => 32, "t" => 5, "diff" => 16, "hp" => -14, "cid" => 82, "kill" => true}, {"rnd" => 32, "t" => 5, "diff" => 3, "hp" => 3, "cid" => 39}, {"rnd" => 32, "t" => 5, "diff" => 3, "hp" => 0, "cid" => 39, "kill" => true}, {"rnd" => 34, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 4}, {"rnd" => 34, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 3}, {"rnd" => 34, "t" => 6, "cid" => 26}, {"rnd" => 34, "t" => 0, "tc" => 1, "cid" => 45}, {"rnd" => 34, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 4}, {"rnd" => 34, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 3}, {"rnd" => 34, "t" => 6, "cid" => 50}, {"rnd" => 34, "t" => 5, "diff" => 1, "hp" => 1, "cid" => 107}, {"rnd" => 34, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 4}, {"rnd" => 34, "t" => 3, "tc" => 1, "resources" => {"order" => 3, "growth" => 6}, "hand" => 3}, {"rnd" => 34, "t" => 6, "cid" => 104}, {"rnd" => 34, "t" => 4, "hp" => -10, "pos" => 0, "diff" => -10}, {"rnd" => 34, "t" => 4, "hp" => -6, "pos" => 4, "diff" => -6}]
    replay.black_sac_res.should == 8
    replay.black_sac_cards.should == 8
    replay.black_resources.should == ["growth", "order"]
    replay.black_res_totals.should == {"growth" => 6, "order" => 3}
    replay.black_time.should == 496
    replay.black_name.should == "Pharticus"
    replay.black_id.should == "8371d035dc9a42d2b4747b082ca5d2be"
    replay.player_ids.should == ["f5634a5cd46244c6ae5b48f2b28b2d2a", "8371d035dc9a42d2b4747b082ca5d2be"]
    replay.game_resources.should == ["energy", "growth", "order"]
    replay.game_type.should == 2
    replay.game_timer.should == 90
    replay.game_rounds.should == 34
    replay.game_length.should == 918
    replay.game_id.should == 4066803
    replay.perspective.should == 1
    replay.winner.should == 1
    replay.played_at.should == Time.parse("2013-07-05 04:13:45 UTC")
    replay.game_version_id.should == @game_version._id
  end

  it "uploads a replay" do
    File.unlink(Rails.root.join("public", "system", "replays", "4170740-white.spr")) rescue nil
    File.exists?(Rails.root.join("public", "system", "replays", "4170740-white.spr")).should be_false

    file = fixture_file_upload(Rails.root.join("spec", "assets", "replays", "4170740-white.spr"))

    post :create, :replay => file
    response.code.should == "200"

    replay = Replay.last
    replay.should_not be_nil

    replay.white_cards.should == [[41, 2], [34, 1], [65, 3], [156, 2], [117, 2], [21, 1], [75, 3], [53, 2], [29, 1]]
    replay.white_stats.should == {"udmg" => 0, "idmg" => 30, "uplay" => 6, "splay" => 0, "eplay" => 0, "drawn" => 13, "hdmg" => 4, "ikill" => 3, "hdmgID" => 75}
    replay.white_gold.should == {"match" => 52, "compl" => 0, "idols" => 60, "total" => 112}
    replay.white_rounds.should == [{"rnd" => 1, "t" => 3, "tc" => 0, "resources" => {}, "hand" => 4}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 0, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 1, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 2, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 3, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 4, "diff" => 0}, {"rnd" => 1, "t" => 3, "tc" => 0, "resources" => {}, "hand" => 5}, {"rnd" => 1, "t" => 1, "tc" => 0, "cid" => 117}, {"rnd" => 1, "t" => 3, "tc" => 0, "resources" => {"growth" => 1}, "hand" => 4}, {"rnd" => 1, "t" => 3, "tc" => 0, "resources" => {"growth" => 2}, "hand" => 3}, {"rnd" => 1, "t" => 6, "cid" => 156}, {"rnd" => 1, "cid" => 156, "t" => 2}, {"rnd" => 3, "t" => 3, "tc" => 0, "resources" => {"growth" => 2}, "hand" => 4}, {"rnd" => 3, "t" => 3, "tc" => 0, "resources" => {"growth" => 2}, "hand" => 3}, {"rnd" => 3, "t" => 6, "cid" => 41}, {"rnd" => 3, "cid" => 41, "t" => 2}, {"rnd" => 3, "t" => 1, "tc" => 0, "cid" => 34}, {"rnd" => 3, "t" => 3, "tc" => 0, "resources" => {"growth" => 3}, "hand" => 2}, {"rnd" => 5, "t" => 3, "tc" => 0, "resources" => {"growth" => 3}, "hand" => 3}, {"rnd" => 5, "t" => 1, "tc" => 0, "cid" => 21}, {"rnd" => 5, "t" => 3, "tc" => 0, "resources" => {"growth" => 4}, "hand" => 2}, {"rnd" => 5, "t" => 3, "tc" => 0, "resources" => {"growth" => 4}, "hand" => 1}, {"rnd" => 5, "t" => 6, "cid" => 65}, {"rnd" => 5, "cid" => 65, "t" => 2}, {"rnd" => 5, "t" => 4, "hp" => 6, "pos" => 4, "diff" => -2}, {"rnd" => 5, "t" => 4, "hp" => 4, "pos" => 4, "diff" => -1}, {"rnd" => 7, "t" => 3, "tc" => 0, "resources" => {"growth" => 4}, "hand" => 2}, {"rnd" => 7, "t" => 1, "tc" => 0, "cid" => 117}, {"rnd" => 7, "t" => 3, "tc" => 0, "resources" => {"growth" => 5}, "hand" => 1}, {"rnd" => 7, "t" => 3, "tc" => 0, "resources" => {"growth" => 5}, "hand" => 0}, {"rnd" => 7, "t" => 6, "cid" => 75}, {"rnd" => 7, "cid" => 75, "t" => 2}, {"rnd" => 7, "t" => 4, "hp" => 4, "pos" => 3, "diff" => -3}, {"rnd" => 7, "t" => 4, "hp" => -2, "pos" => 4, "diff" => -3}, {"rnd" => 9, "t" => 3, "tc" => 0, "resources" => {"growth" => 5}, "hand" => 1}, {"rnd" => 9, "t" => 3, "tc" => 0, "resources" => {"growth" => 5}, "hand" => 0}, {"rnd" => 9, "t" => 6, "cid" => 75}, {"rnd" => 9, "cid" => 75, "t" => 2}, {"rnd" => 9, "t" => 4, "hp" => 2, "pos" => 2, "diff" => -4}, {"rnd" => 9, "t" => 4, "hp" => 2, "pos" => 4, "diff" => 2}, {"rnd" => 9, "t" => 4, "hp" => 4, "pos" => 3, "diff" => 0}, {"rnd" => 11, "t" => 3, "tc" => 0, "resources" => {"growth" => 5}, "hand" => 1}, {"rnd" => 11, "t" => 0, "tc" => 0, "cid" => 53}, {"rnd" => 11, "t" => 3, "tc" => 0, "resources" => {"growth" => 5}, "hand" => 2}, {"rnd" => 11, "t" => 3, "tc" => 0, "resources" => {"growth" => 5}, "hand" => 1}, {"rnd" => 11, "t" => 6, "cid" => 65}, {"rnd" => 11, "cid" => 65, "t" => 2}, {"rnd" => 11, "t" => 4, "hp" => 2, "pos" => 2, "diff" => 0}, {"rnd" => 11, "t" => 4, "hp" => -4, "pos" => 3, "diff" => -4}, {"rnd" => 13, "t" => 3, "tc" => 0, "resources" => {"growth" => 5}, "hand" => 2}, {"rnd" => 13, "t" => 4, "hp" => -2, "pos" => 2, "diff" => -2}]
    replay.white_sac_res.should == 4
    replay.white_sac_cards.should == 1
    replay.white_res_totals.should == {"growth" => 5}
    replay.white_resources.should == ["growth"]
    replay.white_time.should == 110
    replay.white_name.should == "Shadowed"
    replay.white_id.should == "77fcba9f336e4aff954049ccced9d537"
    replay.black_stats.should == {"udmg" => 0, "idmg" => 0, "uplay" => 0, "splay" => 0, "eplay" => 0, "drawn" => 11, "hdmg" => 0, "ikill" => 0}
    replay.black_gold.should == {"match" => 8, "compl" => 0, "idols" => 0, "total" => 8}
    replay.black_rounds.should == [{"rnd" => 1, "t" => 3, "tc" => 0, "resources" => {}, "hand" => 5}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 0, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 1, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 2, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 3, "diff" => 0}, {"rnd" => 1, "t" => 4, "hp" => 10, "pos" => 4, "diff" => 0}, {"rnd" => 2, "t" => 3, "tc" => 1, "resources" => {}, "hand" => 6}, {"rnd" => 4, "t" => 3, "tc" => 1, "resources" => {}, "hand" => 7}, {"rnd" => 6, "t" => 3, "tc" => 1, "resources" => {}, "hand" => 8}, {"rnd" => 8, "t" => 3, "tc" => 1, "resources" => {}, "hand" => 9}, {"rnd" => 10, "t" => 3, "tc" => 1, "resources" => {}, "hand" => 10}, {"rnd" => 12, "t" => 3, "tc" => 1, "resources" => {}, "hand" => 11}]
    replay.black_sac_res.should == 0
    replay.black_sac_cards.should == 0
    replay.black_res_totals.should == {}
    replay.black_resources.should == []
    replay.black_time.should == 56
    replay.black_name.should == "ScrollsPost"
    replay.black_id.should == "9e09398d538448ada4448e57b6d000bb"
    replay.player_ids.should == ["77fcba9f336e4aff954049ccced9d537", "9e09398d538448ada4448e57b6d000bb"]
    replay.game_resources.should == ["growth"]
    replay.game_type.should == 1
    replay.game_timer.should == 90
    replay.game_rounds.should == 13
    replay.game_length.should == 166
    replay.game_id.should == 4170740
    replay.perspective.should == 0
    replay.winner.should == 0
    replay.game_version_id.should == @game_version._id
    replay.played_at.should == Time.parse("2013-07-07 00:23:27 UTC")

    # Check that the file exists
    File.exists?(replay.file_path).should be_true

    hash = Digest::SHA1.hexdigest(File.read(Rails.root.join("spec", "assets", "replays", "4170740-white.spr")))
    hash.should == Digest::SHA1.hexdigest(File.read(replay.file_path))
  end
end