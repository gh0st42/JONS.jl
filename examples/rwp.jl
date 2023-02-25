using ResumableFunctions
using SimJulia
using Plots
using Random

push!(LOAD_PATH, "../src")
push!(LOAD_PATH, "src")

using JONS


NUM_NODES = 10
#DURATION = 86400
DURATION = 360
WORLD_SIZE = (1000, 1000)
ANIMATION_STEPS = 20.0
visualize_simulation = true

function simulate()
  Random.seed!(1)

  one_scenario = generate_randomwaypoint_movement(Float64(DURATION), NUM_NODES, Float32(WORLD_SIZE[1]), Float32(WORLD_SIZE[2]), Float32(1.0), Float32(5.0), Float32(0.0), Float32(60.0))
  movements = one_scenario.movements
  #println("Movements: ", movements)
  last_move_time = Int(ceil(last(movements).time))
  plot_one_scenario(one_scenario)
end

@time simulate()