classdef PushoverOptions < handle

properties
    % Control story for test method.
    controlStory = 'roof';
    % Displacement increment for test method.
    stepSize     = 0.001;
    % Maximum displacement of control story; test will abort if it reaches this value.
    maxDrift     = 6.0;
    % Constraints options.
    % See also OpenSees.ConstraintsOptions
    constraints  = OpenSees.ConstraintsOptions('type','Plain');
    % Test options.
    % See also OpenSees.TestOptions
    test         = OpenSees.TestOptions();
    % Algorithm options.
    % See also OpenSees.AlgorithmOptions
    algorithm    = OpenSees.AlgorithmOptions();
end

methods

function set.controlStory(obj,controlStory)
    if ~strcmp(controlStory,'roof') || controlStory > nStories
        error('Control story must be less than or equal to number of stories')
    end
    obj.controlStory = controlStory;
end
function set.stepSize(obj,stepSize)
    if ~isnumeric(stepSize) || ~isscalar(stepSize) || stepSize < 0
        error('stepSize must be a positive scalar')
    end
    obj.stepSize = stepSize;
end
function set.maxDrift(obj,maxDrift)
    if ~isnumeric(maxDrift) || ~isscalar(maxDrift) || maxDrift < 0
        error('maxDrift must be a positive scalar')
    end
    obj.maxDrift = maxDrift;
end
function set.constraints(obj,constraints)
    assert(isa(constraints,'ConstraintsOptions'), 'constraints must be a ConstraintsOptions object')
    obj.constraints = constraints;
end
function set.test(obj,test)
    assert(isa(test,'TestOptions'), 'test must be a TestOptions object')
    obj.test = test;
end
function set.algorithm(obj,algorithm)
    assert(isa(algorithm,'AlgorithmOptions'), 'algorithm must be a AlgorithmOptions object')
    obj.algorithm = algorithm;
end

end

end
