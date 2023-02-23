
BROADCAST_ADDR::Int = 0xFFFF

function tx_time(message::Message, settings::NetworkSettings)
  return message.size / settings.bandwidth + settings.delay
end

