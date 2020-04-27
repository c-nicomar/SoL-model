classdef Stack < handle
    %STACK A last in, first out data structure for storing elements.
    
    %% Properties =========================================================
    
    properties (Access = private)
        % A cell array for storing each of the elements on the stack
        buffer;
        
        % The number of elements currently on the stack
        count;
        
        % The maximum number of elements that can be stored on the stack.
        % Used for preallocation purposes to avoid having to continuously
        % resize the stack buffer when elements are added. By default it is
        % set to 100.
        capacity;
    end
    
    
    
    %% Methods ============================================================
    
    methods
        %% Constructor ____________________________________________________
        
        function this = Stack(element)
            if(nargin >= 1 && iscell(element))
                % A cell array of elements has been given so assign as the
                % stack
                this.buffer = element(:);
                this.count = numel(element);
                this.capacity = this.count;
            elseif nargin >= 1
                % A single element has been given preallocate the stack to
                % its maximum capacity and push the element onto it
                this.buffer = cell(100, 1);
                this.capacity =100;
                this.buffer{1} = element;
                this.count = 1;
            else
                % No element has been given so just preallocate the stack
                this.buffer = cell(100, 1);
                this.capacity = 100;
                this.count = 0;
            end
        end
        
        
        %% Accessors ______________________________________________________
        
        %% Get the number of elements currently on the stack
        function s = size(this)
            s = this.count;
        end
        
        %% Clear all elements from the Stack
        function clear(this)
            this.count = 0;
            this.buffer = cell(100, 1);
        end
        
        %% Check if any elements exist on the stack
        %  Returns a boolean value that is true if no elements exist on the
        %  stack (count = 0) and false otherwise
        function b = isempty(this)            
            b = ~logical(this.count);
        end
        
        %% Returns the object at the top of the Stack without removing it
        function element = peek(this)
            element = this.buffer{this.count};
        end
        
        %% Returns all objects in the Stack without removing them
        function c = peekAll(this)
            c = this.buffer(1:this.count);
        end
        
        
        %% Mutators _______________________________________________________
        
        %% Inserts an object at the top of the Stack
        function push(this, element)
            if this.count >= this.capacity
                % The capacity of the stack has been exceeded so double the
                % length of the element buffer
                this.buffer(this.capacity+1:2*this.capacity) = cell(this.capacity, 1);
                this.capacity = 2*this.capacity;
            end
            
            this.count = this.count + 1;
            this.buffer{this.count} = element;
        end
        
        %% Removes and returns the object at the top of the Stack
        function element = pop(this)
            if this.count == 0
                element = [];
                warning('Stack:No_Data', 'trying to pop element of an emtpy stack');
            else
                element = this.buffer{this.count};
                this.count = this.count - 1;
            end        
        end
    end
end