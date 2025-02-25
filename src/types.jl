"""
    Guest(name::String, gender::Symbol)

A guest with a name and a gender.

# Fields
- `name::String`: name of the guest
- `gender::Symbol`: gender of the guest, currently only supports :M or :F
"""
struct Guest
    name::String
    gender::Symbol
    function Guest(name::String, gender::Symbol)
        gender !== :F && gender !== :M && error("Unknown gender: ", gender)
        new(name, gender)
    end
end

function Base.show(io::IO, ::MIME"text/plain", g::Guest)
    print(io, typeof(g), ": ", g.name, " (", g.gender, ")")
    return nothing
end

"""
    Wish(mail::String, guest_ids::Vector{Int}, gender::Symbol)

A wish of multiple guests that want to share the same room.

# Fields
- `mail::String`: e-mail the wish was sent with
- `guest_ids::Vector{Int}`: guest indices of the guest in this wish
- `gender::Symbol`: gender of the guests in the wish, currently only supports :M or :F
"""
struct Wish
    mail::String
    guest_ids::Vector{Int}
    gender::Symbol
end

function Base.show(io::IO, ::MIME"text/plain", w::Wish)
    print(io, length(w.guest_ids), "-person ", typeof(w), " from ", w.mail)
    return nothing
end

"""
    Room(name::String, capacity::Int, gender::Symbol)

A room containing multiple guests.

# Fields
- `name::String`: name of the room
- `capacity::Int`: number of guests the room can contain
- `gender::Symbol`: gender of the guests in the room, currently only supports :M or :F
"""
struct Room
    name::String
    capacity::Int
    gender::Symbol
    function Room(name::String, capacity::Int, gender::Symbol)
        gender !== :F && gender !== :M && error("Unknown gender: ", gender)
        new(name, capacity, gender)
    end
end

function Base.show(io::IO, ::MIME"text/plain", r::Room)
    print(io, r.capacity, "-person ", typeof(r), " ", r.name, " (", r.gender, ")")
    return nothing
end

struct RoomOccupancyProblem
    n_guests::Int
    n_wishes::Int
    n_rooms::Int
    n_beds::Int
    max_happiness::Int
    guests::Vector{Guest}
    wishes::Vector{Wish}
    rooms::Vector{Room}
    relations::SparseMatrixCSC{Int64, Int64}
    room_id_of_guest::Vector{Int}
    guest_ids_of_room::Vector{Vector{Int}}
    fulfilled_wishes::Vector{Bool}

    function RoomOccupancyProblem(
        guests::Vector{Guest},
        wishes::Vector{Wish},
        rooms::Vector{Room}
    )
        # get the basic numbers
        n_guests = length(guests)
        n_wishes = length(wishes)
        n_rooms = length(rooms)
        n_beds = sum([r.capacity for r in rooms])

        # error if not enough beds
        if n_guests > n_beds
            err_msg = string(
                "More guests than beds!",
                "\n  number of guests = ", n_guests,
                "\n  number of beds = ", n_beds,
                "\n",
            )
            error(err_msg)
        end

        # find the relations and the maximum happiness between the guests
        relations = find_relations(wishes, n_beds)
        max_happiness = length(findall(!iszero, relations))

        # initializations
        room_id_of_guest = zeros(Int, n_guests)
        guest_ids_of_room = fill(Vector{Int}(), n_rooms)
        fulfilled_wishes = zeros(Bool, n_wishes)

        # create instance of RoomOccupancyProblem
        new(
            n_guests,
            n_wishes,
            n_rooms,
            n_beds,
            max_happiness,
            guests,
            wishes,
            rooms,
            relations,
            room_id_of_guest,
            guest_ids_of_room,
            fulfilled_wishes
        )
    end
end

