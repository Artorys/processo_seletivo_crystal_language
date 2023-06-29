class TravelExpandSerializer
    include JSON::Serializable
    
    def initialize(id : Int32 | Nil | String, travel_stops : Array(LocationBaseSerializer))
        @id = id
        @travel_stops = travel_stops
    end
    
    def id
        @id
    end

    def travel_stops
        @travel_stops
    end
end 
