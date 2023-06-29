class LocationBaseSerializer
    include JSON::Serializable
    @id : String
    @name : String
    @type : String
    @dimension : String
    @residents : Array(Resident)

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