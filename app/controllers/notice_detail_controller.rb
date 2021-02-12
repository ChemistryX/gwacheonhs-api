require 'open-uri'

class NoticeDetailController < ApplicationController
  def index
    render json: {status: true}
  end

  def show
    id = params[:id]

    begin
      render json: {status: true, post: fetch(id)}
    rescue => e
      render json: {status: false, message: e.to_s}    
    end
  end

  private

  def fetch(id)
    # params validation
    raise "Invalid id specified." unless id.match(/^\d+$/)
    document = Nokogiri::HTML(open("http://www.gwacheon.hs.kr/wah/main/bbs/board/view.htm?menuCode=96&domain.dataNo=#{id}"))
    url = "http://www.gwacheon.hs.kr/wah/main/mobile/bbs/view.htm?menuCode=96&domain.dataNo=#{id}"
    base = "http://www.gwacheon.hs.kr"
    data = []
    file_names = []
    attachments = []
    post = document.css('.Board_Cont_Cont')
    matched = post.search('.Cont_Btn_R')
    matched.remove()
    # url conversion
    post.css("img").each do |img|
      value = img.attributes["src"].value
      img.attributes["src"].value = value
      unless value.include? "base64"
        src = open(base + img.attributes["src"].value)
        encoded = Base64.strict_encode64(src.read)
        img.attributes["src"].value = "data:image/png;base64," + encoded
      end
    end
    post.css('div').each do |d|
      if (d.attributes["data-ephox-embed-iri"] != nil)
        value = d.attributes["data-ephox-embed-iri"].value
        d.attributes["data-ephox-embed-iri"].value = base + value
      end
    end
    post.css('video').each do |v|
      if (v.attributes["poster"] != nil)
        value = v.attributes["poster"].value
        v.attributes["poster"].value = base + value
      end
    end
    post.css('source').each do |src|
      if (src.attributes["src"] != nil)
        value = src.attributes["src"].value
        src.attributes["src"].value = base + value
      end
    end
    file_href = document.css('.Board_Cont_Info2 dl:first-child dd a').map{|link| link['href']}
    file_names = document.css('.Board_Cont_Info2 dl:first-child dd a').map{|text| text.text}
    parsed_post = post.children
    raw = parsed_post.to_html.squish
    content = parsed_post.text.squish
    file_names.each_with_index do |file, index|
      url = (file_href[index].starts_with? base) ? file_href[index] : base + file_href[index]
      attachments << {title: file, url: url}
    end
    data << {
      content: content,
      raw: raw,
      attachments: attachments,
      url: url
    }
    return data
  end
end
