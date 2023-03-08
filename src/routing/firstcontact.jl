
function firstcontact_add(sim::NetSim, routerId::Int16, message::Message)
  router = sim.nodes[routerId].router.core
  if length(router.store) < router.capacity
    push!(router.store, message)
    @process firstcontact_forward(sim.env, sim, routerId, message)
  else
    #println("Router full, dropping message")
  end
end

@resumable function firstcontact_forward(env::Environment, sim::NetSim, myId::Int16, message::Message)
  router = sim.nodes[myId].router.core
  if message.dst in router.peers && !router_has_been_spread(sim, myId, message.dst, message)
    #println("attempting direct delivery of message ", message.id, " to ", message.dst, " from ", from)
    sim.routingstats.started += 1
    #for message in router.store
    #  if message.dst == message.dst
    p = @process node_send(env, sim, myId, message.dst, message)
    #@yield p
    router_remember(sim, myId, message.dst, message)

    deleteat!(router.store, findall(x -> x == message, router.store))
  else
    for n in router.peers
      neighbor = sim.nodes[n]
      if !router_has_been_spread(sim, myId, neighbor.id, message)
        sim.routingstats.started += 1
        p = @process node_send(env, sim, myId, neighbor.id, message)
        #@yield p
        router_remember(sim, myId, neighbor.id, message)
        # delete after spreading once
        # TODO: check for successful delivery
        deleteat!(router.store, findall(x -> x == message, router.store))
        return
      end
    end
    #println("No route to ", message.dst, ", dropping message")
  end
end
function firstcontact_on_recv(env::Environment, sim::NetSim, src::Int16, myId::Int16, message::Message)
  router = sim.nodes[myId].router.core
  sim.routingstats.relayed += 1
  if length(router.store) < router.capacity
    if router_msg_known(sim, myId, message)
      #if message in router.store
      #println("Message ", message.id, " already in store")
      sim.routingstats.dups += 1
      router_remember(sim, myId, src, message)
      #end
    else
      router_remember(sim, myId, src, message)
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
        @process firstcontact_forward(env, sim, myId, message)
      end
    end
  else
    #println("OnRecv: Router full, dropping message")
  end
end

function firstcontact_init(sim::NetSim, node::Node)
end

function firstcontact_on_new_peer(env::Environment, sim::NetSim, mynodid::Int16, new_peer::Int16)
  router = sim.nodes[mynodid].router.core
  #println("PEERS: ", length(router.peers))
  #println("Router ", mynodid, " discovered new peer ", new_peer)
  for message in router.store
    @process firstcontact_forward(env, sim, mynodid, message)
  end
end

function FirstContactRouter(capacity::Int, discovery_interval::Float64)::RouterImpl
  router = Router(capacity, discovery_interval)
  return RouterImpl("FirstContact", router, firstcontact_init, firstcontact_on_recv, firstcontact_on_new_peer, firstcontact_add)
end