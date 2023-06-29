class LocationOptimizeSerializer
    include JSON::Serializable
    @id : String
    @name : String
    @type : String
    @dimension : String
    @residents : Array(Resident)
    @dimension_average : Float32 = 0

    def id
        @id
    end

    def name
        @name
    end

    def type
        @type
    end
    
    def dimension
        @dimension
    end

    def residents
        @residents
    end

    def dimension_average=(@dimension_average)
        @dimension_average
    end

    def dimension_average
        @dimension_average
    end


end 
class Resident
    include JSON::Serializable
    @episode : Array(Episode)

    def episode
        @episode
    end
end 

class Episode
    include JSON::Serializable
    @id : String
end