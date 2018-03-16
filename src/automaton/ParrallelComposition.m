function [A] = ParrallelComposition(A1, A2)
% ParrallelComposition 
%   This function returns the parrallel composition of 2 Automata A1 and
%   A2.
%   Input       : A1 and A2 are a struct which contain :
%                    field 1 --> langage
%                    field 2 --> vectors
%% Shielding Inputs  
    if ~isa(A1, 'AutomateGraph')
        error('Input A1 must be an object from class AutomateGraph')
    end
    if ~isa(A2, 'AutomateGraph')
        error('Input A2 must be an object from class AutomateGraph')
    end

%% Creation Final Automata
    A = AutomateGraph();
%% Association of langage
    A.langage = union(A1.langage, A2.langage);
%% Establish vectors    
    %   If L(A1 U A2)(i) is contain in L(A1)
    %       If L(A1 U A2)(i) is contain in L(A2)
    %           kron(v1, v2)
    %       Else
    %           kron(v1, 1)
    %   Else
    %       kron(1, v2)
    for i = 1:length(A.langage)
        L_A1member = find(ismember(A1.langage, A.langage(i))==1) ;
        if ~isempty(L_A1member)  % if L(A)(i) is in L(A1)
            L_A2member = find(ismember(A2.langage, A1.langage(L_A1member))==1);
            if ~isempty(L_A2member) % if L(A2)(i) is in L(A1) recognize in L(A1)
                A.vector(end+1).Name = A1.langage(L_A1member);
                A.vector(end).value = kron(A1.vector(L_A1member).value, A2.vector(L_A2member).value);
            else
                A.vector(end+1).Name = A1.langage(L_A1member);
                A.vector(end).value = kron(A1.vector(L_A1member).value, [1:length(A1.vector(1).value)]);
            end
        else
            L_A2member = find(ismember(A2.langage, A.langage(i))==1);
            A.vector(end+1).Name = A2.langage(L_A2member);
            A.vector(end).value = kron([1:length(A1.vector(1).value)]', A2.vector(L_A2member).value);
        end
    end
end
