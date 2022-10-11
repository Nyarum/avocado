# OpenSSL crypto password (triple des ecb)

def encrypt_password(key, value)
    channel = Channel(String).new
    spawn do
        stdout = IO::Memory.new
        status = Process.run("./bin/encrypt_password", ["-key", key, "-value", value], output: stdout)
        channel.send(stdout.to_s)
    end

    channel.receive
end