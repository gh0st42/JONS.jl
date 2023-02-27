include("epidemic.jl")
include("sprayandwait.jl")

function Base.show(io::IO, router::Router)
  print(io, "Router with capacity ", router.capacity, " and ", length(router.store), " messages")
end

function router_remember(sim::NetSim, routerId::Int16, remote::Int16, message::Message)
  router = sim.nodes[routerId].router.core
  if !haskey(router.history, message.id)
    router.history[message.id] = []
  end
  router.history[message.id] = append!(router.history[message.id], remote)
end

function router_msg_known(sim::NetSim, routerId::Int16, message::Message)::Bool
  router = sim.nodes[routerId].router.core
  return haskey(router.history, message.id)
end

function router_has_been_spread(sim::NetSim, routerId::Int16, remote::Int16, message::Message)::Bool
  router = sim.nodes[routerId].router.core
  #println("HIST: ", length(keys(router.history)))
  if !haskey(router.history, message.id)
    return false
  end
  return remote in router.history[message.id]
end

@resumable function router_discovery(env::Environment, sim::NetSim, router::Router, node::Node)
  while true
    old_peers = copy(router.peers)
    router_update_neighbors(router, node, sim.nodes)
    new_peers = setdiff(router.peers, old_peers)
    for peer in new_peers
      node.router.onpeer(env, sim, node.id, peer)
    end
    @yield timeout(env, router.discovery_interval)
  end
end

function router_update_neighbors(router::Router, node::Node, nodes::Vector{Node})
  router.peers = copy(node.neighbors)
end

function router_init(sim::NetSim, node::Node)
  @process router_discovery(sim.env, sim, node.router.core, node)
end
