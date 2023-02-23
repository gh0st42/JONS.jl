include("epidemic.jl")

function Base.show(io::IO, router::Router)
  print(io, "Router with capacity ", router.capacity, " and ", length(router.store), " messages")
end


@resumable function router_discovery(env::Environment, sim::NetSim, router::Router, node::Node)
  while true
    old_peers = copy(router.peers)
    router_update_neighbors(router, node, sim.nodes)
    new_peers = setdiff(router.peers, old_peers)
    for peer in new_peers
      router_on_new_peer(env, sim, node.id, peer)
    end
    @yield timeout(env, router.discovery_interval)
  end
end

function router_update_neighbors(router::Router, node::Node, nodes::Vector{Node})
  router.peers = copy(node.neighbors)
end

