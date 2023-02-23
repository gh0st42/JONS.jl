#include("routing/router.jl")

@resumable function message_event_generator(env::Environment, sim::NetSim, msggenconfig::MessageGeneratorConfig)
  while true
    @yield timeout(sim.env, rand(msggenconfig.interval))
    msggenconfig.counter += 1
    sim.routingstats.created += 1
    # select source node
    src = sim.nodes[rand(msggenconfig.source[1]:msggenconfig.source[2])]
    # select destination node
    dst = sim.nodes[rand(msggenconfig.destination[1]:msggenconfig.destination[2])]

    msg = Message(msggenconfig.prefix * string(msggenconfig.counter), src.id, dst.id, now(sim.env), 0, Dict(), Dict(), rand(msggenconfig.size[1]:msggenconfig.size[2]))
    # send message
    #println("Generating message ", msg.id, " from ", src.id, " to ", dst.id)
    sim.nodes[src.id].router.add(sim, src.id, msg)
  end
end

@resumable function message_burst_generator(env::Environment, sim::NetSim, msggenconfig::MessageGeneratorConfig)
  while true
    @yield timeout(sim.env, rand(msggenconfig.interval))
    for src in sim.nodes[msggenconfig.source[1]:msggenconfig.source[2]]
      msggenconfig.counter += 1
      sim.routingstats.created += 1

      # select destination node
      dst = sim.nodes[rand(msggenconfig.destination[1]:msggenconfig.destination[2])]
      msg = Message(msggenconfig.prefix * string(msggenconfig.counter), src.id, dst.id, now(sim.env), 0, Dict(), Dict(), rand(msggenconfig.size[1]:msggenconfig.size[2]))
      # send message
      sim.nodes[src.id].router.add(sim, src.id, msg)
    end
  end
end