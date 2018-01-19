classdef IncrementalDynamicAnalysisOptions < handle

% optionsIDA - struct containing settings for incremental dynamic analysis
%
% Contains the following fields:
%   tExtra              - Extra time to add to end of analysis
%   nMotions            - Number of ground motions to analyze
%   ST                  - Vector of intensities to scale each ground motion to
%   collapseDriftRatio  - Story drift ratio used to define collapse
%   collapseProbability - Collapse probability being assessed
%   rating_DR           - Qualitative rating of the design requirements
%   rating_TD           - Qualitative rating of the test data
%   rating_MDL          - Qualitative rating of the archetype models
%
% optionsIDA = struct('tExtra',5, ...
%                     'nMotions',7, ...
%                     'ST',0.25:0.25:8, ...
%                     'collapseDriftRatio',0.05, ...
%                     'rating_DR','C', ...
%                     'rating_TD','C', ...
%                     'rating_MDL','C', ...
%                     'shortCircuit',true, ...
%                     'ST_tol',0.1, ...
%                     'ST_step',0.5 ...
% );

properties
    shortCircuit = true;
    collapseDriftRatio = 0.05;  % Story drift ratio used to define collapse
    tExtra = 5;         % Extra time after end of ground motion to add to each analysis
    nMotions = 7;       % Number of ground motions to analyze
    rating_DR = 'C';    % Qualitative rating of the design requirements
    rating_TD = 'C';    % Qualitative rating of the test data
    rating_MDL = 'C';   % Qualitative rating of the archetype models
end
properties (Hidden, Constant)
    validRatings = {'A', 'B', 'C', 'D'};
end

methods

function set.collapseDriftRatio(obj,cdr)
    assert(isnumeric(cdr) && isscalar(cdr) && (cdr > 0), 'collapseDriftRatio must be a positive scalar')
    obj.collapseDriftRatio = cdr;
end
function set.rating_DR(obj,rating_DR)
    check = strcmpi(rating_DR,obj.validRatings);
    assert(any(check),'Unknown rating: %s',rating_DR);
    obj.rating_DR = obj.validRatings{check};  % Ensure capitalization is correct
end
function set.rating_TD(obj,rating_TD)
    check = strcmpi(rating_TD,obj.validRatings);
    assert(any(check),'Unknown rating: %s',rating_TD);
    obj.rating_TD = obj.validRatings{check};  % Ensure capitalization is correct
end
function set.rating_MDL(obj,rating_MDL)
    check = strcmpi(rating_MDL,obj.validRatings);
    assert(any(check),'Unknown rating: %s',rating_MDL);
    obj.rating_MDL = obj.validRatings{check};  % Ensure capitalization is correct
end

end

end
