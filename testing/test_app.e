note
	description: "Test application for simple_mq"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests.
		do
			create tests
			io.put_string ("simple_mq test runner%N")
			io.put_string ("=====================%N%N")

			passed := 0
			failed := 0

			-- Message Tests
			io.put_string ("Message Tests%N")
			io.put_string ("-------------%N")
			run_test (agent tests.test_message_make, "test_message_make")
			run_test (agent tests.test_message_with_id, "test_message_with_id")
			run_test (agent tests.test_message_headers, "test_message_headers")
			run_test (agent tests.test_message_priority, "test_message_priority")
			run_test (agent tests.test_message_to_json, "test_message_to_json")

			-- Queue Tests (In-Memory)
			io.put_string ("%NQueue Tests (In-Memory)%N")
			io.put_string ("-----------------------%N")
			run_test (agent tests.test_queue_make, "test_queue_make")
			run_test (agent tests.test_queue_enqueue_dequeue, "test_queue_enqueue_dequeue")
			run_test (agent tests.test_queue_peek, "test_queue_peek")
			run_test (agent tests.test_queue_capacity, "test_queue_capacity")
			run_test (agent tests.test_priority_queue, "test_priority_queue")
			run_test (agent tests.test_queue_find_by_id, "test_queue_find_by_id")
			run_test (agent tests.test_queue_remove_by_id, "test_queue_remove_by_id")
			run_test (agent tests.test_queue_dequeue_batch, "test_queue_dequeue_batch")

			-- Topic Tests (Pub/Sub)
			io.put_string ("%NTopic Tests (Pub/Sub)%N")
			io.put_string ("---------------------%N")
			run_test (agent tests.test_topic_make, "test_topic_make")
			run_test (agent tests.test_topic_subscribe_publish, "test_topic_subscribe_publish")
			run_test (agent tests.test_topic_multiple_subscribers, "test_topic_multiple_subscribers")
			run_test (agent tests.test_topic_unsubscribe, "test_topic_unsubscribe")
			run_test (agent tests.test_topic_history, "test_topic_history")
			run_test (agent tests.test_topic_pattern_matching, "test_topic_pattern_matching")

			-- Facade Tests
			io.put_string ("%NFacade Tests%N")
			io.put_string ("------------%N")
			run_test (agent tests.test_mq_new_message, "test_mq_new_message")
			run_test (agent tests.test_mq_new_queue, "test_mq_new_queue")
			run_test (agent tests.test_mq_new_priority_queue, "test_mq_new_priority_queue")
			run_test (agent tests.test_mq_new_topic, "test_mq_new_topic")
			run_test (agent tests.test_mq_registry, "test_mq_registry")
			run_test (agent tests.test_mq_quick_send_receive, "test_mq_quick_send_receive")
			run_test (agent tests.test_mq_topics_matching, "test_mq_topics_matching")

			-- Redis Queue Tests (Mock)
			io.put_string ("%NRedis Queue Tests (Mock)%N")
			io.put_string ("------------------------%N")
			run_test (agent tests.test_redis_queue_make, "test_redis_queue_make")
			run_test (agent tests.test_redis_queue_with_timeout, "test_redis_queue_with_timeout")

			io.put_string ("%N=====================%N")
			io.put_string ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				io.put_string ("TESTS FAILED%N")
			else
				io.put_string ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	tests: LIB_TESTS

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				io.put_string ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			io.put_string ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
