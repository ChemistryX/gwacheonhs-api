Jets.application.routes.draw do
  root "application#index"

  get "notice", to: "notice#index"
  get "notice/:limit/:page", to: "notice#show"
  get "notice_detail", to: "notice_detail#index"
  get "notice_detail/:id", to: "notice_detail#show"
  get "schedule", to: "schedule#index"
  get "timetable", to: "timetable#index"
  get "timetable/update", to: "timetable#update"
  get "timetable/:schoolGrade/:schoolClass", to: "timetable#show"

  any "*catchall", to: "jets/public#show"
end
