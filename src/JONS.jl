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

export struct_to_dataframe
export Node, MovementStep, Message, NetworkSettings, Router, EpidemicRouter, SprayAndWaitRouter, DirectDeliveryRouter, FirstContactRouter
export MessageGeneratorConfig, message_event_generator, message_burst_generator, EventGeneratorType, Single, Burst
export NetSim, sim_report, sim_run, sim_init, parse_one_movement, animator, generate_nodes, OneScenario, sim_report_df, sim_viz
export bundle_stats, net_stats, generate_randomwaypoint_movement, plot_one_scenario, OneScenario

end