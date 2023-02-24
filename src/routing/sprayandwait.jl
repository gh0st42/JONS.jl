
function sprayandwait_add(sim::NetSim, routerId::Int16, message::Message)
    router = sim.nodes[routerId].router.core
    if length(router.store) < router.capacity
        message.metadata["copies"] = router.config["copies"]
        #println("NEW ", message.id, " ", message.src, " <-> ", message.dst, " on ", routerId, " with ", message.metadata["copies"], " copies")
        push!(router.store, message)
        @process sprayandwait_forward(sim.env, sim, routerId, message)
    else
        #println("Router full, dropping message")
    end
end

function sprayandwait_remember(sim::NetSim, routerId::Int16, remote::Int16, message::Message)
    router = sim.nodes[routerId].router.core
    if !haskey(router.history, message.id)
        router.history[message.id] = []
    end
    router.history[message.id] = append!(router.history[message.id], remote)
end

function sprayandwait_msg_known(sim::NetSim, routerId::Int16, message::Message)::Bool
    router = sim.nodes[routerId].router.core
    return haskey(router.history, message.id)
end

function sprayandwait_has_been_spread(sim::NetSim, routerId::Int16, remote::Int16, message::Message)::Bool
    router = sim.nodes[routerId].router.core
    #println("HIST: ", length(keys(router.history)))
    if !haskey(router.history, message.id)
        return false
    end
    return remote in router.history[message.id]
end

@resumable function sprayandwait_forward(env::Environment, sim::NetSim, myId::Int16, message::Message)
    router = sim.nodes[myId].router.core
    if message.dst in router.peers && !sprayandwait_has_been_spread(sim, myId, message.dst, message)
        #println("attempting direct delivery of message ", message.id, " from ", message.src, " to ", message.dst, " via ", myId)
        sim.routingstats.started += 1
        p = @process node_send(env, sim, myId, message.dst, message)
        #@yield p
        sprayandwait_remember(sim, myId, message.dst, message)

        deleteat!(router.store, findall(x -> x == message, router.store))
    elseif message.metadata["copies"] > 1
        #println("SPRAYING", message.metadata["copies"])
        for n in router.peers
            if message.metadata["copies"] <= 1
                # We have spread the message to enough nodes, entering WAIT phase
                #println("Entering WAIT phase")
                return
            end
            neighbor = sim.nodes[n]
            if !sprayandwait_has_been_spread(sim, myId, neighbor.id, message)
                if router.config["binary"] == false
                    message.metadata["copies"] -= 1
                end
                out_message = copy(message)
                out_message.metadata["copies"] = 1
                sim.routingstats.started += 1
                p = @process node_send(env, sim, myId, neighbor.id, out_message)
                #@yield p
                sprayandwait_remember(sim, myId, neighbor.id, message)
            end
        end
        #println("No route to ", message.dst, ", dropping message")
    end
end
function sprayandwait_on_recv(env::Environment, sim::NetSim, src::Int16, myId::Int16, message::Message)
    router = sim.nodes[myId].router.core
    sim.routingstats.relayed += 1
    if length(router.store) < router.capacity
        if sprayandwait_msg_known(sim, myId, message)
            #if message in router.store
            #println("Message ", message.id, " already in store")
            sim.routingstats.dups += 1
            sprayandwait_remember(sim, myId, src, message)
            #end
        else
            sprayandwait_remember(sim, myId, src, message)
            push!(router.store, message)
            message.hops += 1
            #push!(router.store, message)
            #println("SprayAndWaitRouter received message ", message.id, " from ", src, " for ", message.dst, " on ", myId, " with ", message.metadata["copies"], " copies")
            if message.dst == myId
                #println("Message ", message.id, " delivered to ", myId)
                sim.routingstats.delivered += 1
                sim.routingstats.latency += now(env) - message.created
                sim.routingstats.hops += message.hops
            else
                @process sprayandwait_forward(env, sim, myId, message)
            end
        end
    else
        #println("OnRecv: Router full, dropping message")
    end
end

function sprayandwait_init(sim::NetSim, node::Node)
end

function sprayandwait_on_new_peer(env::Environment, sim::NetSim, mynodid::Int16, new_peer::Int16)
    router = sim.nodes[mynodid].router.core
    for message in router.store
        @process sprayandwait_forward(env, sim, mynodid, message)
    end
end

function SprayAndWaitRouter(capacity::Int, discovery_interval::Float64, copies::Int=7, binary::Bool=false)::RouterImpl
    router = Router(capacity, discovery_interval)
    router.config["copies"] = copies
    router.config["binary"] = binary
    return RouterImpl("SprayAndWait", router, sprayandwait_init, sprayandwait_on_recv, sprayandwait_on_new_peer, sprayandwait_add)
end