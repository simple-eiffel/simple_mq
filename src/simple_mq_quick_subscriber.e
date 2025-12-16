note
	description: "Subscriber adapter for SIMPLE_MQ_QUICK - wraps procedure as subscriber."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_MQ_QUICK_SUBSCRIBER

inherit
	SIMPLE_MQ_SUBSCRIBER

create
	make

feature {NONE} -- Initialization

	make (a_handler: PROCEDURE [STRING])
			-- Create subscriber with handler procedure.
		require
			handler_not_void: a_handler /= Void
		do
			handler := a_handler
		ensure
			handler_set: handler = a_handler
		end

feature -- Subscriber interface

	on_message (a_message: SIMPLE_MQ_MESSAGE)
			-- Handle incoming message by calling handler.
		do
			handler.call ([a_message.payload])
		end

feature {NONE} -- Implementation

	handler: PROCEDURE [STRING]
			-- Handler procedure for messages.

invariant
	handler_exists: handler /= Void

end
