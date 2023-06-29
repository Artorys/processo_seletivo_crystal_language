class TravelBaseSerializer
    include JSON::Serializable
    
    def initialize(id : Int32 | Nil | String, travel_stops : Array(Int32))
        @id = id
        @travel_stops = travel_stops
    end
    
    def id
        @id
    end

    def travel_stops
        @travel_stops
    end

    def travel_stops=(@travel_stops : Array(Int32))
        @travel_stops
    end
end 
