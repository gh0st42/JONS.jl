using ResumableFunctions
using SimJulia
using Plots
using Random

push!(LOAD_PATH, "../src")
push!(LOAD_PATH, "src")

using JONS


NUM_NODES = 17
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

  #movements = parse_one_movement("data/10nodesRWP.one")
  movements = parse_one_movement("data/large_1.one")
  last_move_time = Int(ceil(last(movements).time))

  # configure network
  network = NetworkSettings(100, 54000000)

  # configure nodes
  router_template = Router(10000, 2.0)
  epidemic = EpidemicRouter(10000, 2.0)
  println(epidemic)
  nodes = generate_nodes(17, network, epidemic)

  msggenconfig = MessageGeneratorConfig("M", (80, 120), (20.0, 20.0), (6, 15), (17, 17), Burst)
  config = Dict()
  #config["visualize"] = true
  #config["poslogger"] = false
  sim = NetSim(last_move_time + 1, (WORLD_SIZE[1], WORLD_SIZE[2]), nodes, movements, MessageGeneratorConfig[msggenconfig], config)

  sim_init(sim)

  sim_run(sim)

  println("\n")
  sim_report(sim)
  println("Last move time: ", last_move_time)

end

@time simulate()

#jONS_test()\