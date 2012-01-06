require 'puppet'
require 'yaml'

begin
  require 'flowdock'
rescue LoadError => e
  Puppet.info "You need the `flowdock` gem to use the Flowdock report"
end

unless Puppet.version >= '2.6.5'
  fail "This report processor requires Puppet version 2.6.5 or later"
end

Puppet::Reports.register_report(:flowdock) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "flowdock.yaml"])
  raise(Puppet::ParseError, "Flowdock report config file #{configfile} not readable") unless File.exist?(configfile)
  @config = YAML.load_file(configfile)

  API_KEY =  @config[:flowdock_api_key]

  desc <<-DESC
  Send notification of failed reports to Flowdock.
  DESC

  def process
    if self.status == 'failed'
      output = []
      self.logs.each do |log|
        output << log
      end

      # create a new Flow object with API Token and sender information
      flow = Flowdock::Flow.new(:api_token => API_KEY,
        :source => "Puppet",
        :from => {:name => "Puppet master", :address => "puppet@yourdomain.com"})

      # send message to the flow
      flow.send_message(:subject => "Puppet run for #{self.host} #{self.status} at #{Time.now.asctime}.",
        :content => output,
        :tags => ["puppet", "#{self.status}", "#{self.host}"])
    end
  end
end
