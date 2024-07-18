// Feather disable all

/// @param parent
/// @param otherID

function __PostieClassCorrespondant(_parent, _otherID) constructor
{
    __parent  = _parent;
    __otherID = _otherID;
    
    toString = function()
    {
        return $"<Correspondant {__otherID}>";
    }
    
    __streamUUID = int64(__PostieIRandom(0x7FFF_FFFF_FFFF_FFFF));
    __outgoingStreamIndex = 0;
    
    __lastActivity = -infinity;
    
    __streamMap = ds_map_create();
    
    __accumulated = false;
    __accumulationBuffer = __PostieBufferCreate(POSTIE_ACCUMULATION_MAX_SIZE);
    
    if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " created for ", __parent, ", outbound stream UUID = ", ptr(__streamUUID), ", accumulating using ", __accumulationBuffer);
    
    buffer_write(__accumulationBuffer, __POSTIE_DTYPE_OVERALL_LENGTH, 0); //Overall length of message
    buffer_write(__accumulationBuffer, buffer_string, __parent.__selfID);
    buffer_write(__accumulationBuffer, buffer_string, __otherID);
    buffer_write(__accumulationBuffer, __POSTIE_DTYPE_STREAM_UUID, __streamUUID);
    __headerSize = buffer_tell(__accumulationBuffer);
    buffer_write(__accumulationBuffer, __POSTIE_DTYPE_STREAM_INDEX, 0);
    
    __cleanUpKey = undefined;
    __timeSourceCleanUp = time_source_create(time_source_global, 1, time_source_units_seconds, function()
    {
        if (ds_map_size(__streamMap) > 0)
        {
            if (__cleanUpKey != undefined)
            {
                __cleanUpKey = ds_map_find_next(__streamMap, __cleanUpKey);
            }
            
            if (__cleanUpKey == undefined)
            {
                __cleanUpKey = ds_map_find_first(__streamMap);
            }
            
            var _streamStruct = __streamMap[? __cleanUpKey];
            if ((_streamStruct != undefined) && (_streamStruct.__lastRead + 1000*POSTIE_STREAM_TIMEOUT < current_time))
            {
                if (POSTIE_DEBUG_LEVEL >= 1) __PostieTrace("Warning! ", self, " has cleaned up dormant ", _streamStruct);
                
                _streamStruct.__Destroy();
                ds_map_delete(__streamMap, __cleanUpKey);
            }
        }
    },
    [], -1);
    time_source_start(__timeSourceCleanUp);
    
    
    
    __Read = function(_buffer, _endPos)
    {
        var _streamUUID = buffer_read(_buffer, __POSTIE_DTYPE_STREAM_UUID);
        
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " found stream ", ptr(_streamUUID), " (", _buffer, ")");
        
        var _streamStruct = __streamMap[? _streamUUID];
        if (_streamStruct == undefined)
        {
            if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " doesn't have stream ", ptr(_streamUUID), ", creating now");
            
            _streamStruct = new __PostieClassStream(self, _streamUUID);
            __streamMap[? _streamUUID] = _streamStruct;
        }
        
        var _index = buffer_read(_buffer, __POSTIE_DTYPE_STREAM_INDEX);
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " found index ", _index, " for ", _streamStruct);
        
        if (POSTIE_SIMULATE_CONNECTION)
        {
            _streamStruct.__ReadSimulation(_buffer, _index, _endPos);
            
            //Always update read time when simulating a connection
            __lastActivity = current_time;
        }
        else
        {
            var _successfulRead = _streamStruct.__ReadIndex(_buffer, _index, _endPos);
            if (_successfulRead)
            {
                //Only update our last read time if the buffer has the correct index and was accepted
                __lastActivity = current_time;
            }
        }
    }
    
    __ExecuteRead = function(_buffer, _offset, _length)
    {
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " executing read callback (", _buffer, ", offset=", _offset, ", length=", _length, ", parent=", __parent, ")");
        
        __parent.__ExecuteRead(__otherID, _buffer, _offset, _length);
    }
    
    __GetPendingBuffers = function()
    {
        var _count = 0;
        
        var _array = ds_map_values_to_array(__streamMap);
        var _i = 0;
        repeat(array_length(_array))
        {
            _count += _array[_i].__GetPendingBuffers();
            ++_i;
        }
        
        return _count;
    }
    
    __Send = function(_buffer, _offset, _length)
    {
        if (_length <= 0) return;
        
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " accumulating ", _length, " bytes (", _buffer, ", offset=", _offset, ", parent=", __parent, ")");
        
        __lastActivity = current_time;
        
        var _lengthRemaining = _length;
        var _copyOffset = _offset;
        while(_lengthRemaining > 0)
        {
            var _accumulationSpaceRemaining = POSTIE_ACCUMULATION_MAX_SIZE - buffer_tell(__accumulationBuffer);
            if (_accumulationSpaceRemaining <= buffer_sizeof(__POSTIE_DTYPE_PART_LENGTH))
            {
                __Flush();
                _accumulationSpaceRemaining = POSTIE_ACCUMULATION_MAX_SIZE - buffer_tell(__accumulationBuffer);
            }
            
            var _partLength = min(_lengthRemaining, _accumulationSpaceRemaining - buffer_sizeof(__POSTIE_DTYPE_PART_LENGTH));
            
            buffer_write(__accumulationBuffer, __POSTIE_DTYPE_PART_LENGTH, _partLength);
            buffer_copy(_buffer, _copyOffset, _partLength, __accumulationBuffer, buffer_tell(__accumulationBuffer));
            buffer_seek(__accumulationBuffer, buffer_seek_relative, _partLength);
            
            __accumulated = true;
            
            _copyOffset += _partLength;
            _lengthRemaining -= _partLength;
        }
        
        var _accumulationSpaceRemaining = POSTIE_ACCUMULATION_MAX_SIZE - buffer_tell(__accumulationBuffer);
        if (_accumulationSpaceRemaining < buffer_sizeof(__POSTIE_DTYPE_PART_LENGTH))
        {
            __Flush();
        }
        
        buffer_write(__accumulationBuffer, __POSTIE_DTYPE_PART_LENGTH, -1);
    }
    
    __Flush = function()
    {
        if (__accumulated)
        {
            if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " flushing accumulation buffer (index=", __outgoingStreamIndex, ", length=", buffer_tell(__accumulationBuffer), ", parent=", __parent, ")");
            
            buffer_poke(__accumulationBuffer, 0, __POSTIE_DTYPE_OVERALL_LENGTH, buffer_tell(__accumulationBuffer));
            __parent.__ExecuteSend(__otherID, __accumulationBuffer, 0, buffer_tell(__accumulationBuffer));
            
            __accumulated = false;
            
            //Increment our packet counter
            ++__outgoingStreamIndex;
            buffer_seek(__accumulationBuffer, buffer_seek_start, __headerSize);
            buffer_write(__accumulationBuffer, __POSTIE_DTYPE_STREAM_INDEX, __outgoingStreamIndex);
        }
        
        //time_source_reset() doesn't seem to do what we want?
        time_source_stop(__timeSourcePeriodicFlush);
        time_source_start(__timeSourcePeriodicFlush);
    }
    
    __timeSourcePeriodicFlush = time_source_create(time_source_global, POSTIE_ACCUMULATION_MAX_PERIOD/1000, time_source_units_seconds, __Flush);
    time_source_start(__timeSourcePeriodicFlush);
    
    __Destroy = function()
    {
        if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " destroyed (parent ", __parent, ")");
        
        __PostieBufferDelete(__accumulationBuffer);
        
        time_source_destroy(__timeSourcePeriodicFlush);
        time_source_destroy(__timeSourceCleanUp);
        
        var _array = ds_map_values_to_array(__streamMap);
        var _i = 0;
        repeat(array_length(_array))
        {
            _array[_i].__Destroy();
            ++_i;
        }
        
        ds_map_destroy(__streamMap);
        
        __Read              = function() {}
        __ExecuteRead       = function() {}
        __Send              = function() {}
        __Flush             = function() {}
        __Destroy           = function() {}
        __GetPendingBuffers = function() {}
    }
}