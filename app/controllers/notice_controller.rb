require 'open-uri'

class NoticeController < ApplicationController
  def index
    render json: {status: true}
  end

  def show
    limit = params[:limit]
    page = params[:page]

    begin
      render json: fetch(limit, page)
    rescue => e
      render json: {status: false, message: e.to_s}    
    end
  end

  private

  def fetch(limit, page)
    # params validation
    raise "Invalid limit specified." unless limit.match(/^\d+$/)
    raise "Invalid page specified." unless page.match(/^\d+$/)
    document = Nokogiri::HTML(open("http://www.gwacheon.hs.kr/wah/main/bbs/board/list.htm?menuCode=96&scale=#{limit}&pageNo=#{page}"))
    parsed = document.css('.Board_List_Cont tr:not(:nth-of-type(1))')
    total_posts = document.css('.Board_Numview').text.split('/')[1][/\[(.*?)\]/, 1].to_i
    total_pages = (total_posts / limit.to_f).ceil
    if (total_pages < page.to_i) then return {status: false, message: 'page must not be greater than total_pages'} end
    data = []
    parsed.each do |p|
      url = p.css('.Board_List_Sub a')[0]['href']
      id = url.match(/dataNo=([\d]*)/)[1]
      data << {
        id: id.to_i,
        title: p.css('.Board_List_Sub a').text,
        author: p.css('.Board_List_Mem').text.strip,
        created_at: Time.parse(p.css('.Board_List_Date').text).strftime('%F'),
        views: p.css('.Board_List_Vis').text.to_i,
        has_attachments: !p.css('.Board_List_Fil').text.strip.gsub(/[[:space:]]/, '').empty?
      }
    end
    return {status: true, limit: limit.to_i, page: page.to_i, total_pages: total_pages, posts: data}
  end
end
