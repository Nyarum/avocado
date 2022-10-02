require "socket"
require "packet"
require "../lib/models"
require "../lib/avocado"

def handle_client(client)
  puts "wait new packet"

  packet_parser = PacketParser.new
  slice = Bytes.new(1024)
  while message = client.read(slice)
    puts "message len #{message}"

    data = slice[..message-1]

    puts "Received a new packet"
    puts data.to_unsafe_bytes.hexdump

    code = packet_parser.parse(data)
    if code == 1
      client << Packets::Ping.new.result
    end

    while data = packet_parser.next
      break if data[1] == 0

      client << data[0]
    end
  end

end

server = TCPServer.new("0.0.0.0", 1973)

first_time_packet = PacketBuilder.new.build(Packets::FirstTime.new) 

puts "Running server"
while client = server.accept?
  puts first_time_packet.to_slice.to_unsafe_bytes.hexdump
  client << first_time_packet

  puts "Client connected"
  puts client.remote_address

  spawn handle_client(client)
end


