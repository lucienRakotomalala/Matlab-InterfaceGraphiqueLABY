classdef (Abstract) ModelSED %peut-�tre h�ritage de handle pour set/get
    %MODELSED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
        presentState
    end
    
    methods (Abstract)
         nextState   = f(presentState,in)
        presentState = m(nextState,init)
        out          = g(presentState,in)
    end
    
end

