class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  def index
  end

  def after_sign_in_path_for(resource)
    "/"
  end

  def search_apis
    start_date = params[:start_date].to_s
    end_date = params[:end_date].to_s
    keyword = params[:keyword].to_s
    city = params[:city].to_s

    response = JSON.parse RestClient.get('https://www.eventbriteapi.com/v3/events/search?q='+
      keyword+'&sort_by=best&venue.city='+city+'&start_date.range_start='+
      start_date+'T00:00:00Z&start_date.range_end='+end_date+
      'T00:00:00Z',
      authorization: ENV['EVENTBRITE']
      )
    # use line 28 to view response, then comment out and uncomment 29 & 30 for the actual view code
    # render json: response
    @events = response["events"]
    # make an array of bookmarks
    # need to handle empty responses.
    # function that sets empty string if undefined
    # some logos are null
    # @filteredevents = @events.map {
    #   |event| (defined?(event["logo"]) ? event["logo"]=" ")
    # }
    @bookmarks = @events.map { |event|
      if event["description"]["text"] && event["name"]["text"]
        Bookmark.new(
          title: event["name"]["text"],
          image: event["logo"].nil? ? "NULL" : event["logo"]["url"],
          description: event["description"]["text"].gsub!("\n"," "),
          date: event["start"]["local"].split("T")[0],
          time: event["start"]["local"].split("T")[1],
          url: event["url"])
      end
    }

    # @events is an array of objects where the top 10 are displayed
    # data in js file is @events once it is rednered as :json
    # render :index
    @st = @bookmarks.map do |f|
      if !f.nil?
        {
          "title" => f.title,
          "image" => f.image,
          "description" => f.description,
          "location" => params[:city],
          "date" => f.date,
          "time" => f.time,
          "url" => f.url
        }
      end
    end
    @st = @st - [nil]

    render :json => @st.to_json
  end
# take js controller is sending and js is transposing json to html
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:first_name, :last_name, :email, :phone_number, :password, :password_confirmation)
    end
  end
end