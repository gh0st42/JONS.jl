
function epidemic_add(sim::NetSim, routerId::Int16, message::Message)
  router = sim.nodes[routerId].router.core
  if length(router.store) < router.capacity
    push!(router.store, message)
    @process epidemic_forward(sim.env, sim, routerId, message)
  else
    #println("Router full, dropping message")
  end
end

function epidemic_remember(sim::NetSim, routerId::Int16, remote::Int16, message::Message)
  router = sim.nodes[routerId].router.core
  if !haskey(router.history, message.id)
    router.history[message.id] = []
  end
  router.history[message.id] = append!(router.history[message.id], remote)
end
function epidemic_msg_known(sim::NetSim, routerId::Int16, message::Message)::Bool
  router = sim.nodes[routerId].router.core
  return haskey(router.history, message.id)
end
function epidemic_has_been_spread(sim::NetSim, routerId::Int16, remote::Int16, message::Message)::Bool
  router = sim.nodes[routerId].router.core
  #println("HIST: ", length(keys(router.history)))
  if !haskey(router.history, message.id)
    return false
  end
  return remote in router.history[message.id]
end

@resumable function epidemic_forward(env::Environment, sim::NetSim, myId::Int16, message::Message)
  router = sim.nodes[myId].router.core
  if message.dst in router.peers && !epidemic_has_been_spread(sim, myId, message.dst, message)
    #println("attempting direct delivery of message ", message.id, " to ", message.dst, " from ", from)
    sim.routingstats.started += 1
    #for message in router.store
    #  if message.dst == message.dst
    p = @process node_send(env, sim, myId, message.dst, message)
    #@yield p
    epidemic_remember(sim, myId, message.dst, message)

    #println(length(router.store))
    deleteat!(router.store, findall(x -> x == message, router.store))
    #println(length(router.store))
    #  end
    #end
  else
    # epidemic routing
    #println("epidemic delivery of message ", message.id, " to ", message.dst, " from ", from)
    #n_ids = map(x -> x.id, sim.nodes[myId].neighbors)
    #id_diff = setdiff(n_ids, router.peers)
    #if id_diff != []
    #  println("DIFF: ", id_diff)
    #end
    for n in router.peers
      neighbor = sim.nodes[n]
      if !epidemic_has_been_spread(sim, myId, neighbor.id, message)
        sim.routingstats.started += 1
        p = @process node_send(env, sim, myId, neighbor.id, message)
        #@yield p
        epidemic_remember(sim, myId, neighbor.id, message)
      end
    end
    #println("No route to ", message.dst, ", dropping message")
  end
end
function epidemic_on_recv(env::Environment, sim::NetSim, src::Int16, myId::Int16, message::Message)
  router = sim.nodes[myId].router.core
  sim.routingstats.relayed += 1
  if length(router.store) < router.capacity
    if epidemic_msg_known(sim, myId, message)
      #if message in router.store
      #println("Message ", message.id, " already in store")
      sim.routingstats.dups += 1
      epidemic_remember(sim, myId, src, message)
      #end
    else
      epidemic_remember(sim, myId, src, message)
      push!(router.store, message)
      message.hops += 1
      #push!(router.store, message)
      #println("Router received message ", message.id, " from ", src, " for ", message.dst)
      if message.dst == myId
        #println("Message ", message.id, " delivered to ", myId)
        sim.routingstats.delivered += 1
        sim.routingstats.latency += now(env) - message.created
        sim.routingstats.hops += message.hops
      else
        @process epidemic_forward(env, sim, myId, message)
      end
    end
  else
    #println("OnRecv: Router full, dropping message")
  end
end

function epidemic_init(sim::NetSim, node::Node)
end

function epidemic_on_new_peer(env::Environment, sim::NetSim, mynodid::Int16, new_peer::Int16)
  router = sim.nodes[mynodid].router.core
  #println("PEERS: ", length(router.peers))
  #println("Router ", mynodid, " discovered new peer ", new_peer)
  for message in router.store
    @process epidemic_forward(env, sim, mynodid, message)
  end
end

function EpidemicRouter(capacity::Int, discovery_interval::Float64)::RouterImpl
  router = Router(capacity, discovery_interval)
  return RouterImpl("Epidemic", router, epidemic_init, epidemic_on_recv, epidemic_on_new_peer, epidemic_add)
end