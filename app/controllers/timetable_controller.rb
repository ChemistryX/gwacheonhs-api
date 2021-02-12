require 'google/cloud/firestore'
require 'open-uri'
require 'json'

class TimetableController < ApplicationController
  def index
    render json: {status: true}
  end

  def update
    render json: TimetableJob.perform_now(:fetch)
  end

  def show
    schoolGrade = params[:schoolGrade]
    schoolClass = params[:schoolClass]
    begin
      render json: fetch(schoolGrade, schoolClass)
    rescue => e
      render json: {status: false, message: e.to_s}    
    end
  end

  private

  def fetch(schoolGrade, schoolClass)
    firestore = Google::Cloud::Firestore.new
    identifier = "#{schoolGrade}-#{schoolClass}"
    timetable_doc = firestore.doc "timetable/#{identifier}"
    if timetable_doc.get.exists?
      school_info_doc = firestore.doc "timetable/school_info"
      classes = school_info_doc.get.data[:classes]
      grid_raw = timetable_doc.get.data
      grid = []
      grid_raw.sort.each do |key, value|
        grid << value
      end
      return {status: true, content: {classes: classes, grid: grid}}
    else
      return {status: false, message: "Failed to retrieve data from database"}
    end
  end
end
