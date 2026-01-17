# frozen_string_literal: true

require "spec_helper"
require "socket"
require "timeout"

RSpec.describe Docyard::SSEServer do
  let(:port) { 19_876 }
  let(:server) { described_class.new(port: port) }

  after do
    server.stop
  end

  describe "#start" do
    it "starts listening on the specified port" do
      server.start
      expect { TCPSocket.new("127.0.0.1", port) }.not_to raise_error
    end
  end

  describe "#stop" do
    it "stops accepting connections" do
      server.start
      server.stop
      expect { TCPSocket.new("127.0.0.1", port) }.to raise_error(Errno::ECONNREFUSED)
    end
  end

  describe "#connection_count" do
    it "returns 0 when no connections" do
      server.start
      expect(server.connection_count).to eq(0)
    end

    it "tracks connected clients" do
      server.start

      client = TCPSocket.new("127.0.0.1", port)
      client.write("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n")
      client.flush

      sleep 0.1
      expect(server.connection_count).to eq(1)

      client.close
    end
  end

  describe "#broadcast" do
    it "sends SSE formatted messages to connected clients", :aggregate_failures do
      server.start

      client = TCPSocket.new("127.0.0.1", port)
      client.write("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n")
      client.flush

      sleep 0.1

      server.broadcast("reload", { type: "content" })

      response = Timeout.timeout(2) { client.read_nonblock(4096) }
      expect(response).to include("event: reload")
      expect(response).to include("data: {\"type\":\"content\"}")

      client.close
    end
  end
end
