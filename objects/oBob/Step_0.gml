// Feather disable all

if (keyboard_check(ord("B")))
{
    ++count;
    var _buffer = BufferLazy($"Bob says hi (count={count})");
    postie.Send("Alice", _buffer);
    buffer_delete(_buffer);
}