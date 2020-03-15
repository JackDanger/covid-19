require 'csv'
require 'date'
require 'open-uri'
require 'nokogiri'

DOC_URI = "https://docs.google.com/spreadsheets/u/2/d/e/2PACX-1vRwAqp96T9sYYq2-i7Tj0pvTf6XVHjDSMIKBdZHXiCGGdNC0ypEU9NbngS8mxea55JuCFuua1MUeOj5/pubhtml#"
StatesDailyID = '916628299'

# naming known array indexes
COL_CellID = 0
COL_Date = 1
COL_State = 2
COL_Positive = 3
COL_Negative = 4
COL_Pending = 5
COL_Death = 6
COL_Total = 7

module ToCSV
  extend self

  def generate(type = COL_Positive)
    CSV.generate do |csv|
      csv << ['state' ] + dates.map {|d| Date.parse(d) }
      state_names.each do |state|
        row = [state]
        dense_dates_for(state).flat_map do |entry|
          row << entry[type]
        end
        csv << row
      end
    end
  end

  private

  # Fill in any missing dates in the original source data
  def dense_dates_for(state)
    source_rows = get_original_state_rows_for(state)
    dates.map do |date|
      row = source_rows.detect do |r|
        r[COL_Date] == date
      end
      if row
        row
      else
        [nil, date, state, 0, 0, 0, 0, 0]
      end
    end
  end

  def get_original_state_rows_for(state)
    @rows_for ||= {}
    @rows_for[state] ||= document.css("##{StatesDailyID} td").select do |td|
      td.text == state
    end.map do |td|
      td.parent
    end.map do |tr|
      tr.children.map(&:text)
    end
  end

  def dates
    @dates ||= document.css("##{StatesDailyID} tr")[3..-1].map {|tr| tr.children[COL_Date] }.map(&:text).uniq.sort
  end

  def state_names
    @state_names ||= document.css("##{StatesDailyID} tr")[3..-1].map {|tr| tr.children[COL_State] }.map(&:text).uniq.sort
  end

  def document
    @document ||= Nokogiri::HTML(open(DOC_URI).read)
  end

  def headers
    @headers ||= document.css("##{StatesDailyID} tr")[1].children.map(&:text)[1..-1]
  end
end

if ARGV.size < 1
  puts ToCSV.generate(COL_Positive)
elsif ARGV[0] == 'total'
  puts ToCSV.generate(COL_Total)
elsif ARGV[0] == 'positive'
  puts ToCSV.generate(COL_Positive)
end
