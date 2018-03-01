# frozen_string_literal: true

require 'dotenv/load'
require 'binance-ruby'

class BinanceChecker
  Binance::Api::Configuration.api_key = ENV['BINANCE_API_KEY']
  Binance::Api::Configuration.secret_key = ENV['BINANCE_SECRET_KEY']

  def initialize
    @purchased_coins = ENV['BINANCE_PURCHASED_COINS']&.split(',')
    validate
  end

  def export_base_price
    base_prices = purchased_tickers.map { |t| { (t[:symbol]).to_s => (t[:openPrice]).to_s } }
    File.open('base_prices', 'w') { |f| f.puts Marshal.dump(base_prices) }
  end

  def import_base_price
    @import_base_price ||= Marshal.load(File.open('base_prices', 'r'))
  end

  def current_rate
    base_prices = import_base_price
    @purchased_coins.map do |coin|
      base_price = base_prices.find { |b| b.key?(coin) }[coin].to_f
      current_price = purchased_tickers.find { |t| t[:symbol] == coin }[:openPrice].to_f

      rate = current_price / base_price
      { coin.to_s => rate.to_s }
    end
  end

  private

  def validate
    if @purchased_coins.sort != exported_coins.sort
      puts 'The coin symbols (env and exported file) do not match. Please export again.'
      exit
    end
  end

  def exported_coins
    import_base_price.flat_map(&:keys)
  end

  def purchased_tickers
    @purchased_tickers ||= @purchased_coins.map { |coin| Binance::Api.ticker!(symbol: coin, type: 'daily') }
  end

  def all_tickers
    raise 'Too many acquired symbols' if @exchange_info[:symbols].length > request_limit
    @all_tickers ||= Binance::Api.ticker!(symbol: nil, type: 'daily')
  end

  def purchased_exchange_info
    @purchased_exchange_info ||= all_exchange_info[:symbols].select { |e_info| @purchased_coins.include?(e_info[:symbol]) }
  end

  def all_exchange_info
    @all_exchange_info ||= Binance::Api.exchange_info!
  end

  def request_limit
    @exchange_info[:rateLimits].find { |limit| limit[:rateLimitType] == 'REQUESTS' }[:limit]
  end
end

binance_checker = BinanceChecker.new
puts binance_checker.current_rate
