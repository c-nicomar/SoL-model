function hdl = proplistener(hContainer, hSrc, eventName, callback)
%  PROPLISTENER  Attach a listener callback to property value change event(s)
%
%  PROPLISTENER(HContainer, HSrc, EventNames, Callback)
%  Adds a listener to each object in HContainer for events
%  originating from each property in HSrc having one of the names listed
%  in EventNames.
%
%  If EventNames contains only property events (PreGet, PreSet, PostGet,
%  or PostSet), hSrc may contain a list of property handles or a list
%  of property names (string or cell array of strings).
%
%  PROPLISTENER always attaches the listener to each container object
%  so that the listener survives as long as the longest-lived
%  container object.
%
%  Callback should be specified in the normal Matlab Callback format:
%  'string', @function_handle or {@function_handle, params...}. A
%  sample callback function is included at the bottom of this m-file.
%  If Callback is empty, the corresponding event listeners are removed.
%
%  PROPLISTENER(HSrc, EventNames, Callback)
%  Adds a listener to each object in HSrc for events originating from
%  each object in HSrc having one of the names listed in EventNames.
%
%  Note: This is an enhancement of Matlab's hidden and unsupported
%        addlistener function within the uitools folder.
%
%  Note: If you wish to modify the property value in set/get, you need to
%  ^^^^  specify a schema.prop SetFunction (or GetFunction) instead of
%        using this function. The reason is that this function is only a
%        listener for set/get events, and not really a programming hook.
%
%        Here's a skeleton for setting a property's SetFunction:
%          set(findprop(handle(gcf),propName), 'SetFunction', @mySetFunc)
%          ...
%          function updatedValue = mySetFunc(hObj,proposedValue)
%             updatedValue = ...
%          end

% Copyright 2003-2005 The MathWorks, Inc.
% Modified 12-Jan-2008 by Yair M. Altman

    % make sure we have handle objects
    hContainer = handle(hContainer);

    % Get schema.prop handle(s) for the specified property/ies
    if (nargin == 3)
        callback = eventName;
        eventName = hSrc;
        hSrc = hContainer;
    elseif ischar(hSrc) && numel(hContainer) == 1
        try
            hSrc = hContainer.findprop(hSrc);
        catch
            error(['Property ''' hSrc ''' was not found in requested object'])
        end
    elseif iscell(hSrc) && numel(hContainer) == 1
        for i = 1:length(hSrc)
            try
                temp(i) = hContainer.findprop(hSrc{i});  %#ok grow
            catch
                error(['Property ''' hSrc{i} ''' was not found in requested object'])
            end
        end
        hSrc = temp;
    end

    % Fix event name(s) & attach property listener(s) if non-empty callback
    hl = handle([]);
    if ischar(eventName)
        eventName = processEventName(eventName);
        hl = attachListener(hContainer, hSrc, eventName, callback);
    elseif iscell(eventName)
        for i = 1:length(eventName)
            eventName{i} = processEventName(eventName{i});
            hTemp = attachListener(hContainer, hSrc, eventName{i}, callback);
            if ~isempty(hTemp)
                hl(i) = hTemp;
            end
        end
    end

    % Return a handle to the newly created listener, if requested
    if nargout > 0
        hdl = hl;
    end
end

%% Check & fix EventName
function eventName = processEventName(eventName)
    eventName = strrep(lower(eventName),'property','');
    switch eventName
        case {'preset','preget','postset','postget'}
            eventName = ['P' eventName(2:end-3) upper(eventName(end-2)) 'et'];
        otherwise
            error(['unrecognized EventName ''' eventName ''':' char(10) 'only ''PreGet'', ''PreSet'', ''PostGet'' & ''PostSet'' are supported']);
    end
    eventName = ['Property' eventName];
end

%% Attach a property listener
function hl = attachListener(hContainer, hSrc, eventName, callback)

    % Attach the prop listener, if callback is not empty
    hl = handle([]);
    if ~isempty(callback)
        hl = handle.listener(hContainer, hSrc, eventName, callback);
    end

    % Persist property listeners (or remove if empty callback)
    for i = 1:length(hContainer)
        hC = hContainer(i);
        p = findprop(hC, 'Listeners__');
        if (isempty(p))
            p = schema.prop(hC, 'Listeners__', 'handle vector');
            % Hide this property and make it non-serializable and
            % non copy-able.
            set(p,  'AccessFlags.Serialize', 'off', ...
                'AccessFlags.Copy', 'off',...
                'FactoryValue', [], 'Visible', 'off');
        end
        % filter out any non-handles
        hC.Listeners__ = hC.Listeners__(ishandle(hC.Listeners__));

        % If empty callback, remove (delete) listeners
        if isempty(callback)
            removeIdx = strcmp(get(hC.Listeners__,'EventType'),eventName);
            delete(hC.Listeners__(removeIdx));
            hC.Listeners__(removeIdx) = [];

        % Otherwise, persist them in the listeners list
        else
            hC.Listeners__ = [hC.Listeners__; hl];
        end
    end
end

%% Sample PropertyPreSet function
function samplePreSet(hProp, eventData, varargin)  %#ok unused
    eventType  = eventData.Type;  %#ok unused
    hContainer = eventData.AffectedObject;
    try
        newValue = eventData.NewValue          %#ok unused
        oldValue = get(hContainer,hProp.Name)  %#ok unused
    catch
        % NewValue is only available in Property sets - not gets!
    end
end
    
    