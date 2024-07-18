// Feather disable all

/// @param string

function BufferLazy(_string)
{
    var _buffer = buffer_create(string_byte_length(_string)+1, buffer_fixed, 1);
    buffer_write(_buffer, buffer_string, _string);
    return _buffer;
}