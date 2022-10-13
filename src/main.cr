require "socket"
require "./packet"
require "./models"
require "./avocado"
require "./database"

def handle_client(context, client)
  puts "wait new packet"

  packet_parser = PacketParser.new
  slice = Bytes.new(10198)

  while message = client.read(slice)
    puts "message len #{message}"

    data = slice[..message-1]

    puts "Received a new packet #{data.size}"
    puts data.to_unsafe_bytes.hexdump

    code = packet_parser.parse(context, data)
    if code == 1
      client << Packets::Ping.new.result
    end

    while data = packet_parser.next
      break if data[1] == 0

      puts "Send #{data[0].size}"
      client << data[0]
    end
  end

end

server = TCPServer.new("0.0.0.0", 1973)

puts "Running server"
while client = server.accept?
  first_time_packet = Packets::FirstTime.new
  context = { date: first_time_packet.@data.time }

  puts context

  client << PacketBuilder.new.build(first_time_packet)

  puts "Client connected"
  puts client.remote_address

  spawn handle_client(context, client)
end


