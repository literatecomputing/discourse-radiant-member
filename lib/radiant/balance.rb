# frozen_string_literal: true
module Radiant
  # URIs for different chains
  @radiant_uri_arbitrum = "https://api.thegraph.com/subgraphs/name/radiantcapitaldevelopment/radiantcapital"
  @radiant_uri_bsc = "https://api.thegraph.com/subgraphs/name/radiantcapitaldevelopment/radiant-bsc"

  def self.get_siwe_address_by_username(username)
    user = User.find_by_username(username)
    return nil unless user
    get_siwe_address_by_user(user)
  end

  def self.get_siwe_address_by_user(user)
    siwe = user.associated_accounts.filter { |a| a[:name] == "siwe" }.first
    return nil unless siwe
    address = siwe[:description].downcase
    address
  end

  def self.price_of_rdnt_token
    name = "radiant_dollar_value"
    Discourse
      .cache
      .fetch(name, expires_in: SiteSetting.radiant_dollar_cache_minutes.minutes) do
        begin
          result =
            Excon.get(
              "https://api.coingecko.com/api/v3/simple/price?ids=radiant-capital&vs_currencies=usd&include_last_updated_at=true&precision=3",
              connect_timeout: 3,
            )
          parsed = JSON.parse(result.body)
          price = parsed["radiant-capital"]["usd"]
        rescue => e
          Rails.logger.error("problem getting dollar amount: #{e.class}")
        end
        price
      end
  end

  def self.get_rdnt_amount_by_username(username)
    user = User.find_by_username(username)
    return nil unless user
    get_rdnt_amount(user)
  end

  def self.get_rdnt_amount(user)
    # Define cache key for the total RDNT amount
    name_total = "radiant_user_total-#{user.id}"

    # Try fetching the cached value
    cached_value = Discourse.cache.read(name_total)

    # Check if it's the first time (no cache data) or cache has expired
    if cached_value.nil? || cached_value == 0
      total_rdnt_amount = fetch_and_cache_rdnt_amount(user, name_total)
    else
      # Use the cached value
      total_rdnt_amount = cached_value
    end

    # Update groups
    SiteSetting.radiant_group_values.split("|").each do |g|
      group_name, required_amount = g.split(":")
      group = Group.find_by_name(group_name)
      next unless group
      if total_rdnt_amount > required_amount.to_i
        group.add(user)
      else
        group.remove(user)
      end
    end
  
    # Log the final total RDNT amount
    total_rdnt_amount.to_d.round(2, :truncate).to_f
  end

  def self.fetch_and_cache_rdnt_amount(user, cache_key)
    # Get amounts from both chains with the appropriate multipliers
    rdnt_amount_arbitrum = get_rdnt_amount_from_chain(user, @radiant_uri_arbitrum, 0.8)
    rdnt_amount_bsc = get_rdnt_amount_from_chain(user, @radiant_uri_bsc, 0.5)

    # Log the amounts fetched from each chain
    # Rails.logger.warn ("rdnt_amount_arbitrum: #{rdnt_amount_arbitrum}")
    # Rails.logger.warn ("rdnt_amount_bsc: #{rdnt_amount_bsc}")

    # Sum amounts from both chains
    total_rdnt_amount = rdnt_amount_arbitrum + rdnt_amount_bsc

    # Cache the total RDNT amount
    Discourse.cache.write(cache_key, total_rdnt_amount, expires_in: SiteSetting.radiant_user_cache_minutes.minutes)

    total_rdnt_amount
  end
    
  def self.get_rdnt_amount_from_chain(user, radiant_uri, multiplier)
    begin
      address = get_siwe_address_by_user(user)
      if address.nil?
        Rails.logger.warn ("User #{user.username} has not connected their wallet.")
        return 0
      end
      uri = URI(radiant_uri)
      req = Net::HTTP::Post.new(uri)
      req.content_type = "application/json"
      req.body = {
        "query" =>
          'query Lock($address: String!) { lockeds(id: $address, where: {user_: {id: $address}}, orderBy: timestamp, orderDirection: desc, first: 1) { lockedBalance timestamp } lpTokenPrice(id: "1") { price } }',
        "variables" => {
          "address" => address,
        },
      }.to_json
      req_options = { use_ssl: uri.scheme == "https" }
      res = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(req) }
      parsed_body = JSON.parse(res.body)
  
      locked_balance = parsed_body["data"]["lockeds"][0]["lockedBalance"].to_i
      lp_token_price = parsed_body["data"]["lpTokenPrice"]["price"].to_i
      lp_token_price_in_usd = lp_token_price / 1e8
      locked_balance_formatted = locked_balance / 1e18
      locked_balance_in_usd = locked_balance_formatted * lp_token_price_in_usd
      rdnt_amount = (locked_balance_in_usd * multiplier) / price_of_rdnt_token
    rescue => e
      Rails.logger.error ("something went wrong getting rdnt amount #{e}")
      return 0
    end
    rdnt_amount.to_d.round(2, :truncate).to_f
  end
end
