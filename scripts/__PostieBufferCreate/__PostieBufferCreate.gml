// Feather disable all

/// @param size

function __PostieBufferCreate(_size)
{
    return buffer_create(_size, buffer_grow, 1);
}