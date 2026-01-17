# frozen_string_literal: true

require "socket"
require "json"

module Docyard
  class SSEServer
    HEARTBEAT_INTERVAL = 15
    DEFAULT_PORT = 4201

    def initialize(port: DEFAULT_PORT)
      @port = port
      @connections = []
      @mutex = Mutex.new
      @running = false
      @server = nil
      @accept_thread = nil
      @heartbeat_thread = nil
    end

    attr_reader :port

    def start
      @running = true
      @server = TCPServer.new("127.0.0.1", @port)
      @server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)

      start_accept_thread
      start_heartbeat_thread
    end

    def stop
      @running = false
      close_server
      @accept_thread&.kill
      @heartbeat_thread&.kill
      close_all_connections
    end

    def broadcast(event_type, data = {})
      message = format_sse_message(event_type, data)
      dead_connections = []

      @mutex.synchronize do
        @connections.each do |conn|
          write_to_connection(conn, message) or dead_connections << conn
        end

        dead_connections.each { |conn| remove_connection_unsafe(conn) }
      end
    end

    def connection_count
      @mutex.synchronize { @connections.size }
    end

    private

    def close_server
      @server&.close
    rescue StandardError
      nil
    end

    def start_accept_thread
      @accept_thread = Thread.new do
        while @running
          begin
            client = @server.accept
            Thread.new { handle_new_connection(client) }
          rescue IOError, Errno::EBADF
            break unless @running
          end
        end
      end
    end

    def handle_new_connection(client)
      request = read_http_request(client)
      return close_client(client) unless valid_sse_request?(request)

      send_sse_headers(client)
      @mutex.synchronize { @connections << client }
    rescue StandardError
      close_client(client)
    end

    def close_client(client)
      client.close
    rescue StandardError
      nil
    end

    def read_http_request(client)
      lines = []
      while (line = client.gets)
        break if line.strip.empty?

        lines << line
      end
      lines.join
    end

    def valid_sse_request?(request)
      request.include?("GET /_docyard/events") || request.include?("GET / ")
    end

    def send_sse_headers(client)
      headers = [
        "HTTP/1.1 200 OK",
        "Content-Type: text/event-stream",
        "Cache-Control: no-cache",
        "Connection: keep-alive",
        "Access-Control-Allow-Origin: *",
        "",
        ""
      ].join("\r\n")

      client.write(headers)
      client.write("retry: 1000\n\n")
      client.flush
    end

    def start_heartbeat_thread
      @heartbeat_thread = Thread.new do
        while @running
          sleep HEARTBEAT_INTERVAL
          broadcast("heartbeat", { time: Time.now.to_i }) if @running
        end
      end
    end

    def write_to_connection(conn, message)
      conn.write_nonblock(message)
      true
    rescue IO::WaitWritable, IOError, Errno::EPIPE, Errno::ECONNRESET, Errno::ETIMEDOUT
      false
    end

    def format_sse_message(event_type, data)
      json_data = data.to_json
      "event: #{event_type}\ndata: #{json_data}\n\n"
    end

    def remove_connection_unsafe(conn)
      @connections.delete(conn)
      close_client(conn)
    end

    def close_all_connections
      @mutex.synchronize do
        @connections.each { |conn| close_client(conn) }
        @connections.clear
      end
    end
  end
end
