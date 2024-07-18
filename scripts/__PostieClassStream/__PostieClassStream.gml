// Feather disable all

/// @param parent
/// @param streamUUID

function __PostieClassStream(_parent, _streamUUID) constructor
{
    __parent     = _parent;
    __streamUUID = _streamUUID;
    
    toString = function()
    {
        return $"<Stream {ptr(__streamUUID)}>";
    }
    
    __expectingIndex = 0;
    __lastRead = -infinity;
    __pendingMap = ds_map_create();
    
    __accumulationBuffer = __PostieBufferCreate(POSTIE_ACCUMULATION_MAX_SIZE);
    
    if (POSTIE_SIMULATE_CONNECTION)
    {
        __simQueue = ds_priority_create();
        
        __ReadSimulation = function(_buffer, _index, _endPos)
        {
            var _length = _endPos - buffer_tell(_buffer);
            var _copyBuffer = __PostieBufferCreate(_length);
            buffer_copy(_buffer, buffer_tell(_buffer), _length, _copyBuffer, 0);
            
            var _time = current_time + __PostieIRandomRange(POSTIE_SIMULATE_PACKET_DELAY_MIN, POSTIE_SIMULATE_PACKET_DELAY_MAX);
            
            if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " queuing ", _buffer, " through simulator until time ", _time, "ms (index=", _index, ", offset=", buffer_tell(_buffer), ", length=", _length, ")");
            
            ds_priority_add(__simQueue, {
                __buffer: _copyBuffer,
                __index:  _index,
                __time:   _time,
            },
            _time);
        }
        
        __timeSourceSimulation = time_source_create(time_source_global, 1, time_source_units_frames, function()
        {
            while(true)
            {
                var _struct = ds_priority_find_min(__simQueue);
                if (_struct == undefined) break;
                if (_struct.__time > current_time) break;
                
                ds_priority_delete_min(__simQueue);
                var _buffer = _struct.__buffer;
                
                if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " processing buffer with index ", _struct.__index, " (size=", buffer_get_size(_buffer), ", time=", current_time, ")");
                
                __ReadIndex(_buffer, _struct.__index, buffer_get_size(_buffer));
                __PostieBufferDelete(_buffer);
            }
        },
        [], -1);
        time_source_start(__timeSourceSimulation);
    }
    
    
    
    __ReadIndex = function(_buffer, _index, _endPos)
    {
        if (_index < __expectingIndex)
        {
            if (POSTIE_DEBUG_LEVEL >= 1) __PostieTrace("Warning! ", self, " handling index ", _index, " which has already been handled");
            return;
        }
        
        if (_index > __expectingIndex)
        {
            var _length = _endPos - buffer_tell(_buffer);
            
            if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " storing index ", _index, " as pending (", _buffer, ", offset=", buffer_tell(_buffer), ", length=", _length, ")");
            
            var _copyBuffer = __PostieBufferCreate(_length);
            buffer_copy(_buffer, buffer_tell(_buffer), _length, _copyBuffer, 0);
            __pendingMap[? _index] = _copyBuffer;
            
            return;
        }
        
        if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " reading ", _buffer, " with expected index ", __expectingIndex);
        
        __Read(_buffer, _endPos);
    }
    
    __GetPendingBuffers = function()
    {
        return ds_map_size(__pendingMap);
    }
    
    __Read = function(_buffer, _endPos)
    {
        __lastRead = current_time;
        
        while(buffer_tell(_buffer) < _endPos)
        {
            var _length = buffer_read(_buffer, __POSTIE_DTYPE_PART_LENGTH);
            if (_length > 0)
            {
                //Scale up the accumulation buffer if it's too small
                while(_length + buffer_tell(__accumulationBuffer) > buffer_get_size(__accumulationBuffer))
                {
                    if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " resizing accumulation buffer to ", 2*buffer_get_size(__accumulationBuffer));
                    buffer_resize(__accumulationBuffer, 2*buffer_get_size(__accumulationBuffer));
                }
                
                //Copy the input buffer to the accumulation buffer and advance the read head for both buffers
                buffer_copy(_buffer, buffer_tell(_buffer), _length, __accumulationBuffer, buffer_tell(__accumulationBuffer));
                buffer_seek(_buffer, buffer_seek_relative, _length);
                buffer_seek(__accumulationBuffer, buffer_seek_relative, _length);
            }
            else if (_length < 0)
            {
                if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " encountered end of buffer, flushing");
                __Flush();
            }
        }
        
        //Look for the next pending buffer
        ++__expectingIndex;
        var _pendingBuffer = __pendingMap[? __expectingIndex];
        
        //If we find one, read it immediately (and then clean it up)
        if (_pendingBuffer != undefined)
        {
            if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " found next buffer index ", __expectingIndex, " in pending buffers");
            
            ds_map_delete(__pendingMap, __expectingIndex);
            __Read(_pendingBuffer, buffer_get_size(_pendingBuffer));
            __PostieBufferDelete(_pendingBuffer);
        }
        else
        {
            if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " could not find next buffer index ", __expectingIndex, " in pending buffers, waiting");
        }
    }
    
    __Flush = function()
    {
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " flushing ", buffer_tell(__accumulationBuffer), " bytes (parent=", __parent, ")");
        
        var _length = buffer_tell(__accumulationBuffer);
        buffer_seek(__accumulationBuffer, buffer_seek_start, 0);
        __parent.__ExecuteRead(__accumulationBuffer, 0, _length);
        buffer_seek(__accumulationBuffer, buffer_seek_start, 0);
    }
    
    __Destroy = function()
    {
        if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " destroyed (parent=", __parent, ")");
        
        __PostieBufferDelete(__accumulationBuffer);
        
        var _array = ds_map_values_to_array(__pendingMap);
        var _i = 0;
        repeat(array_length(_array))
        {
            __PostieBufferDelete(_array[_i]);
            ++_i;
        }
        
        if (POSTIE_SIMULATE_CONNECTION)
        {
            __ReadSimulation = function() {}
            time_source_destroy(__timeSourceSimulation);
            
            while(ds_priority_size(__simQueue))
            {
                var _struct = ds_priority_delete_min(__simQueue);
                __PostieBufferDelete(_struct.__buffer);
            }
            
            ds_priority_destroy(__simQueue);
        }
        
        __ReadIndex         = function() {}
        __GetPendingBuffers = function() { return 0; }
        __Read              = function() {}
        __Flush             = function() {}
        __Destroy           = function() {}
    }
}