// Feather disable all

#macro __POSTIE_DTYPE_OVERALL_LENGTH    buffer_u16
#macro __POSTIE_DTYPE_STREAM_UUID       buffer_u64
#macro __POSTIE_DTYPE_STREAM_INDEX      buffer_u64
#macro __POSTIE_DTYPE_PART_LENGTH       buffer_s16

__PostieSystem();
function __PostieSystem()
{
    static _system = (function()
    {
        with({})
        {
            return self;
        }
    })();
    
    return _system;
}