#using ResumableFunctions
#using SimJulia


@resumable function move_next(env::Environment, sim::NetSim, node::Node, step::MovementStep)
  @yield timeout(env, step.time - now(env))
  #println(now(env), " Moving node ", node.id, " to (", step.x, ", ", step.y, ")")
  node.x = step.x
  node.y = step.y


  cnt = 0
  #if length(movements) > 0
  while sim.move_idx <= length(sim.movements) && cnt < 1
    next_step = sim.movements[sim.move_idx]
    sim.move_idx += 1
    if next_step.time == step.time
      sim.nodes[next_step.id].x = next_step.x
      sim.nodes[next_step.id].y = next_step.y
    else
      @process move_next(env, sim, sim.nodes[next_step.id], next_step)
      cnt += 1
    end
  end

  for n in sim.nodes
    node_calc_neighbors(n, sim.nodes)
    #println(" Node ", node.id, " has neighbors: ", map(n -> n.id, node.neighbors))
  end
end

function move_init(sim::NetSim)
  if sim.move_idx <= length(sim.movements)
    first_step = sim.movements[sim.move_idx]
    sim.move_idx += 1
    while first_step.time == 0
      sim.nodes[first_step.id].x = first_step.x
      sim.nodes[first_step.id].y = first_step.y
      if sim.move_idx <= length(sim.movements)
        first_step = sim.movements[sim.move_idx]
        sim.move_idx += 1
      else
        return
      end
    end
    for node in sim.nodes
      node_calc_neighbors(node, sim.nodes)
    end

    @process move_next(sim.env, sim, sim.nodes[first_step.id], first_step)
  end
end

mutable struct OneScenario
  duration::Float64
  nn::Int
  w::Float32
  h::Float32
  movements::Array{MovementStep}
end

Base.show(io::IO, move::MovementStep) = print(io, "Step(t=", move.time, " n=", move.id, " x=", move.x, " y=", move.y, ")")

Base.show(io::IO, scenario::OneScenario) = print(io, "OneScenario(duration=", scenario.duration, ", nn=", scenario.nn, ", w=", scenario.w, ", h=", scenario.h, ", #movements=", length(scenario.movements), ")")

"""
  generate_randomwaypoint_movement(duration::Float64, nn::Int, w::Float32, h::Float32, min_speed::Float32, max_speed::Float32, min_pause::Float32, max_pause::Float32)

Generate a random waypoint movement for `nn` nodes in a `w`x`h` world for `duration` seconds.
"""
function generate_randomwaypoint_movement(duration::Float64, nn::Int, w::Float32, h::Float32, min_speed::Float32, max_speed::Float32, min_pause::Float32, max_pause::Float32)
  movements = MovementStep[]
  for i in 1:nn
    cur_time = 0.0
    x = rand() * w
    y = rand() * h
    push!(movements, MovementStep(cur_time, i, x, y))

    while cur_time <= duration
      way_x = rand() * w
      way_y = rand() * h
      speed = rand() * (max_speed - min_speed) + min_speed
      pause = ceil(rand() * (max_pause - min_pause) + min_pause)
      cur_time += pause
      dist = sqrt((way_x - x)^2 + (way_y - y)^2)
      time = dist / speed
      step_x = (way_x - x) / time
      step_y = (way_y - y) / time
      for j in 1:time
        if cur_time + j >= duration
          break
        end
        x += step_x
        y += step_y
        push!(movements, MovementStep(ceil(float(cur_time + j)), i, x, y))
      end
      cur_time += time
    end
  end
  sort!(movements, by=x -> x.time)
  return OneScenario(duration, nn, w, h, movements)
end

"""
  plot_one_scenario(scenario::OneScenario)

Plot the movements of the nodes in `scenario`.
"""
function plot_one_scenario(scenario::OneScenario)
  plt = nothing
  for node in 1:scenario.nn
    x = []
    y = []
    for step in scenario.movements
      if step.id != node
        continue
      end
      push!(x, step.x)
      push!(y, step.y)
    end
    if node == 1
      plt = scatter(x, y, legend=true, markerstrokealpha=0.0, markerstrokewidth=0.0, xlims=[0, scenario.w], ylims=[0, scenario.h], label="Node $node")
    else
      plt = scatter!(x, y, legend=true, markerstrokewidth=0.0, label="Node $node")
    end
  end
  #if plt !== nothing
  #  display(plt)
  #end
  return plt
end

"""
  parse_one_movement(file::String)

Parse a movement file with node positions in TheONE format.
"""
function parse_one_movement(file::String)
  scenario = OneScenario(0.0, 0, 0.0, 0.0, MovementStep[])
  lines = readlines(file)
  movements = MovementStep[]
  for line in lines
    split_line = split(line, ' ')
    if length(split_line) == 4
      if line[1] != '#'
        time = parse(Float64, split_line[1])
        id = parse(Int16, split_line[2]) + 1
        scenario.nn = max(scenario.nn, id)
        x = parse(Float32, split_line[3])
        y = parse(Float32, split_line[4])
        push!(scenario.movements, MovementStep(time, id, x, y))
      end
    elseif length(split_line) == 6
      if line[1] != '#'
        scenario.duration = parse(Float64, split_line[2])
        #scenario.nn = parse(Int16, split_line[2]) + 1
        scenario.w = parse(Float32, split_line[4])
        scenario.h = parse(Float32, split_line[6])
      end
    end
  end
  return scenario
end
