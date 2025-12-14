note
	description: "[
		Subscriber interface for pub/sub messaging.

		Implement this interface to receive messages from topics.
		The `on_message' feature is called when a message is published.

		Usage:
			class MY_HANDLER inherit SIMPLE_MQ_SUBSCRIBER
			feature
				on_message (msg: SIMPLE_MQ_MESSAGE)
					do
						print ("Received: " + msg.payload)
					end
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIMPLE_MQ_SUBSCRIBER

feature -- Callback

	on_message (a_message: SIMPLE_MQ_MESSAGE)
			-- Called when a message is received.
		require
			message_attached: a_message /= Void
		deferred
		end

feature -- Identification

	subscriber_id: STRING_8
			-- Unique identifier for this subscriber.
			-- Override to provide custom ID.
		do
			Result := generating_type.name.to_string_8 + "@" + ($Current).out
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
