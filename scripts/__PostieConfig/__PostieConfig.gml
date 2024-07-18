// Feather disable all

/// How many debug messages to emit during operation. This is useful for debugging the library or
/// tracking down bugs.
/// 
/// 0 = No messages other than errors
/// 1 = Warnings only
/// 2 = Create and destroy messages, and information about data stream ordering
/// 3 = Verbose output
#macro POSTIE_DEBUG_LEVEL  1

/// Postie will send all accumulated outbound packets every x-milliseconds. This guarantees a
/// certain submission rate to avoid hanging packets. Setting this number higher will prevent
/// Postie from straining the network when you're sending many small packets (which is typical for
/// many realtime games) but will add extra latency in your connection. A lower value will strain
/// the network but will lead to lower latency.
#macro POSTIE_ACCUMULATION_MAX_PERIOD  60  //milliseconds

/// Maximum size of a buffer emitted by Postie. The maximum transmission unit that Steam's
/// networking permits is 1200 bytes. Ethernet is typically quoted as 1500 bytes. Depending on what
/// networking your game is running on, these limits may be strictly enforced. To avoid losing
/// buffers, you should generally keep the maximum accumulation size a little below 1200 bytes to
/// account for other headers that may be attached to your buffers by GameMaker or the network.
#macro POSTIE_ACCUMULATION_MAX_SIZE  1150  //bytes

/// Postie will keep track of data streams from correspondants for as long as they are actively
/// sending data. However, if a data stream sits unused for an extended period of time, this may
/// lead to a memory leak. This is commonly the case when a correspondant has an unreliable
/// connection and is generating new data streams regularly. To combat memory leaks, Postie will
/// clean up inactive data streams after a fixed amount of time, as defined by the macro below.
#macro POSTIE_STREAM_TIMEOUT  60  //seconds

/// The following macros control connection simulation. This is helpful when stress testing your
/// networking code, especially when running multiple instances of the same game on one machine.
#macro POSTIE_SIMULATE_CONNECTION        false
#macro POSTIE_SIMULATE_PACKET_DELAY_MIN     50  //millseconds
#macro POSTIE_SIMULATE_PACKET_DELAY_MAX    250  //millseconds

/// Function to send debug messages to. Set this macro to <undefined> to disable debug messages
/// entirely (or set POSTIE_DEBUG_LEVEL to 0).
#macro POSTIE_SHOW_DEBUG_MESSAGE  show_debug_message

/// Function to send errors to. Set this macro to <undefined> to disable errors.
#macro POSTIE_ERROR  show_error