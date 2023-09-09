module V1
  class IsHolidayController < ApplicationController
    def index
      render json: {status:'SUCCESS', message:'Api Aktif'}, status: 200
    end

    def show
      require 'uri'
      require 'net/http'
      require 'json'

      #Get date and parse year info from it
      date = params[:id]
      year = date.split("-")[0]

      uri = URI('https://date.nager.at/api/v3/publicholidays/' + year + '/TR')

      from_api = "H"
      if Rails.cache.read(year) == nil #Check if data will be read from api
        from_api = "E"
      end

      dates = Net::HTTP
      #Try at most 3 times to reach the external api
      3.times do
        dates = Rails.cache.fetch(year, expires_in: 30.minutes) do
            Net::HTTP.get_response(uri)
        end
        if dates.code == 200
          break;
        end
      end

      #Check if we successfully reached the external api, if we couldn't cut the flow and inform the user
      successfull_return = false
      if dates.code == "200"
        successfull_return = true
      end
      unless successfull_return #If couldn't connect to api, return 422 code with message
        render json: {status: "422", message: "Public Holiday API is Unavailable at the moment!"}, status: 422
        return
      end

      #Getting the response from external api and creating own response according to it
      holidays = JSON.parse(dates.body)
      found = false
      jsonObjects = []
      for holiday in holidays
        if holiday["date"] == date
          jsonObjects.append({isHoliday: true, date: date, name: holiday["localName"]}) #This append is done because of multiple holiday dates (ex. 23-04-2023: Hem Ulusal Egemenlik ve Çocuk hem Ramazan Bayramı)
          found = true
        end
      end
      unless found
        jsonObjects.append({isHoliday: false, date: date})
      end
      render json: jsonObjects, status: 200

      #Writing the log
      write_log(date, jsonObjects, from_api)

    end

    private def write_log(request, response, from_api)
      Log.create(request: request, response: response, from_api: from_api)
    end
  end
end