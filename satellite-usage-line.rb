#!/bin/env ruby
require 'net/http'
require 'json'

USAGE_URL = 'http://192.168.0.1/api/home/usage'
STAT_SUMMARY_URL='http://192.168.0.1/api/home/status/summary'
STAT_LAN_URL='http://192.168.0.1/api/home/status/lan'
STAT_WAN_URL='http://192.168.0.1/api/home/status/wan'
STAT_SYS_URL='http://192.168.0.1/api/home/status/system'
STAT_SAN_URL='http://192.168.0.1/api/install/nsp_links'

def router_send_selenium(url)
  driver = Selenium::WebDriver.for :firefox
  driver.get URL
  driver.page_source
end

def router_send(url)
  uri = URI(url)
  request = Net::HTTP::Get.new(uri)
  #request["User-Agent"] = opts[:user_agent]
  resp = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => (uri.scheme == 'https')) {|http|
    http.request(request)

  }
  if resp.code.to_i != 200
    puts "Did not get HTTP 200 (OK). Details:"
    puts resp.class.name
    puts resp.code
    puts resp['content-type']
    puts resp.body
    puts resp.message
    return
  end

  resp.body
end

def summary_from_status_page
  html_str = router_send(STAT_SUMMARY_URL)
  h = JSON.parse( html_str )
  rem = h['allowance']['value'] 
  {
    "state_code" => h['state_code']['value'],
    "state" => h['summary']['value'],
    "remaining" => (rem.is_a? Numeric) ? rem : 0
  }
end

def san_from_status_page
  html_str = router_send(STAT_SAN_URL)
  arr = JSON.parse( html_str )
  arr.first['bus_cid_val']
end

#{"FAP_Status":0,"allowance_reset":{"days":27,"hrs":11,"mins":25},"anytime":{"remaining_mb":49971,"total_mb":50000},"bonus":{"remaining_mb":49875,"total_mb":50000},"bonus_reset":{"hrs":14,"mins":25,"reset_string":"bonus_starts"},"data_allowance":{"data_allowance_rem_mb":51971,"data_allowance_rem_unlimited":false},"tokens":{"remaining_mb":2000}}
def usage_from_home
  html_str = router_send(USAGE_URL)
  h = JSON.parse( html_str )
  remaining_gb = h['anytime']["remaining_mb"].to_f / 1000
  total_gb = h['anytime']["total_mb"].to_f / 1000
  pct = (h['anytime']["remaining_mb"].to_f / h['anytime']["total_mb"]) * 100
  h['anytime']["total_mb"]
  { "reset" => "#{h['allowance_reset']['days']}:#{h['allowance_reset']['hrs']}:#{h['allowance_reset']['mins']}",
    "remaining" => remaining_gb,
    "total" => total_gb,
    "percent" => (pct.finite? ? pct.ceil : 0.0)
  }
end


if __FILE__ == $0
  state = summary_from_status_page
  san = san_from_status_page
  use = usage_from_home
  puts "%s|%d|%d|%0.1f of %0.1f GB|%s|%s|%s|%s" % [ Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                                          use['percent'], state['remaining'],
                                          use['remaining'], use['total'], 
                                          use['reset'], state['state_code'],
                                          state['state'], san]
end

