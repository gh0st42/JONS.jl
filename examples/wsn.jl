using ResumableFunctions
using SimJulia
using Plots
using Random

push!(LOAD_PATH, "../src")
using JONS


NUM_NODES = 10
#DURATION = 86400
DURATION = 3600
WORLD_SIZE = (1000, 1000)
ANIMATION_STEPS = 20.0
visualize_simulation = false


function simulate()
  Random.seed!(1)
  #visualize_simulation = true
  #plotlyjs()

  #movements = MovementStep[]
  #for i in 1:DURATION
  #  push!(movements, MovementStep(float(i), rand(1:MAX_NODES), rand() * 100, rand() * 100))
  #end

  #one_scenario = parse_one_movement("data/10nRWP-3600.one")
  one_scenario = generate_randomwaypoint_movement(Float64(DURATION), NUM_NODES, Float32(WORLD_SIZE[1]), Float32(WORLD_SIZE[2]), Float32(1.0), Float32(5.0), Float32(0.0), Float32(60.0))

  # configure network
  network = NetworkSettings(100, 54000000)

  # configure nodes
  epidemic = EpidemicRouter(10000, 2.0)
  nodes = generate_nodes(one_scenario.nn, network, epidemic)

  msggenconfig = MessageGeneratorConfig("M", (80, 120), (10.0, 60.0), (1, NUM_NODES), (1, NUM_NODES), Single)
  config = Dict()
  #config["visualize"] = true
  #config["poslogger"] = false
  sim = NetSim(one_scenario.duration + 1, (one_scenario.w, one_scenario.h), nodes, one_scenario.movements, MessageGeneratorConfig[msggenconfig], config)

  sim_init(sim)

  sim_run(sim)

  println("\n")
  sim_report(sim)

end

@time simulate()

#jONS_test()