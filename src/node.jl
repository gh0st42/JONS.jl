
function Base.show(io::IO, node::Node)
  print(io, "Node ", node.id, " at (", node.x, ", ", node.y, ") with energy ", node.energy, " and range ", node.network.range)
end

function generate_nodes(n::Int, network::NetworkSettings, router::RouterImpl, offset::Int16=Int16(0))
  nodes = Vector{Node}()
  for i in 1:n
    push!(nodes, Node(Int16(i + offset), network, copy(router)))
  end
  return nodes
end

@resumable function node_send(env::Environment, sim::NetSim, from::Int16, to::Int16, message::Message)
  #println(now(sim.env), " > ", from, " to ", to, " with message: ", message.id)
  #@info now(sim.env), " > ", from, " to ", to, " with message: ", message.id
  tx_t = tx_time(message, sim.nodes[from].network)
  if to == BROADCAST_ADDR # broadcast
    println("Broadcasting message to ", length(sim.nodes[from].neighbors), " neighbors (", sim.nodes[from].neighbors, ")")
    if length(sim.nodes[from].neighbors) == 0
      #println("No neighbors, dropping message")
      return
    end
    #@yield timeout(env, tx_t)
    for neighbor in sim.nodes[from].neighbors

      #println(sim.netstats)
      sim.netstats.tx += 1
      #println(sim.netstats)
      @process DelayedExecution(env, tx_t, node_on_recv, env, sim, from, neighbor, message)
    end
  else # unicast
    if to in sim.nodes[from].neighbors
      sim.netstats.tx += 1
      #println("Sending message ", message.id, " to ", to, " from ", from, " with delay ", tx_t)
      #@process DelayedExecution(env, tx_t, node_on_recv, env, sim, from, to, message)
      @yield timeout(sim.env, tx_t)
      @process node_on_recv(env, sim, from, to, message)
    else
      #println("No route to ", to, ", dropping message")
    end
  end
end
@resumable function node_on_recv(env::Environment, sim::NetSim, from::Int16, to::Int16, message::Message)
  if from in sim.nodes[to].neighbors
    #println(now(sim.env), " < ", from, " to ", to, " with message ", message.id)
    sim.netstats.rx += 1
    sim.nodes[to].router.onrecv(env, sim, from, to, copy(message))
  else
    sim.netstats.drop += 1
    #println(now(sim.env), " < ", from, " to ", to, " with message ", message.id, " (dropped)")
  end
end

function node_calc_neighbors(node::Node, nodes::Vector{Node})
  empty!(node.neighbors)
  for other_node in nodes
    if other_node.id != node.id
      if sqrt((node.x - other_node.x)^2 + (node.y - other_node.y)^2) <= node.network.range
        push!(node.neighbors, other_node.id)
      end
    end
  end
end