classdef Automaton
    %AUTOMATE Mod�lisation, analyse et simulation d'un automate.
    %   Cette classe permet l'�tude d'automate d�terministe ou non
    %   d�termiste � partir de matrices d'�v�nements.
    
    %% Attributs
    properties
        
        MatricesTransition% Transitions de tous les �v�nements.
        Fct % Automate Treillis
        NomsEvenements % nom de chaque �v�nements
    end
    
    
    %% M�thodes
    methods
        
        %%%%%%% Constructeur %%%%%%%%%%%%%%
        function obj = Automaton(varargin)
            if(nargin==2)
                obj.MatricesTransition  = varargin{1}; % matrice de transitions
                obj.MatricesTransition  = AjoutTransitionStable(obj); % Ajout de transition stable
                obj.NomsEvenements      = varargin{2};
                obj.Fct = CreationFonctionTransitionEnsembleDesParties(obj);
                
            end
        end
        
        %%%%%%%% Automate trellis %%%%%%%%%
        function F=CreationFonctionTransitionEnsembleDesParties(obj)
            n = size(obj.MatricesTransition{1},1); % nombre d'états
            c = length(obj.MatricesTransition); % nombre de conditions
            F = zeros(c,2^n); % fonction de conditions à créer
            
            for k=1:c % pour chaque condition de transition
                T=obj.MatricesTransition{k};
                R=zeros(n,2^n);
                % fprintf('Condition %d\n',k); % debug
                
                for j=1:n % pour chaque colonne de matrice de transition
                    M=1;
                    % fprintf('\t Colonne %d,\n',j);disp('\t Press Enter');pause;  % debug
                    for l=1:n % pour chaque case de la colonne
                        %                         fprintf('\t \t Case %d\n',l);  % debug
                        
                        if(l==j) % si on est sur la diagonale
                            % disp('\t \t \t Case diag\n')  % debug
                            
                            M=kron([0 1],M);
                        else     % sinon
                            % disp('\t \t \t Case non diag\n');  % debug
                            M=kron([1 1],M);
                        end
                        % disp('\t \t Press Enter'); pause ;  % debug
                    end
                    R=R+kron(M,T(:,j)) ;
                end
                F(k,1:2^n) = (2.^(0:n-1))*(R>0)+1 ;% R>0 pour r�cup�rer une matrice binaire
            end
        end
        
        %%%% D�placement dans trellis %%%%%
        function R=Evolution(obj,Conditions,Initial)
            R = Initial;
            F = obj.Fct;
            
            for k=1:length(Conditions)
                R = F(Conditions(k),R); % ligne Conditions(k), colonnes correspondant au coup précédent
            end
        end
        
        %%%%%% Transitions stables %%%%%%%%
        function A =AjoutTransitionStable(obj)
            A = obj.MatricesTransition;
            [~,x_c] = size(A);
            
            for a = 1: x_c
                [~,m_x] = find(sum(A{1,a})==0);
                if (~isempty(m_x))
                    for b = 1 : size(m_x,2)
                        A{1,a}(m_x(b),m_x(b))= 1;
                        
                    end
                end
                
            end
        end
        
        %%%%%% Recherche Sequence %%%%%%%%%
        
        function [path, seq] = PathResearche(obj, initialState, studiedState)
            %equivalence to the state of the treillis
            initialState=obj.Etats2Ensemble( initialState );
            studiedState=obj.Etats2Ensemble( studiedState );
            s=[];
            t=[];
            sequence=[];
            %We build the vector s and t for the graph
            for ligne = 1:size(obj.Fct,1)
                for colonne = 1:size(obj.Fct,2)
                    s_from = colonne;
                    t_out =obj.Fct(ligne,colonne);
                    if(t_out ~= s_from)
                        s = [s s_from];
                        t = [t t_out];
                        sequence = [sequence ligne];
                    end
                end
            end
            %we sort them to only keep one transition form a state to
            %another state
            st=[s' t' sequence'];
            st=sortrows(st,1);
            size(st)
            %duplicates are not saved
            new_s=[];
            new_t=[];
            new_sequence=[];
            
            for k=1:size(st,1)-1
                if(st(k,1)==st(k+1,1) && st(k,2)==st(k+1,2))
                else
                    new_s = [new_s st(k,1)];
                    new_t = [new_t st(k,2)];
                    new_sequence = [new_sequence st(k,3)];
                end
                %test for the last value
                lastindice=size(st,1);
                
                if (st(lastindice,1) == st(lastindice-1,1) && st(lastindice,2)~=st(lastindice-1,2))
                else
                    new_s = [new_s st(lastindice,1)];
                    new_t = [new_t st(lastindice,2)];
                    new_sequence = [new_sequence st(lastindice,3)];
                end
            end
            %graph is calculated
            G = digraph(new_s,new_t);
            %plot(G)
            
            %shortestpath is found with Bellaman-Ford algorithm
            path = shortestpath(G,initialState,studiedState,'Method','positive');
            
            %To remind which transition were taken
            seq=[];
            for l=1:(length(path)-1)
                for m=1:length(new_s)
                    if (path(l)==new_s(m) && path(l+1)==new_t(m))
                        seq = [seq new_sequence(m)];
                    end
                end
            end
        end
        
        
        
        
        %%%%%%% Accessibilit�e %%%%%%%%%%%%
        function [path, sequence, existingPath]=AutomateAccessible(obj, initialState, studiedState)
            %Depuis un unique etat issu du labyrinthe
            [path, sequence] = PathResearche(obj, initialState, studiedState);
            existingPath = (~isempty(path)); %(si qqch dans path, renvoie0)
        end
        
        %%%% Accessibilite incertaine %%%%%
        function Accessibilite=AutomateAccessibleIncertain(obj, Etat_initial, Etat)
            %Depuis un ensemble etat issu du labyrinthe
            l=1;
            Accessibilite=cell(1);
            Ensemble_etat=obj.EnsemblesContenantEtat(Etat);
            
            for i = 1 : size(Ensemble_etat,2)
                Ensemble_contenant_etat=obj.Ensemble2Etats(Ensemble_etat(i));
                [~,Accessible,~]= obj.RechercheSequenceEntreDeuxEnsemblesEtats(Etat_initial, Ensemble_contenant_etat);
                if(Accessible==1)
                    Accessibilite{1,l}=obj.NomEnsembleTreillis(obj.Etats2Ensemble(Ensemble_contenant_etat));
                    l=l+1;
                end
            end
        end
        
        %%%%% D'un ensemble aux �tats %%%%%
        function  Etats  = Ensemble2Etats(obj, Ensemble )
            taille = size(obj.FonctionTransitionEnsembleDesParties,2);
            if (taille>0)
                tabBin  = dec2bin(Ensemble-1 , taille); % ok
                C       = 1*( tabBin=='1');
                num     = C*rot90( diag(1:taille) );
                adre    = find(num>0);
                Etats = num(adre);
            else
                Etats = 0;
            end
        end
        
        %%% Tous les ensembles contenant un etat %%%
        function  Ensembles  = EnsemblesContenantEtat(obj, Etats )
            %ENSEMBLESCONTENANTETAT Recherche de tous les ensembles contenant un �tat.
            % Cette fonction prend un Etat et le nombre d'�tat de l'automate et avec
            % ceci trouve tous les ensembles contenant cet etat (entre 1 et
            % 2^NbrEtats).
            % Renvoie un vecteur contenant les ensembles, de taille (1,a) o� a est le
            % nombre d'ensembles.
            % Si le nombre d'�tats est inf�rieur � l'�tat recherch�, renvoie 'NaN'.
            
            taille = size(obj.FonctionTransitionEnsembleDesParties,2);
            if (  (taille >= max(Etats))  && ( isempty( find(Etats==0,1) )==1  )   ) % s'il n'y a pas que des �tats nuls
                R = ones(1,taille);
                
                for j=1:size(Etats,2)% pour tous les �tats entrants
                    M=1;
                    for l= 1:size(obj.MatricesTransition{1,1},1) % pour chaque case de la colonne
                        if(l==Etats(j)) % si on est sur la diagonale
                            M=kron([0 1],M);
                        else     % sinon
                            M=kron([1 1],M);
                            
                        end
                    end
                    R = bitand(R,M);
                end
                Ensembles= find(R);
                
            else
                Ensembles = 'NaN';
            end
        end
        
        %%%  L'ensemble � partir d'etats %%%
        function  Ensemble  = Etats2Ensemble(obj,Etats )
            %ETAT2ENSEMBLE converti un �tat des Etats en ensemble
            %   Detailed explanation goes here
            %% dimensions
            if (isempty(find(Etats<=0,1))) % pas de z�ro
                Ensemble = sum(2.^(Etats-1))+1;
            else
                Ensemble = 1;
            end
            
        end
        
 
    end % methods
end % classdef