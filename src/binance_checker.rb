# frozen_string_literal: true

require 'dotenv/load'
require 'binance-ruby'

class BinanceChecker
  Binance::Api::Configuration.api_key = ENV['BINANCE_API_KEY']
  Binance::Api::Configuration.secret_key = ENV['BINANCE_SECRET_KEY']

  def initialize
    @exchange_info = Binance::Api.exchange_info!
    @purchased_coins = ENV['BINANCE_PURCHASED_COINS']&.split(',')
  end

  def purchased_tickers
    @purchased_tickers ||= @purchased_coins.map { |coin| Binance::Api.ticker!(symbol: coin, type: 'daily') }
  end

  def all_tickers
    raise 'Too many acquired symbols' if @exchange_info[:symbols].length > request_limit
    @all_tickers ||= Binance::Api.ticker!(symbol: nil, type: 'daily')
  end

  private

  def request_limit
    @exchange_info[:rateLimits].find { |limit| limit[:rateLimitType] == 'REQUESTS' }[:limit]
  end
end

binance_checker = BinanceChecker.new
puts binance_checker.purchased_tickers
