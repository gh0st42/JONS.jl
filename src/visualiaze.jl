
@resumable function animator(env::Environment, sim::NetSim, interval::Float64=1.0)
  names = []
  xs = Float64[]
  ys = Float64[]
  for i in sim.nodes
    push!(names, i.id)
    push!(xs, i.x)
    push!(ys, i.y)
  end
  #Plots.CURRENT_PLOT.nullableplot = nothing
  radius = sim.nodes[1].network.range
  plot(xs, ys, seriestype=:scatter, label="", ylims=[0, sim.world[2]], xlims=[0, sim.world[1]], markersize=radius, markerstrokewidth=0, markerstrokealpha=0, markeralpha=0.2, markerstrokecolor=:green, marker=:circle, markercolor=:green, series_annotations=text.(names, :bottom))
  frame(sim.anim, plot!(xs, ys, seriestype=:scatter, label="", ylims=[0, sim.world[2]], xlims=[0, sim.world[1]]))

  #sleep(0.1)
  @yield timeout(env, interval)
  @process animator(env, sim, interval)
end