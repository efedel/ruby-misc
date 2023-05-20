#!/usr/bin/env ruby
# module of basic stock-price stats

def eps(profit, div, num_shares)
  (profit.to_f - div.to_f) / num_shares.to_f
end

def dps(div, ot_div, num_shares)
  (div.to_f - ot_div.to_f) / num_shares
end

def div_payout(profit, div)
  div.to_f / profit.to_f
end

def retention(profit, div, num_shares, ot_div=0)
  dps(div, ot_div, num_shares) / eps(profit, div, num_shares)
end

def pe(profit, div, share_price, num_shares)
  share_price.to_f / eps(profit, div, num_shares)
end
