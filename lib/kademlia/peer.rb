require_relative 'peer_errors'
require_relative 'handshake_response'
require_relative 'messages'
require_relative 'peer_socket'
require_relative 'peer_respond_state_machine'

class Peer
  attr_reader :id
  attr_reader :am_choking
  attr_reader :am_interested
  attr_reader :peer_choking
  attr_reader :peer_interested
  attr_reader :ip
  attr_reader :port
  attr_reader :hashed_info
  attr_reader :local_peer_id

  @@dht_bitmask = 0x0000000000000001
  @@request_sample_size = 10

  def initialize(ip, port, hashed_info, local_peer_id, id = generate_id)
    raise InvalidPeerError, "The hashed info cannot be null" unless hashed_info
    @ip = ip
    @id = set_id(id)
    @port = port
    @hashed_info = hashed_info
    @local_peer_id = local_peer_id
    @socket = PeerSocket.open(self)
    @msg_recv_queue = Queue.new
  end

  def ==(another_peer)
    return @ip == another_peer.ip && @port == another_peer.port
  end

  def to_s
    "ip: #{@ip} port: #{@port} id: #{@id} hashed_info: #{@hashed_info} local_peer_id: #{@local_peer_id} handshake_response: #{@handshake_response}"
  end

  def supports_dht?
    raise InvalidPeerError, "Cannot determine DHT support without a hand shake." unless @handshake_response
    (@handshake_response.reserved & @@dht_bitmask) != 0
  end

  def shake_hands
    # Only shake hands once
    return @handshake_response if @handshake_response != nil
    
    @handshake_response = @socket.shake_hands
    set_id(@handshake_response.peer_id)
    return @handshake_response
  end

  def read_next_message
    @socket.read
  end

  def write(message)
    puts "Writing to #{@ip}: #{message.class}"
    @socket.write(message)

    case message
    when UnchokeMessage
      @respond_machine.send_unchoke!
    end
  end

  def join(swarm)
    @swarm = swarm
  end

  def connect
    raise InvalidPeerState, "Cannot connect a peer without a Swarm." unless @swarm
    shake_hands
    write(@swarm.block_directory.bitfield)
    @respond_machine = PeerRespondStateMachine.new(self)
    start_msg_processing_thread
    start_read_thread
  end

  def disconnect
    stop_read_thread
    stop_msg_processing_thread
    @msg_recv_queue = Queue.new
  end

  def process_msg(msg)
    case msg
    when HaveMessage, BitfieldMessage
      @swarm.process_message(msg, self)
      @respond_machine.recv_have_message!
    end
  end

  def start_msg_processing_thread
    # puts "Starting the message processing thread for #{@ip}"

    @msg_proc_thread = Thread.new do
      loop do
	process_msg(@msg_recv_queue.pop)
      end
    end
  end

  def stop_msg_processing_thread
    @msg_proc_thread.kill
  end

  def start_read_thread
    # puts "Starting the read thread for #{@ip}"

    @read_thread = Thread.new do
      loop do
	msg = read_next_message
	puts "Received from #{@ip}: #{msg.class}"
	@msg_recv_queue.push(msg)
      end
    end
  end

  def stop_read_thread
    @read_thread.kill
  end

  def get_next_request(sample_size = @@request_sample_size)
    candidate_blocks = @swarm.block_directory.incomplete_blocks(self)
    candidate_blocks = candidate_blocks.first(sample_size)
    block = candidate_blocks.sample
    return block.to_wire
  end

  def is_interesting?
    @swarm.interesting_peers.include?(self)
  end

private

  def generate_id
    (0...20).map { ('a'..'z').to_a[rand(26)] }.join
  end

  def set_id(id)
    raise InvalidPeerError, "Peer ids must be 20 characters long." unless id.length == 20
    @id = id
  end

end
