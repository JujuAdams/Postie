// Feather disable al

/// .Destroy()
/// 
/// 
/// .Send(otherID, buffer, [offset=0], [length])
/// 
/// 
/// .Read(buffer, [offset=buffer_tell(buffer)])
/// 
/// 
/// .SetSendCallback(callback, [callbackData=undefined])
/// 
/// 
/// .SetReceiveCallback(callback, [callbackData=undefined])
/// 
/// 
/// .CorrespondantDelete(otherID)
/// 
/// 
/// .CorrespondantExists(otherID)
/// 
/// 
/// .GetPendingBuffers(otherID)
/// 
/// 
/// @param selfID

function Postie(_selfID) constructor
{
    if (not is_string(_selfID))
    {
        __PostieError("Identifier for Postie() must be a string (typeof=", typeof(_selfID), ")");
    }
    
    if (_selfID == "")
    {
        __PostieError("Identifier for Postie() cannot be an empty string");
    }
    
    __selfID = _selfID;
    
    __correspondantMap = ds_map_create();
    
    __sendCallback = function(_buffer, _offset, _length, _callbackData)
    {
        __PostieError("No send callback defined.\nPlease call .SetSendCallback() to set a send callback.");
    }
    
    __sendCallbackData = undefined;
    
    __receiveCallback = function(_buffer, _offset, _length, _callbackData)
    {
        __PostieError("No receive callback defined.\nPlease call .SetReceiveCallback() to set a receive callback.");
    }
    
    __receiveCallbackData = undefined;
    
    toString = function()
    {
        return $"<Postie {__selfID}>";
    }
    
    if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " created");
    
    __cleanUpKey = undefined;
    __timeSourceCleanUp = time_source_create(time_source_global, 1, time_source_units_seconds, function()
    {
        if (ds_map_size(__correspondantMap) > 0)
        {
            if (__cleanUpKey != undefined)
            {
                __cleanUpKey = ds_map_find_next(__correspondantMap, __cleanUpKey);
            }
            
            if (__cleanUpKey == undefined)
            {
                __cleanUpKey = ds_map_find_first(__correspondantMap);
            }
            
            var _correspondantStruct = __correspondantMap[? __cleanUpKey];
            if ((_correspondantStruct != undefined) && (_correspondantStruct.__lastActivity + 1000*POSTIE_CORRESPONDANT_TIMEOUT < current_time))
            {
                if (POSTIE_DEBUG_LEVEL >= 1) __PostieTrace("Warning! ", self, " has cleaned up dormant ", _correspondantStruct);
                
                _correspondantStruct.__Destroy();
                ds_map_delete(__correspondantMap, __cleanUpKey);
            }
        }
    },
    [], -1);
    time_source_start(__timeSourceCleanUp);
    
    
    
    Destroy = function()
    {
        if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " destroyed");
        
        time_source_destroy(__timeSourceCleanUp);
        
        var _array = ds_map_values_to_array(__correspondantMap);
        var _i = 0;
        repeat(array_length(_array))
        {
            _array[_i].__Destroy();
            ++_i;
        }
        
        //Null out our methods
        Destroy = function()
        {
            if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " already destroyed");
        }
        
        SetSendCallback       = function() {}
        SetReceiveCallback    = function() {}
        CorrespondantDelete   = function() {}
        CorrespondantExists   = function() { return false; }
        Send                  = function() {}
        Read                  = function() {}
        __CorrespondantEnsure = function() {}
        __ExecuteSend         = function() {}
        __ExecuteRead         = function() {}
    }
    
    SetSendCallback = function(_callback, _callbackData = undefined)
    {
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " set send callback to ", _callback, " (callback data = ", _callbackData, ")");
        
        __sendCallback     = _callback;
        __sendCallbackData = _callbackData;
    }
    
    SetReceiveCallback = function(_callback, _callbackData = undefined)
    {
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " set receive callback to ", _callback, " (callback data = ", _callbackData, ")");
        
        __receiveCallback     = _callback;
        __receiveCallbackData = _callbackData;
    }
    
    CorrespondantDelete = function(_otherID)
    {
        if (not is_string(_otherID))
        {
            __PostieError("Identifier for .CorrespondantDelete() must be a string (typeof=", typeof(_otherID), ")");
        }
        
        if (_otherID == "")
        {
            __PostieError("Identifier for .CorrespondantDelete() cannot be an empty string");
        }
        
        var _correspondant = __correspondantMap[? _otherID];
        if (_correspondant != undefined)
        {
            if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " deleting correspondant \"", _otherID, "\" for ", self);
            _correspondant.__Destroy();
        }
        else
        {
            if (POSTIE_DEBUG_LEVEL >= 1) __PostieTrace("Warning! ", self, " correspondant \"", _otherID, "\" doesn't exist");
        }
        
        ds_map_delete(__correspondantMap, _otherID);
    }
    
    CorrespondantExists = function(_otherID)
    {
        if (not is_string(_otherID))
        {
            __PostieError("Identifier for .CorrespondantExists() must be a string (typeof=", typeof(_otherID), ")");
        }
        
        if (_otherID == "")
        {
            __PostieError("Identifier for .CorrespondantExists() cannot be an empty string");
        }
        
        return ds_map_exists(__correspondantMap, _otherID);
    }
    
    GetPendingBuffers = function(_otherID)
    {
        if (not is_string(_otherID))
        {
            __PostieError("Identifier for .GetPendingBuffers() must be a string (typeof=", typeof(_otherID), ")");
        }
        
        if (_otherID == "")
        {
            __PostieError("Identifier for .GetPendingBuffers() cannot be an empty string");
        }
        
        var _correspondant = __correspondantMap[? _otherID];
        return (_correspondant == undefined)? undefined : _correspondant.__GetPendingBuffers();
    }
    
    Send = function(_otherID, _buffer, _offset = 0, _length = buffer_get_size(_buffer))
    {
        if (not is_string(_otherID))
        {
            __PostieError("Identifier for .Send() must be a string (typeof=", typeof(_otherID), ")");
        }
        
        if (_otherID == "")
        {
            __PostieError("Identifier for .Send() cannot be an empty string");
        }
        
        if (not buffer_exists(_buffer))
        {
            __PostieError("Buffer doesn't exist (", _buffer, ")");
        }
        
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " sending to \"", _otherID, "\" (", _buffer, ", offset=", _offset, ", length=", _length, ")");
        
        __CorrespondantEnsure(_otherID).__Send(_buffer, _offset, _length);
    }
    
    Read = function(_buffer, _overallOffset = buffer_tell(_buffer))
    {
        if (not buffer_exists(_buffer))
        {
            __PostieError("Buffer doesn't exist (", _buffer, ")");
        }
        
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " reading (", _buffer, ", offset=", _overallOffset, ")");
        
        buffer_seek(_buffer, buffer_seek_start, _overallOffset);
        
        var _overallLength = buffer_read(_buffer, __POSTIE_DATATYPE_OVERALL_LENGTH);
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " found overall length of ", _overallLength, " bytes (", _buffer, ")");
        
        var _sendID = buffer_read(_buffer, buffer_string);
        var _correspondant = __CorrespondantEnsure(_sendID);
        
        var _receiveID = buffer_read(_buffer, buffer_string);
        if (_receiveID != __selfID)
        {
            if (POSTIE_DEBUG_LEVEL >= 1) __PostieTrace("Warning! ", self, " received for \"", _receiveID, "\" from \"", _sendID, "\" but this isn't us (", _buffer, ")");
            return;
        }
        
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " handing ", _buffer, " to ", _correspondant);
        
        _correspondant.__Read(_buffer, _overallOffset + _overallLength);
        buffer_seek(_buffer, buffer_seek_start, _overallOffset + _overallLength);
    }
    
    __CorrespondantEnsure = function(_otherID)
    {
        var _correspondant = __correspondantMap[? _otherID];
        if (_correspondant == undefined)
        {
            if (POSTIE_DEBUG_LEVEL >= 2) __PostieTrace(self, " ensuring new correspondant ", _correspondant);
            
            _correspondant = new __PostieClassCorrespondant(self, _otherID);
            __correspondantMap[? _otherID] = _correspondant;
        }
        
        return _correspondant;
    }
    
    __ExecuteSend = function(_otherID, _buffer, _offset, _length)
    {
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " executing send callback to \"", _otherID, "\" (", _buffer, ", offset=", _offset, ", length=", _length, ")");
        
        __sendCallback(_otherID, _buffer, _offset, _length, __sendCallbackData);
    }
    
    __ExecuteRead = function(_otherID, _buffer, _offset, _length)
    {
        if (POSTIE_DEBUG_LEVEL >= 3) __PostieTrace(self, " executing read callback from \"", _otherID, "\" (", _buffer, ", offset=", _offset, ", length=", _length, ")");
        
        __receiveCallback(_otherID, _buffer, _offset, _length, __receiveCallbackData);
    }
}