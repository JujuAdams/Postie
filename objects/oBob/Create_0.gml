// Feather disable all

postie = new Postie("Bob");
postie.CorrespondantAdd("Alice");

postie.SetSendCallback(function(_otherID, _buffer, _offset, _length)
{
    oAlice.postie.Read(_buffer, _offset);
});

postie.SetReceiveCallback(function(_otherID, _buffer, _offset, _length)
{
    var _string = buffer_read(_buffer, buffer_text);
    Trace("Bob received \"", _string, "\"");
});

count = 0;