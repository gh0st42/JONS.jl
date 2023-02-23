#using ResumableFunctions
#using SimJulia


@resumable function move_next(env::Environment, nodes::Array{Node}, movements::Array{MovementStep}, node::Node, step::MovementStep)
  @yield timeout(env, step.time - now(env))
  #println(now(env), " Moving node ", node.id, " to (", step.x, ", ", step.y, ")")
  node.x = step.x
  node.y = step.y


  cnt = 0
  #if length(movements) > 0
  while length(movements) > 0 && cnt < 1
    next_step = popfirst!(movements)
    if next_step.time == step.time
      nodes[next_step.id].x = next_step.x
      nodes[next_step.id].y = next_step.y
    else
      @process move_next(env, nodes, movements, nodes[next_step.id], next_step)
      cnt += 1
    end
  end

  for node in nodes
    node_calc_neighbors(node, nodes)
    #println(" Node ", node.id, " has neighbors: ", map(n -> n.id, node.neighbors))
  end
end

function move_init(env::Environment, nodes::Array{Node}, movements::Array{MovementStep})
  if length(movements) > 0
    first_step = popfirst!(movements)
    while first_step.time == 0
      nodes[first_step.id].x = first_step.x
      nodes[first_step.id].y = first_step.y
      if length(movements) > 0
        first_step = popfirst!(movements)
      else
        return
      end
    end
    for node in nodes
      node_calc_neighbors(node, nodes)
    end

    @process move_next(env, nodes, movements, nodes[first_step.id], first_step)
  end
end

mutable struct OneScenario
  duration::Float64
  nn::Int
  w::Float32
  h::Float32
  movements::Array{MovementStep}
end

Base.show(io::IO, scenario::OneScenario) = print(io, "OneScenario(duration=", scenario.duration, ", nn=", scenario.nn, ", w=", scenario.w, ", h=", scenario.h, ", #movements=", length(scenario.movements), ")")

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
