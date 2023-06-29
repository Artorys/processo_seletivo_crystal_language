require "json"
require "../serializer/locationBase.serializer.cr"
require "../serializer/locationOptimize.serializer.cr"
require "../serializer/travelBase.serializer.cr"
require "../serializer/travelExpand.serializer.cr"
require "../serializer/travelOptimize.serializer.cr"

route = "/travel_plans"

graphqlApi = {
  "query": "query MyQuery {locations {results {id name type dimension residents {episode {id name}}}}}",
  "operationName": "MyQuery"
}.to_json
api = "https://rickandmortyapi.com/graphql"

get "#{route}" do |env|
begin
  optimize = env.params.query.has_key?("optimize")
  expand = env.params.query.has_key?("expand")
  travels = Travel.all
  response = HTTP::Client.post(api, headers: HTTP::Headers{"Content-Type" => "application/json"},body: graphqlApi)
    if(response.status_code == 200)
      locations = JSON.parse(response.body)["data"]["locations"]["results"].as_a?
      if (locations)
        travels_list = [] of TravelExpandSerializer | TravelBaseSerializer
        travels.each do |travel|
          listOptimize = [] of LocationOptimizeSerializer
          listExpand = [] of LocationBaseSerializer
          travel.travel_stops.each do |stop|
            locations.each do |planet|
              stop_id = stop
              planet_id = planet["id"].as_s.to_i
              if(stop_id == planet_id)
                planet = planet.to_json
                locationOptimize = LocationOptimizeSerializer.from_json(planet)
                locationBase = LocationBaseSerializer.from_json(planet)
                listOptimize << locationOptimize
                listExpand << locationBase
              end
            end
          end
          travelExpand = TravelExpandSerializer.new(id: travel.id, travel_stops: listExpand)
          travelOptimize = TravelOptimizeSerializer.new(id: travel.id, travel_stops: listOptimize)
          dimension_popularity = [] of NamedTuple(dimension_name: String, popularity: Int32)
          travelOptimize.travel_stops.each do |planet|
            if(planet.residents.size > 0)
              popularity = (planet.residents.map {|resident| resident.episode.size}).reduce {|acc,i| acc + i}
              dimension_popularity << {dimension_name: planet.dimension, popularity: popularity}
            else
              dimension_popularity << {dimension_name: planet.dimension, popularity: 0}
            end
          end
          repeated_dimensions = [] of String
          dimensions_average = [] of NamedTuple(dimension_name: String, average: Float32)

          dimension_popularity.each do |dimension_tuple_i|
            popularity = [] of Int32
            dimension_popularity.each do |dimension_tuple_j|
              if (dimension_tuple_i["dimension_name"] == dimension_tuple_j["dimension_name"] && !repeated_dimensions.any? {|repeated_dimension| repeated_dimension == dimension_tuple_i["dimension_name"]})
                popularity << dimension_tuple_j["popularity"]
              end
            end
            if(popularity.size > 0)
                average = ((popularity.reduce {|acc,i| acc + i}) / (popularity.size)).to_f32
                dimensions_average << {dimension_name: dimension_tuple_i["dimension_name"], average: average}
            end
            repeated_dimensions << dimension_tuple_i["dimension_name"]
          end
          dimensions_average.each do |dimension|
            travelOptimize.travel_stops.each do |planet|
              if(dimension["dimension_name"] == planet.dimension)
                planet.dimension_average = dimension["average"]
              end
            end
          end
          travel_stops_sorted_by_popularity = travelOptimize.travel_stops.sort { |planet_a,planet_b| planet_a.dimension_average <=> planet_b.dimension_average}
          travel_stops_sorted_by_popularity = travel_stops_sorted_by_popularity.sort {|planet_a, planet_b| planet_a.dimension_average == planet_b.dimension_average && planet_a.residents.size > 0 && planet_b.residents.size > 0 ? ((planet_a.residents.map {|resident| resident.episode.size}).reduce {|acc,i| acc + i}) == ((planet_b.residents.map {|resident| resident.episode.size}).reduce {|acc,i| acc + i}) ? planet_a.name <=> planet_a.name : ((planet_a.residents.map {|resident| resident.episode.size}).reduce {|acc,i| acc + i}) <=> ((planet_b.residents.map {|resident| resident.episode.size}).reduce {|acc,i| acc + i}) : planet_a.dimension_average <=> planet_b.dimension_average}
          travel_stops_sorted_by_popularity = travel_stops_sorted_by_popularity.map {|location| LocationBaseSerializer.from_json(location.to_json)}   
          if((optimize && env.params.query["optimize"] == "true") && (expand && env.params.query["expand"] == "true"))
            travelExpandOptimize = TravelExpandSerializer.new(id: travelExpand.id,travel_stops: travel_stops_sorted_by_popularity)
            travels_list << travelExpandOptimize
          end
          if((optimize && env.params.query["optimize"] == "true") && (!expand || env.params.query["expand"] != "true"))
            travelBaseOptimize = TravelBaseSerializer.new(id: travelExpand.id, travel_stops: [] of Int32)
            travelBaseOptimize.travel_stops = travel_stops_sorted_by_popularity.map {|location| location.id.to_i32}
            travels_list << travelBaseOptimize
          end
          if((expand && env.params.query["expand"] == "true") && (!optimize || env.params.query["optimize"] != "true"))
            travels_list << travelExpand
          end
        end
        if(travels_list.size > 0)
          halt env, response: travels_list.to_json
        end
        halt env, response: travels.to_json
      end
    else
      env.response.status_code = 500
      env.response.content_type = "application/json"
      halt env, response: "{\"message\": \"The Rick Morty API is not available\"}"
    end
  rescue ArgumentError
    env.response.status_code = 404
    env.response.content_type = "application/json"
    halt env, response: "{\"message\": \"The id must be a valid number\"}"
  rescue Jennifer::RecordNotFound
    env.response.status_code = 404
    env.response.content_type = "application/json"
    halt env, response: "{\"message\": \"Not found\"}"
  end
