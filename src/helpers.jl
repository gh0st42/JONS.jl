macro simproc(func::Function, sim::NetSim, args...)
  #expr.head !== :call && error("Expression is not a function call!")
  esc(:(Process($(func, sim.env, args...))))
end

@resumable function DelayedExecution(env::Environment, delay::Float64, func::Function, args...)
  @yield timeout(env, delay)
  @process func(args...)
end


function Base.show(io::IO, netstats::NetStats)
  println(io, "Network stats:")
  println(io, "  Messages sent: ", netstats.tx)
  println(io, "  Messages received: ", netstats.rx)
  println(io, "  Messages dropped: ", netstats.drop)
end

function Base.show(io::IO, routingstats::RoutingStats)
  println(io, "Routing stats:")
  println(io, "  Bundles created: ", routingstats.created)
  println(io, "  Bundles started: ", routingstats.started)
  println(io, "  Bundles relayed: ", routingstats.relayed)
  println(io, "  Bundles dups: ", routingstats.dups)
  println(io, "  Bundles aborted: ", routingstats.aborted)
  println(io, "  Bundles dropped: ", routingstats.dropped)
  println(io, "  Bundles removed: ", routingstats.removed)
  println(io, "  Bundles delivered: ", routingstats.delivered)
  println(io, "  Bundle delivery rate: ", round(routingstats.delivered / routingstats.created; digits=2))
  println(io, "  Overhead ratio: ", round((routingstats.relayed - routingstats.delivered) / routingstats.delivered; digits=2))
  println(io, "  Bundle latency (avg): ", round(routingstats.latency / routingstats.delivered; digits=2), "s")
  println(io, "  Bundle hops (avg): ", round(routingstats.hops / routingstats.delivered; digits=2))

end

