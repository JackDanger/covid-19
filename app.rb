require 'csv'
require 'open-uri'
require 'nokogiri'

DOC_URI = "https://docs.google.com/spreadsheets/u/2/d/e/2PACX-1vRwAqp96T9sYYq2-i7Tj0pvTf6XVHjDSMIKBdZHXiCGGdNC0ypEU9NbngS8mxea55JuCFuua1MUeOj5/pubhtml#"
StatesDailyID = '916628299'

HTML = open('https://docs.google.com/spreadsheets/u/2/d/e/2PACX-1vRwAqp96T9sYYq2-i7Tj0pvTf6XVHjDSMIKBdZHXiCGGdNC0ypEU9NbngS8mxea55JuCFuua1MUeOj5/pubhtml').read

Document = Nokogiri::HTML(HTML)

module ToCSV

  def render(out)
    CSV.open(out, 'w') do |csv|
      csv << headers
      state_names.each do |state|
        csv << rows_for(state)
      end
    end
  end

  private

  def headers
    @headers ||= d.css("##{StatesDailyID} tr")[1].children.map(&:text)[1..-1]
  end

  def rows_for(state)
    @rows_for ||= {}
    @rows_for[state] ||= d.css("##{StatesDailyID} td").select do |td|
      td.text == State
    end.map do |td|
      td.parent
    end.map do |tr|
      tr.children.map(&:text)
    end
  end
end

ToCSV.render(STDOUT)

