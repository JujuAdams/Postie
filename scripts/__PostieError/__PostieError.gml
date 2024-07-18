// Feather disable all

function __PostieError()
{
    var _string = "Postie:\n";
    
    var _i = 0;
    repeat(argument_count)
    {
        _string += string(argument[_i]);
        ++_i;
    }
    
    if (is_callable(POSTIE_ERROR))
    {
        var _func = POSTIE_ERROR;
        
        if (_func == show_error)
        {
            show_error(_string + "\n ", true);
        }
        else
        {
            _func(_string);
        }
    }
}