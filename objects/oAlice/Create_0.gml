// Feather disable all

postie = new Postie("Alice");

postie.SetSendCallback(function(_otherID, _buffer, _offset, _length)
{
    oBob.postie.Read(_buffer, _offset);
});

postie.SetReceiveCallback(function(_otherID, _buffer, _offset, _length)
{
    var _string = buffer_read(_buffer, buffer_text);
    Trace("Alice received \"", _string, "\"");
});

count = 0;