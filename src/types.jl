using SimJulia

struct MovementStep
  time::Float64
  id::Int16
  x::Float32
  y::Float32
end

@enum EventGeneratorType Single Burst


mutable struct MessageGeneratorConfig
  prefix::String
  size::Tuple{Int,Int}
  interval::Tuple{Float64,Float64}
  source::Tuple{Int16,Int16}
  destination::Tuple{Int16,Int16}
  counter::Int
  type::EventGeneratorType
  function MessageGeneratorConfig(prefix::String, size::Tuple{Int,Int}, interval::Tuple{Float64,Float64}, source::Tuple{Int,Int}, destination::Tuple{Int,Int}, type::EventGeneratorType=Single)
    new(prefix, size, interval, source, destination, 0, type)
  end
end

mutable struct Message
  # The message type
  id::String
  src::Int16
  dst::Int16
  # creation time
  created::Float64
  hops::Int16
  # The message content
  content::Dict
  # The message metadata
  metadata::Dict
  # The message buffers
  size::Int
  #function Message(id::String, src::Int, dst::Int, env::Environment, content::Dict, metadata::Dict, size::Int)
  #  new(id, src, dst, now(env), 0, content, metadata, size)
  #end
end

Base.copy(m::Message) = Message(m.id, m.src, m.dst, m.created, m.hops, copy(m.content), copy(m.metadata), m.size)


struct NetworkSettings
  range::Int16
  bandwidth::Int
  loss::Float16
  delay::Float16
  function NetworkSettings(range::Int, bandwidth::Int)
    new(range, bandwidth, 0.0, 0.01)
  end
end

mutable struct Router
  store::Vector{Message}
  capacity::Int
  peers::Vector{Int16}
  discovery_interval::Float64
  history::Dict{String,Vector{Int16}}
  function Router(capacity::Int, discovery_interval::Float64)
    new(Vector{Message}(), capacity, Vector{Int16}(), discovery_interval, Dict{String,Vector{Int16}}())
  end
end

Base.copy(r::Router) = Router(r.capacity, r.discovery_interval)

struct RouterImpl
  # Router Type Name
  name::String
  # Actual router data
  core::Router
  # Initialize router function
  init::Function
  # Receive message callback
  onrecv::Function
  # Add message to router
  add::Function
end

Base.copy(r::RouterImpl) = RouterImpl(r.name, copy(r.core), r.init, r.onrecv, r.add)

mutable struct Node
  id::Int16
  x::Float64
  y::Float64
  energy::Float16
  network::NetworkSettings
  neighbors::Vector{Int16}
  router::RouterImpl
  function Node(id::Int16, network::NetworkSettings, router::RouterImpl, x::Float64=1.0, y::Float64=1.0, energy::Float16=Float16(100.0))
    new(id, x, y, energy, network, Vector{Int16}(), router)
  end
end

mutable struct NetStats
  tx::Int
  rx::Int
  drop::Int
  function NetStats()
    new(0, 0, 0)
  end
end

mutable struct RoutingStats
  created::Int
  started::Int
  relayed::Int
  aborted::Int
  dropped::Int
  removed::Int
  delivered::Int
  dups::Int
  hops::Int
  latency::Float64
  function RoutingStats()
    new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0.0)
  end
end

mutable struct NetSim
  env::Environment
  duration::Int
  world::Tuple{Int,Int}
  nodes::Vector{Node}
  movements::Vector{MovementStep}
  msggens::Vector{MessageGeneratorConfig}
  netstats::NetStats
  routingstats::RoutingStats
  anim::Animation
  config::Dict
  function NetSim(duration::Int, world::Tuple{Int,Int}, nodes::Vector{Node}, movements::Vector{MovementStep}, msggens::Vector{MessageGeneratorConfig}=MessageGeneratorConfig[], config::Dict=Dict{String,Any}())
    env = Simulation()
    new(env, duration, world, nodes, movements, msggens, NetStats(), RoutingStats(), Animation(), config)
  end
end

