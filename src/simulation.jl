import Dates
using DataFrames

function sim_init(sim::NetSim)
  @info "initializing simulation"

  for i in 1:length(sim.nodes)
    #node_calc_neighbors(sim.nodes[i], sim.nodes)
    router_init(sim, sim.nodes[i])
    sim.nodes[i].router.init(sim, sim.nodes[i])
  end

  # initialize node movement
  #next_step = popfirst!(sim.movements)
  #@process move_next(sim.env, sim.nodes, sim.movements, sim.nodes[next_step.id], next_step)
  move_init(sim)

  for mgc in sim.msggens
    if mgc.interval[1] > 0 || mgc.interval[2] > 0
      if mgc.type == Single
        @process message_event_generator(sim.env, sim, mgc)
      elseif mgc.type == Burst
        @process message_burst_generator(sim.env, sim, mgc)
      end
    end
  end

  if haskey(sim.config, "visualize") && sim.config["visualize"]
    steps = haskey(sim.config, "visualize_steps") ? sim.config["visualize_steps"] : 20.0
    @process animator(sim.env, sim, steps)
  end
end

@resumable function sim_log_moves(env::Environment, sim::NetSim, interval::Float64=1.0)
  while true
    @yield timeout(env, interval)
    println("[", round(Int, now(env)), "]")
    for node in sim.nodes
      #@debug join([now(env), node.id, node.x, node.y], " ")
      println("n", node.id - 1, " ", round(node.x, digits=4), " ", round(node.y, digits=4))
    end
  end
end

@resumable function sim_log_deliveryrate_over_time(env::Environment, sim::NetSim, interval::Float64=1.0)
  sim.reports["dx_over_time"] = DataFrame(time=[], dx=[])
  while true
    @yield timeout(env, interval)
    dx = 0
    if sim.routingstats.created > 0
      dx = sim.routingstats.delivered / sim.routingstats.created
    end

    push!(sim.reports["dx_over_time"], (round(Int, now(env)), dx))
  end
end

function sim_run(sim::NetSim)
  @info "running simulation"

  if haskey(sim.config, "poslogger") && sim.config["poslogger"]
    @process sim_log_moves(sim.env, sim, 1.0)
  end
  if haskey(sim.config, "dx_over_time") && sim.config["dx_over_time"]
    @process sim_log_deliveryrate_over_time(sim.env, sim, 1.0)
  end
  #@process sim_log_moves(sim.env, sim, 1.0)

  start_real = Dates.now()
  last_real = Dates.now()
  last_sim = 0.0
  while (now(sim.env) < sim.duration + 1)
    now_sim = now(sim.env)
    next_stop = min(sim.duration + 1, now_sim + 5.0)
    run(sim.env, next_stop)
    now_real = Dates.now()
    diff = now_real - last_real
    if diff >= Dates.Second(60)
      rate = (now_sim - last_sim) / (diff / Dates.Second(1))
      @info "real: $(now_real - start_real) sim: $(round(Int, now_sim)) rate: $(round(rate, digits=2)) s/s"
      last_real = now_real
      last_sim = now_sim
    end

  end
  #run(sim.env, sim.duration + 1)
  now_real = Dates.now()
  diff = now_real - last_real
  now_sim = now(sim.env)

  rate = (now_sim - last_sim) / (diff / Dates.Second(1))
  @info "real: $(now_real - start_real) sim: $(round(Int, now_sim)) rate: $(round(rate, digits=2)) s/s"
  @info "simulation finished in $(Dates.canonicalize(Dates.CompoundPeriod(now_real - start_real)))"
end

function sim_report(sim::NetSim)
  println(sim.netstats)
  println(sim.routingstats)

  if haskey(sim.config, "visualize") && sim.config["visualize"]
    @info "generating visualization"
    gif(sim.anim, fps=10)
  end
end

"""
    sim_report_df(sim::NetSim)

Generate an animated GIF of the simulation.
"""
function sim_viz(sim::NetSim)
  if haskey(sim.config, "visualize") && sim.config["visualize"]
    gif(sim.anim, fps=10)
  end
end

function sim_report_df(sim::NetSim)
  netstats = struct_to_dataframe(sim.netstats)
  routingstats = struct_to_dataframe(sim.routingstats)
  return netstats, routingstats
end
