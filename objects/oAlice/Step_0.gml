// Feather disable all

if (keyboard_check_pressed(ord("A")))
{
    ++count;
    var _buffer = BufferLazy($"Alice says hi (count={count})");
    postie.Send("Bob", _buffer);
    buffer_delete(_buffer);
}