"""
    RoomJugglerJob(excel_file::String)

A RoomJugglerJob containing the guests, rooms and wishes - a problem that needs juggling!

# Arguments
- `excel_file::String`: Excel file with extension `.xlsx`, containing the guests, rooms and
  wishes

# Fields
- `n_guests::Int`: number of guests
- `n_wishes::Int`: number of wishes
- `n_rooms::Int`: number of rooms
- `n_beds::Int`: number of all beds in the room, the sum of all room capacities
- `ropf::RoomOccupancyProblem`: room occupancy problem of the female guests
- `ropm::RoomOccupancyProblem`: room occupancy problem of the male guests
"""
struct RoomJugglerJob
    n_guests::Int
    n_wishes::Int
    n_rooms::Int
    n_beds::Int
    ropf::RoomOccupancyProblem
    ropm::RoomOccupancyProblem

    function RoomJugglerJob(excel_file::String)
        # read the excel_file
        guests_raw, wishes_raw, rooms_raw = get_raw_data(excel_file)

        # get the Vector{Guest}, Vector{Wish}, Vector{Room}
        guests = get_guests(guests_raw)
        wishes = get_wishes(wishes_raw, guests)
        rooms = get_rooms(rooms_raw)

        # get the basic numbers
        n_guests = length(guests)
        n_wishes = length(wishes)
        n_rooms = length(rooms)
        n_beds = sum([r.capacity for r in rooms])

        # filter genders
        guests_f, wishes_f = filter_genders(guests, wishes, :F)
        guests_m, wishes_m = filter_genders(guests, wishes, :M)
        rooms_f = filter(x -> x.gender == :F, rooms)
        rooms_m = filter(x -> x.gender == :M, rooms)

        # RoomOccupancyProblem for the females
        ropf = RoomOccupancyProblem(guests_f, wishes_f, rooms_f)

        # RoomOccupancyProblem for the males
        ropm = RoomOccupancyProblem(guests_m, wishes_m, rooms_m)

        # create RoomJugglerJob instance
        new(n_guests, n_wishes, n_rooms, n_beds, ropf, ropm)
    end
end

function Base.show(io::IO, ::MIME"text/plain", rjj::RoomJugglerJob)
    println(io, typeof(rjj), ":")
    @printf(io, "%d rooms\n", rjj.n_rooms)
    @printf(io, "  %d females\n", rjj.ropf.n_rooms)
    @printf(io, "  %d males\n", rjj.ropm.n_rooms)
    @printf(io, "%d beds\n", rjj.n_beds)
    @printf(io, "  %d females\n", rjj.ropf.n_beds)
    @printf(io, "  %d males\n", rjj.ropm.n_beds)
    @printf(io, "%d guests\n", rjj.n_guests)
    @printf(io, "  %d females\n", rjj.ropf.n_guests)
    @printf(io, "  %d males\n", rjj.ropm.n_guests)
    @printf(io, "%d wishes\n", rjj.n_wishes)
    @printf(io, "  %d females\n", rjj.ropf.n_wishes)
    @printf(io, "  %d males", rjj.ropm.n_wishes)
    return nothing
end

"""
    JuggleConfig(; [n_iter, beta, t_0, t_min])

Configuration of the underlying simulated annealing optimization.

# Arguments
- `n_iter::Int=300`: number of iterations per temperature (default=300)
- `beta::Real=0.999`: temperature decrease factor (default=0.999, condition: 0 < β < 1)
- `t_0::Real=1.0`: starting temperature (default=1.0)
- `t_min::Real=1e-7`: minimum temperature (default=1e-7)

# Fields
- `n_iter::Int`: number of iterations per temperature
- `n_total_iter::Int`: number of total iterations (`n_iter * length(t_history)`)
- `beta::Float64`: temperature decrease factor
- `t_0::Float64`: starting temperature
- `t_min::Float64`: minimum temperature
- `t_history::Vector{Float64}`: temperature steps
"""
struct JuggleConfig
    n_iter::Int
    n_total_iter::Int
    beta::Float64
    t_0::Float64
    t_min::Float64
    t_history::Vector{Float64}

    function JuggleConfig(;
        n_iter::Int=300,
        beta::Real=0.999,
        t_0::Real=1.0,
        t_min::Real=1e-7,
    )
        # check for bounds of beta
        !(0 < beta < 1) && throw(BoundsError("Condition 0 < β < 1 violated with β = $beta"))
        t_history = temperature_history(t_0, t_min, beta)
        n_total_iter = length(t_history) * n_iter

        new(n_iter, n_total_iter, beta, t_0, t_min, t_history)
    end
end
