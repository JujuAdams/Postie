// Feather disable all

function __PostieTrace()
{
    var _string = "Postie: ";
    
    var _i = 0;
    repeat(argument_count)
    {
        _string += string(argument[_i]);
        ++_i;
    }
    
    if (is_callable(POSTIE_SHOW_DEBUG_MESSAGE))
    {
        var _func = POSTIE_SHOW_DEBUG_MESSAGE;
        _func(_string);
    }
}