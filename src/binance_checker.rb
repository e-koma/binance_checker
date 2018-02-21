# frozen_string_literal: true

require 'dotenv/load'
require 'binance-ruby'

class BinanceChecker
  Binance::Api::Configuration.api_key = ENV['BINANCE_API_KEY']
  Binance::Api::Configuration.secret_key = ENV['BINANCE_SECRET_KEY']

  def initialize
    @purchased_coins = ENV['BINANCE_PURCHASED_COINS']&.split(',')
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

  def export_base_price(tickers)
    base_prices = tickers.map { |t| { "#{t[:symbol]}" => "#{t[:openPrice]}" } }
    File.open("base_prices", "w") { |f| f.puts Marshal.dump(base_prices) }
  end

  def import_base_price
    Marshal.load(File.open("base_prices", "r"))
  end

  private

  def request_limit
    @exchange_info[:rateLimits].find { |limit| limit[:rateLimitType] == 'REQUESTS' }[:limit]
  end
end

binance_checker = BinanceChecker.new
puts binance_checker.purchased_tickers
