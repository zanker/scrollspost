# Card
Card.create_index([[:card_id, Mongo::ASCENDING]], :unique => true)
Card.create_index([[:added_game_version_id, Mongo::ASCENDING]])
Card.create_index([[:last_game_version_id, Mongo::ASCENDING]])
Card.create_index([[:historic_game_version_ids, Mongo::ASCENDING]])
Card.create_index([[:costs, Mongo::ASCENDING]])
Card.create_index([[:category, Mongo::ASCENDING]])

# CardHistory
CardHistory.create_index([[:live_card_id, Mongo::ASCENDING]])
CardHistory.create_index([[:game_patch_id, Mongo::ASCENDING]])

# Ability
Ability.create_index([[:ability_id, Mongo::ASCENDING]], :unique => true)

# PassiveRule
PassiveRule.create_index([[:name, Mongo::ASCENDING]], :unique => true)
PassiveRule.create_index([[:slug, Mongo::ASCENDING]], :unique => true)

# GameVersion
GameVersion.create_index([[:version, Mongo::ASCENDING]], :unique => true)

# CardPriceHistory
CardPriceHistory.create_index([[:card_id, Mongo::ASCENDING], [:created_at, Mongo::ASCENDING]])
CardPriceHistory.create_index([[:hash, Mongo::ASCENDING]], :sparse => true)

# CardPriceGraph
CardPriceGraph.create_index([[:card_id, Mongo::ASCENDING], [:type, Mongo::ASCENDING], [:created_at, Mongo::ASCENDING]], :unique => true)

# Post
Post.create_index([[:created_at, Mongo::ASCENDING]])
Post.create_index([[:slug, Mongo::ASCENDING]], :unique => true)

# User
User.create_index([[:email, Mongo::ASCENDING]], :unique => true)

# User Inventory
UserInventory.create_index([[:user_id, Mongo::ASCENDING]])
UserInventory.create_index([[:card_id, Mongo::ASCENDING]])
UserInventory.create_index([[:sell_quant, Mongo::ASCENDING]])
UserInventory.create_index([[:buy_quant, Mongo::ASCENDING]])

# Replay
Replay.create_index([[:created_at, Mongo::ASCENDING]])
Replay.create_index([[:played_at, Mongo::ASCENDING]])
Replay.create_index([[:game_id, Mongo::ASCENDING], [:perspective, Mongo::ASCENDING]], :unique => true)
Replay.create_index([[:white_rating, Mongo::ASCENDING]], :sparse => true)
Replay.create_index([[:black_rating, Mongo::ASCENDING]], :sparse => true)
Replay.create_index([[:white_name, Mongo::ASCENDING]], :sparse => true)
Replay.create_index([[:black_name, Mongo::ASCENDING]], :sparse => true)


# GameStats
GameStat.create_index([[:type, Mongo::ASCENDING], [:created_at, Mongo::ASCENDING]])