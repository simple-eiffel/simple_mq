note
	description: "Test subscriber for pub/sub testing"
	author: "Larry Rix"

class
	TEST_SUBSCRIBER

inherit
	SIMPLE_MQ_SUBSCRIBER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize test subscriber.
		do
			create received_messages.make (10)
		end

feature -- Access

	received_messages: ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
			-- Messages received by this subscriber.

	received_count: INTEGER
			-- Number of messages received.
		do
			Result := received_messages.count
		end

	last_message: detachable SIMPLE_MQ_MESSAGE
			-- Most recently received message.
		do
			if not received_messages.is_empty then
				Result := received_messages.last
			end
		end

feature -- Callback

	on_message (a_message: SIMPLE_MQ_MESSAGE)
			-- Receive and store message.
		do
			received_messages.extend (a_message)
		end

feature -- Reset

	clear
			-- Clear received messages.
		do
			received_messages.wipe_out
		ensure
			empty: received_count = 0
		end

end
