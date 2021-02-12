require 'open-uri'

class ScheduleController < ApplicationController
  def index
    begin
      render json: {status: true, content: fetch()}
    rescue => e
      render json: {status: false, message: e.to_s}    
    end
  end

  private

  def fetch()
    year = DateTime.now()
    result = []
    for i in 1..2
      document = Nokogiri::HTML(open("https://stu.goe.go.kr/sts_sci_sf00_001.do?schulCode=J100000472&schulCrseScCode=4&schulKndScCode=04&ay=#{year}&sem=#{i}"))
      parsedYear = document.css('#grade').text.strip
      table = document.css('.tbl_type3')
      rows = table.css('tr')
      month = rows.shift.css('th').map(&:text)
      month.shift
      part = []
      month.each_with_index do |m, i|
        m = m.gsub(/[^\d]/, '')
        text_all_rows = rows.map do |row|
          date = row.css('th').text.strip
          pretty = []
          data = []
          content = row.css('.textL').select(&:text).map(&:content).each do |c|
            collected = c.split(/\n/)
            items = []
            collected.each do |item|
              items << item.strip
            end
            pretty << items.reject!(&:empty?)
          end
          {date: "#{parsedYear}-#{m}-#{date}", events: pretty[i]}
        end
        part += text_all_rows
      end
      result += part
    end
    return result
  end
end