end

get "#{route}/:id" do |env|
  begin
    optimize = env.params.query.has_key?("optimize")
    expand = env.params.query.has_key?("expand")
    id = env.params.url.has_key?("id") && env.params.url["id"].to_i
    if id
        id = env.params.url["id"]
        travel = Travel.find!(id)
            response = HTTP::Client.post(api, headers: HTTP::Headers{"Content-Type" => "application/json"},body: graphqlApi)
            if(response.status_code == 200)
              locations = JSON.parse(response.body)["data"]["locations"]["results"].as_a?
              if (locations)
                listOptimize = [] of LocationOptimizeSerializer
                listExpand = [] of LocationBaseSerializer
                travel.travel_stops.each do |plan|
                  locations.each do |planet|
                    plan_id = plan
                    planet_id = planet["id"].as_s.to_i
                    if(plan_id == planet_id)
                      planet = planet.to_json
                      locationOptimize = LocationOptimizeSerializer.from_json(planet)
                      locationBase = LocationBaseSerializer.from_json(planet)
                      listOptimize << locationOptimize
                      listExpand << locationBase
                    end
                  end
                end      
                travelExpand = TravelExpandSerializer.new(id: travel.id, travel_stops: listExpand)
                travelOptimize = TravelOptimizeSerializer.new(id: travel.id, travel_stops: listOptimize)
                dimension_popularity = [] of NamedTuple(dimension_name: String, popularity: Int32)
                travelOptimize.travel_stops.each do |planet|
                  if(planet.residents.size > 0)
                    popularity = (planet.residents.map {|resident| resident.episode.size}).reduce {|acc,i| acc + i}
                    dimension_popularity << {dimension_name: planet.dimension, popularity: popularity}
                  else
                    dimension_popularity << {dimension_name: planet.dimension, popularity: 0}
                  end
                end
                repeated_dimensions = [] of String
                dimensions_average = [] of NamedTuple(dimension_name: String, average: Float32)

                dimension_popularity.each do |dimension_tuple_i|
                  popularity = [] of Int32
                  dimension_popularity.each do |dimension_tuple_j|
                    if (dimension_tuple_i["dimension_name"] == dimension_tuple_j["dimension_name"] && !repeated_dimensions.any? {|repeated_dimension| repeated_dimension == dimension_tuple_i["dimension_name"]})
                      popularity << dimension_tuple_j["popularity"]
                    end
                  end
                  if(popularity.size > 0)
                      average = ((popularity.reduce {|acc,i| acc + i}) / (popularity.size)).to_f32
                      dimensions_average << {dimension_name: dimension_tuple_i["dimension_name"], average: average}
                  end
                  repeated_dimensions << dimension_tuple_i["dimension_name"]
                end
                dimensions_average.each do |dimension|
                  travelOptimize.travel_stops.each do |planet|
                    if(dimension["dimension_name"] == planet.dimension)
                      planet.dimension_average = dimension["average"]
                    end
                  end
                end
                travel_stops_sorted_by_popularity = travelOptimize.travel_stops.sort { |planet_a,planet_b| planet_a.dimension_average <=> planet_b.dimension_average}
                travel_stops_sorted_by_popularity = travel_stops_sorted_by_popularity.sort {|planet_a, planet_b| planet_a.dimension_average == planet_b.dimension_average && planet_a.residents.size > 0 && planet_b.residents.size > 0 ? ((planet_a.residents.map {|resident| resident.episode.size}).reduce {|acc,i| acc + i}) == ((planet_b.residents.map {|resident| resident.episode.size}).reduce {|acc,i| acc + i}) ? planet_a.name <=> planet_a.name : ((planet_a.residents.map {|resident| resident.episode.size}).reduce {|acc,i| acc + i}) <=> ((planet_b.residents.map {|resident| resident.episode.size}).reduce {|acc,i| acc + i}) : planet_a.dimension_average <=> planet_b.dimension_average}
                travel_stops_sorted_by_popularity = travel_stops_sorted_by_popularity.map {|location| LocationBaseSerializer.from_json(location.to_json)}
                if((optimize && env.params.query["optimize"] == "true") && (expand && env.params.query["expand"] == "true"))
                  travel = TravelExpandSerializer.new(id: travelExpand.id,travel_stops: travel_stops_sorted_by_popularity )
                  halt env, response: travel.to_json
                end
                if((optimize && env.params.query["optimize"] == "true") && (!expand || env.params.query["expand"] != "true"))
                  travel = TravelBaseSerializer.new(id: travelExpand.id, travel_stops: [] of Int32)
                  travel.travel_stops = travel_stops_sorted_by_popularity.map {|location| location.id.to_i32}
                  halt env, response: travel.to_json
                end
                if((expand && env.params.query["expand"] == "true") && (!optimize || env.params.query["optimize"] != "true"))
                  halt env, response: travelExpand.to_json
                end
                halt env, response: travel.to_json
              end
            else
              env.response.status_code = 500
              env.response.content_type = "application/json"
              halt env, response: "{\"message\": \"The Rick Morty API is not available\"}"
            end
      else
      env.response.status_code = 404
      {"message": "You need pass a valid id(integer) for find your travel_plan"}.to_json
      end
  rescue ArgumentError
    env.response.status_code = 404
    env.response.content_type = "application/json"
    halt env, response: "{\"message\": \"The id must be a valid number\"}"
  rescue Jennifer::RecordNotFound
    env.response.status_code = 404
    env.response.content_type = "application/json"
    halt env, response: "{\"message\": \"Not found\"}"
  end
    
