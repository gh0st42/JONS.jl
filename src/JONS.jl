module JONS

using ResumableFunctions
using SimJulia
using Plots

macro exported_enum(name, args...)
  esc(quote
    @enum($name, $(args...))
    export $name
    $([:(export $arg) for arg in args]...)
  end)
end

include("types.jl")
include("node.jl")
include("movement/mobility.jl")
include("network.jl")
include("routing/router.jl")
include("helpers.jl")
include("simulation.jl")
include("messagegenerator.jl")
include("visualiaze.jl")

export Node, MovementStep, MessageGeneratorConfig, Message, NetworkSettings, Router, NetSim, jONS_test, EventGeneratorType, Single, Burst
export message_event_generator, message_burst_generator, sim_report, sim_run, sim_init, parse_one_movement, animator, generate_nodes, EpidemicRouter

function jONS_test()
  println("jONS test")
end

end