end

post "#{route}" do |env|
  begin
    has_body = env.params.json.has_key?("travel_stops")
    if has_body
      travel_stops = env.params.json["travel_stops"]
      if travel_stops.is_a?(Array) && travel_stops.size > 0
          list = [] of Int32
          travel_stops.each do |t|
            n = t.as_i?
            list << n if n
          end
          env.response.status_code = 201
          travel = Travel.create(travel_stops: list)

          halt env, response: travel.to_json
      else
        env.response.status_code = 400
        {"message": "travel_stops must be an Array of ids (integers)"}.to_json
      end
    else
      env.response.status_code = 400
      {"message": "travel_stops Array of ids (integers) is required"}.to_json
    end
  rescue JSON::ParseException
    env.response.status_code = 400
    env.response.content_type = "application/json"
    halt env, response: "{\"message\": \"travel_stops Array of ids (integers) is required\"}"
  end
end

put "#{route}/:id" do |env|
  begin
    has_body = env.params.json.has_key?("travel_stops")
    id = env.params.url.has_key?("id") && env.params.url["id"].to_i
    if has_body
      travel_stops = env.params.json["travel_stops"]
      if travel_stops.is_a?(Array) && travel_stops.size > 0
          list = [] of Int32
          travel_stops.each do |t|
            n = t.as_i?
            list << n if n
          end
          id = env.params.url["id"]
          travel = Travel.find!(id)
          travel.travel_stops = list
          travel.save
          halt env, response: travel.to_json
      else
        env.response.status_code = 400
        {"message": "travel_stops must be an Array of ids (integers)"}.to_json
      end
    else
      env.response.status_code = 400
      {"message": "travel_stops Array of ids (integers) is required"}.to_json
    end
  rescue ArgumentError
    env.response.status_code = 400
    env.response.content_type = "application/json"
    halt env, response: "{\"message\": \"The id must be a valid number\"}"
  rescue Jennifer::RecordNotFound
    env.response.status_code = 404
    env.response.content_type = "application/json"
    halt env, response: "{\"message\": \"Not found\"}"
  end
end

delete "#{route}/:id" do |env|
  begin
    id = env.params.url.has_key?("id") && env.params.url["id"].to_i
    id = env.params.url["id"]
    travel = Travel.find!(id)
    travel.delete
    env.response.status_code = 204
    env.response.content_type = ""
  rescue ArgumentError
    env.response.status_code = 400
    env.response.content_type = "application/json"
    halt env, response: "{\"message\": \"The id must be a valid number\"}"
  rescue Jennifer::RecordNotFound
    env.response.status_code = 404
    env.response.content_type = "application/json"
    halt env, response: "{\"message\": \"Not found\"}"
  end
end
